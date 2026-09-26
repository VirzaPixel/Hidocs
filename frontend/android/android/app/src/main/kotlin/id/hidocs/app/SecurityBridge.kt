package id.hidocs.app

import android.app.Activity
import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.app.PictureInPictureParams
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.Manifest
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Process
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.OnApplyWindowInsetsListener
import android.provider.Settings
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Jembatan keamanan ujian.
 *
 * Menangani FLAG_SECURE, status izin overlay, VOLUME OTOMATIS, screening
 * aplikasi floating, dan suara peringatan saat keluar aplikasi.
 *
 * REVISI LANJUTAN 7 — prinsip screening:
 *  - Screening membaca INVENTARIS SELURUH aplikasi terpasang
 *    (`getInstalledPackages` + izin `SYSTEM_ALERT_WINDOW` tiap aplikasi),
 *    BUKAN hanya aplikasi yang kebetulan sedang menayangkan overlay.
 *  - Penilaian "ini aplikasi floating atau bukan" dilakukan di Dart
 *    (lib/services/security/floating_app_catalog.dart) supaya katalog,
 *    pola nama paket, dan kata kunci nama tampilan bisa diperbarui tanpa
 *    menyentuh kode Kotlin dan bisa diuji satuan.
 *  - Sinyal runtime (bubble tampil, op overlay terpakai, task PiP) dikirim
 *    sebagai fakta tambahan `isFloatingActive` — dipakai untuk pemindaian
 *    berkala selama ujian agar tidak menimbulkan pelanggaran berulang.
 *  - "Mode Sunyi Total" (DND) DIHAPUS. Gantinya: volume media dimaksimalkan
 *    (AUTO FULL) saat ujian dimulai, dipulihkan saat ujian selesai, dan
 *    `assets/keluar.mp3` dibunyikan lewat native ketika siswa keluar aplikasi.
 *
 * REVISI LANJUTAN 9 — penguncian TANPA provisioning:
 *  - Seluruh jalur **Lock Task Mode / device owner DIHAPUS**. Mengunci layar
 *    Android sejati hanya mungkin bila aplikasi berstatus device owner, dan
 *    status itu tidak bisa diminta dari dalam aplikasi: harus lewat ADB atau
 *    provisioning QR sebelum aplikasi pernah dipakai. Menyuruh guru/siswa
 *    menjalankan skrip `adb` jelas tidak realistis, jadi jalur itu dibuang.
 *    (Sebagai catatan teknis: `lockTaskMode="if_whitelisted"` TANPA allowlist
 *    hanya memunculkan dialog persetujuan screen pinning — lihat dokumentasi
 *    atribut `lockTaskMode` di SDK — sehingga tidak berguna tanpa provisioning.)
 *  - Penggantinya adalah penguncian berlapis yang bekerja di SEMUA perangkat:
 *      1. [applyFullscreenLock] — status bar + nav bar disembunyikan permanen.
 *      2. [pullTaskToFront] — task HiDocs sendiri ditarik kembali ke depan
 *         begitu siswa menekan Home/Recents (lihat [onUserLeftActivity]),
 *         memakai `ActivityManager.getAppTasks()` + `AppTask.moveToFront()`.
 *         Keduanya menyangkut task MILIK SENDIRI sehingga tidak butuh izin
 *         apa pun dan tidak pernah melempar `SecurityException` — berbeda
 *         dengan `getRunningTasks`/`moveTaskToFront` yang menuntut
 *         `REORDER_TASKS` (sudah diverifikasi pada `android.jar`).
 *      3. Alarm `assets/keluar.mp3` + telemetry pelanggaran milik Dart.
 *  - Perlu dilaporkan jujur: tanpa device owner, sistem Android tetap boleh
 *    memindahkan aplikasi ke latar (mis. pengguna menekan Home dua kali cepat
 *    atau membuka panel notifikasi dari lockscreen). Yang bisa dijamin adalah
 *    aplikasi KEMBALI ke depan dalam hitungan milidetik dan setiap
 *    pelanggaran tercatat — bukan larangan mutlak dari sistem operasi.
 */
class SecurityBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private var secureEnabled = false

    /** Volume media sebelum ujian (dipulihkan saat ujian selesai). -1 = belum disimpan. */
    private var savedExamVolume: Int = -1

    /** Alarm keluar aktif hanya selama sesi ujian berjalan. */
    private var exitAlarmArmed = false
    private var exitAlarmPlayer: MediaPlayer? = null
    private var exitAlarmCachedFile: File? = null

    /**
     * `true` HANYA selama halaman pengisian (sesi ujian) yang sedang dibuka.
     *
     * Ini penjaga kedua untuk alarm keluar: [exitAlarmArmed] disetel dari
     * Dart, tapi baik halaman gerbang maupun layar token BUKAN bagian dari
     * sesi ujian. Tanpa penjaga ini, satu sesi ujian yang tertinggal
     * "armed" membuat suara alarm berbunyi walau siswa baru sekadar
     * sedang memasukkan token. Lihat [onUserLeftActivity].
     */
    private var examSessionActive = false

    /** `true` selama layar dikunci penuh (status bar + nav bar tak bisa muncul). */
    private var fullscreenLocked = false

    /** `true` bila alarm keluar sedang dipasang (dipakai MainActivity). */
    val isExitAlarmArmed: Boolean get() = exitAlarmArmed

    /** `true` bila sesi ujian benar-benar sedang dikerjakan. */
    val isExamSessionActive: Boolean get() = examSessionActive

    /** `true` bila layar sedang dikunci penuh. */
    val isFullscreenLocked: Boolean get() = fullscreenLocked

    /**
     * `true` bila penarikan kembali ke depan sedang diminta aktif.
     *
     * Dipakai [MainActivity.onUserLeaveHint] untuk memutuskan apakah task
     * perlu ditarik kembali: saat siswa baru memasukkan token atau menutup
     * aplikasi dari halaman gerbang, task TIDAK boleh ditarik-tarik lagi.
     */
    private var examConfinementActive = false

    /** `true` bila mode penguncian ujian sedang aktif pada proses ini. */
    val isExamConfinementActive: Boolean get() = examConfinementActive

    fun register() {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecure" -> {
                    enableSecure()
                    result.success(true)
                }
                "disableSecure" -> {
                    disableSecure()
                    result.success(true)
                }
                "isSecureEnabled" -> result.success(secureEnabled)
                "canDrawOverlays" -> result.success(canDrawOverlays())
                "openOverlaySettings" -> {
                    openOverlaySettings()
                    result.success(true)
                }
                "hasUsageStatsPermission" -> result.success(hasUsageStatsPermission())
                "openUsageAccessSettings" -> {
                    openUsageAccessSettings()
                    result.success(true)
                }
                "maximizeExamVolume" -> result.success(maximizeExamVolume())
                "restoreExamVolume" -> result.success(restoreExamVolume())
                "currentMediaVolume" -> result.success(currentMediaVolume())
                // Persentase + status pengisian baterai untuk bilah status
                // dalam aplikasi (halaman pengisian menutupi status bar HP).
                "getBatteryInfo" -> result.success(getBatteryInfo())
                // Inventaris SELURUH aplikasi terpasang + fakta floating-nya.
                "getInstalledApps" -> scanInstalledApps(result)
                // Hanya aplikasi yang SEDANG menayangkan overlay/bubble/PiP.
                "getActiveFloatingApps" -> result.success(getActiveFloatingApps())
                "playExitAlarm" -> result.success(playExitAlarm())
                "stopExitAlarm" -> {
                    stopExitAlarm()
                    result.success(true)
                }
                "setExitAlarmArmed" -> {
                    setExitAlarmArmed(call.arguments as? Boolean ?: false)
                    result.success(true)
                }
                "openAppSettings" -> {
                    result.success(openAppSettings(call.argument("packageName")))
                }
                "isDeviceAdminActive" -> result.success(isDeviceAdminActive())
                // Kunci tampilan penuh saat mengerjakan (status bar + nav bar).
                "setFullscreenLock" -> {
                    setFullscreenLock(call.argument("enabled") ?: false)
                    result.success(true)
                }
                // Screen pinning: satu-satunya cara RESMI memblokir panel
                // notifikasi dari aplikasi biasa. Dipicu tombol siswa karena
                // Android menampilkan dialog persetujuan "Pin app?".
                "startExamLockTask" -> result.success(startExamLockTask())
                "stopExamLockTask" -> result.success(stopExamLockTask())
                "isExamLockTaskActive" -> result.success(isExamLockTaskActive())
                // Penjaga alarm keluar: hanya menyala saat halaman pengisian
                // (sesi ujian) yang benar-benar terbuka.
                "setExamSessionActive" -> {
                    setExamSessionActive(call.argument("active") ?: false)
                    result.success(true)
                }
                "startLockService" -> {
                    ExamLockService.start(activity)
                    result.success(true)
                }
                "stopLockService" -> {
                    ExamLockService.stop(activity)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        fullscreenLocked = false
        examSessionActive = false
        stopSystemBarWatchdog()
        stopExamLockTask()
        disableSecure()
        releaseExitAlarm()
        exitAlarmArmed = false
        examConfinementActive = false
        channel.setMethodCallHandler(null)
    }

    // ---------- Kunci tampilan penuh (fullscreen lock) ----------

    /**
     * Benar-benar mengunci layar saat mengerjakan ujian: status bar DAN nav bar
     * disembunyikan, gesture "geser dari tepi" dibuat tidak interaktif, dan
     * (bila siswa menyetujui) aplikasi diletakkan dalam screen pinning
     * sehingga panel notifikasi benar-benar tertutup.
     *
     * KOREKSI FAKTA (revisi ini). Komentar lama menyatakan
     * `BEHAVIOR_DEFAULT` membuat penyembunyian "permanen". Itu KELIRU.
     * Pada androidx `WindowInsetsControllerCompat`:
     *   - `BEHAVIOR_DEFAULT = 1` dan `BEHAVIOR_SHOW_BARS_BY_SWIPE = 1`
     *     adalah NILAI YANG SAMA — artinya memakai `BEHAVIOR_DEFAULT` justru
     *     MEMBIARKAN system bar dimunculkan lewat geseran dari tepi layar
     *     (dokumentasi resminya: "they can be revealed with system gestures,
     *     such as swiping from the edge of the screen where the bar is hidden
     *     from"), persis keluhan "status bar masih bisa di-swipe".
     *   - `BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE = 2` memunculkan bar HANYA
     *     sementara, sebagai overlay yang tidak interaktif dan otomatis
     *     hilang — jadi siswa tidak bisa menekan notifikasi atau membuka
     *     panelnya. Itu yang dipakai di sini.
     *
     * Untuk BENAR-BENAR memblokir panel notifikasi, Android tidak menyediakan
     * sihir dari sisi aplikasi biasa: satu-satunya jalur resmi adalah
     * **screen pinning / lock task mode** ([startExamLockTask]). Lihat
     * [startExamLockTask] untuk batasnya.
     *
     * Status "yang sedang dikunci" disimpan di [fullscreenLocked] supaya
     * [reapplyFullscreenLock] bisa mengunci ulang setiap kali window regain
     * focus, dan [systemBarWatchdog] mengulanginya berkala.
     */
    private fun setFullscreenLock(enabled: Boolean) {
        fullscreenLocked = enabled
        applyFullscreenLock(enabled)
        if (enabled) startSystemBarWatchdog() else stopSystemBarWatchdog()
    }

    /**
     * Kunci ulang tampilan penuh bila sedang dalam mode ujian.
     *
     * Dipanggil dari [MainActivity.onWindowFocusChanged] / `onResume`:
     * gestur tepi (tarik panel notifikasi, geser nav bar) sewaktu-waktu
     * memunculkan system bar sementara, dan tanpa penguncian ulang bar itu
     * tidak pernah hilang lagi.
     */
    fun reapplyFullscreenLock() {
        if (fullscreenLocked) applyFullscreenLock(true)
    }

    private fun applyFullscreenLock(enabled: Boolean) {
        activity.runOnUiThread {
            val window = activity.window
            if (enabled) {
                window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
                // Hilangkan cutout/system bar insets supaya konten aplikasi
                // benar-benar memenuhi layar.
                WindowCompat.setDecorFitsSystemWindows(window, false)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
            }

            val controller = WindowCompat.getInsetsController(window, window.decorView)
            if (enabled) {
                controller.hide(WindowInsetsCompat.Type.systemBars())
                // PENTING: BEHAVIOR_DEFAULT (== BEHAVIOR_SHOW_BARS_BY_SWIPE, 1)
                // justru MEMBIARKAN status bar ditarik keluar dengan geseran
                // dari tepi layar. Yang benar untuk ujian adalah TRANSIENT:
                // bar hanya muncul sesaat sebagai overlay tidak interaktif
                // lalu hilang sendiri, sehingga notifikasi tidak bisa
                // disentuh maupun dibuka.
                controller.systemBarsBehavior =
                    WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            } else {
                controller.show(WindowInsetsCompat.Type.systemBars())
            }
        }
    }

    /**
     * Penjaga berkala: system bar yang sempat muncul dipaksa tersembunyi lagi.
     *
     * [reapplyFullscreenLock] hanya bekerja saat window kehilangan/mendapat
     * fokus, sedangkan geseran tepi layar bisa memunculkan status bar TANPA
     * perubahan fokus. Selama mode ujian, watchdog ini mengulang penyembunyian
     * setiap [SYSTEM_BAR_WATCHDOG_MS] sehingga bar itu tidak pernah bertahan.
     *
     * Native membuktikan enaknya sendiri: [isSystemBarVisible] diperiksa lebih
     * dulu, jadi saat bar memang sudah tersembunyi tidak ada pemanggilan
     * window yang sia-sia.
     *
     * Selain watchdog polling ini, [startInsetListener] memasang listener
     * event-driven yang bekerja SEKETIKA saat inset berubah — lebih cepat
     * daripada menunggu putaran polling berikutnya.
     */
    private val systemBarWatchdog = object : Runnable {
        override fun run() {
            if (!fullscreenLocked) return
            if (isSystemBarVisible()) applyFullscreenLock(true)
            activity.window.decorView.postDelayed(this, SYSTEM_BAR_WATCHDOG_MS)
        }
    }

    private fun startSystemBarWatchdog() {
        val view = activity.window.decorView
        view.removeCallbacks(systemBarWatchdog)
        view.postDelayed(systemBarWatchdog, SYSTEM_BAR_WATCHDOG_MS)
        startInsetListener()
    }

    private fun stopSystemBarWatchdog() {
        try {
            activity.window.decorView.removeCallbacks(systemBarWatchdog)
        } catch (_: Exception) {
        }
        stopInsetListener()
    }

    /**
     * Listener event-driven untuk perubahan inset window.
     *
     * Watchdog polling (150 ms) masih menyisakan jeda: bar bisa muncul
     * sesaat sebelum putaran berikutnya. Listener ini bereaksi SEKETIKA
     * setiap kali sistem melaporkan perubahan inset — termasuk saat status
     * bar atau nav bar dimunculkan oleh gestur tepi — sehingga bar ditutup
     * sebelum pengguna sempat berinteraksi dengannya.
     *
     * Tipe eksplisit `OnApplyWindowInsetsListener` (bukan `ViewCompat.`-nya)
     * diperlukan agar Kotlin bisa meng-infer parameter lambda dengan benar.
     */
    private val insetListener = OnApplyWindowInsetsListener { _, insets ->
        if (fullscreenLocked && insets.isVisible(WindowInsetsCompat.Type.systemBars())) {
            // Bar baru saja muncul — sembunyikan lagi seketika.
            activity.window.decorView.post { applyFullscreenLock(true) }
        }
        insets
    }

    private fun startInsetListener() {
        ViewCompat.setOnApplyWindowInsetsListener(activity.window.decorView, insetListener)
    }

    private fun stopInsetListener() {
        ViewCompat.setOnApplyWindowInsetsListener(activity.window.decorView, null)
    }

    /**
     * Apakah status bar atau nav bar sedang terlihat.
     *
     * `isVisible` adalah API resmi (`WindowInsetsController`) untuk memeriksa
     * keadaan ini tanpa menebak-nebak dari tinggi inset.
     */
    private fun isSystemBarVisible(): Boolean {
        return try {
            val insets = ViewCompat.getRootWindowInsets(
                activity.window.decorView,
            ) ?: return false
            insets.isVisible(WindowInsetsCompat.Type.systemBars())
        } catch (_: Exception) {
            false
        }
    }

    // ---------- Screen pinning (pemblokiran system bar yang sesungguhnya) ----------

    /**
     * Memasuki **screen pinning** selama sesi ujian.
     *
     * Mengapa ini perlu: menyembunyikan system bar (`applyFullscreenLock`)
     * HANYA menyembunyikan tampilannya. Panel notifikasi tetap bisa ditarik
     * selama aplikasi tidak berstatus *device owner*, dan status itu tidak
     * bisa diminta dari dalam aplikasi (harus lewat ADB/QR provisioning di
     * luar aplikasi). Satu-satunya jalur resmi yang tersedia bagi aplikasi
     * biasa adalah `Activity.startLockTask()` — inilah "screen pinning".
     *
     * Perilaku yang WAJIB diketahui (dan ditulis apa adanya di layar
     * persiapan ujian):
     *  - Bila aplikasi BELUM di-allowlist device owner, Android menampilkan
     *    **dialog persetujuan** "Pin app?" yang hanya bisa diterima siswa.
     *    Itulah sebabnya fungsi ini dipanggil dari tombol yang diketik siswa,
     *    bukan otomatis saat halaman dibuka.
     *  - Selama tersemat, siswa tidak bisa membuka Home/Recents maupun
     *    menarik panel notifikasi; keluar hanya lewat gestur "tahan Back +
     *    Recents" (atau [stopExamLockTask] milik aplikasi sendiri).
     *  - Karena itu tidak ada larangan mutlak: siswa tetap bisa keluar, tapi
     *    lewat tindakan sadar yang tercatat sebagai pelanggaran oleh
     *    `ExamLockdownService` + alarm `assets/keluar.mp3`.
     *
     * Dijalankan di UI thread karena `startLockTask()` adalah API UI.
     * Kembalikan `true` bila permintaan diterima (tanpa menunggu jawaban
     * dialog, karena dialog itu ditangani sistem).
     */
    fun startExamLockTask(): Boolean {
        return try {
            activity.runOnUiThread {
                try {
                    activity.startLockTask()
                } catch (_: Exception) {
                    // Sebagian ROM menolak saat transisi (mis. baru kembali
                    // dari lockscreen). Alarm + penarikan task tetap bekerja.
                }
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Keluar dari screen pinning. WAJIB dipanggil saat ujian selesai /
     * halaman pengisian ditutup, supaya siswa tidak tertahan di dalam
     * aplikasi setelah selesai mengerjakan.
     *
     * Hanya bertindak bila aplikasi memang sedang tersemat, karena
     * `stopLockTask()` di luar mode itu melempar `IllegalStateException`.
     */
    fun stopExamLockTask(): Boolean {
        return try {
            activity.runOnUiThread {
                try {
                    val am = activity.getSystemService(Context.ACTIVITY_SERVICE)
                            as ActivityManager
                    if (am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE) {
                        activity.stopLockTask()
                    }
                } catch (_: Exception) {
                }
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    /** `true` bila aplikasi sedang berada dalam lock task / screen pinning. */
    fun isExamLockTaskActive(): Boolean {
        return try {
            val am = activity.getSystemService(Context.ACTIVITY_SERVICE)
                    as ActivityManager
            am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        } catch (_: Exception) {
            false
        }
    }

    // ---------- Penarikan task sendiri ke depan (tanpa provisioning) ----------

    /**
     * Tarik task HiDocs sendiri kembali ke depan jika siswa mencoba keluar.
     *
     * Kenapa TIDAK memakai `lockTaskMode`. Mengunci layar Android sejati hanya
     * mungkin bila aplikasi berstatus device owner, dan status itu hanya bisa
     * diberikan lewat ADB/QR provisioning di luar aplikasi — tidak realistis
     * untuk guru maupun siswa. Tanpa status itu,
     * `lockTaskMode="if_whitelisted"` hanya memunculkan dialog persetujuan
     * screen pinning yang tetap bisa dibatalkan pengguna.
     *
     * Kenapa `getAppTasks()` dan bukan `getRunningTasks()`:
     *  - `getRunningTasks()` dideklarasikan melempar `SecurityException` dan
     *    hanya boleh untuk aplikasi sistem / pemegang `REORDER_TASKS`;
     *  - `getAppTasks()` tidak punya anotasi izin apa pun dan hanya
     *    mengembalikan task MILIK APLIKASI SENDIRI, sehingga legal dipakai
     *    aplikasi biasa (diverifikasi langsung pada `android.jar`).
     *
     * Kembalikan `true` bila permintaan pemindahan diterima sistem.
     */
    fun pullTaskToFront(): Boolean {
        if (!examConfinementActive) return false
        return try {
            val am = activity.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val tasks = am.appTasks
            if (tasks.isEmpty()) return false
            // Task utama HiDocs ada di depan daftar; `moveToFront()` membawa
            // seluruh task (termasuk halaman Flutter yang sedang terbuka)
            // kembali ke depan tanpa menghancurkan state di dalamnya.
            tasks.first().moveToFront()
            true
        } catch (_: Exception) {
            // Sistem bisa menolak bila pemanggilan terjadi tepat saat transisi
            // (mis. sedang berpindah dari lockscreen). Alarm keluar tetap
            // berbunyi sebagai lapisan berikutnya.
            false
        }
    }

    /**
     * Nyalakan/matikan penanda "siswa sedang mengerjakan soal".
     *
     * Dipakai untuk DUA hal:
     *  1. penjaga alarm keluar — [onUserLeftActivity] hanya berbunyi bila
     *     penanda ini `true`, sehingga halaman gerbang dan layar token
     *     (yang memanggilnya dengan `false`) selalu sunyi;
     *  2. penjaga penarikan task — [pullTaskToFront] menolak bekerja bila
     *     penanda ini `false`, supaya aplikasi yang memang sedang ditutup
     *     siswa dari halaman gerbang tidak ditarik-tarik kembali.
     */
    fun setExamSessionActive(active: Boolean) {
        examSessionActive = active
        examConfinementActive = active
        if (!active) {
            // Berhenti berbunyi + lepaskan SENJATA, supaya tidak ada
            // suara yang masih menggantung saat pindah halaman.
            exitAlarmArmed = false
            stopExitAlarm()
        }
    }

    // ---------- FLAG_SECURE ----------

    private fun enableSecure() {
        activity.runOnUiThread {
            activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            secureEnabled = true
        }
    }

    private fun disableSecure() {
        activity.runOnUiThread {
            activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            secureEnabled = false
        }
    }

    // ---------- Draw over other apps ----------

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(activity)
        } else {
            true
        }
    }

    private fun openOverlaySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${activity.packageName}"),
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(intent)
        }
    }

    // ---------- Usage access ----------

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = activity.getSystemService(Context.APP_OPS_SERVICE)
                as android.app.AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                activity.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                activity.packageName,
            )
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            activity.startActivity(intent)
        } catch (_: Exception) {
            activity.startActivity(
                Intent(Settings.ACTION_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    // ---------- DND / notification policy — DIHAPUS (Revisi Lanjutan 6) ----------
    // Penggantinya adalah volume otomatis (maximizeExamVolume/restoreExamVolume).

    // ---------- Volume ujian: AUTO FULL saat masuk, pulihkan saat keluar ----------
    // (Menggantikan "Mode Sunyi Total"/DND yang DIHAPUS — Revisi Lanjutan 6)

    /**
     * Set volume media (STREAM_MUSIC) ke maksimum.
     * Nilai lama disimpan di [savedExamVolume] supaya `restoreExamVolume()`
     * bisa mengembalikannya.
     */
    private fun maximizeExamVolume(): Boolean {
        return try {
            val am = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val current = am.getStreamVolume(AudioManager.STREAM_MUSIC)
            if (savedExamVolume < 0) savedExamVolume = current
            am.setStreamVolume(AudioManager.STREAM_MUSIC, max, 0)
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Kembalikan volume media ke nilai sebelum ujian dimulai.
     * Aman dipanggil berkali-kali (hanya sekali pemulihan yang dijalankan).
     */
    private fun restoreExamVolume(): Boolean {
        return try {
            val restoreTo = savedExamVolume
            if (restoreTo < 0) return true
            val am = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            am.setStreamVolume(AudioManager.STREAM_MUSIC, restoreTo.coerceIn(0, max), 0)
            savedExamVolume = -1
            true
        } catch (_: Exception) {
            false
        }
    }

    /** Volume media saat ini sebagai rasio 0.0 – 1.0 terhadap maksimum. */
    private fun currentMediaVolume(): Double {
        return try {
            val am = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            if (max <= 0) return 1.0
            am.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / max.toDouble()
        } catch (_: Exception) {
            1.0
        }
    }

    // ---------- Info baterai (bilah status dalam aplikasi) ----------

    /**
     * Persentase (0-100) + status pengisian baterai untuk bilah status
     * dalam aplikasi — halaman pengisian ujian menutup status bar HP dan
     * menggantinya dengan informasi jam + baterai bikinan aplikasi sendiri.
     *
     * Memakai intent lengket `ACTION_BATTERY_CHANGED` sehingga tidak perlu
     * izin tambahan dan tidak perlu menunggu siaran broadcast sungguhan.
     */
    private fun getBatteryInfo(): Map<String, Any> {
        return try {
            val sticky = activity.registerReceiver(
                null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED),
            )
            val level = sticky?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = sticky?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
            val status = sticky?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            val percent = if (level >= 0 && scale > 0) (level * 100) / scale else -1
            val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                    status == BatteryManager.BATTERY_STATUS_FULL
            mapOf(
                "level" to percent,
                "charging" to charging,
            )
        } catch (_: Exception) {
            mapOf("level" to -1, "charging" to false)
        }
    }

    // ---------- Screening floating apps ----------

    /**
     * Aplikasi yang SEDANG menayangkan bubble / jendela mengambang / PiP.
     * Dipakai untuk pemindaian berkala selama ujian (agar aplikasi floating
     * yang hanya terpasang tidak dihitung sebagai pelanggaran).
     */
    private fun getActiveFloatingApps(): List<Map<String, Any?>> {
        val activePackages = collectActivelyFloating()
        val results = ArrayList<Map<String, Any?>>(activePackages.size)
        for (pkg in activePackages) {
            describePackage(pkg, isFloatingActive = true)?.let(results::add)
        }
        return results
    }

    /** Bentuk payload satu aplikasi untuk sisi Dart (fakta mentah saja). */
    private fun describePackage(
        pkg: String,
        isFloatingActive: Boolean,
        pi: PackageInfo? = null,
    ): Map<String, Any?>? {
        val pm = activity.packageManager
        val info = pi ?: packageInfo(pkg) ?: return null
        val appInfo = info.applicationInfo ?: return null
        val label = try {
            pm.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            pkg
        }
        return mapOf(
            "packageName" to pkg,
            "appName" to label,
            "isFloatingActive" to isFloatingActive,
            "isSystem" to isSystemApp(appInfo, pkg),
            "declaresOverlayPermission" to declaresOverlay(info),
            "overlayPermissionGranted" to overlayGrantedFor(info, pkg),
            "isRunning" to isFloatingActive,
            "matchedFloatingLabel" to knownFloatingLabel(pkg),
        )
    }

    private fun isSystemApp(info: ApplicationInfo, pkg: String): Boolean =
        (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
                (info.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0 ||
                pkg.startsWith("com.android.") ||
                pkg.startsWith("android.")

    /**
     * Aplikasi mendeklarasikan izin tampil-di-atas di manifest-nya.
     *
     * WAJIB dipanggil dengan `PackageInfo` yang dimuat memakai flag
     * [PackageManager.GET_PERMISSIONS], karena `requestedPermissions` hanya
     * terisi bila flag itu dipakai.
     */
    private fun declaresOverlay(pi: PackageInfo): Boolean {
        val requested = pi.requestedPermissions ?: return false
        for (p in requested) {
            if (p == Manifest.permission.SYSTEM_ALERT_WINDOW) return true
        }
        return false
    }

    /**
     * `PackageInfo` lengkap dengan daftar izin yang diminta aplikasi [pkg].
     *
     * `getInstalledPackages`/`getInstalledApplications` saja tidak membawa
     * `requestedPermissions`, jadi pemanggilan eksplisit dengan
     * [PackageManager.GET_PERMISSIONS] diperlukan sebelum [declaresOverlay]
     * dan [overlayGrantedFor] dipakai.
     */
    private fun packageInfoWithPermissions(pkg: String): PackageInfo? = try {
        activity.packageManager.getPackageInfo(
            pkg,
            PackageManager.GET_PERMISSIONS,
        )
    } catch (_: Exception) {
        null
    }

    /**
     * Apakah izin overlay aplikasi [pkg] sedang diizinkan.
     *
     * Dua jalur karena tidak ada satu API pun yang dijamin mengembalikan
     * mode app-op aplikasi lain untuk aplikasi non-sistem:
     *  1. `requestedPermissionsFlags` (dibawa oleh `getInstalledPackages`
     *     dengan flag `GET_PERMISSIONS`).
     *  2. `AppOpsManager.unsafeCheckOpNoThrow` (API 29+, cocok dengan minSdk
     *     proyek ini) sebagai cadangan — inilah sumber kebenaran untuk izin
     *     khusus "tampil di atas aplikasi lain".
     */
    private fun overlayGrantedFor(pi: PackageInfo, pkg: String): Boolean {
        try {
            val requested = pi.requestedPermissions
            val flags = pi.requestedPermissionsFlags
            if (requested != null && flags != null) {
                for (i in requested.indices) {
                    if (requested[i] == Manifest.permission.SYSTEM_ALERT_WINDOW &&
                        flags[i] and PackageInfo.REQUESTED_PERMISSION_GRANTED != 0
                    ) {
                        return true
                    }
                }
            }
        } catch (_: Exception) {
        }
        return try {
            val uid = pi.applicationInfo?.uid ?: return false
            val appOps = activity.getSystemService(Context.APP_OPS_SERVICE)
                    as AppOpsManager
            @Suppress("DEPRECATION")
            val mode = appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_SYSTEM_ALERT_WINDOW,
                uid,
                pkg,
            )
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            false
        }
    }

    /** 1) Bubble notifikasi yang sedang tampil. */
    private fun collectActiveBubbles(out: MutableSet<String>) {
        try {
            val nm = activity.getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager
            for (sbn in nm.activeNotifications) {
                val pkg = sbn.packageName ?: continue
                if (pkg == activity.packageName) continue
                val canBubble = try {
                    sbn.notification?.bubbleMetadata != null
                } catch (_: Exception) {
                    false
                }
                if (canBubble) out.add(pkg)
            }
        } catch (_: Exception) {
        }
    }

    /**
     * 2) Aplikasi yang memegang izin overlay DAN sedang benar-benar hidup di
     * foreground (daftar foreground berasal dari UsageStats bila izin
     * "Akses Penggunaan Aplikasi" diberikan, kalau tidak: getRunningAppProcesses).
     */
    private fun collectActiveOverlays(out: MutableSet<String>) {
        val alive = currentForegroundPackages()
        if (alive.isEmpty()) return
        for (pkg in alive) {
            if (pkg == activity.packageName) continue
            val pi = packageInfoWithPermissions(pkg) ?: continue
            if (!overlayGrantedFor(pi, pkg)) continue
            out.add(pkg)
        }
    }

    /** 3) Task picture-in-picture yang sedang berjalan. */
    private fun collectPipPackages(out: MutableSet<String>) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            val am = activity.getSystemService(Context.ACTIVITY_SERVICE)
                    as android.app.ActivityManager
            for (task in am.appTasks) {
                try {
                    val info = task.taskInfo ?: continue
                    if (!taskInPip(info)) continue
                    val base = info.baseActivity?.packageName ?: continue
                    if (base == activity.packageName) continue
                    out.add(base)
                } catch (_: Exception) {
                }
            }
        } catch (_: Exception) {
        }
    }

    /** Refleksi aman untuk TaskInfo.isInPictureInPictureMode (API 26+). */
    private fun taskInPip(info: Any): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val field = info.javaClass.getField("isInPictureInPictureMode")
            field.getBoolean(info)
        } catch (_: Exception) {
            false
        }
    }

    /** 4) Pelengkap: package katalog floating yang dikonfirmasi berjalan. */
    private fun collectRunningKnownFloating(out: MutableSet<String>) {
        try {
            val running = currentForegroundPackages()
            for (pkg in running) {
                if (pkg == activity.packageName) continue
                if (isKnownFloatingPackage(pkg)) out.add(pkg)
            }
        } catch (_: Exception) {
        }
    }

    /** Helper: PackageInfo (termasuk izin yang dideklarasikan) sebuah package. */
    private fun packageInfo(pkg: String): PackageInfo? {
        return try {
            val pm = activity.packageManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getPackageInfo(
                    pkg,
                    PackageManager.PackageInfoFlags.of(
                        PackageManager.GET_PERMISSIONS.toLong(),
                    ),
                )
            } else {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(pkg, PackageManager.GET_PERMISSIONS)
            }
        } catch (_: Exception) {
            null
        }
    }

    /** Helper: uid sebuah package, null bila tidak ditemukan. */
    private fun packageUid(pkg: String): Int? {
        return try {
            packageInfo(pkg)?.applicationInfo?.uid
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Package yang sedang hidup / terlihat.
     *
     * Sejak Android 7.1 `getRunningAppProcesses()` hanya mengembalikan proses
     * aplikasi sendiri, sehingga daftarnya dilengkapi `UsageStatsManager`
     * (butuh izin "Akses Penggunaan Aplikasi"). Bila izin itu belum ada,
     * deteksi "sedang menayangkan overlay" memang terbatas — justru karena
     * itu screening utama memakai inventaris aplikasi terpasang
     * ([scanInstalledApps]), bukan sinyal runtime ini.
     */
    private fun currentForegroundPackages(): Set<String> {
        val out = LinkedHashSet<String>()
        try {
            val am = activity.getSystemService(Context.ACTIVITY_SERVICE)
                    as ActivityManager
            for (proc in am.runningAppProcesses ?: return out) {
                val visible = proc.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND ||
                        proc.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE ||
                        proc.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_PERCEPTIBLE
                if (!visible) continue
                val names = proc.pkgList ?: continue
                for (pkg in names) out.add(pkg)
            }
        } catch (_: Exception) {
        }
        out.addAll(foregroundPackagesFromUsageStats())
        return out
    }

    /** Aplikasi yang tampil di 2 menit terakhir (bila akses penggunaan diberi). */
    private fun foregroundPackagesFromUsageStats(): Set<String> {
        if (!hasUsageStatsPermission()) return emptySet()
        val out = LinkedHashSet<String>()
        try {
            val usm = activity.getSystemService(Context.USAGE_STATS_SERVICE)
                    as android.app.usage.UsageStatsManager
            val now = System.currentTimeMillis()
            val events = usm.queryEvents(now - USAGE_STATS_WINDOW_MS, now)
            val event = android.app.usage.UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                // Catatan: `UsageEvents.Event` hanya punya ACTIVITY_RESUMED,
                // ACTIVITY_PAUSED, dan ACTIVITY_STOPPED (tidak ada
                // ACTIVITY_START_DELIVERED di android.jar mana pun), jadi
                // hanya ACTIVITY_RESUMED yang dipakai sebagai penanda
                // "sedang tampil di foreground".
                if (event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED) {
                    event.packageName?.let(out::add)
                }
            }
        } catch (_: Exception) {
        }
        return out
    }

    /**
     * Kumpulkan package yang SEDANG benar-benar menayangkan sesuatu
     * (bubble / jendela overlay / PiP) atau alat floating yang terbukti hidup.
     */
    private fun collectActivelyFloating(): Set<String> {
        val active = LinkedHashSet<String>()
        collectActiveBubbles(active)
        collectActiveOverlays(active)
        collectPipPackages(active)
        collectRunningKnownFloating(active)
        active.remove(activity.packageName)
        return active
    }

    // ---------- Inventaris SELURUH aplikasi terpasang ----------

    /**
     * Kirim daftar SEMUA aplikasi terpasang beserta fakta floating-nya ke Dart.
     *
     * `getInstalledPackages(GET_PERMISSIONS)` dipakai (bukan
     * `getInstalledApplications`) supaya status izin `SYSTEM_ALERT_WINDOW`
     * tiap aplikasi ikut terbaca dalam satu kali panggilan. Pengerjaannya di
     * thread latar karena membaca ratusan paket + label bisa memakan waktu
     * ratusan milidetik, sedangkan handler MethodChannel berjalan di UI thread.
     */
    private fun scanInstalledApps(result: MethodChannel.Result) {
        Thread {
            val payload: List<Map<String, Any?>> = try {
                buildInstalledAppsPayload()
            } catch (_: Exception) {
                emptyList()
            }
            activity.runOnUiThread { result.success(payload) }
        }.start()
    }

    private fun buildInstalledAppsPayload(): List<Map<String, Any?>> {
        val pm = activity.packageManager
        val rawFlags = PackageManager.GET_PERMISSIONS or PackageManager.GET_META_DATA
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(PackageManager.PackageInfoFlags.of(rawFlags.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(rawFlags)
        }

        val active = collectActivelyFloating()
        val seen = HashSet<String>(packages.size)
        val results = ArrayList<Map<String, Any?>>(packages.size)

        for (pi in packages) {
            val pkg = pi.packageName
            if (pkg == activity.packageName) continue
            if (!seen.add(pkg)) continue
            val appInfo = pi.applicationInfo ?: continue

            val isActive = active.contains(pkg)
            val known = isKnownFloatingPackage(pkg)
            val declaresOverlay = declaresOverlay(pi)
            val grantedOverlay = overlayGrantedFor(pi, pkg)

            // Aplikasi yang tidak punya kaitan apa pun dengan jendela
            // mengambang tidak perlu menyeberangi channel.
            if (!isActive && !known && !declaresOverlay && !grantedOverlay) continue

            val label = try {
                pm.getApplicationLabel(appInfo).toString()
            } catch (_: Exception) {
                pkg
            }
            results.add(
                mapOf(
                    "packageName" to pkg,
                    "appName" to label,
                    "isFloatingActive" to isActive,
                    "isSystem" to isSystemApp(appInfo, pkg),
                    "declaresOverlayPermission" to declaresOverlay,
                    "overlayPermissionGranted" to grantedOverlay,
                    "isRunning" to isActive,
                    "matchedFloatingLabel" to knownFloatingLabel(pkg),
                ),
            )
        }
        return results
    }

// ============================================================
// Katalog floating FUNGSIONAL (Revisi Lanjutan 6, dilengkapi 7).
//
// Hanya berisi aplikasi yang fungsi utamanya MELAYANG (assistive touch,
// screen recorder dengan float-window, bubble/chat-head khusus, PiP player).
//
// Aplikasi populer biasa (WhatsApp, YouTube, Gmail, Truecaller, PUBG Mobile,
// Word, Maps, dsb) SENGAJA TIDAK ADA di sini walau punya fitur bubble
// opsional — bubble aktual mereka sudah terdeteksi lewat
// NotificationManager/AppOps di SecurityBridge dan hanya ditandai bila
// bubble/float-nya BENAR-BENAR sedang tampil.
//
// REVISI LANJUTAN 7: "Floatee" dan "Floating Apps" (dua alat floating populer)
// sebelumnya TIDAK ada di katalog ini sehingga lolos dari screening, padahal
// di sisi Dart keduanya sudah terdaftar. Katalog native kini dilengkapi dan
// pencocokannya memakai prefiks + kata kunci, bukan hanya nama paket persis,
// karena aplikasi yang sama punya banyak applicationId (free/full/pro/plugin).
//
// Format: Triple(package, label tampilan, tingkat risiko 1-3).
private val kKnownFloatingApps: List<Triple<String, String, Int>> = listOf(
    // Alat floating khusus (case pengguna): Floatee & Floating Apps.
    // ID paket di bawah adalah applicationId ASLI (terverifikasi Play Store).
    // `com.floatee.app` / `com.floatee.android` dari revisi sebelumnya TIDAK
    // PERNAH ada di Play Store (404) — aplikasi sungguhannya bernama
    // `com.maika.floatee`, jadi entri palsu itu dibuang supaya label tidak
    // menyesatkan. Deteksi di Dart tetap memakai kata kunci `floatee`, jadi
    // varian ID baru pun tetap tertangkap.
    Triple("com.maika.floatee", "Floatee", 3),
    Triple("com.lwi.android.flapps", "Floating Apps", 3),
    Triple("com.lwi.android.flappsfull", "Floating Apps Full", 3),
    Triple("com.lwi.android.flappsplugin", "Floating Apps Plugin", 3),
    Triple("com.floating.apps.box", "Floating Apps Box", 3),
    Triple("com.flutter.floatingapps", "Floating Apps", 3),
    // Assistive touch / float button
    Triple("com.easytouch.assistivetouch", "Easy Touch", 3),
    Triple("com.assistivetouchpro", "Assistive Touch", 3),
    Triple("com.assistive.touch", "Assistive Touch", 3),
    Triple("com.gau.go.launcherex", "GO Assistive Touch", 2),
    Triple("com.assistivetouch.android", "Assistive Touch for Android", 3),
    Triple("assistive.touch.easytouch", "Assistive Touch Easy", 3),
    // Screen recorder dengan float-window
    Triple("com.hecorat.screenrecorder.free", "Screen Recorder (Hecorat)", 3),
    Triple("com.kimcy929.screenrecorder", "Screen Recorder", 2),
    Triple("com.arlosoft.macrodroid", "MacroDroid", 2),
    Triple("videoeditor.videorecorder.screenrecorder", "XRecorder", 2),
    Triple("com.duapps.recorder", "DU Recorder", 2),
    Triple("com.apowersoft.screenrecord", "Apowersoft Recorder", 2),
    // Bubble / chat-head khusus
    Triple("com.facebook.orca", "Messenger", 3),
    Triple("com.mixplorer.silver", "MiXplorer (float player)", 2),
    // PiP video player
    Triple("com.mxtech.videoplayer.ad", "MX Player", 2),
    Triple("com.mxtech.videoplayer.pro", "MX Player Pro", 2),
    Triple("org.videolan.vlc", "VLC", 2),
    // Cloner / parallel (membuka 2 akun bersamaan)
    Triple("com.lbe.parallel.intl", "Parallel Space", 3),
    Triple("com.excelliance.dualaapp", "Dual Space", 3),
    Triple("com.excelliance.multiaccounts", "Multiple Accounts", 3),
    Triple("com.parallel.space.lite", "Parallel Space Lite", 3),
    Triple("com.jiubang.commerce.multipleaccounts", "Dual Space", 3),
)

/**
 * Kata kunci pada nama package yang menandakan alat floating khusus.
 * Dipakai bila nama paket persis tidak ada di katalog (varian free/full/pro,
 * aplikasi baru, atau paket yang salah tulis di katalog).
 */
private val kFloatingPackageKeywords = listOf(
    "floatee",
    "flapps",
    "floatingapp",
    "floating.app",
    "floatwindow",
    "floaty",
    "float.ball",
    "assistivetouch",
    "assistive.touch",
    "easytouch",
    "easy.touch",
    "chathead",
    "chat.head",
    "parallel.space",
    "dualspace",
    "dual.space",
    "multipleaccounts",
    "screenrecorder",
    "screen.recorder",
    "xrecorder",
    "gameturbo",
    "game.turbo",
    "gamespace",
    "multiwindow",
    "splitscreen",
    "overlay",
)

/** `true` bila package dikenal/terdengar sebagai aplikasi floating fungsional. */
private fun isKnownFloatingPackage(pkg: String): Boolean =
    knownFloatingLabel(pkg).isNotEmpty()

/**
 * Label katalog untuk package yang dikenal, `""` bila tidak dikenal.
 *
 * Urutan pencocokan: nama paket persis -> prefiks varian -> kata kunci.
 */
private fun knownFloatingLabel(pkg: String): String {
    val lower = pkg.lowercase()
    for ((known, label, _) in kKnownFloatingApps) {
        if (lower == known) return label
    }
    for ((known, label, _) in kKnownFloatingApps) {
        if (lower.startsWith(known)) return label
    }
    for (keyword in kFloatingPackageKeywords) {
        if (lower.contains(keyword)) {
            return "Floating tool (${pkg.substringBeforeLast('.')})"
        }
    }
    return ""
}

    // ---------- Suara peringatan keluar aplikasi (assets/keluar.mp3) ----------

    /**
     * Pasang/lepas alarm keluar. Saat terpasang, [playExitAlarm] dipanggil
     * sendiri oleh [MainActivity] ketika aktivitas kehilangan fokus, jadi
     * suara tetap berbunyi walau isolat Dart sedang dijeda.
     */
    fun setExitAlarmArmed(armed: Boolean) {
        exitAlarmArmed = armed
        if (armed) preloadExitAlarm() else stopExitAlarm()
    }

    /** Panggilan dari MainActivity: pengguna sedang meninggalkan ujian. */
    fun onUserLeftActivity() {
        // Dua syarat WAJIB: alarm terpasang (di-set dari `engage()`) DAN sesi
        // ujian benar-benar sedang dikerjakan. Syarat kedua inilah yang
        // membuat halaman masukan token benar-benar sunyi: siswa boleh
        // menutup aplikasi di sana tanpa alarm.
        if (exitAlarmArmed && examSessionActive) playExitAlarm()
        // Lapisan penguncian: begitu siswa menekan Home/Recents di tengah
        // ujian, task HiDocs langsung ditarik kembali ke depan. Tanpa
        // provisioning apa pun — lihat [pullTaskToFront].
        pullTaskToFront()
    }

    /** Panggilan dari MainActivity: pengguna kembali, hentikan alarm. */
    fun onUserReturned() {
        stopExitAlarm()
    }

    /** Salin aset Flutter ke cache sekali saja (MediaPlayer butuh file/URI). */
    private fun exitAlarmFile(): File? {
        exitAlarmCachedFile?.let { if (it.exists()) return it }
        return try {
            val candidates = listOf(
                // Aset Flutter berada di bawah flutter_assets/<asset key>.
                "flutter_assets/assets/keluar.mp3",
                "assets/keluar.mp3",
            )
            var input: java.io.InputStream? = null
            for (path in candidates) {
                try {
                    input = activity.assets.open(path)
                    break
                } catch (_: Exception) {
                }
            }
            if (input == null) return null
            val out = File(activity.cacheDir, "keluar_alarm.mp3")
            input.use { src -> out.outputStream().use { dst -> src.copyTo(dst) } }
            exitAlarmCachedFile = out
            out
        } catch (_: Exception) {
            null
        }
    }

    /** Siapkan (atau siapkan ulang) player alarm dari berkas yang sudah di-cache. */
    private fun newAlarmPlayer(file: File): MediaPlayer? {
        val player = MediaPlayer()
        return try {
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    // USAGE_ALARM: tetap berbunyi meski volume media senyap
                    // dan tidak ikut ter-dim ketika layar mati.
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            player.setDataSource(file.absolutePath)
            player.setVolume(1.0f, 1.0f)
            player.prepare()
            player
        } catch (_: Exception) {
            try {
                player.release()
            } catch (_: Exception) {
            }
            null
        }
    }

    private fun preloadExitAlarm() {
        if (exitAlarmPlayer != null) return
        val file = exitAlarmFile() ?: return
        exitAlarmPlayer = newAlarmPlayer(file)
    }

    /** Bunyikan aset `assets/keluar.mp3`. `true` bila suara mulai diputar. */
    fun playExitAlarm(): Boolean {
        return try {
            val old = exitAlarmPlayer
            if (old != null) {
                try {
                    if (old.isPlaying) return true
                } catch (_: Exception) {
                }
            }
            val file = exitAlarmFile() ?: return false
            // MediaPlayer yang sudah di-stop wajib di-prepare ulang, jadi
            // player lama dibuang lalu dibuat baru (file-nya sudah di cache).
            try {
                old?.release()
            } catch (_: Exception) {
            }
            val player = newAlarmPlayer(file) ?: return false
            exitAlarmPlayer = player
            player.start()
            true
        } catch (_: Exception) {
            false
        }
    }

    fun stopExitAlarm() {
        try {
            val player = exitAlarmPlayer ?: return
            if (player.isPlaying) player.stop()
        } catch (_: Exception) {
        }
    }

    private fun releaseExitAlarm() {
        try {
            exitAlarmPlayer?.release()
        } catch (_: Exception) {
        }
        exitAlarmPlayer = null
    }

    // ---------- Pintu pengaturan aplikasi pihak lain ----------

    /**
     * Buka halaman "Info aplikasi" sistem untuk [packageName], tempat siswa
     * bisa menghentikan paksa, mencabut izin overlay, atau mencopot aplikasi
     * floating yang terdeteksi.
     */
    private fun openAppSettings(packageName: String?): Boolean {
        val pkg = packageName?.takeIf { it.isNotEmpty() } ?: return false
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$pkg")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    // ---------- Device admin ----------
    // Status device owner / admin TIDAK lagi dipakai untuk mengunci ujian
    // (lihat catatan REVISI LANJUTAN 9 di kepala kelas): mengunci lewat jalur
    // itu menuntut provisioning ADB/QR di luar aplikasi, yang tidak realistis
    // dibebankan ke guru maupun siswa. Yang tersisa hanya PEMBACAAN status
    // supaya halaman persiapan ujian bisa menampilkan keadaan apa adanya bila
    // perangkat kebetulan sudah diprovision pihak sekolah — bukan syarat
    // wajib untuk mulai ujian.

    private fun devicePolicyManager(): DevicePolicyManager? =
        activity.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager

    private fun adminComponent(): ComponentName =
        ComponentName(activity, ExamDeviceAdminReceiver::class.java)

    private fun isDeviceAdminActive(): Boolean {
        return try {
            devicePolicyManager()?.isAdminActive(adminComponent()) == true
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        const val CHANNEL_NAME = "id.hidocs.app/security"

        /** Jendela waktu event UsageStats yang dianggap "masih aktif". */
        private const val USAGE_STATS_WINDOW_MS = 120_000L

        /**
         * Selang pemeriksaan [systemBarWatchdog].
         *
         * Dipilih pendek (700 ms) karena tujuannya menutup system bar yang baru
         * saja digeser keluar; terlalu panjang membuat status bar sempat
         * terlihat cukup lama untuk menekan notifikasi.
         */
        private const val SYSTEM_BAR_WATCHDOG_MS = 150L
    }
}
