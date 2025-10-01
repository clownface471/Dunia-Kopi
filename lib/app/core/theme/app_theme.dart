import 'package:duniakopi_project/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get vintageTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.dancingScript(fontSize: 96, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        displayMedium: GoogleFonts.dancingScript(fontSize: 60, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        displaySmall: GoogleFonts.dancingScript(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        headlineMedium: GoogleFonts.dancingScript(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0.25, color: AppColors.onSurface),
        headlineSmall: GoogleFonts.dancingScript(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        titleLarge: GoogleFonts.dancingScript(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.15, color: AppColors.onSurface),
        bodyLarge: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: AppColors.onSurface),
        bodyMedium: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: AppColors.onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: GoogleFonts.dancingScript(
          color: AppColors.primary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}