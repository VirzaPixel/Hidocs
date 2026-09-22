import 'package:flutter/material.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';

class MathFormulaWidget extends StatelessWidget {
  final String formula;
  final double fontSize;

  const MathFormulaWidget({
    required this.formula,
    this.fontSize = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color:        isDark ? AppTheme.darkSurface : context.primaryFaint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? context.primaryWith(0.30)
                : context.primaryWith(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.functions_rounded, size: 16,
              color: isDark ? const Color(0xFF4A90D9) : context.primary),
          const SizedBox(width: 8),
          Text('Rumus Matematika', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF4A90D9) : context.primary,
              letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkCard
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isDark
                    ? AppTheme.darkBorder
                    : AppTheme.border),
          ),
          child: Text(formula, style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF4A90D9) : context.primary,
              fontStyle: FontStyle.italic,
              height: 1.5)),
        ),
      ]),
    );
  }
}
