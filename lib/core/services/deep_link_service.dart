import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

/// 딥링크 처리 서비스
/// - App Links: https://3dweb-rust.vercel.app/simulations/{simId}
/// - Custom scheme: sciencelab://simulation/{simId}
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// 딥링크로 들어온 경로를 전달하는 콜백
  void Function(String path)? onDeepLink;

  /// 앱 콜드 스타트 시 딥링크 URI (초기 링크)
  Uri? _initialUri;
  Uri? get initialUri => _initialUri;

  /// 초기화
  Future<void> initialize() async {
    _appLinks = AppLinks();

    // 1. 앱이 종료 상태에서 딥링크로 열린 경우 (Cold start)
    try {
      _initialUri = await _appLinks.getInitialLink();
      if (_initialUri != null) {
        debugPrint('[DeepLink] Initial link: $_initialUri');
        _handleUri(_initialUri!);
      }
    } catch (e) {
      debugPrint('[DeepLink] getInitialLink error: $e');
    }

    // 2. 앱이 실행 중일 때 딥링크 수신 (Warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('[DeepLink] Stream link: $uri');
        _handleUri(uri);
      },
      onError: (err) {
        debugPrint('[DeepLink] Stream error: $err');
      },
    );
  }

  /// URI → 앱 내 경로 변환
  void _handleUri(Uri uri) {
    String? path;

    if (uri.scheme == 'https' && uri.host == '3dweb-rust.vercel.app') {
      // App Links: https://3dweb-rust.vercel.app/simulations/{simId}
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'simulations') {
        final simId = uri.pathSegments[1];
        path = '/simulation/$simId';
        AnalyticsService.logDeepLinkOpen(simId, 'app_link');
      } else {
        path = '/home';
      }
    } else if (uri.scheme == 'sciencelab') {
      // Custom scheme: sciencelab://simulation/{simId}
      if (uri.host == 'simulation' && uri.pathSegments.isNotEmpty) {
        final simId = uri.pathSegments[0];
        path = '/simulation/$simId';
        AnalyticsService.logDeepLinkOpen(simId, 'custom_scheme');
      } else {
        path = '/home';
      }
    }

    if (path != null && onDeepLink != null) {
      onDeepLink!(path);
    }
  }

  /// 딥링크에서 초기 라우트 경로 추출 (앱 시작 시 사용)
  String? getInitialRoute() {
    if (_initialUri == null) return null;

    final uri = _initialUri!;
    if (uri.scheme == 'https' && uri.host == '3dweb-rust.vercel.app') {
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'simulations') {
        return '/simulation/${uri.pathSegments[1]}';
      }
    } else if (uri.scheme == 'sciencelab' && uri.host == 'simulation') {
      if (uri.pathSegments.isNotEmpty) {
        return '/simulation/${uri.pathSegments[0]}';
      }
    }
    return null;
  }

  /// 리소스 해제
  void dispose() {
    _linkSubscription?.cancel();
  }
}
