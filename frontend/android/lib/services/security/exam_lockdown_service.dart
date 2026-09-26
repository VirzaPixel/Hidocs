import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:hi_docs/services/api/api_client.dart';

import 'exam_security_service.dart';

/// Ringkasan kesiapan SELURUH syarat persiapan ujian (Revisi Lanjutan 7).
///
/// Syaratnya HANYA dua + pemeriksaan sesi:
///  1. `overlayPermissionOk` — HiDocs punya izin "tampil di atas aplikasi".
///  2. `floatingAppsClean` — hasil screening seluruh aplikasi terpasang:
///     tidak ada alat floating khusus terpasang dan tidak ada overlay yang
///     sedang tampil (lihat [ExamLockdownService.evaluateLive] untuk versi
///     "hanya yang sedang tampil" selama ujian).
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

  /// Hanya screening floating aktif + izin overlay.
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
  /// Read-only: TIDAK mengubah volume maupun izin apa pun.
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
  /// volume media AUTO FULL (nilai lama disimpan untuk dipulihkan), dan
  /// alarm keluar aplikasi.
  static Future<void> engage() async {
    await ExamSecurityService.enableSecureScreen();
    await ExamSecurityService.startLockService();
    await ExamSecurityService.maximizeExamVolume();
    await ExamSecurityService.setExitAlarmArmed(true);
  }

  /// Lepaskan persiapan/penguncian: kembalikan FLAG_SECURE, hentikan service,
  /// cabut alarm keluar, dan pulihkan volume perangkat ke nilai semula.
  static Future<void> release() async {
    await ExamSecurityService.setExitAlarmArmed(false);
    await ExamSecurityService.disableSecureScreen();
    await ExamSecurityService.stopLockService();
    await ExamSecurityService.restoreExamVolume();
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
