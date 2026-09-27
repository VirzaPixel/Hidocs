import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/screens/exam/exam_token_screen.dart';
import 'package:hi_docs/services/security/exam_security_service.dart';

/// Channel yang sama dengan `ExamSecurityService._channel` —WAYANG
/// MethodChannel kesamaan Comparing berdasarkan nama, jadi tidak perlu
/// membocorkan field private dari service.
const MethodChannel _securityChannel =
    MethodChannel('id.hidocs.app/security');

/// merekam setiap panggilan ke channel keamanan native.
class _RecordingBridge {
  final List<MethodCall> calls = <MethodCall>[];

  _RecordingBridge() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_securityChannel, (call) async {
      calls.add(call);
      return null;
    });
  }

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_securityChannel, null);
  }

  List<String> get methods => calls.map((c) => c.method).toList();

  /// Baca argumen native yang bisa berupa map (`{'enabled': …}`) maupun bool
  /// polos — `setExitAlarmArmed` memang mengirim bool langsung.
  Object? _argOf(MethodCall call, String key) {
    final args = call.arguments;
    if (args is Map) return args[key];
    return args;
  }

  bool _hasFlag(String method, String key, bool value) => calls.any(
        (c) => c.method == method && _argOf(c, key) == value,
      );

  bool get sessionMarkedIdle => _hasFlag('setExamSessionActive', 'active', false);

  bool get alarmDisarmed => _hasFlag('setExitAlarmArmed', 'armed', false);

  bool get alarmArmed => _hasFlag('setExitAlarmArmed', 'armed', true);
}

FormModel _buildForm({bool tokenProtected = true}) {
  final now = DateTime(2026, 1, 1);
  return FormModel(
    id: 'form-1',
    title: 'Ujian IPA Kelas 8',
    creatorId: 'guru-1',
    formType: FormType.exam,
    examToken: tokenProtected ? 'ABCD12' : '',
    isTokenProtected: tokenProtected,
    customLinkAlias: 'ujian-ipa',
    shortLink: 'ujian-ipa',
    scheduledOpen: now,
    scheduledClose: now.add(const Duration(days: 365)),
    createdAt: now,
  );
}

void main() {
  late _RecordingBridge bridge;

  /// Jalankan [body] dengan tiruan platform Android + channel rekaman.
  ///
  /// Override harus dicabut lagi di dalam badan test: `tearDown` berjalan
  /// setelah `testWidgets` selesai, jadi sudah terlambat untuk test widget.
  Future<void> onAndroid(WidgetTester tester, Future<void> Function() body) async {
    ExamSecurityService.platformOverrideForTest = true;
    bridge = _RecordingBridge();
    try {
      await body();
    } finally {
      bridge.dispose();
      ExamSecurityService.platformOverrideForTest = null;
    }
  }

  Widget wrapScreen(Widget home) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      home: home,
    );
  }

  /// Regresi bug #1: suara alarm keluar berbunyi padahal siswa masih di
  /// halaman masukan token.
  ///
  /// Halaman token BUKAN bagian dari sesi ujian, jadi saat dibuka semua
  /// fitur kunci (terutama alarm `assets/keluar.mp3`) harus dipastikan
  /// mati. Menutup aplikasi di halaman ini harus benar-benar sunyi.
  testWidgets('halaman token memaksa sesi ujian idle saat dibuka',
      (tester) async {
    await onAndroid(tester, () async {
      await tester.pumpWidget(wrapScreen(ExamTokenScreen(form: _buildForm())));
      await tester.pump();
    });

    // Penanda sesi harus dimatikan — inilah penjaga yang dibaca
    // `SecurityBridge.onUserLeftActivity` sebelum membunyikan alarm.
    expect(
      bridge.sessionMarkedIdle,
      isTrue,
      reason: 'halaman token harus menandai sesi ujian tidak aktif',
    );
    // ...dan alarm harus dicabut, bukan sekadar tidak dipicu.
    expect(
      bridge.alarmDisarmed,
      isTrue,
      reason: 'alarm keluar harus dilepas di halaman token',
    );
    // Suara yang mungkin masih berbunyi harus dihentikan seketika.
    expect(
      bridge.methods,
      contains('stopExitAlarm'),
      reason: 'sisa suara dari percobaan sebelumnya harus dihentikan',
    );
  });

  testWidgets('halaman token tidak pernah menyalakan alarm', (tester) async {
    await onAndroid(tester, () async {
      await tester.pumpWidget(wrapScreen(ExamTokenScreen(form: _buildForm())));
      await tester.pump();
    });

    expect(
      bridge.alarmArmed,
      isFalse,
      reason: 'halaman token tidak boleh memasang alarm keluar',
    );
  });

  testWidgets('form tanpa token pun tetap tidak menyalakan alarm',
      (tester) async {
    await onAndroid(tester, () async {
      await tester.pumpWidget(
        wrapScreen(ExamTokenScreen(form: _buildForm(tokenProtected: false))),
      );
      await tester.pump();
    });

    expect(bridge.alarmArmed, isFalse);
    expect(bridge.sessionMarkedIdle, isTrue);
  });
}
