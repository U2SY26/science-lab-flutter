import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language codes supported by the app
enum AppLanguage {
  system('system', 'System Default', '시스템 설정'),
  en('en', 'English', '영어'),
  ko('ko', '한국어', '한국어');

  final String code;
  final String nameEn;
  final String nameKo;

  const AppLanguage(this.code, this.nameEn, this.nameKo);

  String getName(bool isKorean) => isKorean ? nameKo : nameEn;
}

/// Language state notifier
class LanguageNotifier extends StateNotifier<AppLanguage> {
  static const _prefsKey = 'app_language';

  LanguageNotifier() : super(AppLanguage.system) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey) ?? 'system';
    state = AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.system,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }

  /// Get the effective locale based on user preference
  Locale getEffectiveLocale() {
    if (state == AppLanguage.system) {
      // Use system locale
      final systemLocale = PlatformDispatcher.instance.locale;
      if (systemLocale.languageCode == 'ko') {
        return const Locale('ko');
      }
      return const Locale('en');
    }
    return Locale(state.code);
  }

  /// Check if current language is Korean
  bool get isKorean {
    if (state == AppLanguage.system) {
      return PlatformDispatcher.instance.locale.languageCode == 'ko';
    }
    return state == AppLanguage.ko;
  }
}

/// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

/// Convenience provider to check if current language is Korean
final isKoreanProvider = Provider<bool>((ref) {
  final notifier = ref.watch(languageProvider.notifier);
  return notifier.isKorean;
});
