import 'package:flutter/material.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';

class TimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final bool isWarning;

  const TimerWidget({
    required this.remainingSeconds,
    this.isWarning = false,
    super.key,
  });

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AppTheme.error : context.primary;
    final bg    = isWarning
        ? AppTheme.error.withValues(alpha: 0.12)
        : context.primaryFaint;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_rounded, size: 17, color: color),
        const SizedBox(width: 7),
        Text(_fmt(remainingSeconds), style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: color,
            fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}
