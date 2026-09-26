import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:hi_docs/services/api/api_client.dart';

import 'exam_security_service.dart';

/// Ringkasan kesiapan SELURUH syarat persiapan ujian (Revisi Lanjutan 7).
///
/// Syaratnya TIGA:
///  1. `overlayPermissionOk` — HiDocs punya izin "tampil di atas aplikasi".
///  2. `floatingAppsClean` — hasil screening seluruh aplikasi terpasang:
///     tidak ada alat floating khusus terpasang dan tidak ada overlay yang
///     sedang tampil (lihat [ExamLockdownService.evaluateLive] untuk versi
///     "hanya yang sedang tampil" selama ujian).
///  3. `kioskReady` — HP sudah diprovision sebagai **device owner** sehingga
///     Lock Task Mode (kiosk sejati) bisa dikunci saat siswa mengerjakan.
///     Tanpa status ini `startLockTask()` hanya berhenti pada dialog screen
///     pinning yang masih bisa dibatalkan siswa (lihat `KioskReadiness`).
///
/// "Mode Sunyi Total" DIHAPUS sesuai permintaan: tidak ada DND, tidak ada
/// akses kebijakan notifikasi. Field `dndAccessOk`/`dndActive` dipertahankan
/// sebagai konstanta kompatibilitas agar pemanggil lama tidak pecah — keduanya
/// SELALU true dan tidak lagi mengunci kesiapan.
class LockdownReadiness {
  final bool overlayPermissionOk;
  final bool floatingAppsClean;

  /// Kesiapan Lock Task Mode; lihat [KioskReadiness].
  final KioskReadiness kiosk;

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
    this.kiosk = KioskReadiness.unsupported,
  });

  /// Hanya screening floating aktif + izin overlay + kesiapan kiosk.
  bool get isReady =>
      overlayPermissionOk && floatingAppsClean && kiosk.deviceOwner;

  /// Daftar id syarat yang belum terpenuhi.
  List<String> get unmetRequirements {
    final list = <String>[];
    if (!overlayPermissionOk) list.add('overlay');
    if (!floatingAppsClean) list.add('floating_apps');
    if (!kiosk.deviceOwner) list.add('kiosk');
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
  /// Read-only: TIDAK mengubah volume, izin, maupun status Lock Task.
  ///
  /// Versi "persiapan": memindai seluruh aplikasi yang terpasang di perangkat
  /// dan mengkategorikan mana yang aplikasi floating, sekaligus membaca
  /// kesiapan Lock Task Mode (apakah HiDocs sudah jadi device owner).
  static Future<LockdownReadiness> evaluate() async {
    final screening = await ExamSecurityService.screenFloatingApps();
    final overlayOk = await ExamSecurityService.canDrawOverlays();
    final kiosk = await ExamSecurityService.getKioskReadiness();

    return LockdownReadiness(
      overlayPermissionOk: overlayOk,
      floatingAppsClean: screening.isClean,
      kiosk: kiosk,
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
    final kiosk = await ExamSecurityService.getKioskReadiness();

    return LockdownReadiness(
      overlayPermissionOk: overlayOk,
      floatingAppsClean: screening.isClean,
      kiosk: kiosk,
      screening: screening,
    );
  }

  /// Aktifkan persiapan/awal ujian: FLAG_SECURE, foreground service,
  /// volume media AUTO FULL (nilai lama disimpan untuk dipulihkan), alarm
  /// keluar aplikasi, dan Lock Task Mode (kiosk sejati).
  ///
  /// `setExamSessionActive(true)` adalah pemicu penjaga alarm keluar di
  /// native: tanpa itu, `MainActivity` akan membunyikan alarm untuk halaman
  /// mana pun yang kebetulan terbuka sebelum ujian dimulai (mis. layar
  /// masukan token).
  ///
  /// Urutan penting: penanda sesi dinyalakan SEBELUM [ExamSecurityService
  /// .startKiosk]. Bila siswa menekan Home tepat saat kiosk aktif, penanda
  /// sesi sudah `true` sehingga alarm berbunyi.
  ///
  /// Kembalikan `true` bila perangkat benar-benar terkunci (device owner).
  static Future<bool> engage() async {
    await ExamSecurityService.enableSecureScreen();
    await ExamSecurityService.startLockService();
    await ExamSecurityService.maximizeExamVolume();
    await ExamSecurityService.setExamSessionActive(true);
    await ExamSecurityService.setExitAlarmArmed(true);
    // Kunci tampilan penuh: status bar + nav bar tidak bisa dimunculkan lagi
    // lewat gestur tepi layar.
    await ExamSecurityService.setFullscreenLock(true);
    // Kunci Task Mode: Home/Recents/notifikasi mati total. Hanya berhasil
    // penuh bila HiDocs berstatus device owner (lihat KioskReadiness).
    return ExamSecurityService.startKiosk();
  }

  /// Lepaskan persiapan/penguncian: kembalikan FLAG_SECURE, hentikan service,
  /// cabut alarm keluar, lepas Lock Task Mode, dan pulihkan volume perangkat
  /// ke nilai semula.
  static Future<void> release() async {
    // Keluar dari kiosk lebih dulu supaya aplikasi bisa benar-benar meninggalkan
    // layar ujian.
    await ExamSecurityService.stopKiosk();
    // Matikan penanda sesi DULUAN: native ikut menghentikan suara yang
    // masih berbunyi sebelum alarm dilepas sepenuhnya.
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
  /// berbunyi dan tanpa layar terkunci. Fungsi ini idempoten — aman
  /// dipanggil berulang, termasuk untuk membersihkan sisa sesi sebelumnya.
  ///
  /// Jika kiosk ternyata masih aktif (mis. aplikasi dibuka ulang saat masih
  /// terkunci), Lock Task Mode juga dilepas di sini supaya tidak ada paket
  /// yang tertinggal di allowlist.
  static Future<void> ensureIdle() async {
    await ExamSecurityService.setExamSessionActive(false);
    await ExamSecurityService.setExitAlarmArmed(false);
    await ExamSecurityService.stopExitAlarm();
    await ExamSecurityService.setFullscreenLock(false);
    final kiosk = await ExamSecurityService.getKioskReadiness();
    if (kiosk.kioskActive) {
      await ExamSecurityService.stopKiosk();
    }
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
