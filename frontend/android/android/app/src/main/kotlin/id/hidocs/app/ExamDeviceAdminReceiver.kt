package id.hidocs.app

import android.app.admin.DeviceAdminReceiver

/**
 * Receiver device admin untuk memperkuat mode ujian.
 * Tidak memakai kebijakan destruktif (wipe) — hanya penanda admin aktif.
 */
class ExamDeviceAdminReceiver : DeviceAdminReceiver()
