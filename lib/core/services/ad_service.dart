import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors, Color;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 서비스 - AdMob 배너, 전면, 보상형 전면 광고 관리
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
    return 'ca-app-pub-3715008468517611/9546788030';
  }

  // 네이티브 광고 ID
  String get nativeAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110'
          : 'ca-app-pub-3940256099942544/3986624511';
    }
    return 'ca-app-pub-3715008468517611/9070027306';
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

  // 보상형 전면 광고 ID (AI 해설용)
  String get rewardedInterstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5354046379'
          : 'ca-app-pub-3940256099942544/6978759866';
    }
    return 'ca-app-pub-3715008468517611/9904590655';
  }

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isRewardedAdLoading = false;

  /// AdMob 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;

    if (kDebugMode) {
      print('AdMob initialized');
    }

    // 보상형 전면 광고 미리 로드
    loadRewardedInterstitialAd();
  }

  /// 네이티브 광고 생성
  NativeAd createNativeAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: const Color(0xFF1A1A2E),
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF7C3AED),
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF888888),
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF888888),
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
      ),
    );
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

  /// 보상형 전면 광고 로드
  void loadRewardedInterstitialAd() {
    if (_isRewardedAdLoading || _rewardedInterstitialAd != null) return;
    _isRewardedAdLoading = true;

    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedAdLoading = false;
          if (kDebugMode) {
            print('Rewarded interstitial ad loaded');
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          _isRewardedAdLoading = false;
          if (kDebugMode) {
            print('Rewarded interstitial ad failed to load: $error');
          }
        },
      ),
    );
  }

  /// 보상형 전면 광고가 준비되었는지 확인
  bool get isRewardedAdReady => _rewardedInterstitialAd != null;

  /// 보상형 전면 광고 표시
  /// [onRewarded] 사용자가 광고를 끝까지 본 경우 호출
  /// [onFailed] 광고 표시 실패 시 호출
  Future<void> showRewardedInterstitialAd({
    required Function() onRewarded,
    Function()? onFailed,
  }) async {
    if (_rewardedInterstitialAd == null) {
      if (kDebugMode) {
        print('Rewarded interstitial ad not ready');
      }
      onFailed?.call();
      // 다시 로드 시도
      loadRewardedInterstitialAd();
      return;
    }

    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        // 다음 광고 미리 로드
        loadRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        if (kDebugMode) {
          print('Rewarded interstitial ad failed to show: $error');
        }
        onFailed?.call();
        loadRewardedInterstitialAd();
      },
    );

    await _rewardedInterstitialAd!.show(
      onUserEarnedReward: (ad, reward) {
        if (kDebugMode) {
          print('User earned reward: ${reward.amount} ${reward.type}');
        }
        onRewarded();
      },
    );
  }
}
