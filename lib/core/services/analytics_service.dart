import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics 서비스
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 시뮬레이션 열기 이벤트
  static Future<void> logSimulationOpen(String simId, String category) async {
    await _analytics.logEvent(
      name: 'simulation_open',
      parameters: {
        'sim_id': simId,
        'category': category,
      },
    );
  }

  /// 시뮬레이션 완료 이벤트
  static Future<void> logSimulationComplete(String simId) async {
    await _analytics.logEvent(
      name: 'simulation_complete',
      parameters: {
        'sim_id': simId,
      },
    );
  }

  /// 즐겨찾기 추가 이벤트
  static Future<void> logFavoriteAdd(String simId) async {
    await _analytics.logEvent(
      name: 'favorite_add',
      parameters: {
        'sim_id': simId,
      },
    );
  }

  /// 즐겨찾기 제거 이벤트
  static Future<void> logFavoriteRemove(String simId) async {
    await _analytics.logEvent(
      name: 'favorite_remove',
      parameters: {
        'sim_id': simId,
      },
    );
  }

  /// 카테고리 열기 이벤트
  static Future<void> logCategoryOpen(String categoryId) async {
    await _analytics.logEvent(
      name: 'category_open',
      parameters: {
        'category_id': categoryId,
      },
    );
  }

  /// 언어 변경 이벤트
  static Future<void> logLanguageChange(String language) async {
    await _analytics.logEvent(
      name: 'language_change',
      parameters: {
        'language': language,
      },
    );
  }

  /// 광고 제거 구매 이벤트
  static Future<void> logPurchaseAdsRemoved() async {
    await _analytics.logEvent(
      name: 'purchase_ads_removed',
    );
  }

  /// 화면 조회 이벤트
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  /// 앱 시작 이벤트
  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  /// 검색 이벤트
  static Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: query);
  }

  /// 공유 이벤트
  static Future<void> logShare(String simId, String method) async {
    await _analytics.logShare(
      contentType: 'simulation',
      itemId: simId,
      method: method,
    );
  }

  /// 사용자 속성 설정
  static Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
