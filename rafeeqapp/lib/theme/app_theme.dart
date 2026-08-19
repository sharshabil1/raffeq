import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Static palette constants
  static const Color plum = Color(0xFF8A5B7E);
  static const Color plumDeep = Color(0xFF6E4665);
  static const Color sage = Color(0xFF6E9C82);
  static const Color gold = Color(0xFFD9A05B);
  static const Color rose = Color(0xFFC4676B);

  // Dynamic light/dark theme helpers
  static Color bg(bool isDark) =>
      isDark ? const Color(0xFF101815) : const Color(0xFFEAF1EE);
  static Color surface(bool isDark) =>
      isDark ? const Color(0xFF18221E) : const Color(0xFFFFFFFF);
  static Color surfaceSoft(bool isDark) =>
      isDark ? const Color(0xFF202C27) : const Color(0xFFF4F9F6);
  static Color ink(bool isDark) =>
      isDark ? const Color(0xFFE5EFEA) : const Color(0xFF1E2E29);
  static Color muted(bool isDark) =>
      isDark ? const Color(0xFFA1B3AA) : const Color(0xFF5C6B65);
  static Color faint(bool isDark) =>
      isDark ? const Color(0xFF6B7E75) : const Color(0xFF93A39C);
  static Color line(bool isDark) =>
      isDark ? const Color(0xFF293832) : const Color(0xFFD8E3DE);

  // Direct static colors for legacy access
  static const Color lightBg = Color(0xFFEAF1EE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSoft = Color(0xFFF4F9F6);
  static const Color lightInk = Color(0xFF1E2E29);
  static const Color lightMuted = Color(0xFF5C6B65);
  static const Color lightFaint = Color(0xFF93A39C);
  static const Color lightLine = Color(0xFFD8E3DE);
}

class AppTheme {
  static ThemeData lightTheme(bool isArabic) {
    final baseFont = isArabic ? GoogleFonts.tajawalTextTheme : GoogleFonts.karlaTextTheme;
    final displayFont = isArabic ? GoogleFonts.amiri : GoogleFonts.fraunces;

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg(false),
      colorScheme: ColorScheme.light(
        primary: AppColors.ink(false),
        secondary: AppColors.plum,
        surface: AppColors.surface(false),
        error: AppColors.rose,
      ),
      textTheme: baseFont().copyWith(
        displayLarge: displayFont(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.ink(false),
        ),
        displayMedium: displayFont(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.ink(false),
        ),
        displaySmall: displayFont(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.ink(false),
        ),
        headlineMedium: displayFont(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.ink(false),
        ),
        bodyLarge: GoogleFonts.karla(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.ink(false),
        ),
        bodyMedium: GoogleFonts.karla(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: AppColors.ink(false),
        ),
        bodySmall: GoogleFonts.karla(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.muted(false),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSoft(false),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.line(false)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.line(false)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.plum, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData darkTheme(bool isArabic) {
    final displayFont = isArabic ? GoogleFonts.amiri : GoogleFonts.fraunces;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg(true),
      colorScheme: ColorScheme.dark(
        primary: AppColors.ink(true),
        secondary: AppColors.plum,
        surface: AppColors.surface(true),
        error: AppColors.rose,
      ),
      textTheme: TextTheme(
        displayLarge: displayFont(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.ink(true),
        ),
        displayMedium: displayFont(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.ink(true),
        ),
        displaySmall: displayFont(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.ink(true),
        ),
        headlineMedium: displayFont(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.ink(true),
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.ink(true),
        ),
        bodyMedium: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: AppColors.ink(true),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.muted(true),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSoft(true),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.line(true)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.line(true)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.plum, width: 1.5),
        ),
      ),
    );
  }
}
