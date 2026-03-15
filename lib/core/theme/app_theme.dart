import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// 3DWeb Science Lab 다크 테마
class AppTheme {
  AppTheme._();

  /// 수학 유니코드 기호 렌더링을 위한 폰트 fallback 체인
  static const List<String> _mathFallback = ['Noto Sans', 'Roboto', 'sans-serif'];

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
          displayLarge: TextStyle(color: AppColors.ink, fontFamilyFallback: _mathFallback),
          displayMedium: TextStyle(color: AppColors.ink, fontFamilyFallback: _mathFallback),
          displaySmall: TextStyle(color: AppColors.ink, fontFamilyFallback: _mathFallback),
          headlineMedium: TextStyle(color: AppColors.ink, fontFamilyFallback: _mathFallback),
          titleLarge: TextStyle(color: AppColors.ink, fontFamilyFallback: _mathFallback),
          titleMedium: TextStyle(color: AppColors.muted, fontFamilyFallback: _mathFallback),
          bodyLarge: TextStyle(color: AppColors.ink, fontFamilyFallback: _mathFallback),
          bodyMedium: TextStyle(color: AppColors.muted, fontFamilyFallback: _mathFallback),
          labelLarge: TextStyle(color: AppColors.accent, fontFamilyFallback: _mathFallback),
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
    );
  }
}
