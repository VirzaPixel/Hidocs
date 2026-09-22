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

/// Aplikasi terpasang ringkas dari native.
class InstalledAppInfo {
  final String packageName;
  final String appName;
  final bool isSystem;
  final bool hasLaunchIntent;

  const InstalledAppInfo({
    required this.packageName,
    required this.appName,
    required this.isSystem,
    required this.hasLaunchIntent,
  });

  FloatingAppEntry? get catalogEntry => lookupCatalog(packageName);

  int get riskLevel => catalogEntry?.riskLevel ?? 2;

  factory InstalledAppInfo.fromMap(Map<dynamic, dynamic> map) {
    return InstalledAppInfo(
      packageName: (map['packageName'] ?? '').toString(),
      appName: (map['appName'] ?? '').toString(),
      isSystem: map['isSystem'] == true,
      hasLaunchIntent: map['hasLaunchIntent'] == true,
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

  /// Ambil aplikasi terpasang dari native, lalu saring yang berisiko.
  ///
  /// Hasil HANYA berdasarkan katalog hardcode + pola nama — tidak ada
  /// keputusan yang bergantung pada jaringan.
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

      // Lewati aplikasi tanpa launcher (service/plugin) — tidak mengganggu.
      if (!info.hasLaunchIntent) continue;

      if (isSuspiciousFloatingApp(
        packageName: info.packageName,
        appName: info.appName,
      )) {
        suspicious.add(info);
      }
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
  // DND / notification policy
  // ---------------------------------------------------------------

  static Future<bool> isDndAccessGranted() async {
    if (!_isAndroid) return true;
    try {
      return await _channel
              .invokeMethod<bool>('isNotificationPolicyAccessGranted') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openDndAccessSettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('openNotificationPolicySettings');
    } catch (_) {}
  }

  static Future<String> getInterruptionFilter() async {
    if (!_isAndroid) return 'unknown';
    try {
      return await _channel.invokeMethod<String>('getInterruptionFilter') ??
          'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  static Future<bool> isTotalSilenceActive() async {
    return (await getInterruptionFilter()) == 'none';
  }

  /// mode: "none" (sunyi total) | "priority" | "alarms" | "all"
  static Future<bool> setInterruptionFilter(String mode) async {
    if (!_isAndroid) return false;
    try {
      return await _channel
              .invokeMethod<bool>('setInterruptionFilter', {'mode': mode}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enableTotalSilence() => setInterruptionFilter('none');

  static Future<bool> restoreInterruptions() => setInterruptionFilter('all');

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
