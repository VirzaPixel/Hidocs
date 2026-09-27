import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/screens/forms/fill_form_screen.dart';

/// Regresi "soal Ya/Tidak tidak bisa dipencet".
///
/// Akar masalahnya BUKAN hit-test, melainkan ketidakcocokan nilai:
/// halaman pengisian menyimpan jawaban sebagai **ID opsi**
/// (`selected_option_id` yang dikirim ke backend), sementara widget
/// `_YesNoAnswer` dulu membandingkannya dengan teks harfiah `'yes'`/`'no'`.
/// Akibatnya jawaban BENAR-BENAR tersimpan (terlihat di panel nomor soal),
/// tetapi tidak ada tombol yang pernah tersorot — bagi siswa ini terasa
/// seperti tombolnya rusak / tidak bisa ditekan.
///
/// Tes di bawah mengunci dua hal sekaligus:
///  1. menekan Ya/Tidak menyorot tombol yang benar (dan berpindah dengan
///     benar saat pilihan diganti);
///  2. perbaikan ini TIDAK merembet ke tipe soal lain (pilihan ganda tetap
///     berperilaku seperti sebelumnya).
///
/// Label opsi mengikuti data nyata: editor form menyimpan "Yes"/"No" sedangkan
/// parser Excel menyimpan "Ya"/"Tidak", jadi kedua bentuk diuji.
FormModel _formWith(QuestionModel question) {
  final now = DateTime(2026, 1, 1);
  return FormModel(
    id: 'form-1',
    title: 'Ujian Ya/Tidak',
    creatorId: 'guru-1',
    formType: FormType.exam,
    examToken: 'ABCD12',
    isTokenProtected: true,
    scheduledOpen: now,
    scheduledClose: now.add(const Duration(days: 365)),
    createdAt: now,
    questions: <QuestionModel>[question],
  );
}

QuestionModel _yesNoQuestion({
  String yesLabel = 'Yes',
  String noLabel = 'No',
  List<OptionModel>? options,
}) {
  return QuestionModel(
    id: 'q-1',
    type: QuestionType.yesNo,
    text: 'Apakah air mendidih pada 100 derajat?',
    options: options ??
        <OptionModel>[
          OptionModel(id: 'opt-y', text: yesLabel),
          OptionModel(id: 'opt-n', text: noLabel),
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

void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Warna garis tepi kotak tombol jawaban yang sedang terlihat.
///
/// Dipakai sebagai bukti "tombol tersorot": widget hanya mewarnai tepi
/// tombol dengan warna aksi saat pilihannya benar-benar aktif.
Color? _optionBorder(WidgetTester tester, String label) {
  final container = tester.widget<AnimatedContainer>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return (container.decoration as BoxDecoration?)?.border?.top.color;
}

/// Buka panel "Nomor Soal" lalu baca jumlah soal yang terhitung terjawab.
///
/// Angka ini dihitung dari `_answers`, jadi ia membuktikan jawaban BENAR-BENAR
/// tersimpan — terpisah dari pertanyaan apakah tombolnya terlihat tersorot.
Future<int> _answeredCount(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.grid_view_rounded).first);
  await tester.pumpAndSettle();

  final summary = tester
      .widgetList<Text>(find.textContaining('Sudah dijawab:'))
      .map((t) => t.data ?? '')
      .toList();
  expect(summary, isNotEmpty,
      reason: 'panel nomor soal harus menampilkan ringkasan');

  final match = RegExp(r'(\d+)').firstMatch(summary.first);
  await tester.tapAt(const Offset(600, 40));
  await tester.pumpAndSettle();
  return int.parse(match!.group(1)!);
}

void main() {
  testWidgets(
      'menekan "Ya" menyorot tombol Ya (jawaban tersimpan sebagai ID opsi)',
      (tester) async {
    _useTallScreen(tester);
    await tester
        .pumpWidget(_wrap(FillFormScreen(form: _formWith(_yesNoQuestion()))));
    await tester.pump();

    // Sebelum dijawab: tepi netral, bukan warna aksi mana pun.
    expect(_optionBorder(tester, 'Ya'), AppTheme.border);
    expect(_optionBorder(tester, 'Tidak'), AppTheme.border);

    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();

    // REGRESI: inilah yang dulu gagal — tepi tetap AppTheme.border walau
    // jawaban sudah tersimpan, sehingga tombol terasa "tidak bisa dipencet".
    expect(
      _optionBorder(tester, 'Ya'),
      AppTheme.success,
      reason: 'tombol Ya harus tersorot setelah ditekan',
    );
    expect(
      _optionBorder(tester, 'Tidak'),
      AppTheme.border,
      reason: 'tombol Tidak tidak boleh ikut tersorot',
    );

    // Jawabannya memang tercatat (bukan cuma tampilan).
    expect(await _answeredCount(tester), 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'menekan "Tidak" memindahkan sorotan dari "Ya" ke "Tidak"',
      (tester) async {
    _useTallScreen(tester);
    await tester
        .pumpWidget(_wrap(FillFormScreen(form: _formWith(_yesNoQuestion()))));
    await tester.pump();

    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();
    expect(_optionBorder(tester, 'Ya'), AppTheme.success);

    await tester.tap(find.text('Tidak'));
    await tester.pumpAndSettle();

    expect(
      _optionBorder(tester, 'Tidak'),
      AppTheme.error,
      reason: 'tombol Tidak harus tersorot setelah ditekan',
    );
    expect(
      _optionBorder(tester, 'Ya'),
      AppTheme.border,
      reason: 'pilihan lama harus dilepas (satu jawaban saja)',
    );
    expect(await _answeredCount(tester), 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'soal Ya/Tidak berlabel "Ya"/"Tidak" (hasil impor Excel) juga tersorot',
      (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(FillFormScreen(
      form: _formWith(_yesNoQuestion(yesLabel: 'Ya', noLabel: 'Tidak')),
    )));
    await tester.pump();

    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();
    expect(_optionBorder(tester, 'Ya'), AppTheme.success);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'label opsi tidak standar tetap terpetakan: opsi pertama = Ya, '
      'opsi terakhir = Tidak', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(FillFormScreen(
      form: _formWith(_yesNoQuestion(
        options: <OptionModel>[
          OptionModel(id: 'opt-a', text: 'Opsi A'),
          OptionModel(id: 'opt-b', text: 'Opsi B'),
        ],
      )),
    )));
    await tester.pump();

    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();

    // Sorotan mengikuti urutan opsi, bukan teks tombolnya.
    expect(_optionBorder(tester, 'Ya'), AppTheme.success);
    expect(_optionBorder(tester, 'Tidak'), AppTheme.border);
    expect(await _answeredCount(tester), 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'soal Ya/Tidak tanpa pasangan yang sah: tombol nonaktif dan tidak '
      'menyimpan jawaban', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(FillFormScreen(
      form: _formWith(_yesNoQuestion(
        // Label tak dikenal DAN hanya satu opsi: tidak ada dasar untuk
        // memutuskan mana "Ya" mana "Tidak", jadi jangan mengarang id.
        options: <OptionModel>[OptionModel(id: 'opt-only', text: 'Opsi Tunggal')],
      )),
    )));
    await tester.pump();

    await tester.tap(find.text('Ya'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      _optionBorder(tester, 'Ya'),
      AppTheme.border.withValues(alpha: 0.50),
      reason: 'tombol nonaktif tampil redup dan tidak pernah tersorot',
    );
    expect(await _answeredCount(tester), 0,
        reason: 'tidak ada id opsi yang boleh disimpan');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'soal Ya/Tidak dengan satu opsi "Ya" tetap bisa dijawab (pasangan '
      'yang sah tidak dikorbankan)', (tester) async {
    _useTallScreen(tester);
    await tester.pumpWidget(_wrap(FillFormScreen(
      form: _formWith(_yesNoQuestion(
        options: <OptionModel>[OptionModel(id: 'opt-y', text: 'Ya')],
      )),
    )));
    await tester.pump();

    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();

    expect(_optionBorder(tester, 'Ya'), AppTheme.success);
    expect(await _answeredCount(tester), 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'perbaikan Ya/Tidak TIDAK mengubah perilaku tipe soal lain '
      '(pilihan ganda tetap bisa dijawab)', (tester) async {
    _useTallScreen(tester);

    final now = DateTime(2026, 1, 1);
    final form = FormModel(
      id: 'form-2',
      title: 'Ujian Pilihan Ganda',
      creatorId: 'guru-1',
      formType: FormType.exam,
      scheduledOpen: now,
      scheduledClose: now.add(const Duration(days: 365)),
      createdAt: now,
      questions: <QuestionModel>[
        QuestionModel(
          id: 'q-mc',
          type: QuestionType.multipleChoice,
          text: 'Berapa hasil dari 2 + 2?',
          options: <OptionModel>[
            OptionModel(id: 'o-1', text: '4', isCorrect: true),
            OptionModel(id: 'o-2', text: '5'),
          ],
        ),
      ],
    );

    await tester.pumpWidget(_wrap(FillFormScreen(form: form)));
    await tester.pump();

    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    // Pilihan ganda memakai warna tema (catatan: bukan warna aksi Ya/Tidak).
    final selectedBorder = _optionBorder(tester, '4');
    expect(selectedBorder, isNot(AppTheme.border));
    expect(selectedBorder, isNot(AppTheme.success));
    expect(selectedBorder, isNot(AppTheme.error));
    expect(_optionBorder(tester, '5'), AppTheme.border);
    expect(await _answeredCount(tester), 1);

    await tester.pumpWidget(const SizedBox());
  });
}

