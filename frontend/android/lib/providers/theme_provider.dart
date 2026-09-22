import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hi_docs/app_theme.dart';

enum AppColorScheme {
  blue,
  green,
  purple,
  orange,
  teal,
  red,
  custom,
}

extension AppColorSchemeExt on AppColorScheme {
  String get label {
    switch (this) {
      case AppColorScheme.blue:
        return 'Biru (Default)';
      case AppColorScheme.green:
        return 'Hijau';
      case AppColorScheme.purple:
        return 'Ungu';
      case AppColorScheme.orange:
        return 'Oranye';
      case AppColorScheme.teal:
        return 'Teal';
      case AppColorScheme.red:
        return 'Merah';
      case AppColorScheme.custom:
        return 'Custom';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppColorScheme.blue:
        return const Color(0xFF133E76);
      case AppColorScheme.green:
        return const Color(0xFF1B7A4A);
      case AppColorScheme.purple:
        return const Color(0xFF5B2D8A);
      case AppColorScheme.orange:
        return const Color(0xFFCC5500);
      case AppColorScheme.teal:
        return const Color(0xFF00695C);
      case AppColorScheme.red:
        return const Color(0xFFC62828);
      case AppColorScheme.custom:
        return const Color(0xFF133E76);
    }
  }

  Color get primaryLightColor {
    switch (this) {
      case AppColorScheme.blue:
        return const Color(0xFF1A5FAB);
      case AppColorScheme.green:
        return const Color(0xFF2EA364);
      case AppColorScheme.purple:
        return const Color(0xFF7B3DB5);
      case AppColorScheme.orange:
        return const Color(0xFFE86820);
      case AppColorScheme.teal:
        return const Color(0xFF00897B);
      case AppColorScheme.red:
        return const Color(0xFFE53935);
      case AppColorScheme.custom:
        return const Color(0xFF1A5FAB);
    }
  }

  Color get primaryDarkColor {
    switch (this) {
      case AppColorScheme.blue:
        return const Color(0xFF0A2A55);
      case AppColorScheme.green:
        return const Color(0xFF0D5230);
      case AppColorScheme.purple:
        return const Color(0xFF3D1E61);
      case AppColorScheme.orange:
        return const Color(0xFF993D00);
      case AppColorScheme.teal:
        return const Color(0xFF004D40);
      case AppColorScheme.red:
        return const Color(0xFF8E0000);
      case AppColorScheme.custom:
        return const Color(0xFF0A2A55);
    }
  }

  Color get primaryFaintColor {
    switch (this) {
      case AppColorScheme.blue:
        return const Color(0xFFEAF0FA);
      case AppColorScheme.green:
        return const Color(0xFFE6F4EC);
      case AppColorScheme.purple:
        return const Color(0xFFF0E8FA);
      case AppColorScheme.orange:
        return const Color(0xFFFAEFE6);
      case AppColorScheme.teal:
        return const Color(0xFFE0F2F1);
      case AppColorScheme.red:
        return const Color(0xFFFAEAEA);
      case AppColorScheme.custom:
        return const Color(0xFFEAF0FA);
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppColorScheme _colorScheme = AppColorScheme.blue;

  Color? _customPrimary;
  Color? _customPrimaryLight;
  Color? _customPrimaryDark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AppColorScheme get colorScheme => _colorScheme;

  Color get primary {
    if (_colorScheme == AppColorScheme.custom &&
        _customPrimary != null) {
      return _customPrimary!;
    }

    return _colorScheme.primaryColor;
  }

  Color get primaryLight {
    if (_colorScheme == AppColorScheme.custom &&
        _customPrimaryLight != null) {
      return _customPrimaryLight!;
    }

    return _colorScheme.primaryLightColor;
  }

  Color get primaryDark {
    if (_colorScheme == AppColorScheme.custom &&
        _customPrimaryDark != null) {
      return _customPrimaryDark!;
    }

    return _colorScheme.primaryDarkColor;
  }

  Color get primaryFaint =>
      primary.withValues(alpha: 0.10);

  Color? get customPrimary => _customPrimary;

  ThemeProvider() {
    _loadPrefs();
  }

  void toggleTheme() {
    _themeMode =
        isDarkMode ? ThemeMode.light : ThemeMode.dark;

    _savePrefs();
    notifyListeners();
  }

  void setColorScheme(AppColorScheme scheme) {
    _colorScheme = scheme;

    _savePrefs();
    notifyListeners();
  }

  void setCustomColor(Color picked) {
    _colorScheme = AppColorScheme.custom;

    _customPrimary = picked;
    _customPrimaryLight = _lighten(picked, 0.15);
    _customPrimaryDark = _darken(picked, 0.20);

    _savePrefs();
    notifyListeners();
  }

  Future<void> resetTheme() async {
    _colorScheme = AppColorScheme.blue;

    _customPrimary = null;
    _customPrimaryLight = null;
    _customPrimaryDark = null;

    await _savePrefs();

    notifyListeners();
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);

    return hsl
        .withLightness(
          (hsl.lightness + amount).clamp(0.0, 1.0),
        )
        .toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);

    return hsl
        .withLightness(
          (hsl.lightness - amount).clamp(0.0, 1.0),
        )
        .toColor();
  }

  ThemeData buildLightTheme() {
    final p = primary;
    final pl = primaryLight;
    final faint = primaryFaint;

    return AppTheme.lightTheme.copyWith(
      primaryColor: p,

      colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
        primary: p,
        secondary: p,
        primaryContainer: pl,
        secondaryContainer: pl,
        tertiary: p,
      ),

      scaffoldBackgroundColor:
          AppTheme.lightTheme.scaffoldBackgroundColor,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      inputDecorationTheme:
          AppTheme.lightTheme.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: p,
            width: 2,
          ),
        ),
      ),

      chipTheme: AppTheme.lightTheme.chipTheme.copyWith(
        backgroundColor: faint,
        selectedColor: p,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: p,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (_) => Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) {
            return states.contains(WidgetState.selected)
                ? p
                : AppTheme.border;
          },
        ),
      ),

      // HEADER SELALU MENGIKUTI WARNA TEMA
      appBarTheme:
          AppTheme.lightTheme.appBarTheme.copyWith(
        backgroundColor: p,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      bottomNavigationBarTheme:
          AppTheme.lightTheme.bottomNavigationBarTheme.copyWith(
        selectedItemColor: p,
        backgroundColor:
            AppTheme.lightTheme.colorScheme.surface,
      ),
    );
  }

  ThemeData buildDarkTheme() {
    final p = _colorScheme == AppColorScheme.blue
        ? const Color(0xFF4A90D9)
        : _colorScheme == AppColorScheme.custom &&
                _customPrimary != null
            ? _lighten(_customPrimary!, 0.20)
            : _colorScheme.primaryLightColor.withValues(
                alpha: 0.9,
              );
    final pl = primaryLight;

    return AppTheme.darkTheme.copyWith(
      primaryColor: p,

      colorScheme: AppTheme.darkTheme.colorScheme.copyWith(
        primary: p,
        secondary: p,
        primaryContainer: pl,
        secondaryContainer: pl,
        tertiary: p,
      ),

      scaffoldBackgroundColor:
          AppTheme.darkTheme.scaffoldBackgroundColor,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // HEADER SELALU MENGIKUTI WARNA TEMA
      appBarTheme:
          AppTheme.darkTheme.appBarTheme.copyWith(
        backgroundColor: p,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      bottomNavigationBarTheme:
          AppTheme.darkTheme.bottomNavigationBarTheme.copyWith(
        selectedItemColor: p,
        backgroundColor: AppTheme.darkSurface,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (_) => Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) {
            return states.contains(WidgetState.selected)
                ? p
                : AppTheme.darkBorder;
          },
        ),
      ),
    );
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark =
        prefs.getBool('isDarkMode') ?? false;

    _themeMode =
        isDark ? ThemeMode.dark : ThemeMode.light;

    final schemeIdx =
        prefs.getInt('colorScheme') ?? 0;

    _colorScheme = AppColorScheme.values[
        schemeIdx.clamp(
          0,
          AppColorScheme.values.length - 1,
        )];

    final customInt =
        prefs.getInt('customPrimaryColor');

    if (customInt != null) {
      _customPrimary = Color(customInt);

      _customPrimaryLight =
          _lighten(_customPrimary!, 0.15);

      _customPrimaryDark =
          _darken(_customPrimary!, 0.20);
    }

    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'isDarkMode',
      isDarkMode,
    );

    await prefs.setInt(
      'colorScheme',
      _colorScheme.index,
    );

    if (_customPrimary != null) {
      await prefs.setInt(
        'customPrimaryColor',
        _customPrimary!.toARGB32(),
      );
    } else {
      await prefs.remove(
        'customPrimaryColor',
      );
    }
  }
}