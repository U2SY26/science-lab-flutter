import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/iap_service.dart';
import '../../core/constants/app_colors.dart';

/// 모바일 플랫폼 체크
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// 배너 광고 위젯
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _adsRemoved = false;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _adsRemoved = IAPService().adsRemoved;

    // 구매 상태 변경 구독
    _subscription = IAPService().adsRemovedStream.listen((removed) {
      if (mounted) {
        setState(() => _adsRemoved = removed);
        if (removed) {
          _bannerAd?.dispose();
          _bannerAd = null;
        }
      }
    });

    if (_isMobilePlatform && !_adsRemoved) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (!_isMobilePlatform || _adsRemoved) return;
    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        if (mounted) setState(() => _isAdLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        if (mounted) setState(() => _isAdLoaded = false);
      },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 광고 제거 구매 시 빈 영역
    if (_adsRemoved) {
      return const SizedBox(height: 8);
    }

    // 모바일이 아니면 빈 영역
    if (!_isMobilePlatform) {
      return const SizedBox.shrink();
    }

    // 광고 로드 중이거나 실패한 경우 - 홈버튼/네비게이션 영역 확보용 패딩
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// 하단 고정 배너 광고 위젯
class BottomAdBanner extends StatelessWidget {
  final Widget child;

  const BottomAdBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        // 광고 배너 + Safe Area
        SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: const AdBannerWidget(),
        ),
      ],
    );
  }
}
