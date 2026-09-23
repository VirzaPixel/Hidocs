import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary      = Color(0xFF133E76);
  static const Color primaryLight = Color(0xFF1A5FAB);
  static const Color primaryDark  = Color(0xFF0A2A55);
  static const Color primaryFaint = Color(0xFFEAF0FA);

  static const Color accent      = Color(0xFF6A5AE0);
  static const Color accentDark  = Color(0xFF4E3FC4);
  static const Color accentLight = Color(0xFFEDEBFD);
  static const Color accentCream = Color(0xFFF5F4FF);

  static const Color success      = Color(0xFF1B9E5E);
  static const Color successLight = Color(0xFFE6F7EF);
  static const Color warning      = Color(0xFFF0A500);
  static const Color warningLight = Color(0xFFFFF4E0);
  static const Color error        = Color(0xFFD93025);
  static const Color errorLight   = Color(0xFFFDEAE8);
  static const Color info         = Color(0xFF1976D2);
  static const Color infoLight    = Color(0xFFE3F0FF);

  static const Color errorRed      = Color(0xFFD93025);
  static const Color warningOrange = Color(0xFFF0A500);
  static const Color successGreen  = Color(0xFF1B9E5E);
  static const Color primaryBlue   = Color(0xFF133E76);
  static const Color darkPrimaryLight = Color(0xFF4A90D9);

  static const Color textPrimary   = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF3D4F63);
  static const Color textMuted     = Color(0xFF8A9BB0);
  static const Color border        = Color(0xFFDDE3EC);
  static const Color surfaceLight  = Color(0xFFF4F6FA);
  static const Color surfaceCard   = Color(0xFFFFFFFF);

  static const Color darkBg            = Color(0xFF0C1521);
  static const Color darkSurface       = Color(0xFF131F2E);
  static const Color darkCard          = Color(0xFF1A2840);
  static const Color darkBorder        = Color(0xFF243448);
  static const Color darkTextPrimary   = Color(0xFFEDF1F7);
  static const Color darkTextSecondary = Color(0xFFB0BFCE);
  static const Color darkTextMuted     = Color(0xFF5A7080);

  static const Radius _radius = Radius.circular(24);
  static const Radius _buttonRadius = Radius.circular(16);
  static const Radius _fieldRadius = Radius.circular(16);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: surfaceLight,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryFaint,
      onPrimaryContainer: primaryDark,
      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: accentLight,
      onSecondaryContainer: Color(0xFF33286B),
      tertiary: success,
      error: error,
      onError: Colors.white,
      surface: surfaceCard,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceLight,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border,
      shadow: Color(0x1A0D1B2A),
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: primary,        letterSpacing: -1.0),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primary,        letterSpacing: -0.5),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary,    letterSpacing: -0.3),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
      titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textSecondary, height: 1.55),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, height: 1.45),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
      labelSmall:    TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted,     letterSpacing: 0.5),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: surfaceCard,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(_radius)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2),
      iconTheme: IconThemeData(color: Colors.white, size: 22),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(_buttonRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(_buttonRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(_buttonRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: surfaceCard,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border:         OutlineInputBorder(borderRadius: BorderRadius.all(_fieldRadius), borderSide: BorderSide(color: border)),
      enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.all(_fieldRadius), borderSide: BorderSide(color: border)),
      focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.all(_fieldRadius), borderSide: BorderSide(color: primary, width: 2)),
      errorBorder:    OutlineInputBorder(borderRadius: BorderRadius.all(_fieldRadius), borderSide: BorderSide(color: error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.all(_fieldRadius), borderSide: BorderSide(color: error, width: 2)),
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle:      TextStyle(fontSize: 14, color: textMuted, fontWeight: FontWeight.w400),
      labelStyle:     TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surfaceCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
      contentTextStyle: TextStyle(fontSize: 13, color: textSecondary, height: 1.45),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF24344D),
      contentTextStyle: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 3,
      focusElevation: 3,
      hoverElevation: 4,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceCard,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle:   TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceCard,
      indicatorColor: primaryFaint,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? primary : textMuted)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(fontSize: 12, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500, color: s.contains(WidgetState.selected) ? primary : textMuted)),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: primaryFaint,
      // Stateful background: pilihan yang aktif tetap memakai warna muda
      // sehingga teks (warna primary) selalu terbaca — sebelumnya background
      // terpilih = primary sama persis dengan warna teks (hilang konten).
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primary.withValues(alpha: 0.18)
            : primaryFaint,
      ),
      selectedColor: primary.withValues(alpha: 0.18),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
      secondaryLabelStyle: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: primary),
      side: BorderSide(color: primary.withValues(alpha: 0.30)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : Colors.transparent),
      side: const BorderSide(color: border, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : textMuted),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: border,
      circularTrackColor: border,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: textSecondary,
      textColor: textPrimary,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF24344D),
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(fontSize: 12, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : border),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );

  static const Color _darkPrimary = Color(0xFF4A90D9);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _darkPrimary,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: Color(0xFF0A2A55),
      primaryContainer: Color(0xFF1C3D6E),
      onPrimaryContainer: Color(0xFFD6E4F8),
      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF352B8A),
      onSecondaryContainer: Color(0xFFE6E3FF),
      tertiary: success,
      error: error,
      onError: Colors.white,
      surface: darkCard,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkSurface,
      onSurfaceVariant: darkTextSecondary,
      outline: darkBorder,
      outlineVariant: darkBorder,
      shadow: Color(0x66000000),
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: _darkPrimary,       letterSpacing: -1.0),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _darkPrimary,       letterSpacing: -0.5),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: darkTextPrimary,    letterSpacing: -0.3),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: darkTextPrimary),
      titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
      titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
      titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextSecondary),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: darkTextSecondary, height: 1.55),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: darkTextSecondary, height: 1.45),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: darkTextMuted),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: darkTextSecondary),
      labelSmall:    TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: darkTextMuted,     letterSpacing: 0.5),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: darkCard,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(_radius)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2),
      iconTheme: IconThemeData(color: Colors.white, size: 22),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: const Color(0xFF0A2A55),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(_buttonRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: const Color(0xFF0A2A55),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(_buttonRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimary,
        side: const BorderSide(color: darkBorder, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(_buttonRadius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border:         OutlineInputBorder(borderRadius: BorderRadius.all(_fieldRadius), borderSide: BorderSide(color: darkBorder)),
      enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.all(_fieldRadius), borderSide: BorderSide(color: darkBorder)),
      focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.all(_fieldRadius), borderSide: BorderSide(color: _darkPrimary, width: 2)),
      errorBorder:    OutlineInputBorder(borderRadius: BorderRadius.all(_fieldRadius), borderSide: BorderSide(color: error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.all(_fieldRadius), borderSide: BorderSide(color: error, width: 2)),
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle:      TextStyle(fontSize: 14, color: darkTextMuted),
      labelStyle:     TextStyle(fontSize: 13, color: darkTextSecondary, fontWeight: FontWeight.w500),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: darkCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: darkTextPrimary),
      contentTextStyle: TextStyle(fontSize: 13, color: darkTextSecondary, height: 1.45),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF33455F),
      contentTextStyle: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 3,
      focusElevation: 3,
      hoverElevation: 4,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      selectedItemColor: _darkPrimary,
      unselectedItemColor: darkTextMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle:   TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkCard,
      indicatorColor: const Color(0xFF1C3D6E),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? _darkPrimary : darkTextMuted)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(fontSize: 12, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500, color: s.contains(WidgetState.selected) ? _darkPrimary : darkTextMuted)),
    ),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurface,
      // Teks pakai warna terang supaya selalu terbaca di atas background chip
      // (terpilih maupun tidak) pada tema gelap — dulu label & background sama
      // persis warna primary sehingga teks hilang.
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _darkPrimary.withValues(alpha: 0.30)
            : darkSurface,
      ),
      selectedColor: _darkPrimary.withValues(alpha: 0.30),
      labelStyle: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: darkTextPrimary),
      secondaryLabelStyle: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: _darkPrimary),
      side: BorderSide(color: _darkPrimary.withValues(alpha: 0.45)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _darkPrimary : Colors.transparent),
      side: const BorderSide(color: darkBorder, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _darkPrimary : darkTextMuted),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _darkPrimary,
      linearTrackColor: darkBorder,
      circularTrackColor: darkBorder,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: darkTextSecondary,
      textColor: darkTextPrimary,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF33455F),
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(fontSize: 12, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _darkPrimary : darkBorder),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}