package id.hidocs.app

import android.app.Activity
import android.app.AppOpsManager
import android.app.NotificationManager
import android.app.PictureInPictureParams
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Jembatan keamanan ujian.
 *
 * Menangani FLAG_SECURE, status izin overlay, VOLUME OTOMATIS, dan screening
 * aplikasi floating yang SEDANG AKTIF (bubble/chat-head/float-window/PiP).
 *
 * REVISI LANJUTAN 6 — prinsip screening:
 *  - Hanya aplikasi floating yang BENAR-BENAR menayangkan jendela/bubble
 *    yang ditandai. Aplikasi populer yang hanya terpasang (WhatsApp, YouTube,
 *    Gmail, Truecaller, PUBG Mobile, Word, Maps, dsb) TIDAK PERNAH ditandai
 *    bila tidak menampilkan floating — screening berdasarkan fungsi aktual,
 *    bukan nama aplikasi.
 *  - "Mode Sunyi Total" (DND) DIHAPUS. Gantinya: volume media dimaksimalkan
 *    (AUTO FULL) saat ujian dimulai dan dipulihkan saat ujian selesai.
 */
class SecurityBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private var secureEnabled = false

    /** Volume media sebelum ujian (dipulihkan saat ujian selesai). -1 = belum disimpan. */
    private var savedExamVolume: Int = -1

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
                "getInstalledApps" -> result.success(getActiveFloatingApps())
                "isDeviceAdminActive" -> result.success(isDeviceAdminActive())
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
        disableSecure()
        channel.setMethodCallHandler(null)
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

    // ---------- Screening floating apps (hanya yang SEDANG AKTIF) ----------

    /**
     * Kembalikan daftar aplikasi floating yang SEDANG AKTIF menampilkan
     * bubble/jendela mengambang/PiP — BUKAN daftar semua aplikasi terpasang.
     */
    private fun getActiveFloatingApps(): List<Map<String, Any?>> {
        val pm = activity.packageManager
        val activePackages = LinkedHashSet<String>()

        collectActiveBubbles(activePackages)
        collectActiveOverlays(activePackages)
        collectPipPackages(activePackages)
        collectRunningKnownFloating(activePackages)

        val results = ArrayList<Map<String, Any?>>(activePackages.size)
        for (pkg in activePackages) {
            try {
                val info = packageInfo(pkg) ?: continue
                val label = try {
                    pm.getApplicationLabel(info).toString()
                } catch (_: Exception) {
                    pkg
                }
                val isSystem = (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
                        (info.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0 ||
                        pkg.startsWith("com.android.") ||
                        pkg.startsWith("com.google.android.")
                results.add(
                    mapOf(
                        "packageName" to pkg,
                        "appName" to label,
                        "isFloatingActive" to true,
                        "isSystem" to isSystem,
                        "matchedFloatingLabel" to knownFloatingLabel(pkg),
                    ),
                )
            } catch (_: Exception) {
            }
        }
        return results
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

    /** 2) Aplikasi yang sedang memakai izin overlay (AppOps aktif). */
    private fun collectActiveOverlays(out: MutableSet<String>) {
        try {
            val appOps = activity.getSystemService(Context.APP_OPS_SERVICE)
                    as AppOpsManager
            val running = currentRunningPackages()
            val overlayOp = AppOpsManager.OPSTR_SYSTEM_ALERT_WINDOW
            for (pkg in running) {
                if (pkg == activity.packageName) continue
                try {
                    val uid = packageUid(pkg) ?: continue
                    val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        appOps.unsafeCheckOpNoThrow(overlayOp, uid, pkg)
                    } else {
                        @Suppress("DEPRECATION")
                        appOps.checkOpNoThrow(overlayOp, uid, pkg)
                    }
                    if (mode == AppOpsManager.MODE_ALLOWED) out.add(pkg)
                } catch (_: Exception) {
                }
            }
        } catch (_: Exception) {
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
            val running = currentRunningPackages()
            for (pkg in running) {
                if (pkg == activity.packageName) continue
                if (isKnownFloatingPackage(pkg)) out.add(pkg)
            }
        } catch (_: Exception) {
        }
    }

    /** Helper: ApplicationInfo sebuah package, null bila tidak ditemukan. */
    private fun packageInfo(pkg: String): ApplicationInfo? {
        return try {
            val pm = activity.packageManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getApplicationInfo(pkg, PackageManager.ApplicationInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.getApplicationInfo(pkg, 0)
            }
        } catch (_: Exception) {
            null
        }
    }

    /** Helper: uid sebuah package, null bila tidak ditemukan. */
    private fun packageUid(pkg: String): Int? {
        return try {
            packageInfo(pkg)?.uid
        } catch (_: Exception) {
            null
        }
    }

    /** Package yang sedang berjalan (foreground/visible) — kandidat, bukan vonis. */
    private fun currentRunningPackages(): Set<String> {
        val out = LinkedHashSet<String>()
        try {
            val am = activity.getSystemService(Context.ACTIVITY_SERVICE)
                    as android.app.ActivityManager
            val info = android.app.ActivityManager.RunningAppProcessInfo
            for (proc in am.runningAppProcesses ?: return out) {
                val visible = proc.importance == info.IMPORTANCE_FOREGROUND ||
                        proc.importance == info.IMPORTANCE_VISIBLE ||
                        proc.importance == info.IMPORTANCE_PERCEPTIBLE
                if (!visible) continue
                val names = proc.pkgList ?: continue
                for (pkg in names) out.add(pkg)
            }
        } catch (_: Exception) {
        }
        return out
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = activity.packageManager
        val flags = PackageManager.GET_META_DATA
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(
                PackageManager.ApplicationInfoFlags.of(flags.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(flags)
        }

        val results = ArrayList<Map<String, Any?>>(packages.size)
        for (info in packages) {
            val launchIntent = pm.getLaunchIntentForPackage(info.packageName)
            val isSystem = (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            results.add(
                mapOf(
                    "packageName" to info.packageName,
                    "appName" to pm.getApplicationLabel(info).toString(),
                    "isSystem" to isSystem,
                    "hasLaunchIntent" to (launchIntent != null),
                ),
            )
        }
        return results
    }

// ============================================================
// Katalog floating FUNGSIONAL (Revisi Lanjutan 6).
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
// Format: Triple(package, label tampilan, tingkat risiko 1-3).
private val kKnownFloatingApps: List<Triple<String, String, Int>> = listOf(
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

/** `true` bila package dikenal sebagai aplikasi floating fungsional. */
private fun isKnownFloatingPackage(pkg: String): Boolean {
    val lower = pkg.lowercase()
    for ((known, _, _) in kKnownFloatingApps) {
        if (lower == known) return true
    }
    return false
}

/** Label katalog untuk package yang dikenal, `""` bila tidak dikenal. */
private fun knownFloatingLabel(pkg: String): String {
    val lower = pkg.lowercase()
    for ((known, label, _) in kKnownFloatingApps) {
        if (lower == known) return label
    }
    return ""
}

    // ---------- Device admin ----------

    private fun isDeviceAdminActive(): Boolean {
        return try {
            val dpm = activity.getSystemService(Context.DEVICE_POLICY_SERVICE)
                    as android.app.admin.DevicePolicyManager
            dpm.isAdminActive(
                android.content.ComponentName(activity, ExamDeviceAdminReceiver::class.java),
            )
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        const val CHANNEL_NAME = "id.hidocs.app/security"
    }
}
