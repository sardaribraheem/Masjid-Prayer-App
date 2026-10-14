import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class ColorPalette {
  static const lightBg = Color(0xFFF6F7F3);
  static const lightCardBg = Colors.white;
  static const lightText = Color(0xFF182D25);
  static const lightTextSecondary = Color(0xFF5C6B63);
  static const lightBorder = Color(0xFFD7DFD9);
  static const lightIcon = lightTextSecondary;
  static const darkBg = Color(0xFF101B17);
  static const darkCardBg = Color(0xFF1A2922);
  static const darkText = Color(0xFFEAF2EB);
  static const darkTextSecondary = Color(0xFFBBCBC0);
  static const darkBorder = Color(0xFF43564A);
  static const darkIcon = darkTextSecondary;
  static const primary = Color(0xFF1B5E47);
  static const secondary = Color(0xFF916C3F);
  static const tertiary = Color(0xFF277A5C);
  static const success = Color(0xFF237149);
  static const warning = Color(0xFF93610D);
  static const error = Color(0xFFB3261E);
  static const info = Color(0xFF326891);
}

class AppTheme {
  static final lightTheme = _build(Brightness.light);
  static final darkTheme = _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: ColorPalette.primary,
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFFA2D9BA) : ColorPalette.primary,
          onPrimary: dark ? const Color(0xFF103824) : Colors.white,
          surface: dark ? ColorPalette.darkCardBg : Colors.white,
          onSurface: dark ? ColorPalette.darkText : ColorPalette.lightText,
          onSurfaceVariant: dark
              ? ColorPalette.darkTextSecondary
              : ColorPalette.lightTextSecondary,
          outline: dark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? ColorPalette.darkBg
          : ColorPalette.lightBg,
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        height: 76,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
