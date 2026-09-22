import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/models/response_model.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/screens/forms/grading_screen.dart';
import 'package:hi_docs/screens/forms/response_detail_screen.dart';
import 'package:hi_docs/utils/custom_page_route.dart';
import 'package:hi_docs/utils/web_download_stub.dart'
    if (dart.library.js_interop) 'package:hi_docs/utils/web_download_web.dart';

class ResultsScreen extends StatefulWidget {
  final FormModel form;

  const ResultsScreen({
    required this.form,
    super.key,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResponses();
    });
  }

  Future<void> _loadResponses() async {
    if (!mounted) return;
    await Provider.of<ResponseProvider>(context, listen: false)
        .loadResponsesForForm(widget.form.id, form: widget.form);
  }

  bool _isManuallyGraded(QuestionModel q) {
    return q.isScorable &&
        (q.type == QuestionType.longText ||
            q.type == QuestionType.shortText ||
            q.type == QuestionType.codeInput ||
            q.type == QuestionType.mathFormula);
  }

  bool _isFullyGraded(ResponseModel r) {
    final essays = widget.form.questions.where(_isManuallyGraded).toList();
    if (essays.isEmpty) return true;
    final gradedCount =
        essays.where((q) => r.essayScores[q.id] != null && r.essayScores[q.id] != 0).length;
    return gradedCount >= essays.length;
  }

  String _formatDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final responses = Provider.of<ResponseProvider>(context)
        .getResponsesByForm(widget.form.id)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    // Always recalculate percentage using the current form's maxScore
    // so that non-scorable questions (e.g. rating) are always excluded,
    // even for responses that were stored before the fix.
    final formMax = widget.form.maxScore;

    double calcPct(r) {
      if (formMax <= 0) return 0;
      final v = r.score / formMax * 100;
      return v.clamp(0, 100);
    }

    final total = responses.length;

    var avgScore = 0.0;
    if (total > 0) {
      final sum = responses.fold<double>(0, (prev, r) => prev + calcPct(r));
      avgScore = sum / total;
    }

    final essays = widget.form.questions.where(_isManuallyGraded).toList();
    final pendingGradingResponses =
        responses.where((r) => !_isFullyGraded(r)).length;

    // Calculate score brackets for legend breakdown
    var count90_100 = 0;
    var count75_89 = 0;
    var count60_74 = 0;
    var countUnder60 = 0;

    for (final r in responses) {
      final p = calcPct(r);
      if (p >= 90) {
        count90_100++;
      } else if (p >= 75) {
        count75_89++;
      } else if (p >= 60) {
        count60_74++;
      } else {
        countUnder60++;
      }
    }

    final primaryTxt = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.surfaceCard;
    final borderClr = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Form Results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.form.title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: responses.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // 1. Top Stats Cards Row (2 equal side-by-side cards)
                Row(
                  children: [
                    Expanded(
                      child: _TopStatCard(
                        icon: Icons.people_alt_outlined,
                        value: '$total',
                        label: 'Total Responses',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _TopStatCard(
                        icon: Icons.trending_up_rounded,
                        value: '${avgScore.round()}%',
                        label: 'Average Score',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Banner Card (Needs Grading Alert)
                if (essays.isNotEmpty && pendingGradingResponses > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2008)
                          : const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFE599),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: AppTheme.warning,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$pendingGradingResponses response needs grading',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${essays.length} questions require manual grading',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              CustomPageRoute(page:
                                    GradingScreen(form: widget.form),
                              ),
                            ).then((_) {
                              if (mounted) _loadResponses();
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Text(
                              'Open Grading',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: context.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Score Distribution Card with Donut Chart
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderClr),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.donut_large_rounded,
                            size: 20,
                            color: context.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Score Distribution',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: primaryTxt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Left side: Donut Chart
                          Expanded(
                            flex: 5,
                            child: SizedBox(
                              height: 140,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(130, 130),
                                    painter: _DonutChartPainter(
                                      c90: count90_100,
                                      c75: count75_89,
                                      c60: count60_74,
                                      cUnder60: countUnder60,
                                      total: total,
                                      midColor: context.primary,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${avgScore.round()}%',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: primaryTxt,
                                        ),
                                      ),
                                      const Text(
                                        'average',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Right side: Legend table with count badges
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                _LegendRow(
                                  color: AppTheme.success,
                                  label: '90-100%',
                                  count: count90_100,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 8),
                                _LegendRow(
                                  color: context.primary,
                                  label: '75-89%',
                                  count: count75_89,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 8),
                                _LegendRow(
                                  color: AppTheme.warning,
                                  label: '60-74%',
                                  count: count60_74,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 8),
                                _LegendRow(
                                  color: AppTheme.error,
                                  label: '< 60%',
                                  count: countUnder60,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Respondents Header & List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Respondents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryTxt,
                      ),
                    ),
                    Text(
                      '$total participants',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...responses.map((r) {
                  final fullyGraded = _isFullyGraded(r);
                  final initial = r.respondentName.isEmpty
                      ? '?'
                      : r.respondentName.substring(0, 1).toUpperCase();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderClr),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            CustomPageRoute(page: ResponseDetailScreen(
                                form: widget.form,
                                response: r,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) _loadResponses();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Avatar Box
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (!fullyGraded
                                          ? AppTheme.warning
                                          : context.primary)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: !fullyGraded
                                          ? AppTheme.warning
                                          : context.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.respondentName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTxt,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_formatDate(r.submittedAt)} • ${r.durationText}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Status / Score Badge
                              if (!fullyGraded)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: context.primaryWith(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${r.percentage.round()}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: context.primary,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppTheme.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // 5. Action Buttons (Export to Excel & Export to PDF)
                ElevatedButton.icon(
                  onPressed: () => _exportExcel(context),
                  icon: const Icon(Icons.table_chart_rounded, size: 20),
                  label: const Text(
                    'Export to Excel',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B9E5E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _exportPdf(context),
                  icon: Icon(Icons.picture_as_pdf_outlined,
                      size: 20, color: context.primary),
                  label: Text(
                    'Export to PDF',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: cardBg,
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: borderClr, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    final formProvider = Provider.of<FormProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await formProvider.exportResponses(widget.form.id, format: 'xlsx');
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (bytes.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Tidak ada data untuk diexport.'),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
      final safeTitle = widget.form.title.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
      final fileName = '${safeTitle}_responses.xlsx';
      if (kIsWeb) {
        await _downloadOnWeb(bytes, fileName,
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      } else {
        // Mobile / Desktop: write to temp dir then share
        String dirPath;
        try {
          final dir = await getTemporaryDirectory();
          dirPath = dir.path;
        } catch (_) {
          try {
            final dir = await getApplicationDocumentsDirectory();
            dirPath = dir.path;
          } catch (_) {
            dirPath = '/sdcard/Download';
          }
        }
        final file = File('$dirPath/$fileName');
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Export ${widget.form.title}'));
      }
      messenger.showSnackBar(
        SnackBar(
          content: const Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('Excel berhasil diexport')]),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
        final msg = e.toString().contains('ApiException') ? e.toString() : 'Gagal export Excel: $e';
        messenger.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final responses = Provider.of<ResponseProvider>(context, listen: false)
        .getResponsesByForm(widget.form.id);
    if (responses.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Tidak ada respons untuk diexport.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final pdf = pw.Document();
      final title = widget.form.title;
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (ctx) => pw.Text(title, style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          build: (ctx) => [
            pw.SizedBox(height: 8),
            pw.Text('Total Responses: ${responses.length}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['No', 'Email', 'Score', 'Submitted'],
              data: responses.asMap().entries.map((e) {
                final i = e.key + 1;
                final r = e.value;
                return [
                  '$i',
                  r.respondentEmail,
                  '${r.score.round()}/${r.maxScore.round()} (${r.percentage.round()}%)',
                  '${r.submittedAt.day}/${r.submittedAt.month}/${r.submittedAt.year}',
                ];
              }).toList(),
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 16),
            pw.Text('Questions:', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ...widget.form.questions.asMap().entries.map((en) => pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text('${en.key + 1}. ${en.value.text} (${en.value.score.round()} pts)', style: const pw.TextStyle(fontSize: 8)),
                )),
          ],
        ),
      );
      final Uint8List pdfBytes = await pdf.save();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
      final fileName = '${safeTitle}_responses.pdf';
      if (kIsWeb) {
        await _downloadOnWeb(pdfBytes, fileName, 'application/pdf');
      } else {
        // Mobile / Desktop: write to temp dir then share
        String dirPath;
        try {
          final dir = await getTemporaryDirectory();
          dirPath = dir.path;
        } catch (_) {
          try {
            final dir = await getApplicationDocumentsDirectory();
            dirPath = dir.path;
          } catch (_) {
            dirPath = '/sdcard/Download';
          }
        }
        final file = File('$dirPath/$fileName');
        await file.writeAsBytes(pdfBytes);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Export PDF $title'));
      }
      messenger.showSnackBar(
        SnackBar(
          content: const Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('PDF berhasil diexport')]),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal export PDF: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  /// Unduh berkas di web tanpa dart:html (pakai web_download_stub di non-web).
  Future<void> _downloadOnWeb(
    List<int> bytes,
    String fileName,
    String mimeType,
  ) =>
      WebDownload.save(
        bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        fileName,
        mimeType,
      );
}

class _TopStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  const _TopStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.primaryWith(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.primary, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final bool isDark;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : const Color(0xFFF0F4FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final int c90;
  final int c75;
  final int c60;
  final int cUnder60;
  final int total;
  final Color midColor;

  _DonutChartPainter({
    required this.c90,
    required this.c75,
    required this.c60,
    required this.cUnder60,
    required this.total,
    required this.midColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFEAEFF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (total == 0) return;

    var startAngle = -pi / 2;

    void drawArc(int count, Color color) {
      if (count <= 0) return;
      final sweepAngle = (count / total) * 2 * pi;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    drawArc(c90, AppTheme.success);
    drawArc(c75, midColor);
    drawArc(c60, AppTheme.warning);
    drawArc(cUnder60, AppTheme.error);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: context.primaryWith(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Responses Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Responses submitted by users will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
