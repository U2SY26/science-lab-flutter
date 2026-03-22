import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/ai_chat_provider.dart';
import 'core/providers/user_profile_provider.dart';
import 'core/services/ad_service.dart';
import 'core/services/iap_service.dart';
import 'core/services/force_update_service.dart';
import 'core/services/whats_new_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/firebase_ai_service.dart';
import 'core/services/device_id_service.dart';
import 'core/services/stt_service.dart';
import 'core/services/tts_service.dart';
import 'shared/widgets/ai_chat_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Riverpod 2.6.1 + Flutter 3.35 호환성 이슈 우회
  // _dirty assertion은 디버그 전용 — 릴리즈에선 발생 안 함
  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains('_dirty') || msg.contains('hasSize')) {
      debugPrint('[FlutterError] Ignored: $msg');
      return;
    }
    FlutterError.presentError(details);
  };

  // Firebase 초기화 (실패해도 앱은 계속 실행)
  try {
    await Firebase.initializeApp();
    // App Check — 릴리즈: Play Integrity / 디버그: Debug Provider
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
    // Firebase AI Logic (Gemini) 초기화 — API 키 불필요
    FirebaseAiService().initialize();
    // 앱 시작 이벤트 로깅
    AnalyticsService.logAppOpen();
  } catch (e) {
    debugPrint('[main] Firebase init failed: $e');
  }

  // Edge-to-Edge 시스템 UI 설정 (Android 15+ 대응)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // 모바일 전용 서비스 초기화 (병렬 실행으로 시작 속도 개선)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Future.wait([
      AdService().initialize(),
      IAPService().initialize(),
      WhatsNewService().initialize(),
      SttService().initialize(),
      TtsService().initialize(),
      DeviceIdService().initialize(),
    ]);
    // 딥링크 & 강제 업데이트는 별도로 (순서 무관)
    unawaited(ForceUpdateService().initialize());
    unawaited(DeepLinkService().initialize());
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
    // 유저 프로필 초기화 — 첫 프레임 이후 (빌드 중 provider 변경 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(userProfileProvider.notifier).initialize();
    });
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
