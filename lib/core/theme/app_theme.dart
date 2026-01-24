import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// 3DWeb Science Lab 다크 테마
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent2,
        surface: AppColors.bgSoft,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: AppColors.ink,
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: AppColors.ink),
          displayMedium: TextStyle(color: AppColors.ink),
          displaySmall: TextStyle(color: AppColors.ink),
          headlineMedium: TextStyle(color: AppColors.ink),
          titleLarge: TextStyle(color: AppColors.ink),
          titleMedium: TextStyle(color: AppColors.muted),
          bodyLarge: TextStyle(color: AppColors.ink),
          bodyMedium: TextStyle(color: AppColors.muted),
          labelLarge: TextStyle(color: AppColors.accent),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        thumbColor: AppColors.accent,
        inactiveTrackColor: AppColors.muted.withValues(alpha: 0.3),
        overlayColor: AppColors.accent.withValues(alpha: 0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansKr(
          color: AppColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
