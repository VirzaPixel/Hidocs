import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/models/response_model.dart';
import 'package:hi_docs/providers/response_provider.dart';

/// Quick / Bulk grading mode: grades one essay question at a time
/// across ALL responses, allowing rapid score entry without
/// opening each response individually.
class BulkGradingScreen extends StatefulWidget {
  final FormModel form;
  const BulkGradingScreen({required this.form, super.key});

  @override
  State<BulkGradingScreen> createState() => _BulkGradingScreenState();
}

class _BulkGradingScreenState extends State<BulkGradingScreen> {
  late List<QuestionModel> _essayQuestions;
  int _currentQuestionIndex = 0;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _essayQuestions = widget.form.questions
        .where((q) =>
            q.isScorable &&
            (q.type == QuestionType.longText ||
                q.type == QuestionType.shortText ||
                q.type == QuestionType.codeInput ||
                q.type == QuestionType.mathFormula))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  QuestionModel get _currentQuestion => _essayQuestions[_currentQuestionIndex];

  double _questionWeight(QuestionModel q) {
    final w = (q.hasScore || q.score > 0) ? q.score : 0.0;
    return w == 0 ? 10.0 : w;
  }

  String _answerText(QuestionModel q, dynamic answer) {
    if (answer == null) return '-';
    return answer.toString().trim().isEmpty ? '-' : answer.toString();
  }

  void _onGradeChanged(String responseId, String value) {
    final parsed = double.tryParse(value);
    final provider =
        Provider.of<ResponseProvider>(context, listen: false);
    final responses = provider.getResponsesByForm(widget.form.id);
    final idx = responses.indexWhere((r) => r.id == responseId);
    if (idx < 0) return;

    final r = responses[idx];
    final updatedScores = Map<String, double>.from(r.essayScores);
    if (parsed != null && parsed >= 0) {
      updatedScores[_currentQuestion.id] = parsed;
    } else if (value.trim().isEmpty) {
      updatedScores.remove(_currentQuestion.id);
    }

    // Recalculate total score
    var autoBase = 0.0;
    if (r.autoScores.isNotEmpty) {
      autoBase = r.autoScores.values.fold(0.0, (a, b) => a + b);
    } else {
      autoBase = r.score;
      for (final q in widget.form.questions) {
        final existing = r.essayScores[q.id];
        if (existing == null || existing == 0) continue;
        autoBase -= _questionWeight(q) * (existing / 100);
      }
      autoBase = autoBase.clamp(0.0, widget.form.maxScore);
    }

    var total = autoBase;
    for (final q in widget.form.questions) {
      if (!q.isScorable) continue;
      if (q.type != QuestionType.longText &&
          q.type != QuestionType.shortText &&
          q.type != QuestionType.codeInput &&
          q.type != QuestionType.mathFormula) {
        continue;
      }
      final v = updatedScores[q.id];
      if (v == null || v == 0) continue;
      total += _questionWeight(q) * (v / 100);
    }
    total = total.clamp(0.0, widget.form.maxScore);

    final updated = r.copyWith(
      essayScores: updatedScores,
      score: total,
    );
    provider.updateResponse(updated);
    provider.saveGrade(r.id, total);
    provider.rememberGrades(r.id, updatedScores);
  }

  TextEditingController _getController(ResponseModel r) {
    final key = '${r.id}_${_currentQuestion.id}';
    if (_controllers.containsKey(key)) return _controllers[key]!;
    final existing = r.essayScores[_currentQuestion.id];
    final hasExisting = existing != null && existing != 0;
    final ctrl = TextEditingController(
      text: hasExisting ? _formatGrade(existing) : '',
    );
    _controllers[key] = ctrl;
    return ctrl;
  }

  String _formatGrade(double value) {
    if (value % 1 == 0) return value.round().toString();
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responses =
        Provider.of<ResponseProvider>(context)
            .getResponsesByForm(widget.form.id)
            .toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    if (_essayQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bulk Grading')),
        body: const Center(
          child: Text('No essay questions to grade.'),
        ),
      );
    }

    final q = _currentQuestion;
    final weight = _questionWeight(q);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(
          'Bulk Grading — Q${_currentQuestionIndex + 1}/${_essayQuestions.length}',
        ),
      ),
      body: Column(
        children: [
          // Question selector chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _essayQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isSelected = i == _currentQuestionIndex;
                  return ChoiceChip(
                    label: Text(
                      'Q${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: context.primary,
                    backgroundColor:
                        isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
                    onSelected: (_) => setState(() {
                      _currentQuestionIndex = i;
                    }),
                  );
                },
              ),
            ),
          ),

          // Current question info card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_iconForType(q.type), size: 16, color: context.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          q.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Weight: ${weight.round()} pts  •  Enter score 0–100',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Response list with inline score inputs
          Expanded(
            child: responses.isEmpty
                ? const Center(child: Text('No responses yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: responses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = responses[i];
                      final answer = r.answers[q.id];
                      final ctrl = _getController(r);
                      final graded = r.essayScores[q.id] != null &&
                          r.essayScores[q.id] != 0;
                      return _BulkGradingRow(
                        response: r,
                        answerText: _answerText(q, answer),
                        controller: ctrl,
                        isGraded: graded,
                        isDark: isDark,
                        onChanged: (v) => _onGradeChanged(r.id, v),
                      );
                    },
                  ),
          ),

          // Navigation buttons
          if (_essayQuestions.length > 1)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentQuestionIndex > 0
                          ? () => setState(() => _currentQuestionIndex--)
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        side: BorderSide(
                          color: isDark ? AppTheme.darkBorder : AppTheme.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _currentQuestionIndex < _essayQuestions.length - 1
                              ? () => setState(() => _currentQuestionIndex++)
                              : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForType(QuestionType t) {
    switch (t) {
      case QuestionType.shortText:
        return Icons.short_text_rounded;
      case QuestionType.longText:
        return Icons.subject_rounded;
      case QuestionType.codeInput:
        return Icons.code_rounded;
      case QuestionType.mathFormula:
        return Icons.functions_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }
}

class _BulkGradingRow extends StatelessWidget {
  final ResponseModel response;
  final String answerText;
  final TextEditingController controller;
  final bool isGraded;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _BulkGradingRow({
    required this.response,
    required this.answerText,
    required this.controller,
    required this.isGraded,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTxt = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final name = response.respondentName;
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGraded
              ? (isDark ? AppTheme.darkBorder : AppTheme.border)
              : AppTheme.warning.withValues(alpha: 0.50),
          width: isGraded ? 1.0 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (isGraded ? AppTheme.success : AppTheme.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isGraded ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryTxt,
                      ),
                    ),
                    Text(
                      response.respondentEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                height: 38,
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,3}(\.\d{0,2})?$')),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          if (answerText.isNotEmpty && answerText != '-') ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                answerText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
