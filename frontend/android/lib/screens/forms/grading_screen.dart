import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/models/response_model.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/screens/forms/response_detail_screen.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class GradingScreen extends StatefulWidget {
  final FormModel form;

  const GradingScreen({
    required this.form,
    super.key,
  });

  @override
  State<GradingScreen> createState() => _GradingScreenState();
}

class _GradingScreenState extends State<GradingScreen> {
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

  List<QuestionModel> get _manualQuestions =>
      widget.form.questions.where(_isManuallyGraded).toList();

  int _gradedCount(ResponseModel r) {
    return _manualQuestions
        .where((q) => r.essayScores[q.id] != null && r.essayScores[q.id] != 0)
        .length;
  }

  bool _isFullyGraded(ResponseModel r) {
    return _manualQuestions.isNotEmpty &&
        _gradedCount(r) >= _manualQuestions.length;
  }

  Future<void> _openResponse(ResponseModel response) async {
    await Navigator.push(
      context,
      CustomPageRoute(page: ResponseDetailScreen(
          form: widget.form,
          response: response,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
      await _loadResponses();
    }
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

    final pending = responses.where((r) => !_isFullyGraded(r)).length;
    final graded = responses.length - pending;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Grading'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
            ),
            onPressed: () => _showHelpDialog(isDark),
          ),
        ],
      ),
      body: _manualQuestions.isEmpty
          ? const _EmptyState(
              icon: Icons.grading_rounded,
              title: 'Nothing to grade',
              subtitle:
                  'This form has no typed questions that require manual grading.',
            )
          : responses.isEmpty
              ? const _EmptyState(
                  icon: Icons.how_to_reg_rounded,
                  title: 'No responses yet',
                  subtitle:
                      'Responses will appear here once students submit the form.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _SummaryBanner(
                      total: responses.length,
                      graded: graded,
                      pending: pending,
                      essayCount: _manualQuestions.length,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Responses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${responses.length} total',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...responses.map(
                      (r) => _GradingCard(
                        response: r,
                        essayTotal: _manualQuestions.length,
                        gradedCount: _gradedCount(r),
                        isGraded: _isFullyGraded(r),
                        hasScore: _isFullyGraded(r) || r.score > 0,
                        percentage: r.percentage,
                        maxScore: widget.form.maxScore,
                        dateText: _formatDate(r.submittedAt),
                        isDark: isDark,
                        onTap: () => _openResponse(r),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showHelpDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Manual Grading'),
        content: Text(
          'Give manual scores to short answer, essay, code, or math answers that were typed by students. Tap a response to open the grading page.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final int total;
  final int graded;
  final int pending;
  final int essayCount;
  final bool isDark;

  const _SummaryBanner({
    required this.total,
    required this.graded,
    required this.pending,
    required this.essayCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : graded / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 22,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Grading',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$essayCount manual questions',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B9E5E).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$graded/$total graded',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B9E5E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  isDark ? AppTheme.darkBorder : const Color(0xFFF0F4FA),
              valueColor: const AlwaysStoppedAnimation(AppTheme.warning),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pending == 0
                ? 'All responses have been graded. Great job!'
                : '$pending response${pending == 1 ? '' : 's'} still need${pending == 1 ? 's' : ''} grading.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: pending == 0 ? AppTheme.success : AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradingCard extends StatelessWidget {
  final ResponseModel response;
  final int essayTotal;
  final int gradedCount;
  final bool isGraded;
  final bool hasScore;
  final double percentage;
  final double maxScore;
  final String dateText;
  final bool isDark;
  final VoidCallback onTap;

  const _GradingCard({
    required this.response,
    required this.essayTotal,
    required this.gradedCount,
    required this.isGraded,
    required this.hasScore,
    required this.percentage,
    required this.maxScore,
    required this.dateText,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTextColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted;
    final name = response.respondentName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGraded
              ? (isDark ? AppTheme.darkBorder : AppTheme.border)
              : AppTheme.warning.withValues(alpha: 0.50),
          width: isGraded ? 1.0 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isGraded
                        ? const Color(0xFF1B9E5E).withValues(alpha: 0.10)
                        : AppTheme.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isGraded
                            ? const Color(0xFF1B9E5E)
                            : AppTheme.warning,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dateText,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _StatusRow(
                        isGraded: isGraded,
                        gradedCount: gradedCount,
                        essayTotal: essayTotal,
                        scoreText: response.score > 0
                            ? (maxScore > 0
                                ? 'score ${response.score.round()}/${maxScore.round()}'
                                : 'score ${response.score.round()}')
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (isGraded)
                  _ScoreBadge(percentage: percentage)
                else
                  _PendingBadge(),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool isGraded;
  final int gradedCount;
  final int essayTotal;
  final String? scoreText;

  const _StatusRow({
    required this.isGraded,
    required this.gradedCount,
    required this.essayTotal,
    this.scoreText,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGraded ? const Color(0xFF1B9E5E) : AppTheme.warning;
    var text = isGraded ? 'Graded' : '$gradedCount/$essayTotal manual graded';

    if (scoreText != null) {
      text = '$text • $scoreText';
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double percentage;

  const _ScoreBadge({
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: context.primaryWith(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${percentage.round()}%',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: context.primary,
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.primaryWith(0.07),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 36,
                color: context.primaryWith(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

