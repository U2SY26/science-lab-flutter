import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob 초기화 (모바일만)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await AdService().initialize();
  }

  runApp(
    const ProviderScope(
      child: ScienceLabApp(),
    ),
  );
}

/// 눈으로 보는 과학 앱
class ScienceLabApp extends StatelessWidget {
  const ScienceLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '눈으로 보는 과학',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
