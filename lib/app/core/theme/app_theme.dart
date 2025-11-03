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
        headlineMedium: GoogleFonts.robotoSlab(fontSize: 34, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: AppColors.onSurface),
        headlineSmall: GoogleFonts.robotoSlab(fontSize: 24, fontWeight: FontWeight.w400, color: AppColors.onSurface),
        titleLarge: GoogleFonts.robotoSlab(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0.15, color: AppColors.onSurface),
        bodyLarge: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: AppColors.onSurface),
        bodyMedium: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: AppColors.onSurface),
        labelLarge: GoogleFonts.robotoSlab(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25, color: Colors.white),
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
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.onSurface.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400, width: 2.0),
           borderRadius: BorderRadius.circular(8.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade600, width: 2.0),
           borderRadius: BorderRadius.circular(8.0),
        ),
        labelStyle: GoogleFonts.lora(color: AppColors.onSurface),
      ),
    );
  }
}