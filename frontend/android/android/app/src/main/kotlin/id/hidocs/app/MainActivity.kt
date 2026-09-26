package id.hidocs.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var securityBridge: SecurityBridge? = null
    private val deepLinkChannel = "hidocs/deep_link"
    private var pendingLink: String? = null

    /**
     * Penguncian ujian bertingkat.
     *
     * Tingkat utama: **Lock Task Mode** (kiosk sejati) lewat
     * [SecurityBridge.startKiosk]. Ini bekerja penuh hanya bila HiDocs
     * berstatus device owner (lihat `tool/exam_device_owner.sh`); saat aktif,
     * tombol Home, daftar aplikasi terbaru, dan panel notifikasi dimatikan
     * oleh sistem, sehingga siswa tidak punya jalan keluar.
     *
     * Sudah diverifikasi pada perangkat: saat Lock Task Mode aktif, menekan
     * KEYCODE_HOME maupun KEYCODE_APP_SWITCH tidak memindahkan fokus keluar
     * dari aplikasi.
     *
     * Tingkat cadangan (perangkat TANPA device owner): alarm keluar tetap
     * berbunyi dan [pullBackToForeground] dicoba. Perlu dicatat jujur bahwa
     * pada kondisi itu `FLAG_ACTIVITY_REORDER_TO_FRONT` hanya menyusun ulang
     * riwayat di dalam task sendiri, jadi siswa tetap bisa keluar — itulah
     * alasan halaman persiapan ujian memblokir mulai ujian tanpa device owner.
     *
     * [returningFromLock] mencegah recursive re-launch: setelah
     * `startActivity` di bawah, aktivitas bisa kehilangan fokus lagi dan
     * tanpa penjaga itu aplikasi akan terus menarik dirinya sendiri.
     */
    private var returningFromLock = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        securityBridge = SecurityBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        securityBridge?.register()
        io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, deepLinkChannel
        ).setMethodCallHandler { call, result ->
            if (call.method == "getInitialLink") {
                result.success(pendingLink ?: intent?.dataString)
                pendingLink = null
            } else {
                result.notImplemented()
            }
        }
        pendingLink = intent?.dataString
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingLink = intent.dataString
    }

    /**
     * Siswa meninggalkan aplikasi ujian (tombol Home, Recents, ganti aplikasi,
     * layar notifikasi): bunyikan assets/keluar.mp3 dari SISI NATIVE, lalu
     * tarik aktivitas kembali ke depan selama sesi ujian masih terkunci.
     *
     * Kenapa dari sisi native: kalau menunggu callback lifecycle dari Dart,
     * suara sering tidak sempat keluar karena engine Flutter sudah dijeda
     * saat aktivitas paused.
     *
     * [onUserLeaveHint] adalah SATU-SATUNYA callback "pengguna hendak keluar"
     * yang disediakan Android (berlaku sejak API 3, tanpa pengganti di versi
     * baru) — jadi penguncian dan penarikan kembali dilakukan di sini.
     *
     * Penarikan kembali HANYA dilakukan bila Lock Task Mode benar-benar aktif
     * (device owner). Pada perangkat tanpa device owner, `startLockTask` tidak
     * pernah masuk mode terkunci, dan `startActivity(REORDER_TO_FRONT)` hanya
     * menyusun ulang riwayat dalam task sendiri — tidak membawa task yang sudah
     * di latar kembali ke depan. Menjalankannya hanya menambah alarm palsu.
     */
    override fun onUserLeaveHint() {
        val kiosk = securityBridge?.isKioskActive == true
        securityBridge?.onUserLeftActivity()
        if (kiosk) pullBackToForeground()
        super.onUserLeaveHint()
    }

    /**
     * Jalankan ulang aktivitas ini di depan task yang sama supaya langsung
     * kelihatan lagi oleh siswa.
     */
    private fun pullBackToForeground() {
        if (returningFromLock) return
        returningFromLock = true
        try {
            val reopen = Intent(this, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP,
                )
            }
            startActivity(reopen)
        } catch (_: Exception) {
            // Bila sistem menolak (mis. sedang transisi), tidak ada yang
            // bisa dilakukan — alarm tetap berbunyi sebagai gantinya.
        } finally {
            // Di-reset pada frame berikutnya supaya trigger berikutnya
            // (mis. siswa menekan Home lagi) tetap bisa bekerja.
            window.decorView.postDelayed({ returningFromLock = false }, 1500)
        }
    }

    /**
     * Geser tepi / panel notifikasi sempat memunculkan status bar. Begitu
     * window kembali punya fokus, kunci ulang tampilan penuh supaya tidak
     * ada akses keluar lewat system bar.
     *
     * [SecurityBridge.reapplyFullscreenLock] juga membangun ulang Lock Task
     * Mode bila mode itu lepas padahal sesi ujian masih berjalan.
     */
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) securityBridge?.reapplyFullscreenLock()
    }

    /**
     * Siswa meninggalkan aktivitas: beri tahu bridge supaya alarm berbunyi
     * bila alarm memang terpasang DAN sesi ujian aktif.
     *
     * Penjagaannya (`exitAlarmArmed && examSessionActive`) dilakukan di
     * `SecurityBridge.onUserLeftActivity`, jadi halaman gerbang, layar token,
     * maupun aplikasi tanpa device owner tidak ikut berbunyi.
     */
    override fun onPause() {
        securityBridge?.onUserLeftActivity()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        securityBridge?.onUserReturned()
        securityBridge?.reapplyFullscreenLock()
    }

    override fun onDestroy() {
        securityBridge?.dispose()
        securityBridge = null
        super.onDestroy()
    }
}
