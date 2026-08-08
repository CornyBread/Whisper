import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens taken directly from the "Diseño de app Susurro" mockups.
abstract class AppColors {
  static const background = Color(0xFF0D0E13);
  static const card = Color(0xFF141620);
  static const surface = Color(0xFF1E2029);
  static const bar = Color(0xFF101118);
  static const panel = Color(0xFF15161C);

  static const lavender = Color(0xFFC7C2FF);
  static const mint = Color(0xFFA7E8C8);
  static const peach = Color(0xFFFFCBA6);
  static const rose = Color(0xFFF4B6C8);

  static const textPrimary = Color(0xFFECEDF2);
  static const textSecondary = Color(0xFF8E90A0);

  static const border = Color(0x12FFFFFF); // rgba(255,255,255,.07)
}

abstract class AppRadius {
  static const card = 20.0;
  static const field = 16.0;
  static const button = 16.0;
  static const chip = 13.0;
}

abstract class AppSpacing {
  static const unit = 4.0;
}

ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.lavender,
      onPrimary: AppColors.panel,
      secondary: AppColors.mint,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.rose,
      onError: AppColors.panel,
    ),
    textTheme: baseTextTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bar,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    ),
    dividerColor: AppColors.border,
    splashFactory: InkRipple.splashFactory,
  );
}
