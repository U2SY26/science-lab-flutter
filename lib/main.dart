import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/ai_chat_provider.dart';
import 'core/services/ad_service.dart';
import 'core/services/iap_service.dart';
import 'core/services/force_update_service.dart';
import 'core/services/whats_new_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/firebase_ai_service.dart';
import 'core/services/stt_service.dart';
import 'core/services/tts_service.dart';
import 'shared/widgets/ai_chat_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp();

  // Firebase 익명 인증 (firebase_ai 필수, 개인정보 수집 없음)
  await FirebaseAuth.instance.signInAnonymously();

  // Firebase AI (Gemini) 초기화
  FirebaseAiService().initialize();

  // 앱 시작 이벤트 로깅
  AnalyticsService.logAppOpen();

  // Edge-to-Edge 시스템 UI 설정 (Android 15+ 대응)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // AdMob + Remote Config 초기화 (모바일만)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await AdService().initialize();
    await IAPService().initialize();
    await ForceUpdateService().initialize();
    await WhatsNewService().initialize();
    await DeepLinkService().initialize();

    // STT / TTS 초기화
    await SttService().initialize();
    await TtsService().initialize();
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
  @override
  void initState() {
    super.initState();
    // 딥링크 수신 시 GoRouter로 네비게이션
    DeepLinkService().onDeepLink = (String path) {
      appRouter.go(path);
    };
    // 콜드 스타트 딥링크: 스플래시 이후 처리되도록 딜레이
    final initialRoute = DeepLinkService().getInitialRoute();
    if (initialRoute != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) appRouter.go(initialRoute);
      });
    }
  }

  @override
  void dispose() {
    DeepLinkService().onDeepLink = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLocale = ref.watch(effectiveLocaleProvider);
    final showAiOverlay = ref.watch(showAiOverlayProvider);

    return MaterialApp.router(
      title: 'Visual Science Lab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      locale: effectiveLocale,

      // 글로벌 AI 튜터 오버레이 (인트로 이후에만 표시)
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (showAiOverlay) const AiChatOverlay(),
          ],
        );
      },

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
      ],
    );
  }
}
