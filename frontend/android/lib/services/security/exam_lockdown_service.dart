import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:hi_docs/services/api/api_client.dart';

import 'exam_security_service.dart';

/// Ringkasan kesiapan SELURUH syarat persiapan ujian (Revisi Lanjutan 9).
///
/// Syaratnya DUA, dan keduanya bisa dipenuhi dari dalam aplikasi:
///  1. `overlayPermissionOk` — HiDocs punya izin "tampil di atas aplikasi".
///  2. `floatingAppsClean` — hasil screening seluruh aplikasi terpasang:
///     tidak ada alat floating khusus terpasang dan tidak ada overlay yang
///     sedang tampil (lihat [ExamLockdownService.evaluateLive] untuk versi
///     "hanya yang sedang tampil" selama ujian).
///
/// Syarat "device owner / Lock Task Mode" DIHAPUS. Mengunci layar Android
/// sejati menuntut provisioning ADB/QR di luar aplikasi — jalur yang tidak
/// realistis dibebankan ke guru maupun siswa. Penguncian sekarang dikerjakan
/// sepenuhnya dari dalam aplikasi (lihat [ExamLockdownService.engage]).
///
/// "Mode Sunyi Total" DIHAPUS sesuai permintaan: tidak ada DND, tidak ada
/// akses kebijakan notifikasi. Field `dndAccessOk`/`dndActive` dipertahankan
/// sebagai konstanta kompatibilitas agar pemanggil lama tidak pecah — keduanya
/// SELALU true dan tidak lagi mengunci kesiapan.
class LockdownReadiness {
  final bool overlayPermissionOk;
  final bool floatingAppsClean;

  /// Kompatibilitas: selalu true. Mode Sunyi Total (DND) dihapus —
  /// lihat [ExamLockdownService].
  final bool dndAccessOk;
  final bool dndActive;
  final FloatingAppScreeningResult screening;

  const LockdownReadiness({
    required this.overlayPermissionOk,
    required this.floatingAppsClean,
    @Deprecated('Mode Sunyi Total dihapus (Revisi Lanjutan 6). Selalu true.')
    this.dndAccessOk = true,
    @Deprecated('Mode Sunyi Total dihapus (Revisi Lanjutan 6). Selalu true.')
    this.dndActive = true,
    required this.screening,
  });

  /// Screening floating bersih + izin overlay ada. Tidak ada lagi syarat
  /// perangkat yang harus diprovision dari luar aplikasi.
  bool get isReady => overlayPermissionOk && floatingAppsClean;

  /// Daftar id syarat yang belum terpenuhi.
  List<String> get unmetRequirements {
    final list = <String>[];
    if (!overlayPermissionOk) list.add('overlay');
    if (!floatingAppsClean) list.add('floating_apps');
    return list;
  }
}

/// Batas maksimum pelanggaran (keluar dari aplikasi / floating app terdeteksi)
/// sebelum akses ujian dicabut otomatis dan jawaban di-submit paksa.
const int kMaxExitViolations = 3;

/// Orkestrator persiapan ujian (Revisi Lanjutan 7).
///
/// Syarat HANYA dua, tetap terpisah:
///  1. `floatingAppsClean` — hasil screening SELURUH aplikasi terpasang:
///     tidak ada alat floating khusus yang terpasang dan tidak ada overlay
///     yang sedang tampil.
///  2. `overlayPermissionOk` — HiDocs mengantongi izin overlay.
///
/// "Mode Sunyi Total" (DND) SUDAH DIHAPUS. Sebagai gantinya, saat `engage()`
/// dipanggil, volume media perangkat dimaksimalkan (AUTO FULL), alarm keluar
/// (`assets/keluar.mp3`) dipasangkan, dan keduanya dibongkar kembali saat
/// `release()`. Tidak ada lagi permintaan "Akses Kebijakan Notifikasi".
class ExamLockdownService {
  ExamLockdownService._();

  /// Jalankan seluruh pemeriksaan dan kembalikan ringkasannya.
  /// Read-only: TIDAK mengubah volume, izin, maupun status penguncian.
  ///
  /// Versi "persiapan": memindai seluruh aplikasi yang terpasang di perangkat
  /// dan mengkategorikan mana yang aplikasi floating.
  static Future<LockdownReadiness> evaluate() async {
    final screening = await ExamSecurityService.screenFloatingApps();
    final overlayOk = await ExamSecurityService.canDrawOverlays();

    return LockdownReadiness(
      overlayPermissionOk: overlayOk,
      floatingAppsClean: screening.isClean,
      screening: screening,
    );
  }

  /// Versi "selama ujian": hanya aplikasi yang SAAT ITU JUGA menayangkan
  /// bubble/float/PiP yang dihitung. Dipakai oleh pemeriksaan berkala dan
  /// saat aplikasi kembali ke depan, supaya aplikasi floating yang hanya
  /// terpasang tidak memicu pelanggaran berulang.
  static Future<LockdownReadiness> evaluateLive() async {
    final screening = await ExamSecurityService.screenActiveFloatingApps();
    final overlayOk = await ExamSecurityService.canDrawOverlays();

    return LockdownReadiness(
      overlayPermissionOk: overlayOk,
      floatingAppsClean: screening.isClean,
      screening: screening,
    );
  }

  /// Aktifkan persiapan/awal ujian: FLAG_SECURE, foreground service,
  /// volume media AUTO FULL (nilai lama disimpan untuk dipulihkan), kunci
  /// tampilan penuh, dan alarm keluar aplikasi.
  ///
  /// Penguncian berjalan di SEMUA perangkat tanpa provisioning: status bar +
  /// nav bar disembunyikan permanen, dan begitu siswa menekan Home/Recents
  /// task HiDocs ditarik kembali ke depan oleh native
  /// (`SecurityBridge.pullTaskToFront`).
  ///
  /// `setExamSessionActive(true)` adalah pemicu penjaga di native: tanpa itu
  /// `MainActivity` akan membunyikan alarm DAN menarik task kembali untuk
  /// halaman mana pun yang kebetulan terbuka sebelum ujian dimulai (mis.
  /// layar masukan token).
  ///
  /// Kembalikan `true` bila seluruh lapisan berhasil diminta ke native.
  static Future<bool> engage() async {
    await ExamSecurityService.enableSecureScreen();
    await ExamSecurityService.startLockService();
    await ExamSecurityService.maximizeExamVolume();
    await ExamSecurityService.setExamSessionActive(true);
    await ExamSecurityService.setExitAlarmArmed(true);
    // Kunci tampilan penuh: status bar + nav bar tidak bisa dimunculkan lagi
    // lewat gestur tepi layar.
    await ExamSecurityService.setFullscreenLock(true);
    return true;
  }

  /// Lepaskan persiapan/penguncian: kembalikan FLAG_SECURE, hentikan service,
  /// cabut alarm keluar, buka kembali system bar, dan pulihkan volume
  /// perangkat ke nilai semula.
  static Future<void> release() async {
    // Matikan penanda sesi DULUAN: native ikut menghentikan suara yang
    // masih berbunyi dan berhenti menarik task ke depan sebelum alarm
    // dilepas sepenuhnya.
    await ExamSecurityService.setExamSessionActive(false);
    await ExamSecurityService.setExitAlarmArmed(false);
    await ExamSecurityService.setFullscreenLock(false);
    await ExamSecurityService.disableSecureScreen();
    await ExamSecurityService.stopLockService();
    await ExamSecurityService.restoreExamVolume();
  }

  /// Pastikan tidak ada penguncian maupun suara yang menyala.
  ///
  /// Dipanggil halaman gerbang dan layar token: keduanya BUKAN bagian dari
  /// sesi ujian, jadi siswa boleh menutup aplikasi di sana tanpa alarm
  /// berbunyi, tanpa ditarik kembali, dan tanpa layar terkunci. Fungsi ini
  /// idempoten — aman dipanggil berulang, termasuk untuk membersihkan sisa
  /// sesi sebelumnya.
  static Future<void> ensureIdle() async {
    await ExamSecurityService.setExamSessionActive(false);
    await ExamSecurityService.setExitAlarmArmed(false);
    await ExamSecurityService.stopExitAlarm();
    await ExamSecurityService.setFullscreenLock(false);
  }

  /// Kirim event pelanggaran ke backend dan kembalikan status berhasil.
  static Future<void> reportViolation(
    String responseId, {
    required String eventType,
    String? message,
    int questionIndex = 0,
  }) async {
    final target = ExamViolationReporter.reporter;
    if (target == null) return;
    try {
      await target(responseId, eventType, message, questionIndex);
    } catch (_) {
      debugPrint('[ExamLockdown] gagal kirim telemetry');
    }
  }

  /// Cabut akses ujian untuk response ini karena pelanggaran keluar
  /// melebihi batas. Panggil API + kirim telemetry.
  static Future<void> revokeAccess(
    String responseId, {
    required int violationCount,
  }) async {
    reportViolation(
      responseId,
      eventType: 'ACCESS_REVOKED',
      message:
          'Akses dicabut: $violationCount pelanggaran (maks $kMaxExitViolations).',
    );

    // Beritahu backend (graceful bila endpoint belum ada).
    try {
      await ApiClient.revokeExamAccess(responseId);
    } catch (_) {
      debugPrint('[ExamLockdown] gagal cabut akses backend');
    }
  }
}

/// Hook pelaporan pelanggaran agar service ini tetap bebas dari provider.
typedef ExamViolationReporterFn = Future<void> Function(
  String responseId,
  String eventType,
  String? message,
  int questionIndex,
);

class ExamViolationReporter {
  ExamViolationReporter._();

  static ExamViolationReporterFn? reporter;

  static void register(ExamViolationReporterFn fn) => reporter = fn;

  static void unregister() => reporter = null;
}
