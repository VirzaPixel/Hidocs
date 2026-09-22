import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/models/response_model.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/widgets/exam/audio_player_widget.dart';
import 'package:hi_docs/widgets/exam/code_block_widget.dart';
import 'package:hi_docs/widgets/exam/math_formula_widget.dart';
import 'package:hi_docs/widgets/form/rich_text_view.dart';

class HistoryDetailScreen extends StatefulWidget {
  final FormModel form;
  final ResponseModel response;

  const HistoryDetailScreen({
    required this.form,
    required this.response,
    super.key,
  });

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late FormModel _form;
  late ResponseModel _response;

  bool _loadingQuestions = false;
  bool _loadingResponse = false;

  @override
  void initState() {
    super.initState();

    _form = widget.form;
    _response = widget.response;

    _initialize();
  }

  Future<void> _initialize() async {
    if (_form.questions.isEmpty) {
      await _loadFullForm();
    } else {
      await _ensureResponseLoaded();
    }
  }

  Future<void> _loadFullForm() async {
    if (_loadingQuestions) return;

    setState(() {
      _loadingQuestions = true;
    });

    final formProvider = Provider.of<FormProvider>(
      context,
      listen: false,
    );

    try {
      final detail = await formProvider.loadFormDetail(_form.id);

      if (!mounted) return;

      if (detail != null) {
        setState(() {
          _form = detail;
          _loadingQuestions = false;
        });
      } else {
        setState(() {
          _loadingQuestions = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingQuestions = false;
      });
    }

    await _ensureResponseLoaded();
  }

  Future<void> _ensureResponseLoaded() async {
    if (_response.answers.isNotEmpty) return;
    if (_loadingResponse) return;

    _loadingResponse = true;

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final responseProvider = Provider.of<ResponseProvider>(
      context,
      listen: false,
    );

    try {
      if (!mounted) return;

      final currentId = auth.currentUser?.id ?? '';
      final currentEmail = auth.currentUser?.email ?? '';

      final responses = responseProvider.getResponsesByRespondent(
        currentId,
      );

      ResponseModel? matched;

      for (final response in responses) {
        final sameId = currentId.isNotEmpty &&
            response.respondentId == currentId;

        final sameEmail = currentEmail.isNotEmpty &&
            response.respondentEmail.toLowerCase() ==
                currentEmail.toLowerCase();

        if (sameId || sameEmail) {
          matched = response;
          break;
        }
      }

      if (matched != null) {
        setState(() {
          _response = matched!;
        });
      }
    } catch (_) {
      // Keep the response passed from HistoryScreen.
    }

    _loadingResponse = false;
  }

  String _answerText(
    QuestionModel question,
    dynamic answer,
    AppLocalizations l10n,
  ) {
    if (answer == null) {
      return l10n.notAnsweredDash;
    }

    String findOptionText(String fallback) {
      final normalized = answer.toString().trim().toLowerCase();

      for (final option in question.options) {
        if (option.text.trim().toLowerCase() == normalized) {
          return option.text;
        }
      }

      return fallback;
    }

    switch (question.type) {
      case QuestionType.checkbox:
        Set<String> selectedIds;

        if (answer is Set) {
          selectedIds = answer.map((e) => e.toString()).toSet();
        } else if (answer is List) {
          selectedIds = answer.map((e) => e.toString()).toSet();
        } else {
          selectedIds = {answer.toString()};
        }

        final selectedOptions = question.options
            .where((option) => selectedIds.contains(option.id))
            .map((option) => option.text)
            .toList();

        if (selectedOptions.isEmpty) {
          return selectedIds.isEmpty
              ? l10n.notAnsweredDash
              : selectedIds.join(', ');
        }

        return selectedOptions.join(', ');

      case QuestionType.multipleChoice:
      case QuestionType.imageChoice:
        for (final option in question.options) {
          if (option.id == answer.toString()) {
            return option.text;
          }
        }

        return findOptionText(answer.toString());

      case QuestionType.yesNo:
        for (final option in question.options) {
          if (option.id == answer.toString()) {
            return option.text;
          }
        }

        return findOptionText(
          answer.toString().toLowerCase() == 'yes'
              ? l10n.yes
              : l10n.no,
        );

      case QuestionType.rating:
        return l10n.outOfStars(
          question.ratingMax ?? 5,
          answer,
        );

      case QuestionType.matching:
        try {
          Map<String, dynamic> map;

          if (answer is Map) {
            map = Map<String, dynamic>.from(answer);
          } else {
            final decoded = jsonDecode(answer.toString());

            if (decoded is Map) {
              map = Map<String, dynamic>.from(decoded);
            } else {
              return answer.toString();
            }
          }

          if (map.isEmpty) {
            return l10n.notAnsweredDash;
          }

          return map.entries.map((entry) {
            final pair = question.matchingPairs.where(
              (pair) => pair.id == entry.key,
            );

            final leftLabel =
                pair.isNotEmpty ? pair.first.left : entry.key;

            return '$leftLabel → ${entry.value}';
          }).join('\n');
        } catch (_) {
          return answer.toString();
        }

      default:
        final text = answer.toString().trim();

        return text.isEmpty ? l10n.notAnsweredDash : text;
    }
  }

  Map<String, dynamic>? _matchingAnswerMap(dynamic answer) {
    try {
      if (answer is Map) {
        return Map<String, dynamic>.from(answer);
      }

      final decoded = jsonDecode(answer.toString());

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  bool? _isCorrectAnswer(
    QuestionModel question,
    dynamic answer,
  ) {
    if (answer == null) {
      return false;
    }

    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.imageChoice:
      case QuestionType.yesNo:
        final selected = answer.toString().trim();

        for (final option in question.options) {
          if (option.id == selected ||
              option.text.trim().toLowerCase() ==
                  selected.toLowerCase()) {
            return option.isCorrect;
          }
        }

        return false;

      case QuestionType.checkbox:
        Set<String> selected;

        if (answer is Set) {
          selected = answer.map((e) => e.toString()).toSet();
        } else if (answer is List) {
          selected = answer.map((e) => e.toString()).toSet();
        } else {
          selected = {answer.toString()};
        }

        final correctIds = question.options
            .where((option) => option.isCorrect)
            .map((option) => option.id)
            .toSet();

        if (correctIds.isEmpty) {
          return null;
        }

        return selected.length == correctIds.length &&
            selected.every(correctIds.contains);

      case QuestionType.matching:
        final map = _matchingAnswerMap(answer);

        if (map == null || question.matchingPairs.isEmpty) {
          return false;
        }

        var correct = 0;

        for (final pair in question.matchingPairs) {
          final userAnswer = map[pair.id]?.toString().trim();

          if (userAnswer != null &&
              userAnswer.toLowerCase() ==
                  pair.right.trim().toLowerCase()) {
            correct++;
          }
        }

        return correct == question.matchingPairs.length;

      default:
        return null;
    }
  }

  String _scoreLabel(
    double percentage,
  ) {
    if (percentage >= 90) return 'Sangat Baik';
    if (percentage >= 75) return 'Bagus';
    if (percentage >= 60) return 'Fair';
    if (percentage >= 40) return 'Poor';
    return 'Perlu Perbaikan';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final primaryTextColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final manualTypes = {
      QuestionType.longText,
      QuestionType.shortText,
      QuestionType.codeInput,
      QuestionType.mathFormula,
    };

    double maxScore = _form.maxScore;

    if (maxScore <= 0) {
      var weights = 0.0;

      for (final question in _form.questions) {
        if (!question.isScorable) {
          continue;
        }

        if (question.hasScore || question.score > 0) {
          weights += question.score;
        }
      }

      maxScore = weights > 0
          ? weights
          : _form.questions.length.toDouble();
    }

    double autoScore;

    if (_response.autoScores.isNotEmpty) {
      autoScore = _response.autoScores.values.fold<double>(
        0,
        (sum, value) => sum + value,
      );
    } else {
      autoScore = 0;

      for (final question in _form.questions) {
        if (manualTypes.contains(question.type)) {
          continue;
        }

        final answer = _response.answers[question.id];

        final correct = _isCorrectAnswer(
          question,
          answer,
        );

        if (correct == true) {
          autoScore +=
              question.hasScore && question.score > 0
                  ? question.score
                  : 1.0;
        }
      }
    }

    final essayScore = _response.essayScores.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    var displayScore = autoScore + essayScore;

    if (displayScore < 0) {
      displayScore = 0;
    }

    if (maxScore > 0 && displayScore > maxScore) {
      displayScore = maxScore;
    }

    final percentage = maxScore > 0
        ? (displayScore / maxScore * 100).clamp(0.0, 100.0)
        : 0.0;

    final hasScore =
        displayScore > 0 || _response.answers.isNotEmpty;

    final hasUngradedEssay = _form.questions.any((question) {
      if (!manualTypes.contains(question.type)) {
        return false;
      }

      final answer = _response.answers[question.id];

      final hasAnswer =
          answer != null && answer.toString().trim().isNotEmpty;

      final grade = _response.essayScores[question.id] ?? 0;

      return hasAnswer && grade == 0;
    });

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(
          l10n.historyAnswer,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: (_loadingQuestions && _form.questions.isEmpty)
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                40,
              ),
              children: [
                _SummaryCard(
                  form: _form,
                  response: _response,
                  hasScore: hasScore,
                  hasUngradedEssay: hasUngradedEssay,
                  displayScore: displayScore,
                  maxScore: maxScore,
                  percentage: percentage,
                  scoreLabel: _scoreLabel(
                    percentage,
                  ),
                  isDark: isDark,
                  l10n: l10n,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: context.primary.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.fact_check_outlined,
                        size: 20,
                        color: context.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.yourAnswers,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                    if (_form.questions.isNotEmpty)
                      Text(
                        '${_form.questions.length} soal',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._form.questions.asMap().entries.map((entry) {
                  final question = entry.value;
                  final answer = _response.answers[question.id];
                  final essayGrade =
                      _response.essayScores[question.id];

                  final isEssay = manualTypes.contains(
                    question.type,
                  );

                  final isCorrect = isEssay
                      ? null
                      : _isCorrectAnswer(
                          question,
                          answer,
                        );

                  final questionMaxScore =
                      question.hasScore && question.score > 0
                          ? question.score
                          : (question.isScorable ? 1.0 : 0.0);

                  final double earnedScore;

                  if (isEssay) {
                    earnedScore = essayGrade ?? 0.0;
                  } else if (_response.autoScores
                      .containsKey(question.id)) {
                    earnedScore =
                        _response.autoScores[question.id] ?? 0.0;
                  } else if (isCorrect == true) {
                    earnedScore = questionMaxScore;
                  } else {
                    earnedScore = 0.0;
                  }

                  return _AnswerCard(
                    number: entry.key + 1,
                    question: question,
                    answerText: _answerText(
                      question,
                      answer,
                      l10n,
                    ),
                    grade: essayGrade != null &&
                            essayGrade != 0
                        ? essayGrade
                        : null,
                    qMaxScore: questionMaxScore,
                    isCorrect: isCorrect,
                    earnedScore: earnedScore,
                    isDark: isDark,
                  );
                }),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final FormModel form;
  final ResponseModel response;
  final bool hasScore;
  final bool hasUngradedEssay;
  final double displayScore;
  final double maxScore;
  final double percentage;
  final String scoreLabel;
  final bool isDark;
  final AppLocalizations l10n;

  const _SummaryCard({
    required this.form,
    required this.response,
    required this.hasScore,
    required this.hasUngradedEssay,
    required this.displayScore,
    required this.maxScore,
    required this.percentage,
    required this.scoreLabel,
    required this.isDark,
    required this.l10n,
  });

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');

    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primary,
            context.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.primaryWith(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            form.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          _HeaderRow(
            icon: Icons.person_outline_rounded,
            label: l10n.participant,
            value: response.respondentName,
          ),
          const SizedBox(height: 9),
          _HeaderRow(
            icon: Icons.email_outlined,
            label: l10n.email,
            value: response.respondentEmail,
          ),
          const SizedBox(height: 9),
          _HeaderRow(
            icon: Icons.calendar_today_outlined,
            label: l10n.historySubmitted,
            value: _formatDateTime(response.submittedAt),
          ),
          const SizedBox(height: 9),
          _HeaderRow(
            icon: Icons.timer_outlined,
            label: l10n.duration,
            value: response.durationText,
          ),
          if (hasScore) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          maxScore > 0
                              ? l10n.nilaiMax(
                                  displayScore.round(),
                                  maxScore.round(),
                                )
                              : l10n.nilaiOnly(
                                  displayScore.round(),
                                ),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (maxScore > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            '${percentage.round()}% — $scoreLabel',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white
                                  .withValues(alpha: 0.82),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (hasUngradedEssay)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 6),
                            child: Text(
                              'Ada essay yang belum dinilai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white
                                    .withValues(alpha: 0.72),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (maxScore > 0)
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: percentage / 100,
                            backgroundColor:
                                Colors.white.withValues(
                              alpha: 0.18,
                            ),
                            valueColor:
                                const AlwaysStoppedAnimation<
                                    Color>(
                              Colors.white,
                            ),
                            strokeWidth: 5,
                          ),
                          Text(
                            '${percentage.round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ] else if (hasUngradedEssay) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_empty_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menunggu penilaian',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
        Icon(
          icon,
          size: 16,
          color: Colors.white70,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 12,
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
  final double? grade;
  final double? qMaxScore;
  final bool? isCorrect;
  final double? earnedScore;
  final bool isDark;

  const _AnswerCard({
    required this.number,
    required this.question,
    required this.answerText,
    this.grade,
    this.qMaxScore,
    this.isCorrect,
    this.earnedScore,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    final secondaryText =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final cardColor =
        isDark ? AppTheme.darkCard : AppTheme.surfaceCard;

    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.border;

    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: context.primaryWith(0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.primary,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: RichTextContentView(
                  content: null,
                  fallbackText: question.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                    height: 1.35,
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
            CodeBlockWidget(
              code: question.codeSnippet!,
            ),
          ],
          if (question.audioUrl != null) ...[
            const SizedBox(height: 12),
            AudioPlayerWidget(
              audioSource: question.audioUrl!,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            l10n.answerLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              answerText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primaryText,
                height: 1.45,
              ),
            ),
          ),
          if (grade != null) ...[
            const SizedBox(height: 10),
            _ResultBadge(
              icon: Icons.check_circle_rounded,
              color: AppTheme.success,
              text: qMaxScore != null && qMaxScore! > 0
                  ? l10n.nilaiMax(
                      grade! % 1 == 0
                          ? grade!.toInt()
                          : grade!,
                      qMaxScore!.toInt(),
                    )
                  : 'Nilai: ${grade! % 1 == 0 ? grade!.toInt() : grade!}/100',
            ),
          ] else if (isCorrect != null) ...[
            const SizedBox(height: 10),
            _ResultBadge(
              icon: isCorrect == true
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: isCorrect == true
                  ? AppTheme.success
                  : AppTheme.error,
              text: isCorrect == true
                  ? 'Benar (+${_formatScore(
                      earnedScore ?? qMaxScore ?? 1,
                    )} poin)'
                  : 'Salah (0 poin)',
            ),
          ] else if (qMaxScore != null && qMaxScore! > 0) ...[
            const SizedBox(height: 10),
            _ResultBadge(
              icon: Icons.stars_rounded,
              color: context.primary,
              text: 'Poin soal: ${qMaxScore!.toInt()}',
            ),
          ],
        ],
      ),
    );
  }

  String _formatScore(double value) {
    return value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}

class _ResultBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ResultBadge({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}