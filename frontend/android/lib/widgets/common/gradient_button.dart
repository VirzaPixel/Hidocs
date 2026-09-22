import 'package:flutter/material.dart';
import 'package:hi_docs/utils/theme_context.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final List<Color>? colors;
  final double height;

  const GradientButton({
    required this.text,
    required this.onPressed,
    this.isLoading  = false,
    this.fullWidth  = false,
    this.icon,
    this.colors,
    this.height = 52,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final grad = colors ?? [context.primary, context.primaryLight];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width:   fullWidth ? double.infinity : null,
      height:  height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLoading
              ? [grad.first.withValues(alpha: 0.70), grad.last.withValues(alpha: 0.70)]
              : grad,
          begin: Alignment.centerLeft,
          end:   Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isLoading ? null : [
          BoxShadow(
            color: grad.first.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : onPressed,
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (icon != null) ...[
                      Icon(icon!, size: 19, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(text, style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 0.2)),
                  ]),
          ),
        ),
      ),
    );
  }
}

