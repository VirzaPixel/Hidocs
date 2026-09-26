import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/screens/exam/exam_lockdown_gate_screen.dart';
import 'package:hi_docs/screens/exam/exam_token_screen.dart';
import 'package:hi_docs/screens/forms/user_form_detail_screen.dart';

/// Regresi untuk urutan alur ujian (Revisi Lanjutan 8):
///
///   detail form → gerbang "Persiapan Ujian" → layar token → pengisian
///
/// Dua hal yang diverifikasi di sini:
///  1. Tombol detail form bertuliskan "Persiapan Ujian" untuk tipe ujian.
///  2. Gerbang TIDAK lagi menuntut "sesi ujian terdaftar" dan melempar ke
///     layar token (bukan langsung ke pengisian).
FormModel _buildForm({required FormType type, bool tokenProtected = false}) {
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
  );
}

Widget _wrap(Widget home) {
  return ChangeNotifierProvider<FormProvider>(
    create: (_) => FormProvider(),
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
  testWidgets('detail form ujian menawarkan "Persiapan Ujian" lalu ke gerbang',
      (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(UserFormDetailScreen(form: _buildForm(
      type: FormType.exam,
      tokenProtected: true,
    ))));

    await _pumpUntil(
      tester,
      () => find.text('Persiapan Ujian').evaluate().isNotEmpty,
    );

    expect(find.text('Persiapan Ujian'), findsOneWidget);
    // Layar token TIDAK dibuka langsung dari detail form.
    expect(find.byType(ExamTokenScreen), findsNothing);

    await tester.tap(find.text('Persiapan Ujian'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ExamLockdownGateScreen), findsOneWidget);
    expect(find.byType(ExamTokenScreen), findsNothing);
  });

  testWidgets(
      'gerbang persiapan tidak lagi menuntut sesi ujian terdaftar '
      'dan lanjutnya ke layar token', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(ExamLockdownGateScreen(
      form: _buildForm(type: FormType.exam, tokenProtected: true),
    )));

    // Tunggu hasil evaluasi (screening + izin overlay) di UI.
    await _pumpUntil(
      tester,
      () =>
          find.text('Tidak ada aplikasi floating terdeteksi').evaluate().isNotEmpty,
    );

    // Syarat "sesi ujian terdaftar" sudah dihapus dari ringkasan.
    expect(find.text('Tidak ada aplikasi floating terdeteksi'), findsOneWidget);
    expect(find.text('Izin overlay HiDocs'), findsOneWidget);
    expect(find.text('Sesi ujian terdaftar (response id aktif)'), findsNothing);
    expect(
      find.textContaining(
        RegExp('sesi ujian terdaftar', caseSensitive: false),
      ),
      findsNothing,
    );

    // Tombol utama mengarah ke layar token, bukan langsung pengisian.
    final startButton = find.widgetWithText(ElevatedButton,
        'Syarat Belum Lengkap');
    final nextButton =
        find.widgetWithText(ElevatedButton, 'Lanjut Ke Token Ujian');
    expect(startButton, findsNothing);
    expect(nextButton, findsOneWidget);

    await tester.tap(nextButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ExamTokenScreen), findsOneWidget);
    expect(find.byType(ExamLockdownGateScreen), findsNothing);
  });

  testWidgets('gerbang memakai label "Mulai Ujian" untuk tipe survei',
      (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(ExamLockdownGateScreen(
      form: _buildForm(type: FormType.survey),
    )));

    await _pumpUntil(
      tester,
      () =>
          find.text('Tidak ada aplikasi floating terdeteksi').evaluate().isNotEmpty,
    );

    expect(find.text('Tidak ada aplikasi floating terdeteksi'), findsOneWidget);
    expect(find.text('Izin overlay HiDocs'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Mulai Ujian'),
      findsOneWidget,
    );
  });
}
