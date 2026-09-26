import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/screens/exam/exam_lockdown_gate_screen.dart';
import 'package:hi_docs/screens/exam/exam_token_screen.dart';
import 'package:hi_docs/screens/forms/fill_form_screen.dart';
import 'package:hi_docs/screens/forms/user_form_detail_screen.dart';
import 'package:hi_docs/services/security/exam_security_service.dart';

/// Regresi untuk urutan alur ujian (Revisi Lanjutan 10):
///
///   detail form → layar token → gerbang "Persiapan Ujian" → pengisian
///
/// Tiga hal yang diverifikasi di sini:
///  1. Tombol detail form membuka LAYAR TOKEN lebih dulu (bukan gerbang).
///  2. Layar token melempar ke gerbang persiapan setelah token diterima.
///  3. Gerbang TIDAK lagi menuntut "sesi ujian terdaftar", dan tombolnya
///     langsung membuka pengisian soal.
///  4. Selama screening ulang berjalan, tombol gerbang TERKUNCI — hasil
///     screening lama tidak boleh dipercaya.
///
/// Alasan urutannya: screening aplikasi floating harus menjadi langkah
/// TERAKHIR sebelum soal dimuat, supaya siswa tidak bisa memanfaatkan layar
/// token untuk memasang aplikasi floating setelah lolos pemeriksaan.
FormModel _buildForm({
  required FormType type,
  bool tokenProtected = false,
  List<QuestionModel>? questions,
}) {
  final now = DateTime(2026, 1, 1);
  return FormModel(
    id: 'form-1',
    title: type == FormType.exam ? 'Ujian IPA Kelas 8' : 'Survei Minat',
    creatorId: 'guru-1',
    formType: type,
    examToken: tokenProtected ? 'ABCD12' : '',
    isTokenProtected: tokenProtected,
    customLinkAlias: type == FormType.exam ? 'ujian-ipa' : 'survei-minat',
    shortLink: type == FormType.exam ? 'ujian-ipa' : 'survei-minat',
    scheduledOpen: now,
    scheduledClose: now.add(const Duration(days: 365)),
    createdAt: now,
    questions: questions ?? const <QuestionModel>[],
  );
}

/// Form ujian dengan SATU soal pilihan ganda.
///
/// Dipakai untuk membuktikan gerbang benar-benar membuka halaman pengisian:
/// [FillFormScreen] tanpa soal akan langsung menutup dirinya sendiri
/// (auto-pop), sehingga hasil navigasinya tidak bisa dites.
FormModel _buildFormWithQuestion({required FormType type}) {
  return _buildForm(
    type: type,
    questions: <QuestionModel>[
      QuestionModel(
        id: 'q-1',
        type: QuestionType.multipleChoice,
        text: 'Berapa hasil dari 2 + 2?',
        options: <OptionModel>[
          OptionModel(id: 'o-1', text: '4', isCorrect: true),
          OptionModel(id: 'o-2', text: '5'),
        ],
      ),
    ],
  );
}

Widget _wrap(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<FormProvider>(create: (_) => FormProvider()),
      ChangeNotifierProvider<ResponseProvider>(create: (_) => ResponseProvider()),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      home: home,
    ),
  );
}

/// Beri ruang layar cukup supaya tombol di bagian bawah tidak perlu
/// digulirkan (menghindari kegagalan `tap` karena off-screen).
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Payload tiruan untuk [MethodChannel] `id.hidocs.app/security`.
///
/// Native mengirim objek `{'apps': [...], 'totalInstalled': n}`. Daftar
/// kosong dianggap **gagal memindai** oleh `screenInstalledPayload`
/// (fail-closed: HP Android pasti punya puluhan aplikasi), jadi payload di
/// sini memuat satu aplikasi biasa yang tidak menghalangi ujian.
Map<String, Object?> _cleanScreeningPayload() => <String, Object?>{
      'apps': <Map<String, Object?>>[
        <String, Object?>{
          'packageName': 'com.example.calculator',
          'appName': 'Calculator',
          'isSystem': false,
          'isFloatingActive': false,
          'declaresOverlayPermission': false,
          'overlayPermissionGranted': false,
          'isRunning': false,
        },
      ],
      'totalInstalled': 48,
    };

/// Payload tiruan: Floatee (alat floating khusus) terpasang di perangkat.
Map<String, Object?> _floateeScreeningPayload() => <String, Object?>{
      'apps': <Map<String, Object?>>[
        <String, Object?>{
          'packageName': 'com.maika.floatee',
          'appName': 'Floatee',
          'isSystem': false,
          'isFloatingActive': false,
          'declaresOverlayPermission': true,
          'overlayPermissionGranted': true,
          'isRunning': false,
        },
      ],
      'totalInstalled': 49,
    };

/// Tiruan channel keamanan native: HP dianggap SIAP (tidak ada aplikasi
/// mengganggu, izin overlay ada).
///
/// Tidak ada lagi tiruan status kiosk/device owner: sejak Revisi Lanjutan 9
/// penguncian ujian dikerjakan dari dalam aplikasi, jadi halaman persiapan
/// hanya perlu screening bersih + izin overlay.
void _mockReadySecurityChannel(WidgetTester tester) {
  const channel = MethodChannel('id.hidocs.app/security');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
      (call) async {
    switch (call.method) {
      case 'getInstalledApps':
      case 'getActiveFloatingApps':
        return _cleanScreeningPayload();
      case 'canDrawOverlays':
        return true;
      default:
        return null;
    }
  });
  addTearDown(() {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}

/// Tandai pengujian berjalan di jalur Android supaya panggilan channel native
/// benar-benar dikirim ke tiruan [_mockReadySecurityChannel].
void _asAndroid(WidgetTester tester) {
  ExamSecurityService.platformOverrideForTest = true;
  addTearDown(() => ExamSecurityService.platformOverrideForTest = null);
}

/// Pump beberapa kali sampai kondisi terpenuhi (evaluasi gerbang bersifat
/// async walaupun di host uji berjalan sangat cepat).
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxPumps = 12,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets(
      'detail form ujian membuka LAYAR TOKEN lebih dulu (bukan gerbang)',
      (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(UserFormDetailScreen(form: _buildForm(
      type: FormType.exam,
      tokenProtected: true,
    ))));

    await _pumpUntil(
      tester,
      () => find.text('Masukkan Token Ujian').evaluate().isNotEmpty,
    );

    // Langkah pertama ujian adalah token — labelnya mengikuti.
    expect(find.text('Masukkan Token Ujian'), findsOneWidget);

    await tester.tap(find.text('Masukkan Token Ujian'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ExamTokenScreen), findsOneWidget);
    // Gerbang persiapan TIDAK dibuka lebih dulu: screening floating harus
    // menjadi langkah terakhir sebelum soal dimuat.
    expect(find.byType(ExamLockdownGateScreen), findsNothing);
  });

  testWidgets(
      'layar token melempar ke gerbang persiapan, bukan langsung ke pengisian',
      (tester) async {
    _useTallScreen(tester);
    _asAndroid(tester);
    _mockReadySecurityChannel(tester);

    // Form TANPA token dipakai supaya jalurnya tidak bergantung pada balasan
    // `verify-token`: pada form seperti ini kegagalan pencatatan sesi tidak
    // mengunci siswa, dan halaman berikutnya (gerbang) tetap dibuka.
    await tester.pumpWidget(_wrap(
      ExamTokenScreen(form: _buildForm(type: FormType.exam)),
    ));

    await _pumpUntil(
      tester,
      () =>
          find.widgetWithText(ElevatedButton, 'Lanjutkan').evaluate().isNotEmpty,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Lanjutkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ExamLockdownGateScreen), findsOneWidget);
    expect(find.byType(FillFormScreen), findsNothing);
  });

  testWidgets(
      'gerbang persiapan tidak lagi menuntut sesi ujian terdaftar '
      'dan langsung membuka pengisian soal', (tester) async {
    _useTallScreen(tester);
    _asAndroid(tester);
    _mockReadySecurityChannel(tester);
    await tester.pumpWidget(_wrap(ExamLockdownGateScreen(
      form: _buildFormWithQuestion(type: FormType.exam),
      preEnteredToken: 'ABCD12',
      responseId: 'resp-123',
    )));

    // Tunggu hasil evaluasi (screening + izin overlay) di UI.
    await _pumpUntil(
      tester,
      () => find
          .text('Tidak ada aplikasi floating yang terdeteksi menghalangi ujian.')
          .evaluate()
          .isNotEmpty,
    );

    // Syarat "sesi ujian terdaftar" sudah dihapus dari ringkasan.
    expect(
      find.text('Tidak ada aplikasi floating yang terdeteksi menghalangi ujian.'),
      findsOneWidget,
    );
    expect(find.text('Izin overlay HiDocs'), findsOneWidget);
    expect(find.text('Sesi ujian terdaftar (response id aktif)'), findsNothing);
    expect(
      find.textContaining(
        RegExp('sesi ujian terdaftar', caseSensitive: false),
      ),
      findsNothing,
    );

    // Penguncian ujian TIDAK lagi menuntut device owner/kiosk, jadi tidak ada
    // lagi kartu provisioning maupun syaratnya di ringkasan gerbang.
    expect(find.text('Kunci Kiosk Sejati'), findsNothing);
    expect(find.text('Kunci kiosk aktif (device owner)'), findsNothing);
    expect(find.text('tool/exam_device_owner.sh'), findsNothing);
    expect(find.text('Kunci layar ujian siap'), findsOneWidget);

    // Gerbang adalah langkah terakhir: tombolnya langsung membuka pengisian.
    final startButton =
        find.widgetWithText(ElevatedButton, 'Syarat Belum Lengkap');
    final nextButton = find.widgetWithText(ElevatedButton, 'Mulai Ujian');
    expect(startButton, findsNothing);
    expect(nextButton, findsOneWidget);

    await tester.tap(nextButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(FillFormScreen), findsOneWidget);
    expect(find.byType(ExamLockdownGateScreen), findsNothing);

    // Token + response id dari layar token ikut sampai ke pengisian.
    final fill = tester.widget<FillFormScreen>(find.byType(FillFormScreen));
    expect(fill.preEnteredToken, 'ABCD12');
    expect(fill.responseId, 'resp-123');

    // Bersihkan pohon widget supaya timer milik halaman pengisian
    // (bilah status + autosave) tidak tertinggal saat tes selesai.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('gerbang memakai label "Mulai Ujian" untuk tipe survei',
      (tester) async {
    _useTallScreen(tester);
    _asAndroid(tester);
    _mockReadySecurityChannel(tester);
    await tester.pumpWidget(_wrap(ExamLockdownGateScreen(
      form: _buildForm(type: FormType.survey),
    )));

    await _pumpUntil(
      tester,
      () =>
          find.text('Tidak ada aplikasi floating yang terdeteksi menghalangi ujian.').evaluate().isNotEmpty,
    );

    expect(
      find.text('Tidak ada aplikasi floating yang terdeteksi menghalangi ujian.'),
      findsOneWidget,
    );
    expect(find.text('Izin overlay HiDocs'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Mulai Ujian'),
      findsOneWidget,
    );
  });

  testWidgets(
      'HP biasa tanpa provisioning tetap bisa lanjut ke pengisian soal',
      (tester) async {
    _useTallScreen(tester);
    _asAndroid(tester);
    // Channel keamanan sengaja dibiarkan MINIMAL: hanya screening bersih dan
    // izin overlay. Tidak ada `getLockTaskReport` — penguncian ujian tidak
    // boleh lagi bergantung pada provisioning device owner.
    const channel = MethodChannel('id.hidocs.app/security');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      switch (call.method) {
        case 'getInstalledApps':
        case 'getActiveFloatingApps':
          return _cleanScreeningPayload();
        case 'canDrawOverlays':
          return true;
        default:
          return null;
      }
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await tester.pumpWidget(_wrap(ExamLockdownGateScreen(
      form: _buildForm(type: FormType.exam, tokenProtected: true),
    )));

    await _pumpUntil(
      tester,
      () => find
          .widgetWithText(ElevatedButton, 'Mulai Ujian')
          .evaluate()
          .isNotEmpty,
    );

    // Tombol utama AKTIF: syaratnya hanya screening + izin overlay.
    expect(
      find.widgetWithText(ElevatedButton, 'Mulai Ujian'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ElevatedButton, 'Syarat Belum Lengkap'),
      findsNothing,
    );
    // Tidak ada lagi permintaan aksi teknisi/guru maupun skrip ADB.
    expect(find.text('Diperlukan aksi dari teknisi/guru'), findsNothing);
    expect(find.text('tool/exam_device_owner.sh'), findsNothing);
    expect(find.text('Kunci layar ujian siap'), findsOneWidget);
  });

  testWidgets(
      'selama screening ulang berjalan tombol gerbang TERKUNCI '
      '(hasil lama tidak dipercaya)', (tester) async {
    _useTallScreen(tester);
    _asAndroid(tester);

    // Panggilan screening ke-2 sengaja DITAHAN sampai tes selesai memeriksa
    // keadaan UI; inilah yang meniru "siswa baru kembali dari layar Settings".
    final secondScanGate = Completer<void>();
    var scanCount = 0;

    const channel = MethodChannel('id.hidocs.app/security');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      switch (call.method) {
        case 'getInstalledApps':
          scanCount++;
          if (scanCount == 1) return _cleanScreeningPayload();
          await secondScanGate.future;
          // Floatee baru saja dipasang di layar Settings.
          return _floateeScreeningPayload();
        case 'getActiveFloatingApps':
          return _cleanScreeningPayload();
        case 'canDrawOverlays':
          return true;
        default:
          return null;
      }
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await tester.pumpWidget(_wrap(ExamLockdownGateScreen(
      form: _buildFormWithQuestion(type: FormType.exam),
      preEnteredToken: 'ABCD12',
      responseId: 'resp-123',
    )));

    // Screening pertama bersih → tombol "Mulai Ujian" aktif.
    await _pumpUntil(
      tester,
      () => find
          .widgetWithText(ElevatedButton, 'Mulai Ujian')
          .evaluate()
          .isNotEmpty,
    );
    expect(find.widgetWithText(ElevatedButton, 'Mulai Ujian'), findsOneWidget);

    // Siswa keluar-masuk aplikasi (mis. dari layar Settings) → screening ulang.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // REGRESI: hasil screening lama TIDAK boleh dipakai untuk membuka ujian
    // selama pemeriksaan baru belum selesai.
    expect(
      find.widgetWithText(ElevatedButton, 'Syarat Belum Lengkap'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'Mulai Ujian'), findsNothing);

    // Screening baru selesai: Floatee terdeteksi → tombol tetap terkunci.
    secondScanGate.complete();
    await _pumpUntil(
      tester,
      () => find.text('Floatee').evaluate().isNotEmpty,
    );

    expect(find.text('Floatee'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Syarat Belum Lengkap'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'Mulai Ujian'), findsNothing);
    expect(find.byType(FillFormScreen), findsNothing);
  });
}
