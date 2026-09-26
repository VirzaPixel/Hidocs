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

/// Temuan satu aplikasi floating selama screening.
enum FloatingFindingKind {
  /// Sedang menayangkan bubble / jendela mengambang / PiP saat ini.
  activeOverlay,

  /// Alat floating KHUSUS yang terpasang (Floatee, Floating Apps, Easy
  /// Touch, XRecorder, Parallel Space, dsb) — memblokir walau sedang tidak
  /// tampil, karena tinggal satu ketukan untuk memunculkan overlay.
  installedTool,

  /// Aplikasi harian dengan kemampuan bubble/overlay (WhatsApp, Messenger,
  /// Gmail, keyboard, browser) yang TIDAK sedang menayangkannya → info saja.
  informational,
}

/// Hasil screening SELURUH aplikasi yang terpasang di perangkat.
class FloatingAppScreeningResult {
  /// Aplikasi yang menghalangi mulai ujian: overlay sedang tampil ATAU
  /// alat floating khusus terpasang.
  final List<InstalledAppInfo> blocking;

  /// Aplikasi ber-kemampuan floating yang hanya perlu dilaporkan, tidak
  /// memblokir (agar pengguna dengan WhatsApp/Gmail/keyboard pihak ketiga
  /// tetap bisa mengerjakan ujian).
  final List<InstalledAppInfo> informational;

  /// Jumlah aplikasi yang berhasil dibaca dari perangkat.
  final int totalScanned;

  /// `false` bila perangkat tidak menyediakan daftar aplikasi terpasang
  /// (non-Android atau scan gagal).
  final bool scanSupported;

  /// `true` bila pemindaian di Android diminta tapi GAGAL (channel tidak ada /
  /// PackageManager melempar error / daftar kosong pada perangkat yang jelas
  /// punya aplikasi terpasang).
  ///
  /// Ini menutup bug "fail-open": dulu kegagalan pemindaian dianggap hasil
  /// bersih sehingga gerbang ujian menyala hijau tanpa memeriksa apa pun.
  /// Sekarang kegagalan mengunci tombol mulai sampai pemindaian berhasil.
  final bool scanFailed;

  /// Total aplikasi yang terlihat di perangkat (untuk "memindai N dari M").
  /// `-1` bila native lama tidak mengirim angka ini.
  final int totalInstalled;

  const FloatingAppScreeningResult({
    required this.blocking,
    required this.informational,
    required this.totalScanned,
    required this.scanSupported,
    this.scanFailed = false,
    this.totalInstalled = -1,
  });

  /// Bersih = pemindaian benar-benar berhasil DAN tidak ada temuan blokir.
  bool get isClean => !scanFailed && blocking.isEmpty;

  /// Semua temuan floating (blokir + info), terurut risiko tertinggi.
  List<InstalledAppInfo> get allFindings => [...blocking, ...informational]
    ..sort((a, b) => b.riskLevel.compareTo(a.riskLevel));

  static const FloatingAppScreeningResult unsupported =
      FloatingAppScreeningResult(
    blocking: [],
    informational: [],
    totalScanned: 0,
    scanSupported: false,
  );

  /// Pemindaian gagal total — BUKAN bersih (fail-closed).
  static const FloatingAppScreeningResult scanFailure =
      FloatingAppScreeningResult(
    blocking: [],
    informational: [],
    totalScanned: 0,
    scanSupported: false,
    scanFailed: true,
  );

  static const FloatingAppScreeningResult empty = FloatingAppScreeningResult(
    blocking: [],
    informational: [],
    totalScanned: 0,
    scanSupported: true,
  );
}

/// Satu aplikasi yang dibaca dari perangkat beserta fakta floating-nya.
///
/// Native mengirim FAKTA (terpasang, izin overlay, sedang menayangkan
/// jendela); klasifikasi "floating app atau bukan" dilakukan di Dart lewat
/// katalog [kFloatingAppCatalog] sehingga mudah diuji dan bisa diperluas
/// tanpa menyentuh kode Kotlin.
class InstalledAppInfo {
  final String packageName;
  final String appName;

  /// `true` bila aplikasi BENAR-BENAR menayangkan jendela mengambang saat ini
  /// (bubble tampil / op overlay sedang dipakai task PiP), menurut native.
  final bool isFloatingActive;

  /// Aplikasi sistem / bawaan ROM tidak pernah dianggap mengganggu ujian.
  final bool isSystem;

  /// Aplikasi mendeklarasikan `SYSTEM_ALERT_WINDOW` di manifest-nya.
  final bool declaresOverlayPermission;

  /// Aplikasi sudah diberi izin "tampil di atas aplikasi lain".
  final bool overlayPermissionGranted;

  /// Proses aplikasi sedang terlihat/foreground (best-effort native).
  final bool isRunning;

  /// Nama tampilan dari katalog native bila package dikenal; `null` bila tidak.
  final String? matchedFloatingLabel;

  /// Hasil klasifikasi katalog/pola di sisi Dart.
  final FloatingClassification classification;

  InstalledAppInfo({
    required this.packageName,
    required this.appName,
    required this.isFloatingActive,
    required this.isSystem,
    this.declaresOverlayPermission = false,
    this.overlayPermissionGranted = false,
    this.isRunning = false,
    this.matchedFloatingLabel,
    FloatingClassification? classification,
  }) : classification =
            classification ??
            // PERBAIKAN BUG: klasifikasi kini ikut memakai FAKTA dari
            // perangkat (izin overlay diberikan / sedang menayangkan jendela),
            // bukan hanya kecocokan nama-package dengan katalog. Tanpa ini,
            // alat floating yang tidak terdaftar di katalog lolos diam-diam.
            classifyFloatingTool(
              packageName: packageName,
              appName: appName,
              facts: FloatingFacts(
                declaresOverlayPermission: declaresOverlayPermission,
                overlayPermissionGranted: overlayPermissionGranted,
                isFloatingActive: isFloatingActive,
                isSystemApp: isSystem,
              ),
            );

  FloatingAppEntry? get catalogEntry => classification.catalogEntry;

  int get riskLevel => classification.riskLevel;

  String get category => classification.category;

  /// Cara temuannya disimpulkan — dipakai sebagai teks alasan di UI.
  FloatingFindingKind get kind {
    if (isFloatingActive) return FloatingFindingKind.activeOverlay;
    if (classification.isDedicatedFloatingTool) {
      return FloatingFindingKind.installedTool;
    }
    return FloatingFindingKind.informational;
  }

  bool get blocks => kind != FloatingFindingKind.informational;

  /// Nama yang ditampilkan ke pengguna.
  String get displayName =>
      appName.isNotEmpty ? appName : (matchedFloatingLabel ?? packageName);

  /// Penjelasan singkat mengapa aplikasi ini ditandai.
  String get why {
    switch (kind) {
      case FloatingFindingKind.activeOverlay:
        return 'Sedang menayangkan jendela mengambang / bubble / PiP';
      case FloatingFindingKind.installedTool:
        final extra = overlayPermissionGranted
            ? ' · izin overlay sudah diberikan'
            : (declaresOverlayPermission
                ? ' · mendeklarasikan izin overlay'
                : '');
        return 'Alat floating khusus terpasang '
            '(${classification.reason})$extra';
      case FloatingFindingKind.informational:
        return 'Punya kemampuan bubble/overlay (${classification.reason}), '
            'tetapi tidak sedang menayangkannya';
    }
  }

  factory InstalledAppInfo.fromMap(Map<dynamic, dynamic> map) {
    final pkg = (map['packageName'] ?? '').toString();
    final label = (map['appName'] ?? '').toString();
    final matched = (map['matchedFloatingLabel'] ?? '').toString();
    return InstalledAppInfo(
      packageName: pkg,
      appName: label,
      isFloatingActive: map['isFloatingActive'] == true,
      isSystem: map['isSystem'] == true,
      declaresOverlayPermission: map['declaresOverlayPermission'] == true,
      overlayPermissionGranted: map['overlayPermissionGranted'] == true,
      isRunning: map['isRunning'] == true,
      matchedFloatingLabel: matched.isEmpty ? null : matched,
    );
  }
}


/// Service penguncian ujian.
///
/// Mengolah payload mentah dari channel native menjadi hasil screening.
///
/// Murni (tidak menyentuh platform) sehingga bisa diuji satuan — dan memang
/// di sinilah keputusan "apakah Floatee/Floating Apps menghalangi ujian"
/// diambil.
///
/// Menerima dua bentuk payload agar tahan terhadap perbedaan versi build
/// native yang terpasang di perangkat:
///  * `List` — bentuk lama: hanya daftar aplikasi hasil filter native.
///  * `Map`  — bentuk baru: `{'apps': [...], 'totalInstalled': int}` sehingga
///    UI bisa menulis "memindai N dari M aplikasi" dengan jujur.
FloatingAppScreeningResult screenInstalledPayload(
  Object? payload, {
  bool liveOnly = false,
}) {
  if (payload == null) return FloatingAppScreeningResult.scanFailure;

  List<dynamic> raw = const <dynamic>[];
  int totalInstalled = -1;

  if (payload is List) {
    raw = payload;
  } else if (payload is Map) {
    final apps = payload['apps'];
    if (apps is List) raw = apps;
    final total = payload['totalInstalled'];
    if (total is num) totalInstalled = total.toInt();
  } else {
    return FloatingAppScreeningResult.scanFailure;
  }

  final blocking = <InstalledAppInfo>[];
  final informational = <InstalledAppInfo>[];
  final seen = <String>{};
  var scanned = 0;

  for (final item in raw) {
    if (item is! Map) continue;
    scanned++;
    final info = InstalledAppInfo.fromMap(item);
    if (info.packageName.isEmpty) continue;

    // Mode live (selama ujian berlangsung): HANYA jendela yang benar-benar
    // sedang tampil yang dihitung, supaya alat floating yang cuma terpasang
    // tidak memicu pelanggaran berulang pada setiap pengecekan berkala.
    if (liveOnly && !info.isFloatingActive) continue;

    // Satu package bisa muncul dua kali (mis. profil kerja & profil utama).
    if (!seen.add(info.packageName)) continue;

    // Aplikasi kritikal sistem (telepon, SMS, settings, dsb) dikecualikan.
    if (isCriticalAllowed(info.packageName)) continue;

    // HiDocs sendiri tidak pernah ditandai.
    if (info.packageName == 'id.hidocs.app') continue;

    // Bawaan OEM tidak boleh membuat pengguna terkunci dari ujiannya:
    // izin overlay sistem jarang bisa dicabut dan aplikasinya tak bisa
    // di-uninstall. Tetap dilaporkan bila memang alat floating terkenal,
    // dan tetap diblokir bila SEDANG menayangkan jendela di atas ujian.
    if (info.isSystem && !info.isFloatingActive) {
      if (!liveOnly && info.classification.isDedicatedFloatingTool) {
        informational.add(info);
      }
      continue;
    }

    if (info.blocks) {
      blocking.add(info);
    } else {
      informational.add(info);
    }
  }

  // Build native lama tidak mengirim totalInstalled; pakai jumlah terbaca.
  if (totalInstalled < 0) totalInstalled = scanned;

  // Fail-closed: HP Android pasti punya puluhan aplikasi terpasang. Nol
  // berarti enumerasi gagal (mis. izin QUERY_ALL_PACKAGES ditolak), BUKAN
  // berarti perangkat bebas aplikasi floating.
  if (scanned == 0 && totalInstalled <= 0) {
    return FloatingAppScreeningResult.scanFailure;
  }

  blocking.sort((a, b) {
    final byKind = installedFindingRank(a.kind).compareTo(
      installedFindingRank(b.kind),
    );
    if (byKind != 0) return byKind;
    return b.riskLevel.compareTo(a.riskLevel);
  });
  informational.sort((a, b) => b.riskLevel.compareTo(a.riskLevel));

  return FloatingAppScreeningResult(
    blocking: blocking,
    informational: informational,
    totalScanned: scanned,
    totalInstalled: totalInstalled,
    scanSupported: true,
  );
}

/// Urutan tampil temuan: yang sedang aktif paling atas, lalu alat terpasang.
int installedFindingRank(FloatingFindingKind kind) => switch (kind) {
      FloatingFindingKind.activeOverlay => 0,
      FloatingFindingKind.installedTool => 1,
      FloatingFindingKind.informational => 2,
    };

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
  // Proses 1 — screening SELURUH aplikasi terpasang + kategorisasi
  // ---------------------------------------------------------------

  /// Screening penuh: membaca SELURUH aplikasi yang terpasang di perangkat,
  /// lalu mengkategorikan mana yang merupakan aplikasi floating.
  ///
  /// Kategori hasil (lihat [FloatingAppScreeningResult]):
  ///  * `blocking` — aplikasi yang SEDANG menayangkan bubble/float/PiP, atau
  ///    alat floating khusus yang terpasang (Floatee, Floating Apps, Easy
  ///    Touch, XRecorder, Parallel Space, dsb).
  ///  * `informational` — aplikasi harian ber-kemampuan bubble (WhatsApp,
  ///    Messenger, Gmail, keyboard, browser) yang tidak sedang menayangkannya.
  ///
  /// Ini memperbaiki bug lama: hasil native dulu difilter
  /// `isFloatingActive == true` saja, sehingga alat floating yang terpasang
  /// tetapi sedang tidak tampil (Floatee & Floating Apps) tidak pernah
  /// muncul di daftar.
  static Future<FloatingAppScreeningResult> screenFloatingApps() async {
    return _screen(useLiveOnlyChannel: false);
  }

  /// Screening ketat: HANYA aplikasi yang benar-benar sedang menayangkan
  /// jendela mengambang saat ini. Dipakai selama ujian berlangsung, supaya
  /// aplikasi floating yang sekadar terpasang tidak dihitung sebagai
  /// pelanggaran berulang.
  static Future<FloatingAppScreeningResult> screenActiveFloatingApps() async {
    return _screen(useLiveOnlyChannel: true);
  }

  static Future<FloatingAppScreeningResult> _screen({
    required bool useLiveOnlyChannel,
  }) async {
    if (!_isAndroid) return FloatingAppScreeningResult.unsupported;

    final method =
        useLiveOnlyChannel ? 'getActiveFloatingApps' : 'getInstalledApps';

    Object? payload;
    try {
      payload = await _channel.invokeMethod<Object?>(method);
    } catch (_) {
      // Termasuk MissingPluginException — artinya build native yang terpasang
      // belum punya method ini. Jangan pernah melapor "bersih" untuk
      // pemindaian yang sebenarnya tidak terjadi.
      return FloatingAppScreeningResult.scanFailure;
    }

    return screenInstalledPayload(payload, liveOnly: useLiveOnlyChannel);
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

  // ---------------------------------------------------------------
  // Suara peringatan saat keluar aplikasi (assets/keluar.mp3)
  // ---------------------------------------------------------------

  /// Senyalkan assets/keluar.mp3 lewat pemain audio NATIVE.
  ///
  /// Sengaja tidak memakai audioplayers: ketika aplikasi berpindah ke
  /// latar, isolat Dart bisa tertunda sehingga suara gagal berbunyi tepat
  /// di saat pengguna keluar. MediaPlayer native dengan `USAGE_ALARM`
  /// tetap berbunyi (dan tidak terpengaruh volume media yang di-mute).
  static Future<bool> playExitAlarm() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('playExitAlarm') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Hentikan suara peringatan (mis. pengguna sudah kembali ke ujian).
  static Future<void> stopExitAlarm() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('stopExitAlarm');
    } catch (_) {}
  }

  /// Pasang/lepas "senjata" alarm keluar. Hanya saat bernilai `true`
  /// native akan berbunyi sendiri ketika aktivitas kehilangan fokus
  /// (tombol Home, Recents, ganti aplikasi).
  static Future<void> setExitAlarmArmed(bool armed) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('setExitAlarmArmed', armed);
    } catch (_) {}
  }

  /// Buka halaman "Info aplikasi" milik [packageName] di Setelan, tempat
  /// pengguna bisa menghentikan paksa / mencabut izin overlay / mencopot
  /// aplikasi floating yang terdeteksi.
  static Future<bool> openAppSettings(String packageName) async {
    if (!_isAndroid || packageName.isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'openAppSettings',
            {'packageName': packageName},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
