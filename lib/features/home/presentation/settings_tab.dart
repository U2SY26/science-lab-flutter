import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/iap_service.dart';

/// 설정 탭
class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  int _completedCount = 0;
  int _favoritesCount = 0;
  bool _adsRemoved = false;
  StreamSubscription<bool>? _iapSubscription;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _adsRemoved = IAPService().adsRemoved;
    _iapSubscription = IAPService().adsRemovedStream.listen((removed) {
      if (mounted) setState(() => _adsRemoved = removed);
    });
  }

  @override
  void dispose() {
    _iapSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedCount = prefs.getStringList('completedSims')?.length ?? 0;
      _favoritesCount = prefs.getStringList('favorites')?.length ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          '설정',
          style: TextStyle(color: AppColors.ink, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 프로필/통계 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.2),
                  AppColors.accent2.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.science,
                  size: 48,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 12),
                Text(
                  '3DWeb Science Lab',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '눈으로 보는 과학',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(label: '완료', value: '$_completedCount'),
                    Container(width: 1, height: 30, color: AppColors.cardBorder),
                    _StatItem(label: '즐겨찾기', value: '$_favoritesCount'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 개발자 지원 섹션
          _SectionTitle(title: '개발자 지원'),
          _SettingCard(
            icon: Icons.coffee,
            iconColor: const Color(0xFFD4A574),
            title: '개발자에게 커피 사주기',
            subtitle: 'PayPal로 응원해주세요',
            onTap: _openPayPal,
          ),
          _SettingCard(
            icon: _adsRemoved ? Icons.check_circle : Icons.block,
            iconColor: _adsRemoved ? Colors.green : AppColors.accent,
            title: '광고 제거',
            subtitle: _adsRemoved ? '구매 완료 - 광고 없이 이용 중' : '₩990 일회성 구매',
            onTap: _adsRemoved ? () {} : _purchaseRemoveAds,
          ),
          const SizedBox(height: 24),

          // 앱 설정 섹션
          _SectionTitle(title: '앱 설정'),
          _LanguageSelector(
            currentLanguage: ref.watch(languageProvider),
            onLanguageChanged: (lang) {
              ref.read(languageProvider.notifier).setLanguage(lang);
            },
          ),
          _SettingCard(
            icon: Icons.refresh,
            iconColor: Colors.orange,
            title: '학습 기록 초기화',
            subtitle: '완료 기록과 즐겨찾기를 삭제합니다',
            onTap: _resetProgress,
          ),
          const SizedBox(height: 24),

          // 정보 섹션
          _SectionTitle(title: '정보'),
          _SettingCard(
            icon: Icons.info_outline,
            iconColor: AppColors.accent2,
            title: '앱 정보',
            subtitle: 'v1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
          _SettingCard(
            icon: Icons.language,
            iconColor: Colors.blue,
            title: '웹 버전',
            subtitle: '3dweb-rust.vercel.app',
            onTap: () => _launchUrl('https://3dweb-rust.vercel.app'),
          ),
          _SettingCard(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.green,
            title: '개인정보 처리방침',
            subtitle: '개인정보 보호 정책',
            onTap: () => _launchUrl('https://3dweb-rust.vercel.app/privacy'),
          ),
          _SettingCard(
            icon: Icons.email_outlined,
            iconColor: Colors.purple,
            title: '문의하기',
            subtitle: '버그 제보 및 기능 제안',
            onTap: () => _launchUrl('mailto:3dweb.science@gmail.com'),
          ),
          const SizedBox(height: 32),

          // 크레딧
          Center(
            child: Column(
              children: [
                Text(
                  'Made with Flutter',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '과학을 사랑하는 모든 분들께',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _purchaseRemoveAds() async {
    HapticFeedback.mediumImpact();

    final iap = IAPService();
    final product = iap.removeAdsProduct;

    if (product == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('스토어에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // 구매 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text(
              '광고 제거',
              style: TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${product.price}로 모든 광고를 영구적으로 제거합니다.',
              style: const TextStyle(color: AppColors.ink, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '일회성 구매로 평생 광고 없이 이용할 수 있습니다.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.bg,
            ),
            child: Text('${product.price} 구매'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await iap.purchaseRemoveAds();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구매를 시작할 수 없습니다. 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openPayPal() async {
    HapticFeedback.mediumImpact();

    // PayPal 기부 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.coffee, color: const Color(0xFFD4A574)),
            const SizedBox(width: 8),
            const Text(
              '커피 한 잔 사주기',
              style: TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 앱이 도움이 되셨다면 개발자에게 커피 한 잔 사주세요!',
              style: TextStyle(color: AppColors.ink, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '여러분의 후원이 더 나은 시뮬레이션을 만드는 원동력이 됩니다.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('나중에', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('PayPal 열기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0070BA),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _launchUrl('https://paypal.me/u2dia');
    }
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('학습 기록 초기화', style: TextStyle(color: AppColors.ink)),
        content: const Text(
          '모든 완료 기록과 즐겨찾기가 삭제됩니다.\n계속하시겠습니까?',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('completedSims');
      await prefs.remove('favorites');
      setState(() {
        _completedCount = 0;
        _favoritesCount = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('학습 기록이 초기화되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.science, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text(
              '3DWeb Science Lab',
              style: TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '버전 1.0.0',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              '눈으로 보는 과학 - 물리, 수학, AI 등의 개념을 인터랙티브 시뮬레이션으로 배워보세요.',
              style: TextStyle(color: AppColors.ink, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              '특징:',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _FeatureItem(text: '28개 이상의 인터랙티브 시뮬레이션'),
            _FeatureItem(text: '물리, 수학, AI/ML, 카오스 이론'),
            _FeatureItem(text: '직접 조작하며 원리 이해'),
            _FeatureItem(text: '지속적인 업데이트'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('닫기', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    HapticFeedback.lightImpact();
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.ink, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const _LanguageSelector({
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.translate, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '언어 / Language',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentLanguage.getName(true),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<AppLanguage>(
                value: currentLanguage,
                underline: const SizedBox.shrink(),
                dropdownColor: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                items: AppLanguage.values.map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(
                      lang.getName(true),
                      style: const TextStyle(color: AppColors.ink, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (lang) {
                  if (lang != null) onLanguageChanged(lang);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
