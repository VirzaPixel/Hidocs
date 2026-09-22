import 'package:flutter/material.dart';

import 'package:hi_docs/app_theme.dart';

class FormTheme {
  const FormTheme._();

  static Color primaryOf(String hex) {
    final clean = hex.trim().replaceFirst('#', '');
    if (clean.length == 6) {
      final value = int.tryParse(clean, radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return AppTheme.primary;
  }

  static Color darkOf(String hex) {
    final hsl = HSLColor.fromColor(primaryOf(hex));
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }

  static Color lightOf(String hex) {
    final hsl = HSLColor.fromColor(primaryOf(hex));
    return hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
  }

  static List<Color> gradientOf(String hex, int index) {
    final p = primaryOf(hex);
    final d = darkOf(hex);
    final l = lightOf(hex);
    switch (index % 4) {
      case 1:
        return [p, l];
      case 2:
        return [d, p];
      case 3:
        return [l, p];
      default:
        return [d, p, l];
    }
  }

  static LinearGradient headerGradient(String hex, int index) {
    return LinearGradient(
      colors: gradientOf(hex, index),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
