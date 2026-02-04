import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/language_provider.dart';
import 'core/services/ad_service.dart';
import 'core/services/iap_service.dart';
import 'core/services/force_update_service.dart';
import 'core/services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp();

  // 앱 시작 이벤트 로깅
  AnalyticsService.logAppOpen();

  // AdMob 초기화 (모바일만)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await AdService().initialize();
    await IAPService().initialize();
  }

  runApp(
    const ProviderScope(
      child: ScienceLabApp(),
    ),
  );
}

/// Visual Science Lab App
class ScienceLabApp extends ConsumerStatefulWidget {
  const ScienceLabApp({super.key});

  @override
  ConsumerState<ScienceLabApp> createState() => _ScienceLabAppState();
}

class _ScienceLabAppState extends ConsumerState<ScienceLabApp> {
  bool _hasCheckedUpdate = false;

  @override
  Widget build(BuildContext context) {
    // Watch language provider to rebuild when language changes
    final languageNotifier = ref.watch(languageProvider.notifier);
    final effectiveLocale = languageNotifier.getEffectiveLocale();

    return MaterialApp.router(
      title: 'Visual Science Lab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      locale: effectiveLocale,

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ko'), // Korean
      ],
      builder: (context, child) {
        // Check for force update after first frame
        if (!_hasCheckedUpdate) {
          _hasCheckedUpdate = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkForceUpdate(context);
          });
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }

  void _checkForceUpdate(BuildContext context) {
    final updateService = ForceUpdateService();
    if (updateService.isUpdateRequired()) {
      // Show force update dialog
      ForceUpdateDialog.show(
        context,
        isForced: true,
        currentVersion: ForceUpdateService.currentVersion,
        requiredVersion: ForceUpdateService.minimumRequiredVersion,
      );
    }
  }
}
