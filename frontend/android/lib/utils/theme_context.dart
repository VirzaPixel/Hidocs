import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get primary => cs.primary;
  Color primaryWith(double opacity) => cs.primary.withValues(alpha: opacity);

  Color get primaryLight => cs.primaryContainer;
  Color primaryLightWith(double opacity) =>
      cs.primaryContainer.withValues(alpha: opacity);

  Color get primaryDark {
    final hsl = HSLColor.fromColor(cs.primary);
    return hsl
        .withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0))
        .toColor();
  }

  Color get primaryFaint => cs.primary.withValues(alpha: 0.10);
}
