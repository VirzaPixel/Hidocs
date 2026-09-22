package id.hidocs.app

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Jembatan keamanan ujian.
 * Menangani FLAG_SECURE, status izin overlay, DND, dan daftar aplikasi terpasang.
 */
class SecurityBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private var secureEnabled = false

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
                "isNotificationPolicyAccessGranted" ->
                    result.success(isNotificationPolicyAccessGranted())
                "openNotificationPolicySettings" -> {
                    openNotificationPolicySettings()
                    result.success(true)
                }
                "setInterruptionFilter" -> {
                    val mode = call.argument<String>("mode") ?: "all"
                    result.success(setInterruptionFilter(mode))
                }
                "getInterruptionFilter" ->
                    result.success(getInterruptionFilter())
                "getInstalledApps" -> result.success(getInstalledApps())
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

    // ---------- DND / notification policy ----------

    private fun isNotificationPolicyAccessGranted(): Boolean {
        val nm = activity.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
        return nm.isNotificationPolicyAccessGranted
    }

    private fun openNotificationPolicySettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
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

    private fun getInterruptionFilter(): String {
        val nm = activity.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
        if (!nm.isNotificationPolicyAccessGranted) return "unknown"
        return when (nm.currentInterruptionFilter) {
            NotificationManager.INTERRUPTION_FILTER_NONE -> "none"
            NotificationManager.INTERRUPTION_FILTER_PRIORITY -> "priority"
            NotificationManager.INTERRUPTION_FILTER_ALARMS -> "alarms"
            NotificationManager.INTERRUPTION_FILTER_ALL -> "all"
            else -> "unknown"
        }
    }

    /**
     * mode: "all" | "priority" | "none" | "alarms"
     * "none" = total silence (blokir notifikasi + telepon selama ujian).
     */
    private fun setInterruptionFilter(mode: String): Boolean {
        val nm = activity.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
        if (!nm.isNotificationPolicyAccessGranted) return false
        val filter = when (mode) {
            "none" -> NotificationManager.INTERRUPTION_FILTER_NONE
            "priority" -> NotificationManager.INTERRUPTION_FILTER_PRIORITY
            "alarms" -> NotificationManager.INTERRUPTION_FILTER_ALARMS
            else -> NotificationManager.INTERRUPTION_FILTER_ALL
        }
        return try {
            nm.setInterruptionFilter(filter)
            true
        } catch (_: SecurityException) {
            false
        }
    }

    // ---------- Installed apps ----------

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
