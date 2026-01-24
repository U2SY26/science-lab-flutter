import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 서비스 - AdMob 배너 및 전면 광고 관리
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;

  // 배너 광고 ID
  String get bannerAdUnitId {
    if (kDebugMode) {
      // 테스트 광고 ID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    // 프로덕션 광고 ID
    return Platform.isAndroid
        ? 'ca-app-pub-3715008468517611/4145970315'
        : 'ca-app-pub-3715008468517611/9546788030';
  }

  // 전면 광고 ID (선택적)
  String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    // TODO: 프로덕션 전면 광고 ID 추가
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-3940256099942544/4411468910';
  }

  /// AdMob 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;

    if (kDebugMode) {
      print('AdMob initialized');
    }
  }

  /// 배너 광고 생성
  BannerAd createBannerAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  /// 전면 광고 로드
  Future<InterstitialAd?> loadInterstitialAd() async {
    InterstitialAd? interstitialAd;

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('Interstitial ad failed to load: $error');
          }
        },
      ),
    );

    return interstitialAd;
  }
}
