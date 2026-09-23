import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'floating_app_catalog.dart';

/// Status satu syarat penguncian ujian.
enum LockRequirementStatus { granted, denied, unsupported }

/// Satu syarat yang harus dipenuhi sebelum siswa boleh mengerjakan ujian.
class LockRequirement {
  final String id;
  final String title;
  final String description;
  final LockRequirementStatus status;

  const LockRequirement({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  bool get isSatisfied =>
      status == LockRequirementStatus.granted ||
      status == LockRequirementStatus.unsupported;

  LockRequirement copyWith({LockRequirementStatus? status}) {
    return LockRequirement(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
    );
  }
}

/// Hasil screening aplikasi berbahaya yang terpasang.
class FloatingAppScreeningResult {
  final List<InstalledAppInfo> suspicious;
  final int totalScanned;
  final bool scanSupported;

  const FloatingAppScreeningResult({
    required this.suspicious,
    required this.totalScanned,
    required this.scanSupported,
  });

  bool get isClean => suspicious.isEmpty;

  static const FloatingAppScreeningResult unsupported =
      FloatingAppScreeningResult(
    suspicious: [],
    totalScanned: 0,
    scanSupported: false,
  );
}

/// Aplikasi aktif yang sedang tampil/menjalankan jendela mengambang (bubble,
/// chat-head, float-window, picture-in-picture) menurut pemeriksaan native.
///
/// Ini adalah *fungsi aktual* aplikasi yang terdeteksi — bukan asumsi dari
/// nama package. WhatsApp/YouTube/Gmail yang terpasang tetapi TIDAK menayangkan
/// bubble/float TIDAK akan pernah muncul di sini.
class InstalledAppInfo {
  final String packageName;
  final String appName;

  /// `true` bila aplikasi ini BENAR-BENAR menayangkan jendela mengambang
  /// saat ini (bubble sedang tampil / overlay aktif). Diambil dari
  /// `NotificationManager.getActiveNotifications` flag bubble,
  /// `AppOpsManager` overlay yang sedang dipakai, task PiP, dan katalog
  /// floating yang dikonfirmasi berjalan.
  final bool isFloatingActive;

  /// Sistem / launcher bawaan tidak pernah dianggap mengganggu ujian.
  final bool isSystem;

  /// Nama tampilan dari katalog bila package dikenal sebagai aplikasi
  /// floating; `null` untuk aplikasi biasa.
  final String? matchedFloatingLabel;

  const InstalledAppInfo({
    required this.packageName,
    required this.appName,
    required this.isFloatingActive,
    required this.isSystem,
    this.matchedFloatingLabel,
  });

  FloatingAppEntry? get catalogEntry => lookupCatalog(packageName);

  int get riskLevel => catalogEntry?.riskLevel ?? 2;

  /// Nama yang ditampilkan ke pengguna: nama asli aplikasi, atau nama
  /// katalog bila nama asli generik.
  String get displayName =>
      appName.isNotEmpty ? appName : (matchedFloatingLabel ?? packageName);

  factory InstalledAppInfo.fromMap(Map<dynamic, dynamic> map) {
    return InstalledAppInfo(
      packageName: (map['packageName'] ?? '').toString(),
      appName: (map['appName'] ?? '').toString(),
      isFloatingActive: map['isFloatingActive'] == true,
      isSystem: map['isSystem'] == true,
      matchedFloatingLabel: (map['matchedFloatingLabel'] ?? '').toString().isEmpty
          ? null
          : (map['matchedFloatingLabel'] ?? '').toString(),
    );
  }
}

/// Service penguncian ujian.
///
/// Menyatukan dua proses screening yang terpisah:
///  1. Screening daftar aplikasi terpasang (floating/bubble/overlay apps).
///  2. Pemeriksaan izin "tampil di atas aplikasi lain" (draw over other apps).
///
/// Ditambah syarat DND dan penguncian layar (FLAG_SECURE) + foreground service.
class ExamSecurityService {
  ExamSecurityService._();

  static const MethodChannel _channel =
      MethodChannel('id.hidocs.app/security');

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  // ---------------------------------------------------------------
  // Penguncian layar (FLAG_SECURE)
  // ---------------------------------------------------------------

  /// Blokir screenshot, screen recording, dan preview di task switcher.
  static Future<void> enableSecureScreen() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('enableSecure');
    } catch (_) {}
  }

  /// Kembalikan perilaku normal setelah ujian selesai.
  static Future<void> disableSecureScreen() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('disableSecure');
    } catch (_) {}
  }

  static Future<bool> isSecureEnabled() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isSecureEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------
  // Proses 1 — screening daftar aplikasi floating
  // ---------------------------------------------------------------

  /// Ambil aplikasi floating yang SEDANG AKTIF (menayangkan bubble /
  /// jendela mengambang) dari native, bukan sekadar "terpasang".
  ///
  /// Hasil HANYA aplikasi yang menurut Android benar-benar memunculkan
  /// bubble/chat-head/float-window/PiP saat ini. WhatsApp, YouTube, Gmail,
  /// Truecaller, PUBG, Word, Maps yang HANYA terpasang tetapi tidak
  /// menampilkan floating TIDAK akan pernah ditandai — persis sesuai
  /// permintaan: screening berdasarkan *fungsi aktual* aplikasi, bukan nama.
  static Future<FloatingAppScreeningResult> screenFloatingApps() async {
    if (!_isAndroid) return FloatingAppScreeningResult.unsupported;

    List<dynamic> raw;
    try {
      raw = await _channel.invokeMethod<List<dynamic>>('getInstalledApps') ??
          const [];
    } catch (_) {
      return FloatingAppScreeningResult.unsupported;
    }

    final suspicious = <InstalledAppInfo>[];
    var total = 0;

    for (final item in raw) {
      if (item is! Map) continue;
      total++;
      final info = InstalledAppInfo.fromMap(item);
      if (info.packageName.isEmpty) continue;

      // Aplikasi kritikal sistem (telepon, SMS, settings, dsb) dikecualikan.
      if (isCriticalAllowed(info.packageName)) continue;

      // HiDocs sendiri tidak pernah ditandai.
      if (info.packageName == 'id.hidocs.app') continue;

      // HANYA aplikasi floating yang benar-benar aktif yang ditandai.
      if (!info.isFloatingActive) continue;

      suspicious.add(info);
    }

    suspicious.sort((a, b) => b.riskLevel.compareTo(a.riskLevel));

    return FloatingAppScreeningResult(
      suspicious: suspicious,
      totalScanned: total,
      scanSupported: true,
    );
  }

  // ---------------------------------------------------------------
  // Proses 2 — izin draw over other apps
  // ---------------------------------------------------------------

  /// Cek apakah HiDocs sendiri punya izin overlay.
  static Future<bool> canDrawOverlays() async {
    if (!_isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Buka pengaturan izin overlay milik HiDocs.
  static Future<void> openOverlaySettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('openOverlaySettings');
    } catch (_) {}
  }

  // ---------------------------------------------------------------
  // Akses kebijakan notifikasi (DND) — DIHAPUS (Revisi Lanjutan 6).
  // Method-channel native terkait sudah dicabut. Stub di bawah selalu
  // mengembalikan nilai yang TIDAK mengunci kesiapan, agar kode lama
  // yang masih memanggil tidak pecah.
  // ---------------------------------------------------------------

  static Future<bool> isDndAccessGranted() async => true;

  static Future<void> openDndAccessSettings() async {}

  static Future<String> getInterruptionFilter() async => 'all';

  static Future<bool> isTotalSilenceActive() async {
    // Mode Sunyi Total DIHAPUS (Revisi Lanjutan 6) — sebelumnya memeriksa
    // filter interupsi DND. Selalu false agar tidak pernah mengunci kesiapan.
    return false;
  }

  /// mode: "none" (sunyi total) | "priority" | "alarms" | "all"
  ///
  /// DIHAPUS (Revisi Lanjutan 6): Mode Sunyi Total tidak boleh dipakai lagi.
  /// Method ini dipertahankan agar kode lama tidak pecah, tetapi TIDAK
  /// melakukan apa-apa dan selalu mengembalikan `false`.
  static Future<bool> setInterruptionFilter(String mode) async {
    return false;
  }

  /// DIHAPUS (Revisi Lanjutan 6): tidak melakukan apa-apa.
  static Future<bool> enableTotalSilence() => Future.value(false);

  /// DIHAPUS (Revisi Lanjutan 6): tidak melakukan apa-apa. Pemulihan volume
  /// ditangani oleh [restoreExamVolume].
  static Future<bool> restoreInterruptions() => Future.value(false);

  // ---------------------------------------------------------------
  // Volume ujian: AUTO FULL saat masuk, pulihkan saat keluar
  // (Revisi Lanjutan 6 — pengganti "Mode Sunyi Total"/DND yang dihapus)
  // ---------------------------------------------------------------

  /// Maksimalkan volume media perangkat (STREAM_MUSIC) saat persiapan/
  /// mulai ujian. Nilai lama disimpan native supaya bisa dipulihkan
  /// saat [restoreExamVolume].
  static Future<bool> maximizeExamVolume() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('maximizeExamVolume') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Kembalikan volume perangkat ke nilai semula (sebelum ujian).
  static Future<bool> restoreExamVolume() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('restoreExamVolume') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Nilai volume media saat ini (0.0 – 1.0, relatif terhadap maksimum).
  static Future<double> currentMediaVolume() async {
    if (!_isAndroid) return 1.0;
    try {
      return await _channel.invokeMethod<double>('currentMediaVolume') ?? 1.0;
    } catch (_) {
      return 1.0;
    }
  }

  // ---------------------------------------------------------------
  // Foreground service
  // ---------------------------------------------------------------

  static Future<void> startLockService() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('startLockService');
    } catch (_) {}
  }

  static Future<void> stopLockService() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('stopLockService');
    } catch (_) {}
  }

  // ---------------------------------------------------------------
  // Cek izin lain
  // ---------------------------------------------------------------

  static Future<bool> hasUsageStatsPermission() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('hasUsageStatsPermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openUsageAccessSettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('openUsageAccessSettings');
    } catch (_) {}
  }
}
