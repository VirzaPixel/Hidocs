import 'dart:async';

import 'package:flutter/foundation.dart';

import 'exam_security_service.dart';

/// Ringkasan kesiapan seluruh syarat penguncian ujian.
class LockdownReadiness {
  final bool overlayPermissionOk;
  final bool floatingAppsClean;
  final bool dndAccessOk;
  final bool dndActive;
  final FloatingAppScreeningResult screening;

  const LockdownReadiness({
    required this.overlayPermissionOk,
    required this.floatingAppsClean,
    required this.dndAccessOk,
    required this.dndActive,
    required this.screening,
  });

  /// Kedua proses screening + DND harus terpenuhi.
  bool get isReady =>
      overlayPermissionOk && floatingAppsClean && dndAccessOk && dndActive;

  /// Daftar id syarat yang belum terpenuhi.
  List<String> get unmetRequirements {
    final list = <String>[];
    if (!overlayPermissionOk) list.add('overlay');
    if (!floatingAppsClean) list.add('floating_apps');
    if (!dndAccessOk) list.add('dnd_access');
    if (!dndActive) list.add('dnd_active');
    return list;
  }
}

/// Orkestrator penguncian ujian.
///
/// Menggabungkan DUA proses screening yang tetap terpisah:
///  1. `floatingAppsClean` — hasil screening katalog aplikasi floating.
///  2. `overlayPermissionOk` — HiDocs mengantongi izin overlay.
///
/// Ditambah syarat DND akses + DND aktif (sunyi total) selama ujian.
class ExamLockdownService {
  ExamLockdownService._();

  /// Jalankan seluruh pemeriksaan dan kembalikan ringkasannya.
  /// Read-only: TIDAK mengubah DND, hanya membaca status sunyi.
  static Future<LockdownReadiness> evaluate() async {
    final screening = await ExamSecurityService.screenFloatingApps();
    final overlayOk = await ExamSecurityService.canDrawOverlays();
    final dndAccess = await ExamSecurityService.isDndAccessGranted();
    final dndActive =
        dndAccess ? await ExamSecurityService.isTotalSilenceActive() : false;

    return LockdownReadiness(
      overlayPermissionOk: overlayOk,
      floatingAppsClean: screening.isClean,
      dndAccessOk: dndAccess,
      dndActive: dndActive,
      screening: screening,
    );
  }

  /// Aktifkan seluruh penguncian: FLAG_SECURE, foreground service, DND sunyi.
  static Future<void> engage() async {
    await ExamSecurityService.enableSecureScreen();
    await ExamSecurityService.startLockService();
    await ExamSecurityService.enableTotalSilence();
  }

  /// Lepaskan seluruh penguncian dan pulihkan notifikasi normal.
  static Future<void> release() async {
    await ExamSecurityService.disableSecureScreen();
    await ExamSecurityService.stopLockService();
    await ExamSecurityService.restoreInterruptions();
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
