import 'package:flutter/material.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';

class FormTheme {
  const FormTheme._();

  /// Warna tema bawaan form (default DB & model). Aplikasi Android tidak punya
  /// color picker untuk `theme_color`, sehingga form lama semuanya "ungu" dan
  /// terlihat tidak mengikuti tema custom milik pengguna.
  static const String defaultHex = '4F46E5';

  static String _normalize(String hex) =>
      hex.trim().replaceFirst('#', '').toUpperCase();

  /// `true` kalau warna form masih bawaan / kosong → pakai warna tema app.
  static bool isUnsetOrDefault(String hex) {
    final clean = _normalize(hex);
    return clean.isEmpty || clean == defaultHex;
  }

  /// Warna utama: warna form sendiri bila ada, kalau tidak ikut tema Profile.
  static Color resolvePrimary(BuildContext context, String hex) =>
      isUnsetOrDefault(hex) ? context.primary : primaryOf(hex);

  /// Gradasi header: untuk form bawaan memakai nuansa warna tema app
  /// (gelap → utama → terang), sama bentuknya dengan [headerGradient].
  static LinearGradient resolveHeaderGradient(
      BuildContext context, String hex, int index) {
    if (!isUnsetOrDefault(hex)) return headerGradient(hex, index);

    final p = context.primary;
    final d = context.primaryDark;
    final l = context.primaryLight;
    return LinearGradient(
      colors: switch (index % 4) {
        1 => [p, l],
        2 => [d, p],
        3 => [l, p],
        _ => [d, p, l],
      },
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

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
