import 'package:flutter/material.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/screens/exam/exam_lockdown_gate_screen.dart';
import 'package:hi_docs/screens/exam/exam_token_screen.dart';
import 'package:hi_docs/screens/forms/fill_form_screen.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class UserFormDetailScreen extends StatelessWidget {
  final FormModel form;

  const UserFormDetailScreen({
    required this.form,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final isExam = form.hasTimer;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.formDetail),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: (isExam ? AppTheme.warning : context.primary)
                        .withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    isExam
                        ? Icons.quiz_rounded
                        : Icons.article_rounded,
                    size: 40,
                    color: isExam ? AppTheme.warning : context.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                form.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isExam
                    ? l10n.fillAsExam
                    : l10n.formInfoSub,
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: secondaryTextColor),
              ),
              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Form',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor),
                    ),
                    const SizedBox(height: 18),
                    _InfoRow(
                      icon: Icons.edit_document,
                      title: 'Judul Form',
                      value: form.title,
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.help_outline_rounded,
                      title: 'Jumlah Soal',
                      value: form.questions.isEmpty
                          ? l10n.loading
                          : l10n.nQuestions(form.questions.length),
                    ),
                    if (isExam) ...[
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.timer_outlined,
                        title: l10n.infoExamTime,
                        value: l10n.timerMinutesStr(form.timerMinutes),
                      ),
                    ],
                    if (form.hasAccessToken) ...[
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.vpn_key_rounded,
                        title: l10n.infoToken,
                        value: l10n.whichToken,
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      const _InfoRow(
                        icon: Icons.check_circle_outline,
                        title: 'Pengiriman',
                        value: 'Hanya bisa dikirim satu kali',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isExam ? AppTheme.warning : context.primary)
                      .withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (isExam ? AppTheme.warning : context.primary)
                        .withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isExam
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: isExam ? AppTheme.warning : context.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isExam
                            ? '${l10n.timerStartNote}${l10n.autoSubmitNote}'
                            : 'Pastikan kamu siap sebelum memulai. ${l10n.afterSubmitCant}',
                        style: TextStyle(
                            fontSize: 12, height: 1.5, color: secondaryTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (form.hasAccessToken) {
                      Navigator.pushReplacement(
                        context,
                        CustomPageRoute(page: ExamTokenScreen(form: form),
                        ),
                      );
                    } else if (form.isExam) {
                      Navigator.pushReplacement(
                        context,
                        CustomPageRoute(
                          page: ExamLockdownGateScreen(form: form),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        CustomPageRoute(page: FillFormScreen(form: form),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    form.hasAccessToken
                        ? Icons.vpn_key_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    form.hasAccessToken
                        ? l10n.enterTokenStart
                        : l10n.startFill,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        form.hasAccessToken ? AppTheme.warning : context.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: secondaryTextColor),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.primaryWith(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: context.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
