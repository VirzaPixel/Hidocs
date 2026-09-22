import 'package:flutter/material.dart';
import 'package:hi_docs/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final bool hasBorder;
  final bool hasShadow;

  const CustomCard({
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.radius    = 18,
    this.hasBorder = true,
    this.hasShadow = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = color ?? (isDark ? AppTheme.darkCard : AppTheme.surfaceCard);
    final bd     = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Container(
      margin:  margin  ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:         bg,
        borderRadius:  BorderRadius.circular(radius),
        border: hasBorder ? Border.all(color: bd) : null,
        boxShadow: hasShadow && !isDark ? [
          BoxShadow(
            color:  Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(18),
            child: child,
          ),
        ),
      ),
    );
  }
}

