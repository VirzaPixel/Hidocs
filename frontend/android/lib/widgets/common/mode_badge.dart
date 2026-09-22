import 'package:flutter/material.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/models/form_model.dart';

class ModeBadge extends StatelessWidget {
  final bool isExam;
  final double fontSize;

  const ModeBadge({
    required this.isExam,
    this.fontSize = 10,
    super.key,
  });

  factory ModeBadge.fromForm(FormModel form, {double fontSize = 10}) {
    return ModeBadge(isExam: form.isExam, fontSize: fontSize);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExam
            ? AppTheme.error.withValues(alpha: 0.12)
            : context.primaryWith(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExam
              ? AppTheme.error.withValues(alpha: 0.35)
              : context.primaryWith(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExam ? Icons.shield_rounded : Icons.assignment_rounded,
            size: fontSize + 3,
            color: isExam ? AppTheme.error : context.primary,
          ),
          const SizedBox(width: 4),
          Text(
            isExam ? l10n.modeExam : l10n.modeSurvey,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isExam ? AppTheme.error : context.primary,
            ),
          ),
        ],
      ),
    );
  }
}
