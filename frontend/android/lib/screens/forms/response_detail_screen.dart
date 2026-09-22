import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/models/response_model.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/widgets/exam/code_block_widget.dart';
import 'package:hi_docs/widgets/common/gradient_button.dart';
import 'package:hi_docs/widgets/exam/math_formula_widget.dart';
import 'package:hi_docs/widgets/form/rich_text_view.dart';

class ResponseDetailScreen extends StatefulWidget {
  final FormModel form;
  final ResponseModel response;

  const ResponseDetailScreen({
    required this.form,
    required this.response,
    super.key,
  });

  @override
  State<ResponseDetailScreen> createState() => _ResponseDetailScreenState();
}

class _ResponseDetailScreenState extends State<ResponseDetailScreen> {
  final Map<String, TextEditingController> _gradeControllers = {};
  final Map<String, double> _grades = {};

  bool _isSaving = false;

  bool get _hasGradable => widget.form.questions.any(_isManuallyGraded);

  int get _gradableCount => widget.form.questions.where(_isManuallyGraded).length;

  int get _gradedCount => widget.form.questions
      .where(_isManuallyGraded)
      .where((q) => _grades.containsKey(q.id))
      .length;

  double get _maxScore => widget.form.maxScore;

  bool _isManuallyGraded(QuestionModel q) {
    // Must be scorable (not a rating/survey-only type) AND require human review
    return q.isScorable &&
        (q.type == QuestionType.longText ||
            q.type == QuestionType.shortText ||
            q.type == QuestionType.codeInput ||
            q.type == QuestionType.mathFormula);
  }

  double _questionWeight(QuestionModel q) {
    final w = (q.hasScore || q.score > 0) ? q.score : 0.0;
    // Essay with 0 pts would make grading invisible — fallback to 10
    if (_isManuallyGraded(q) && w == 0) return 10.0;
    return w;
  }

  /// Auto-scored portion: sum of autoScores from API (stable across re-grades).
  /// Fallback to subtraction method if autoScores is empty (e.g., legacy data).
  double get _autoBase {
    if (widget.response.autoScores.isNotEmpty) {
      var sum = 0.0;
      for (final v in widget.response.autoScores.values) {
        sum += v;
      }
      return sum.clamp(0, _maxScore).toDouble();
    }
    // Fallback: derive from total minus previous essay weighted part
    var essayPart = 0.0;
    for (final q in widget.form.questions) {
      if (!_isManuallyGraded(q)) continue;
      final existing = widget.response.essayScores[q.id];
      if (existing == null) continue;
      // Ignore 0 placeholder that means "not yet graded" (see response_model)
      if (existing == 0) continue;
      essayPart += _questionWeight(q) * (existing / 100);
    }
    return (widget.response.score - essayPart).clamp(0, _maxScore).toDouble();
  }

  double get _total {
    // If no manual grades edited yet, show stored total (already includes previous grades)
    if (!_hasGradable) {
      return widget.response.score.clamp(0, _maxScore).toDouble();
    }
    // If user cleared all grades, total = auto only
    if (_grades.isEmpty) {
      // No essay grades set -> auto only (or 0 if no auto)
      return _autoBase;
    }

    var sum = _autoBase;
    for (final q in widget.form.questions) {
      if (!_isManuallyGraded(q)) continue;
      final v = _grades[q.id];
      if (v == null) continue;
      sum += _questionWeight(q) * (v / 100);
    }
    return sum.clamp(0, _maxScore).toDouble();
  }

  @override
  void initState() {
    super.initState();

    for (final q in widget.form.questions) {
      if (!_isManuallyGraded(q)) continue;

      final existing = widget.response.essayScores[q.id];
      // Ignore placeholder 0 (not yet graded)
      if (existing != null && existing != 0) {
        _grades[q.id] = existing;
      }

      final hasExisting = existing != null && existing != 0;
      _gradeControllers[q.id] = TextEditingController(
        // ignore: unnecessary_non_null_assertion
        text: hasExisting ? _formatGrade(existing!) : '',
      );
    }
  }

  String _formatGrade(double value) {
    if (value % 1 == 0) return value.round().toString();
    return value.toString();
  }

  @override
  void dispose() {
    for (final c in _gradeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }

  String _answerText(QuestionModel q, dynamic answer) {
    if (answer == null) return '-';

    String byText(String fallback) {
      final normalized = answer.toString().trim().toLowerCase();
      for (final opt in q.options) {
        if (opt.text.trim().toLowerCase() == normalized) {
          return opt.text;
        }
      }
      return fallback;
    }

    switch (q.type) {
      case QuestionType.multipleChoice:
      case QuestionType.imageChoice:
        for (final opt in q.options) {
          if (opt.id == answer) return opt.text;
        }
        return byText(answer.toString());

      case QuestionType.yesNo:
        for (final opt in q.options) {
          if (opt.id == answer) return opt.text;
        }
        return byText(answer == 'yes' ? 'Yes' : 'No');

      case QuestionType.rating:
        return '$answer out of ${q.ratingMax ?? 5}';

      default:
        return answer.toString().trim().isEmpty ? '-' : answer.toString();
    }
  }

  bool get _hasInvalidGrade {
    for (final c in _gradeControllers.entries) {
      final raw = c.value.text.trim();
      if (raw.isEmpty) continue;

      final parsed = double.tryParse(raw);
      if (parsed == null || parsed < 0 || parsed > 100) {
        return true;
      }
    }
    return false;
  }

  void _save() {
    if (_isSaving) return;

    if (_hasInvalidGrade) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Score must be a number between 0 and 100.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final essayScores = <String, double>{};
    for (final q in widget.form.questions) {
      if (!_isManuallyGraded(q)) continue;

      final v = _grades[q.id];
      if (v != null) {
        essayScores[q.id] = v;
      }
    }

    setState(() {
      _isSaving = true;
    });

    final updated = widget.response.copyWith(
      essayScores: essayScores,
      score: _total,
      maxScore: _maxScore,
    );

    final provider = Provider.of<ResponseProvider>(context, listen: false);

    provider.saveGrade(widget.response.id, _total).then((_) {
      if (!mounted) return;
      provider.rememberGrades(widget.response.id, essayScores);
      provider.updateResponse(updated);

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                  _maxScore > 0
                      ? 'Score saved: ${_total.round()}/${_maxScore.round()}'
                      : 'Score saved successfully',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }).catchError((Object error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal menyimpan skor.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Detail Respons'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // Header Deep Blue Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF133E76),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.form.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                _HeaderRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Respondent',
                  value: widget.response.respondentName,
                ),
                const SizedBox(height: 8),
                _HeaderRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: widget.response.respondentEmail,
                ),
                const SizedBox(height: 8),
                _HeaderRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Submitted',
                  value: _formatDateTime(widget.response.submittedAt),
                ),

              ],
            ),
          ),
          const SizedBox(height: 24),

          // Total Score Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B9E5E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _gradableCount > 0
                      ? '$_gradedCount / $_gradableCount'
                      : (_maxScore > 0
                          ? '${_total.toInt()} / ${_maxScore.round()}'
                          : '${_total.toInt()}'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B9E5E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section Title: Answers & Grading
          Text(
            'Answers & Grading',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),

          ...widget.form.questions.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final q = entry.value;
              final answer = widget.response.answers[q.id];

              return _AnswerCard(
                number: index + 1,
                question: q,
                answerText: _answerText(q, answer),
                isEssay: _isManuallyGraded(q),
                controller: _gradeControllers[q.id],
                existingGrade: widget.response.essayScores[q.id],
                currentGrade: _grades[q.id],
                onGradeChanged: (value) {
                  final parsed = double.tryParse(value);
                  setState(() {
                    if (parsed == null) {
                      _grades.remove(q.id);
                    } else {
                      final clamped = parsed.clamp(0, 100).toDouble();
                      _grades[q.id] = clamped;

                      if (parsed != clamped) {
                        final controller = _gradeControllers[q.id];
                        if (controller != null) {
                          controller.text = _formatGrade(clamped);
                          controller.selection = TextSelection.collapsed(
                            offset: controller.text.length,
                          );
                        }
                      }
                    }
                  });
                },
                isDark: isDark,
              );
            },
          ),

          if (!_hasGradable) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.primaryWith(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.primaryWith(0.20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: context.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This form has no questions that require manual grading. The total score is computed automatically.',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_hasGradable) ...[
            const SizedBox(height: 24),
            GradientButton(
              text: _isSaving ? 'Saving...' : 'Save Score',
              onPressed: _save,
              isLoading: _isSaving,
              fullWidth: true,
              icon: Icons.save_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final int number;
  final QuestionModel question;
  final String answerText;
  final bool isEssay;
  final TextEditingController? controller;
  final double? existingGrade;
  final double? currentGrade;
  final ValueChanged<String>? onGradeChanged;
  final bool isDark;

  const _AnswerCard({
    required this.number,
    required this.question,
    required this.answerText,
    required this.isEssay,
    required this.controller,
    this.existingGrade,
    this.currentGrade,
    this.onGradeChanged,
    required this.isDark,
  });

  bool _isInputOutOfRange(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final parsed = double.tryParse(text.trim());
    return parsed == null || parsed < 0 || parsed > 100;
  }

  @override
  Widget build(BuildContext context) {
    final primaryTextColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final activeGrade = currentGrade ?? existingGrade;
    final isGraded = activeGrade != null && activeGrade != 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEssay
              ? AppTheme.warning.withValues(alpha: 0.50)
              : (isDark ? AppTheme.darkBorder : AppTheme.border),
          width: isEssay ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: context.primaryWith(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: context.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichTextContentView(
                  content: question.content,
                  fallbackText: question.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                    height: 1.3,
                  ),
                ),
              ),
              if (isEssay)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'MANUAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
            ],
          ),
          if (question.type == QuestionType.mathFormula &&
              question.mathFormula != null) ...[
            const SizedBox(height: 12),
            MathFormulaWidget(
              formula: question.mathFormula!,
              fontSize: 14,
            ),
          ],
          if (question.type == QuestionType.codeInput &&
              question.codeSnippet != null) ...[
            const SizedBox(height: 12),
            CodeBlockWidget(code: question.codeSnippet!),
          ],
          const SizedBox(height: 12),
          Text(
            'Answer',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF162E25)
                  : const Color(0xFFEBF7F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF1B9E5E).withValues(alpha: 0.20),
              ),
            ),
            child: Text(
              answerText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
                height: 1.4,
              ),
            ),
          ),
          if (isEssay) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  isGraded
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isGraded ? const Color(0xFF1B9E5E) : AppTheme.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  isGraded
                      ? 'Graded: ${activeGrade % 1 == 0 ? activeGrade.round() : activeGrade}/100'
                      : 'Not graded yet',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color:
                        isGraded ? const Color(0xFF1B9E5E) : AppTheme.warning,
                  ),
                ),
                const Spacer(),
                Text(
                  'Weight: ${question.score.round()} pts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: onGradeChanged,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
              decoration: InputDecoration(
                labelText: 'Score (0 - 100)',
                errorText:
                    _isInputOutOfRange(controller?.text) && currentGrade == null
                        ? 'Must be between 0 and 100'
                        : null,
                prefixIcon: const Icon(
                  Icons.star_outline_rounded,
                  size: 20,
                  color: AppTheme.warning,
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkSurface
                    : AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.warning.withValues(alpha: 0.30),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.warning.withValues(alpha: 0.30),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.warning,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

