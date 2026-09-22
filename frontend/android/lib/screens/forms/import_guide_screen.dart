import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';

class ImportGuideScreen extends StatefulWidget {
  final String initialTab; // 'word' or 'excel'

  const ImportGuideScreen({
    super.key,
    this.initialTab = 'word',
  });

  @override
  State<ImportGuideScreen> createState() => _ImportGuideScreenState();
}

class _ImportGuideScreenState extends State<ImportGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'excel' ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    const assetPath = 'assets/templates/template_import.docx';
    const fileName = 'template_import.docx';
    try {
      final data = await rootBundle.load(assetPath);
      String dirPath;
      try {
        dirPath = (await getTemporaryDirectory()).path;
      } catch (_) {
        try {
          dirPath = (await getApplicationDocumentsDirectory()).path;
        } catch (_) {
          dirPath = '/sdcard/Download';
        }
      }
      final file = File('$dirPath/$fileName');
      await file.writeAsBytes(data.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Template impor soal HiDocs'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh template: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text(
          'Panduan Format Impor',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Unduh Template',
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.download_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark ? AppTheme.darkCard : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: context.primary,
              labelColor: context.primary,
              unselectedLabelColor:
                  isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(
                  text: 'Dokumen Word (.docx)',
                ),
                Tab(
                  text: 'Spreadsheet Excel (.xlsx)',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WordGuideView(
            isDark: isDark,
            onCopyExample: (text) =>
                _copyToClipboard(text, 'Contoh format Word berhasil disalin!'),
            onDownloadTemplate: _downloadTemplate,
          ),
          _ExcelGuideView(
            isDark: isDark,
            onCopyExample: (text) =>
                _copyToClipboard(text, 'Contoh format Excel berhasil disalin!'),
            onDownloadTemplate: _downloadTemplate,
          ),
        ],
      ),
    );
  }
}

class _WordGuideView extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onCopyExample;
  final VoidCallback onDownloadTemplate;

  const _WordGuideView({
    required this.isDark,
    required this.onCopyExample,
    required this.onDownloadTemplate,
  });

  static const String wordExampleText = '''1. Apa ibu kota negara Indonesia?
A. Surabaya
*B. Nusantara
C. Bandung
D. Medan

2. Jelaskan pengertian dari Fotosintesis!
[Essay]

3. Apakah air mendidih pada suhu 100 derajat Celsius?
*A. Ya
B. Tidak

4. Pilih hewan mamalia berikut! (boleh lebih dari satu)
[Checkbox]
*A. Paus
B. Hiu
*C. Kelelawar
D. Buaya

5. Jodohkan negara dengan ibu kotanya!
[Matching]
Indonesia | Jakarta
Jepang | Tokyo
Prancis | Paris

6. Seberapa puas Anda dengan layanan kami?
[Rating 5]

7. Tuliskan fungsi untuk menjumlahkan dua bilangan!
[Code]

8. Tuliskan rumus luas lingkaran!
[Math]

9. Jelaskan isi gambar berikut! (sertakan gambar di dokumen)''';

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final borderClr = isDark ? AppTheme.darkBorder : AppTheme.border;
    final primaryTxt = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final mutedTxt = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Overview card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.primaryWith(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.primaryWith(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.primaryWith(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_rounded,
                    color: context.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Impor Otomatis Dokumen Word',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryTxt,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sistem akan membaca soal & opsi secara otomatis dari file .docx Anda.',
                      style: TextStyle(fontSize: 12, color: mutedTxt, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Rules Section
        Text(
          'Aturan Penulisan Dokumen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: primaryTxt,
          ),
        ),
        const SizedBox(height: 12),

        _RuleTile(
          number: '1',
          title: 'Format Soal (Nomor)',
          description:
              'Gunakan penomoran diawali angka dan titik / kurung. Contoh: "1.", "Soal 1", atau "Q1."',
          isDark: isDark,
        ),
        _RuleTile(
          number: '2',
          title: 'Pilihan Ganda (Opsi)',
          description:
              'Awali opsi dengan huruf A., B., C., D. atau a), b), c). Tulis setiap opsi di baris baru.',
          isDark: isDark,
        ),
        _RuleTile(
          number: '3',
          title: 'Kunci Jawaban (Pilihan Ganda)',
          description:
              'Berikan tanda bintang (*) di depan huruf opsi benar (contoh: "*B. Jawaban Benar") atau tambahkan baris "Kunci Jawaban: B" di bawah soal.',
          isDark: isDark,
        ),
        _RuleTile(
          number: '4',
          title: 'Soal Essay / Isian',
          description:
              'Untuk membuat soal essay tanpa opsi pilihan ganda, cukup tuliskan "[Essay]" atau tidak memberikan pilihan opsi A-D di bawah soal. Untuk isian singkat, kosongkan opsi tanpa marker.',
          isDark: isDark,
        ),
        _RuleTile(
          number: '5',
          title: 'Checkbox (Jawaban Ganda)',
          description:
              'Tulis "[Checkbox]" di bawah soal, lalu tulis opsi seperti PG. Tandai jawaban benar dengan bintang (*) — boleh lebih dari satu (contoh: "*A. Paus").',
          isDark: isDark,
        ),
        _RuleTile(
          number: '6',
          title: 'Menjodohkan (Matching)',
          description:
              'Tulis "[Matching]" di bawah soal, lalu tulis tiap pasangan dengan format "Kiri | Kanan" per baris (contoh: "Indonesia | Jakarta").',
          isDark: isDark,
        ),
        _RuleTile(
          number: '7',
          title: 'Rating / Ya-Tidak / Code / Math / Gambar',
          description:
              'Rating: tulis "[Rating 5]" (angka 3/5/10 = jumlah bintang). Ya-Tidak: opsi A. Ya / B. Tidak. Code: tulis "[Code]". Math/rumus: tulis "[Math]". Soal gambar: sisipkan gambar di bawah teks soal.',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onDownloadTemplate,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: const Text(
              'Unduh Template Word (.docx)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Preview Example Code Box
        Row(
          children: [
            Expanded(
              child: Text(
                'Contoh Teks Dokumen Word',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: primaryTxt,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => onCopyExample(wordExampleText),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Salin Contoh'),
              style: TextButton.styleFrom(
                foregroundColor: context.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderClr),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                wordExampleText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ExcelGuideView extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onCopyExample;
  final VoidCallback onDownloadTemplate;

  const _ExcelGuideView({
    required this.isDark,
    required this.onCopyExample,
    required this.onDownloadTemplate,
  });

  static const String excelCsvExample = '''No,Soal,Tipe,Opsi A,Opsi B,Opsi C,Opsi D,Kunci Jawaban,Poin
1,Apa ibu kota Indonesia?,PG,Surabaya,Nusantara,Bandung,Medan,B,10
2,Jelaskan Fotosintesis!,Essay,,,,,,15
3,Apakah bumi itu bulat?,YaTidak,Ya,Tidak,,,A,5
4,Pilih hewan mamalia!,Checkbox,Paus;Hiu;Kelelawar;Buaya,,,,A;C,10
5,Jodohkan negara-ibu kota!,Matching,Indonesia|Jakarta;Jepang|Tokyo;Prancis|Paris,,,,,10
6,Seberapa puas layanan kami?,Rating,,,,,,5,5
7,Tulis fungsi jumlah dua bilangan!,Code,,,,,, ,10
8,Tulis rumus luas lingkaran!,Math,,,,,, ,10
9,Jelaskan isi gambar berikut!,Essay,,,,,, ,10''';

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final borderClr = isDark ? AppTheme.darkBorder : AppTheme.border;
    final primaryTxt = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final mutedTxt = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Overview card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.table_chart_rounded,
                    color: AppTheme.success, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Impor Tabel Spreadsheet Excel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryTxt,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Susun kolom spreadsheet Excel (.xlsx) sesuai dengan tata letak header di bawah.',
                      style: TextStyle(fontSize: 12, color: mutedTxt, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onDownloadTemplate,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: const Text(
              'Unduh Template Word (.docx)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Struktur Header Kolom Excel',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: primaryTxt,
          ),
        ),
        const SizedBox(height: 12),

        // Table Structure representation
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderClr),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                context.primaryWith(0.08),
              ),
              columns: const [
                DataColumn(label: Text('Kolom', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Header', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Deskripsi & Contoh', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('A')),
                  DataCell(Text('No')),
                  DataCell(Text('Nomor urut soal (1, 2, 3...)')),
                ]),
                DataRow(cells: [
                  DataCell(Text('B')),
                  DataCell(Text('Soal')),
                  DataCell(Text('Teks pertanyaan')),
                ]),
                DataRow(cells: [
                  DataCell(Text('C')),
                  DataCell(Text('Tipe')),
                  DataCell(Text('PG / Checkbox / Essay / Isian / YaTidak / Rating / Math / Code / Image / Matching')),
                ]),
                DataRow(cells: [
                  DataCell(Text('D - G')),
                  DataCell(Text('Opsi A - D')),
                  DataCell(Text('Pilihan jawaban (Kosongkan jika Essay)')),
                ]),
                DataRow(cells: [
                  DataCell(Text('H')),
                  DataCell(Text('Kunci Jawaban')),
                  DataCell(Text('Huruf opsi benar (misal: A / B / C / D)')),
                ]),
                DataRow(cells: [
                  DataCell(Text('I')),
                  DataCell(Text('Poin')),
                  DataCell(Text('Bobot nilai soal (misal: 10)')),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Example Box
        Row(
          children: [
            Expanded(
              child: Text(
                'Contoh Baris Excel (CSV)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: primaryTxt,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => onCopyExample(excelCsvExample),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Salin Format'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.success,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderClr),
          ),
          child: const SelectableText(
            excelCsvExample,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RuleTile extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final bool isDark;

  const _RuleTile({
    required this.number,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.primaryWith(0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: context.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
