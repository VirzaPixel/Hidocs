import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/l10n/l10n_extension.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/question_model.dart';
import 'package:hi_docs/utils/constants.dart';

class SettingsTab extends StatelessWidget {
  final FormType formType;
  final bool shuffleQuestion;
  final bool shuffleOption;
  final bool oneTime;
  final bool active;
  final ResultVisibility visibility;
  final int timerMinutes;
  final String examToken;
  final bool isTokenProtected;

  /// Daftar soal live dari layar create/edit form — dipakai kartu "Penilaian
  /// Poin" untuk menghitung total poin form dan menerapkan poin massal.
  final List<QuestionModel> questions;
  final ValueChanged<bool> onSetScoringForAll;
  final ValueChanged<int> onApplyPointsToAll;

  final ValueChanged<FormType>? onFormTypeChanged;
  final ValueChanged<bool> onShuffleQuestion;
  final ValueChanged<bool> onShuffleOption;
  final ValueChanged<bool> onOneTime;
  final ValueChanged<bool> onActive;
  final ValueChanged<ResultVisibility> onVisibility;
  final ValueChanged<String>? onExamTokenChanged;
  final ValueChanged<bool>? onIsTokenProtectedChanged;

  const SettingsTab({
    super.key,
    this.formType = FormType.survey,
    this.onFormTypeChanged,
    required this.shuffleQuestion,
    required this.shuffleOption,
    required this.oneTime,
    required this.active,
    required this.visibility,
    required this.timerMinutes,
    this.examToken = '',
    this.isTokenProtected = false,
    this.questions = const [],
    required this.onSetScoringForAll,
    required this.onApplyPointsToAll,
    required this.onShuffleQuestion,
    required this.onShuffleOption,
    required this.onOneTime,
    required this.onActive,
    required this.onVisibility,
    this.onExamTokenChanged,
    this.onIsTokenProtectedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        _SectionLabel(l10n.formTypeSecurityMode, Icons.security_rounded, isDark),
        const SizedBox(height: 12),

        _FormTypeRadioCard(
          icon: Icons.assignment_outlined,
          iconColor: context.primary,
          title: l10n.surveyModeTitle,
          subtitle: l10n.surveyModeSub,
          value: FormType.survey,
          groupValue: formType,
          onChanged: onFormTypeChanged ?? (_) {},
          isDark: isDark,
        ),
        _FormTypeRadioCard(
          icon: Icons.shield_rounded,
          iconColor: AppTheme.error,
          title: l10n.examModeTitle,
          subtitle: l10n.examModeSub,
          value: FormType.exam,
          groupValue: formType,
          onChanged: onFormTypeChanged ?? (_) {},
          isDark: isDark,
        ),
        if (formType == FormType.exam) ...[
          const SizedBox(height: 14),
          _ExamTokenCard(
            examToken: examToken,
            isTokenProtected: isTokenProtected,
            onExamTokenChanged: onExamTokenChanged,
            onIsTokenProtectedChanged: onIsTokenProtectedChanged,
            isDark: isDark,
          ),
        ],
        const SizedBox(height: 24),

        _SectionLabel(l10n.formBehaviorLabel, Icons.tune_rounded, isDark),
        const SizedBox(height: 16),

        _SwitchCard(
          key: const ValueKey('shuffle_question'),
          icon: Icons.shuffle_rounded,
          iconColor: context.primary,
          iconBg: context.primaryFaint,
          title: l10n.shuffleQuestionsTitle,
          subtitle: l10n.shuffleQuestionsSub,
          value: shuffleQuestion,
          onChanged: onShuffleQuestion,
          isDark: isDark,
        ),
        _SwitchCard(
          key: const ValueKey('shuffle_option'),
          icon: Icons.swap_vert_rounded,
          iconColor: context.primary,
          iconBg: context.primaryFaint,
          title: l10n.shuffleOptionsTitle,
          subtitle: l10n.shuffleOptionsSub,
          value: shuffleOption,
          onChanged: onShuffleOption,
          isDark: isDark,
        ),
        _SwitchCard(
          key: const ValueKey('one_time'),
          icon: Icons.lock_outline_rounded,
          iconColor: AppTheme.error,
          iconBg: AppTheme.error.withValues(alpha: 0.10),
          title: l10n.oneTimeSubmitTitle,
          subtitle: l10n.oneTimeSubmitSub,
          value: oneTime,
          onChanged: onOneTime,
          isDark: isDark,
        ),
        _SwitchCard(
          key: const ValueKey('active'),
          icon: Icons.play_circle_outline_rounded,
          iconColor: AppTheme.success,
          iconBg: AppTheme.success.withValues(alpha: 0.10),
          title: l10n.activateImmediatelyTitle,
          subtitle: l10n.activateImmediatelySub,
          value: active,
          onChanged: onActive,
          isDark: isDark,
        ),
        const SizedBox(height: 28),

        _SectionLabel(l10n.resultVisibilityLabel, Icons.bar_chart_rounded, isDark),
        const SizedBox(height: 8),
        Text(
          l10n.resultVisibilityDesc,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 16),

        _RadioCard(
          icon: Icons.visibility_off_outlined,
          iconColor: AppTheme.textMuted,
          title: l10n.hideResultsTitle,
          subtitle: l10n.hideResultsSub,
          value: ResultVisibility.hidden,
          groupValue: visibility,
          onChanged: onVisibility,
          isDark: isDark,
        ),
        _RadioCard(
          icon: Icons.visibility_outlined,
          iconColor: context.primary,
          title: l10n.showResultOnlyTitle,
          subtitle: l10n.showResultOnlySub,
          value: ResultVisibility.resultOnly,
          groupValue: visibility,
          onChanged: onVisibility,
          isDark: isDark,
        ),
        _RadioCard(
          icon: Icons.leaderboard_outlined,
          iconColor: AppTheme.success,
          title: l10n.showResultAndScoreTitle,
          subtitle: l10n.showResultAndScoreSub,
          value: ResultVisibility.resultAndScore,
          groupValue: visibility,
          onChanged: onVisibility,
          isDark: isDark,
        ),
        const SizedBox(height: 28),

        // ----------------------------------------------------------------
        // PENILAIAN POIN — logika sederhana ala Google Forms:
        //   * setiap soal punya poinnya sendiri (0 = tidak dinilai)
        //   * total poin form = jumlah seluruh poin soal yang dinilai
        //   * guru cukup memakai aksi cepat tanpa membuka tiap soal
        // ----------------------------------------------------------------
        _SectionLabel(
          l10n.isIndonesian ? 'Penilaian Poin' : 'Points & Scoring',
          Icons.grade_rounded,
          isDark,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.isIndonesian
              ? 'Setiap soal punya poin sendiri. Total poin form adalah jumlah seluruh poin soal yang dinilai.'
              : 'Each question has its own points. The form total is the sum of all scored questions.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        _ScoringCard(
          questions: questions,
          onSetScoringForAll: onSetScoringForAll,
          onApplyPointsToAll: onApplyPointsToAll,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isDark;

  const _SectionLabel(this.text, this.icon, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark
                ? context.primaryWith(0.15)
                : context.primaryFaint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isDark ? const Color(0xFF4A90D9) : context.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SwitchCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SwitchCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  State<_SwitchCard> createState() => _SwitchCardState();
}

class _SwitchCardState extends State<_SwitchCard> {
  late bool _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _SwitchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  void _handleTap() {
    setState(() {
      _currentValue = !_currentValue;
    });
    widget.onChanged(_currentValue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark ? AppTheme.darkBorder : AppTheme.border,
            ),
            boxShadow: widget.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.icon, size: 20, color: widget.iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.fastOutSlowIn,
                width: 44,
                height: 26,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _currentValue
                      ? context.primary
                      : (widget.isDark ? Colors.grey[700] : Colors.grey[300]),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.fastOutSlowIn,
                  alignment: _currentValue
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ResultVisibility value;
  final ResultVisibility groupValue;
  final ValueChanged<ResultVisibility> onChanged;
  final bool isDark;

  const _RadioCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.fastOutSlowIn,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? context.primary
                  : (isDark ? AppTheme.darkBorder : AppTheme.border),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.fastOutSlowIn,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? context.primaryWith(0.10)
                      : (isDark
                          ? AppTheme.darkSurface
                          : AppTheme.surfaceLight),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? context.primary : iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.fastOutSlowIn,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? context.primary
                        : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                    width: selected ? 6 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu ringkas penilaian poin ala Google Forms: total poin form + aksi cepat
/// untuk mengaktifkan/menonaktifkan poin seluruh soal sekaligus.
class _ScoringCard extends StatelessWidget {
  final List<QuestionModel> questions;
  final ValueChanged<bool> onSetScoringForAll;
  final ValueChanged<int> onApplyPointsToAll;
  final bool isDark;

  const _ScoringCard({
    required this.questions,
    required this.onSetScoringForAll,
    required this.onApplyPointsToAll,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final scorable = questions.where((q) => q.isScorable).length;
    final scored = questions.where((q) => q.isScorable && q.hasScore).length;
    final total = questions.fold<double>(
      0,
      (sum, q) => sum + (q.isScorable && q.hasScore ? q.score : 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      child: scorable == 0
          ? Text(
              l10n.isIndonesian
                  ? 'Belum ada soal. Tambahkan soal terlebih dahulu di tab Soal.'
                  : 'No questions yet. Add questions in the Questions tab first.',
              style: TextStyle(fontSize: 12.5, color: muted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.primaryFaint,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(Icons.grade_rounded,
                          size: 20, color: context.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.isIndonesian
                                ? 'Total Poin Form'
                                : 'Form Total Points',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.isIndonesian
                                ? '$scored dari $scorable soal dinilai'
                                : '$scored of $scorable questions scored',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${total.round()}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ScoringAction(
                        label: l10n.isIndonesian
                            ? 'Nilai semua soal'
                            : 'Score all',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppTheme.success,
                        enabled: scored != scorable,
                        isDark: isDark,
                        onTap: () => onSetScoringForAll(true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ScoringAction(
                        label: l10n.isIndonesian ? 'Hapus nilai' : 'Clear',
                        icon: Icons.remove_circle_outline_rounded,
                        color: AppTheme.error,
                        enabled: scored != 0,
                        isDark: isDark,
                        onTap: () => onSetScoringForAll(false),
                      ),
                    ),
                  ],
                ),
                if (scored > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.isIndonesian
                              ? 'Poin tiap soal dinilai:'
                              : 'Points per scored question:',
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                      ),
                      _PointsChips(onApplyPointsToAll: onApplyPointsToAll),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

/// Tombol poin cepat (1 / 5 / 10) — mengingatkan cara kerja Google Forms yang
/// tidak ribet: satu angka dipakai untuk seluruh soal yang dinilai.
class _PointsChips extends StatelessWidget {
  final ValueChanged<int> onApplyPointsToAll;
  const _PointsChips({required this.onApplyPointsToAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in const [1, 5, 10]) ...[
          const SizedBox(width: 6),
          ActionChip(
            label: Text('$p'),
            onPressed: () => onApplyPointsToAll(p),
            visualDensity: VisualDensity.compact,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.primary,
            ),
            side: BorderSide(color: context.primary.withValues(alpha: 0.45)),
            backgroundColor: context.primary.withValues(alpha: 0.06),
          ),
        ],
      ],
    );
  }
}

class _ScoringAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _ScoringAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled;
    final fg = disabled
        ? (isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)
        : color;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: disabled
              ? (isDark ? AppTheme.darkSurface : AppTheme.surfaceLight)
              : color.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disabled
                ? (isDark ? AppTheme.darkBorder : AppTheme.border)
                : color.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamTokenCard extends StatelessWidget {
  final String examToken;
  final bool isTokenProtected;
  final ValueChanged<String>? onExamTokenChanged;
  final ValueChanged<bool>? onIsTokenProtectedChanged;
  final bool isDark;

  const _ExamTokenCard({
    required this.examToken,
    required this.isTokenProtected,
    this.onExamTokenChanged,
    this.onIsTokenProtectedChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.vpn_key_rounded, size: 18, color: AppTheme.error),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).examTokenTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).examTokenDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    examToken.isEmpty ? '—' : examToken,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                      color: examToken.isEmpty
                          ? (isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)
                          : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: AppLocalizations.of(context).copy,
                  onPressed: examToken.isEmpty
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: examToken));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context).examTokenCopied),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).examTokenRegenerate,
                  onPressed: onExamTokenChanged == null
                      ? null
                      : () {
                          final fresh = generateRandomLink(6).toUpperCase();
                          onExamTokenChanged!(fresh);
                        },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).examTokenProtectedTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: isTokenProtected,
                onChanged: onIsTokenProtectedChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: context.primary,
                inactiveThumbColor: Colors.white,
              ),
            ],
          ),
          Text(
            AppLocalizations.of(context).examTokenProtectedSub,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormTypeRadioCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final FormType value;
  final FormType groupValue;
  final ValueChanged<FormType> onChanged;
  final bool isDark;

  const _FormTypeRadioCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.fastOutSlowIn,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? context.primary
                  : (isDark ? AppTheme.darkBorder : AppTheme.border),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.fastOutSlowIn,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? context.primaryWith(0.10)
                      : (isDark
                          ? AppTheme.darkSurface
                          : AppTheme.surfaceLight),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? context.primary : iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.fastOutSlowIn,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? context.primary
                        : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                    width: selected ? 6 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}