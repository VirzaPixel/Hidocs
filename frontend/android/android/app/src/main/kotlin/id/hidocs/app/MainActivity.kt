package id.hidocs.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var securityBridge: SecurityBridge? = null
    private val deepLinkChannel = "hidocs/deep_link"
    private var pendingLink: String? = null

    /**
     * Penguncian ujian TANPA provisioning.
     *
     * Sebelumnya kelas ini mengandalkan Lock Task Mode (kiosk sejati) yang
     * menuntut status **device owner**. Status itu hanya bisa diberikan lewat
     * ADB atau provisioning QR di luar aplikasi — jalur yang tidak realistis
     * dibebankan ke guru/siswa, jadi seluruhnya dibuang.
     *
     * Penggantinya berlapis, dan setiap lapisan bekerja di perangkat biasa:
     *  1. **System bar disembunyikan permanen** — [SecurityBridge.applyFullscreenLock]
     *     mematikan status bar + nav bar, dan [SecurityBridge.reapplyFullscreenLock]
     *     mengunci ulang setiap kali window kembali fokus (geser tepi sempat
     *     memunculkannya).
     *  2. **Task ditarik kembali ke depan** — begitu siswa menekan Home/Recents,
     *     [onUserLeaveHint] memanggil [SecurityBridge.pullTaskToFront] yang
     *     memakai `ActivityManager.getAppTasks()` + `AppTask.moveToFront()`.
     *     Keduanya hanya menyangkut task MILIK APLIKASI INI, sehingga tidak
     *     memerlukan izin apa pun (berbeda dari `getRunningTasks`/
     *     `moveTaskToFront` yang menuntut `REORDER_TASKS`).
     *  3. **Alarm keluar + telemetry** — `assets/keluar.mp3` dibunyikan native
     *     dan pelanggaran dicatat oleh `ExamLockdownService` di sisi Dart.
     *
     * Batas yang perlu diketahui: tanpa device owner, sistem Android tetap
     * boleh memindahkan aplikasi ke latar (mis. Home ditekan dua kali cepat).
     * Yang dijamin adalah aplikasi KEMBALI ke depan hampir seketika dan
     * setiap pelanggaran tercatat — bukan larangan mutlak dari OS.
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
     * tarik task HiDocs kembali ke depan selama ujian masih berjalan.
     *
     * Kenapa dari sisi native: kalau menunggu callback lifecycle dari Dart,
     * suara sering tidak sempat keluar karena engine Flutter sudah dijeda
     * saat aktivitas paused.
     *
     * Penarikan kembali HANYA dilakukan bila mode penguncian ujian benar-benar
     * aktif (`isExamConfinementActive`), yaitu selama sesi pengisian soal —
     * halaman gerbang dan layar token tidak masuk hitungan, sehingga siswa
     * tetap boleh menutup aplikasi di sana.
     */
    override fun onUserLeaveHint() {
        val confinementActive =
            securityBridge?.isExamConfinementActive == true
        securityBridge?.onUserLeftActivity()
        if (confinementActive) pullBackToForeground()
        super.onUserLeaveHint()
    }

    /**
     * Tarik task aplikasi ini ke depan supaya siswa langsung melihat soal lagi.
     *
     * [returningFromLock] mencegah re-launch rekursif: pemindahan task bisa
     * memicu `onUserLeaveHint` lagi, dan tanpa penjaga itu aplikasi akan
     * menarik dirinya sendiri tanpa henti.
     */
    private fun pullBackToForeground() {
        if (returningFromLock) return
        returningFromLock = true
        val moved = securityBridge?.pullTaskToFront() == true
        if (!moved) {
            // Cadangan: `getAppTasks()` tidak tersedia pada sebagian ROM
            // (mis. perangkat yang membatasi API task). `REORDER_TO_FRONT`
            // memang TIDAK bisa membawa task yang sudah di latar kembali ke
            // depan, jadi ini hanya penyelamat untuk kondisi task masih di
            // dalam tumpukan yang sama.
            try {
                startActivity(
                    Intent(this, MainActivity::class.java).apply {
                        addFlags(
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                Intent.FLAG_ACTIVITY_SINGLE_TOP,
                        )
                    },
                )
            } catch (_: Exception) {
                // Tidak ada yang bisa dilakukan — alarm tetap berbunyi sebagai
                // gantinya.
            }
        }
        // Di-reset pada frame berikutnya supaya trigger berikutnya (mis.
        // siswa menekan Home lagi) tetap bisa bekerja.
        window.decorView.postDelayed({ returningFromLock = false }, 1500)
    }

    /**
     * Geser tepi / panel notifikasi sempat memunculkan status bar. Begitu
     * window kembali punya fokus, kunci ulang tampilan penuh supaya tidak
     * ada akses keluar lewat system bar.
     */
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) securityBridge?.reapplyFullscreenLock()
    }

    /**
     * Siswa meninggalkan aktivitas: beri tahu bridge supaya alarm berbunyi
     * (bila alarm memang terpasang DAN sesi ujian aktif) sekaligus task
     * HiDocs ditarik kembali ke depan.
     *
     * Penjagaannya (`exitAlarmArmed && examSessionActive` untuk alarm,
     * `examConfinementActive` untuk penarikan task) ada di
     * `SecurityBridge.onUserLeftActivity`, jadi halaman gerbang dan layar
     * token tidak ikut berbunyi maupun ditarik kembali.
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
