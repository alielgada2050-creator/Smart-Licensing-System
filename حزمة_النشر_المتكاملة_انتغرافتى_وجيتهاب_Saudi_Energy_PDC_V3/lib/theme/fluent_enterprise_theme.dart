// Microsoft Fluent 2 Calm Light Theme + Saudi Energy & PDC Luxury Dark Mode

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FluentEnterpriseTheme {
  // Fluent 2 Primary Brand Colors
  static const Color fluentBlue = Color(0xFF0F6CBD);
  static const Color fluentBlueHover = Color(0xFF115EA3);
  static const Color fluentBlueTint = Color(0xFFEFF6FF);
  static const Color fluentBlueStroke = Color(0xFFBFDBFE);

  // Saudi Energy Official Accents
  static const Color saudiNavy = Color(0xFF00183A);
  static const Color saudiDarkBlue = Color(0xFF001F5E);
  static const Color saudiElectricBlue = Color(0xFF0080FF);
  static const Color saudiEnergyGreen = Color(0xFF00FF86);

  // Semantic Colors
  static const Color successFg = Color(0xFF107C10);
  static const Color successBg = Color(0xFFF1FAF1);
  static const Color warningFg = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFFF9F5);
  static const Color dangerFg = Color(0xFFC50F1F);
  static const Color dangerBg = Color(0xFFFDF3F4);

  static ThemeData buildLightTheme() {
    final baseTextTheme = GoogleFonts.cairoTextTheme(
      ThemeData.light().textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: fluentBlue,
        brightness: Brightness.light,
        primary: fluentBlue,
        secondary: const Color(0xFF0284C7),
        surface: const Color(0xFFFFFFFF),
        error: dangerFg,
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF242424),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: const Color(0xFFE5E7EB),
      textTheme: baseTextTheme.apply(
        bodyColor: const Color(0xFF242424),
        displayColor: const Color(0xFF1E293B),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: fluentBlue, width: 2),
        ),
      ),
    );
  }

  static ThemeData buildDarkTheme() {
    final baseTextTheme = GoogleFonts.cairoTextTheme(
      ThemeData.dark().textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: saudiElectricBlue,
        brightness: Brightness.dark,
        primary: const Color(0xFF32C2FF),
        secondary: saudiEnergyGreen,
        surface: saudiNavy,
        error: const Color(0xFFFF3377),
      ),
      scaffoldBackgroundColor: const Color(0xFF001026),
      cardTheme: CardThemeData(
        color: saudiNavy,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: const Color(0xFF32C2FF).withValues(alpha: 0.22),
            width: 1,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000B1C),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: const Color(0xFF32C2FF).withValues(alpha: 0.2),
      textTheme: baseTextTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: saudiDarkBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: const Color(0xFF32C2FF).withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: const Color(0xFF32C2FF).withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: saudiEnergyGreen, width: 2),
        ),
      ),
    );
  }
}
