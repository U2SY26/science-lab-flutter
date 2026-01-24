import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/ad_service.dart';
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

  @override
  void initState() {
    super.initState();
    if (_isMobilePlatform) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (!_isMobilePlatform) return;
    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        setState(() => _isAdLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        setState(() => _isAdLoaded = false);
      },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
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
        const SafeArea(
          top: false,
          child: AdBannerWidget(),
        ),
      ],
    );
  }
}
