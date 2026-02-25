import 'package:flutter/material.dart';

class AppColors {
  static const primary    = Color(0xFFFF6B2B);
  static const primaryDark = Color(0xFFE55A1A);
  static const accent     = Color(0xFF00D4AA);
  static const warning    = Color(0xFFFFD93D);
  static const danger     = Color(0xFFFF4757);
  static const bgDark     = Color(0xFF0F0F1A);
  static const bgCard     = Color(0xFF1A1A2E);
  static const bgCard2    = Color(0xFF252540);
  static const textMain   = Color(0xFFF0F0F5);
  static const textMuted  = Color(0xFF8888AA);
  static const border     = Color(0x14FFFFFF);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.bgCard,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgCard,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgCard2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo'),
      hintStyle:  const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
