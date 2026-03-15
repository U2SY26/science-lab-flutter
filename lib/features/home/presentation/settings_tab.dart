import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/ai_persona.dart';
import '../../../core/models/rive_character_mode.dart';
import '../../../core/providers/ai_chat_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/services/iap_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../shared/widgets/lottie_character.dart';
import '../data/simulation_data.dart';

/// Settings tab widget.
/// When [embedded] is true, returns only the body content without Scaffold/AppBar
/// (used for the landscape side panel).
class SettingsTab extends ConsumerStatefulWidget {
  final bool embedded;

  const SettingsTab({super.key, this.embedded = false});

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

  Widget _buildBody(bool isKorean) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile/stats card
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
                isKorean ? '\ub208\uc73c\ub85c \ubcf4\ub294 \uacfc\ud559' : 'See Science Come Alive',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(label: isKorean ? '\uc644\ub8cc' : 'Done', value: '$_completedCount'),
                  Container(width: 1, height: 30, color: AppColors.cardBorder),
                  _StatItem(label: isKorean ? '\uc990\uaca8\ucc3e\uae30' : 'Favorites', value: '$_favoritesCount'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Support section
        _SectionTitle(title: isKorean ? '\uac1c\ubc1c\uc790 \uc9c0\uc6d0' : 'Support'),
        _SettingCard(
          icon: Icons.coffee,
          iconColor: const Color(0xFFD4A574),
          title: isKorean ? '\uac1c\ubc1c\uc790\uc5d0\uac8c \ucee4\ud53c \uc0ac\uc8fc\uae30' : 'Buy Developer a Coffee',
          subtitle: isKorean ? 'PayPal\ub85c \uc751\uc6d0\ud574\uc8fc\uc138\uc694' : 'Support via PayPal',
          onTap: _openPayPal,
        ),
        _SettingCard(
          icon: _adsRemoved ? Icons.check_circle : Icons.block,
          iconColor: _adsRemoved ? Colors.green : AppColors.accent,
          title: isKorean ? '\uad11\uace0 \uc81c\uac70' : 'Remove Ads',
          subtitle: _adsRemoved
              ? (isKorean ? '\uad6c\ub9e4 \uc644\ub8cc - \uad11\uace0 \uc5c6\uc774 \uc774\uc6a9 \uc911' : 'Purchased - Ad-free')
              : (isKorean ? '\u20a9990 \uc77c\ud68c\uc131 \uad6c\ub9e4' : '\u20a9990 one-time purchase'),
          onTap: _adsRemoved ? () {} : _purchaseRemoveAds,
        ),
        _AiSubscriptionCard(isKorean: isKorean),
        const SizedBox(height: 24),

        // AI 튜터 페르소나 선택
        _SectionTitle(title: isKorean ? 'AI 튜터 페르소나' : 'AI Tutor Persona'),
        _PersonaSelector(isKorean: isKorean),
        const SizedBox(height: 24),

        // App settings section
        _SectionTitle(title: isKorean ? '\uc571 \uc124\uc815' : 'App Settings'),
        _LanguageSelector(
          currentLanguage: ref.watch(languageProvider),
          onLanguageChanged: (lang) {
            ref.read(languageProvider.notifier).setLanguage(lang);
          },
        ),
        _SettingCard(
          icon: Icons.refresh,
          iconColor: Colors.orange,
          title: isKorean ? '학습 기록 초기화' : 'Reset Progress',
          subtitle: isKorean ? '완료 기록과 즐겨찾기를 삭제합니다' : 'Delete all completed records and favorites',
          onTap: () => _resetProgress(isKorean),
        ),
        const SizedBox(height: 24),

        // 계정 & 구독 관리 섹션
        _SectionTitle(title: isKorean ? '계정 & 구독 관리' : 'Account & Subscription'),
        _SettingCard(
          icon: Icons.restart_alt,
          iconColor: const Color(0xFFEF4444),
          title: isKorean ? '레벨 초기화' : 'Reset Level',
          subtitle: isKorean ? 'XP와 레벨을 초기화합니다' : 'Reset XP and level to zero',
          onTap: () => _resetLevel(isKorean),
        ),
        _SettingCard(
          icon: Icons.credit_card_off,
          iconColor: const Color(0xFFEF4444),
          title: isKorean ? '구독 취소' : 'Cancel Subscription',
          subtitle: isKorean
              ? '취소 후에도 결제 기간 끝까지 이용 가능'
              : 'Access until current billing period ends',
          onTap: () => _cancelSubscription(isKorean),
        ),
        _SettingCard(
          icon: Icons.delete_forever,
          iconColor: const Color(0xFFDC2626),
          title: isKorean ? '모든 데이터 삭제' : 'Delete All Data',
          subtitle: isKorean
              ? '학습 기록, 설정, 채팅 기록 등 모든 앱 데이터 삭제'
              : 'Remove all app data including progress, settings, and chat',
          onTap: () => _deleteAllData(isKorean),
        ),
        _SettingCard(
          icon: Icons.person_remove,
          iconColor: const Color(0xFF991B1B),
          title: isKorean ? '계정 탈퇴' : 'Delete Account',
          subtitle: isKorean
              ? '구독 취소 + 모든 데이터 삭제 (복구 불가)'
              : 'Cancel subscription + delete all data (irreversible)',
          onTap: () => _deleteAccount(isKorean),
        ),
        const SizedBox(height: 24),

        // About section
        _SectionTitle(title: isKorean ? '\uc815\ubcf4' : 'About'),
        _SettingCard(
          icon: Icons.info_outline,
          iconColor: AppColors.accent2,
          title: isKorean ? '\uc571 \uc815\ubcf4' : 'App Info',
          subtitle: 'v1.19.2',
          onTap: () => _showAboutDialog(context, isKorean),
        ),
        _SettingCard(
          icon: Icons.language,
          iconColor: Colors.blue,
          title: isKorean ? '\uc6f9 \ubc84\uc804' : 'Web Version',
          subtitle: '3dweb-rust.vercel.app',
          onTap: () => _launchUrl('https://3dweb-rust.vercel.app'),
        ),
        _SettingCard(
          icon: Icons.privacy_tip_outlined,
          iconColor: Colors.green,
          title: isKorean ? '\uac1c\uc778\uc815\ubcf4 \ucc98\ub9ac\ubc29\uce68' : 'Privacy Policy',
          subtitle: isKorean ? '\uac1c\uc778\uc815\ubcf4 \ubcf4\ud638 \uc815\ucc45' : 'Privacy protection policy',
          onTap: () => _launchUrl('https://3dweb-rust.vercel.app/privacy'),
        ),
        _SettingCard(
          icon: Icons.email_outlined,
          iconColor: Colors.purple,
          title: isKorean ? '\ubb38\uc758\ud558\uae30' : 'Contact Us',
          subtitle: isKorean ? '\ubc84\uadf8 \uc81c\ubcf4 \ubc0f \uae30\ub2a5 \uc81c\uc548' : 'Bug reports & feature requests',
          onTap: () => _launchUrl('mailto:3dweb.science@gmail.com'),
        ),
        const SizedBox(height: 32),

        // Credits
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
                    isKorean ? '\uacfc\ud559\uc744 \uc0ac\ub791\ud558\ub294 \ubaa8\ub4e0 \ubd84\ub4e4\uaed8' : 'For all who love science',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);
    final body = _buildBody(isKorean);

    // Embedded mode: return body only without Scaffold/AppBar (for landscape side panel)
    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(
          isKorean ? '\uc124\uc815' : 'Settings',
          style: const TextStyle(color: AppColors.ink, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: body,
    );
  }

  Future<void> _purchaseRemoveAds() async {
    HapticFeedback.mediumImpact();
    final isKorean = ref.read(isKoreanProvider);

    final iap = IAPService();
    final product = iap.removeAdsProduct;

    if (product == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isKorean ? '\uc2a4\ud1a0\uc5b4\uc5d0 \uc5f0\uacb0\ud560 \uc218 \uc5c6\uc2b5\ub2c8\ub2e4. \uc7a0\uc2dc \ud6c4 \ub2e4\uc2dc \uc2dc\ub3c4\ud574\uc8fc\uc138\uc694.' : 'Cannot connect to store. Please try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              isKorean ? '\uad11\uace0 \uc81c\uac70' : 'Remove Ads',
              style: const TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKorean ? '${product.price}\ub85c \ubaa8\ub4e0 \uad11\uace0\ub97c \uc601\uad6c\uc801\uc73c\ub85c \uc81c\uac70\ud569\ub2c8\ub2e4.' : 'Remove all ads permanently for ${product.price}.',
              style: const TextStyle(color: AppColors.ink, fontSize: 14),
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
                  const Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isKorean ? '\uc77c\ud68c\uc131 \uad6c\ub9e4\ub85c \ud3c9\uc0dd \uad11\uace0 \uc5c6\uc774 \uc774\uc6a9\ud560 \uc218 \uc788\uc2b5\ub2c8\ub2e4.' : 'One-time purchase for lifetime ad-free experience.',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
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
            child: Text(isKorean ? '\ucde8\uc18c' : 'Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.bg,
            ),
            child: Text(isKorean ? '${product.price} \uad6c\ub9e4' : 'Buy ${product.price}'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await iap.purchaseRemoveAds();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isKorean ? '\uad6c\ub9e4\ub97c \uc2dc\uc791\ud560 \uc218 \uc5c6\uc2b5\ub2c8\ub2e4. \ub2e4\uc2dc \uc2dc\ub3c4\ud574\uc8fc\uc138\uc694.' : 'Cannot start purchase. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openPayPal() async {
    HapticFeedback.mediumImpact();
    final isKorean = ref.read(isKoreanProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.coffee, color: const Color(0xFFD4A574)),
            const SizedBox(width: 8),
            Text(
              isKorean ? '\ucee4\ud53c \ud55c \uc794 \uc0ac\uc8fc\uae30' : 'Buy a Coffee',
              style: const TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKorean ? '\uc774 \uc571\uc774 \ub3c4\uc6c0\uc774 \ub418\uc168\ub2e4\uba74 \uac1c\ubc1c\uc790\uc5d0\uac8c \ucee4\ud53c \ud55c \uc794 \uc0ac\uc8fc\uc138\uc694!' : 'If this app helped you, buy the developer a coffee!',
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
                      isKorean ? '\uc5ec\ub7ec\ubd84\uc758 \ud6c4\uc6d0\uc774 \ub354 \ub098\uc740 \uc2dc\ubbac\ub808\uc774\uc158\uc744 \ub9cc\ub4dc\ub294 \uc6d0\ub3d9\ub825\uc774 \ub429\ub2c8\ub2e4.' : 'Your support helps create better simulations.',
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
            child: Text(isKorean ? '\ub098\uc911\uc5d0' : 'Later', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(isKorean ? 'PayPal \uc5f4\uae30' : 'Open PayPal'),
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

  Future<void> _resetProgress(bool isKorean) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(isKorean ? '\ud559\uc2b5 \uae30\ub85d \ucd08\uae30\ud654' : 'Reset Progress', style: const TextStyle(color: AppColors.ink)),
        content: Text(
          isKorean ? '\ubaa8\ub4e0 \uc644\ub8cc \uae30\ub85d\uacfc \uc990\uaca8\ucc3e\uae30\uac00 \uc0ad\uc81c\ub429\ub2c8\ub2e4.\n\uacc4\uc18d\ud558\uc2dc\uaca0\uc2b5\ub2c8\uae4c?' : 'All completed records and favorites will be deleted.\nContinue?',
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isKorean ? '\ucde8\uc18c' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isKorean ? '\ucd08\uae30\ud654' : 'Reset', style: const TextStyle(color: Colors.red)),
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
          SnackBar(
            content: Text(isKorean ? '\ud559\uc2b5 \uae30\ub85d\uc774 \ucd08\uae30\ud654\ub418\uc5c8\uc2b5\ub2c8\ub2e4' : 'Progress has been reset'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 레벨 초기화
  Future<void> _resetLevel(bool isKorean) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.restart_alt, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(
              isKorean ? '레벨 초기화' : 'Reset Level',
              style: const TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isKorean
              ? '정말 초기화하시겠습니까? XP와 레벨이 모두 0으로 초기화됩니다.'
              : 'Are you sure? XP and level will be reset to 0.',
          style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isKorean ? '취소' : 'Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text(isKorean ? '초기화' : 'Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await ref.read(userProfileProvider.notifier).resetProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isKorean ? 'XP와 레벨이 초기화되었습니다' : 'XP and level have been reset'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 구독 취소 — Google Play 구독 관리 페이지로 이동
  Future<void> _cancelSubscription(bool isKorean) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.credit_card_off, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(
              isKorean ? '구독 취소' : 'Cancel Subscription',
              style: const TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isKorean
              ? '구독을 취소하시겠습니까?\n\n• 취소 후에도 현재 결제 기간이 끝나는 날까지 모든 기능을 자유롭게 이용할 수 있습니다.\n• Google Play 구독 관리 페이지에서 취소할 수 있습니다.'
              : 'Cancel your subscription?\n\n• You can still use all features until the end of your current billing period.\n• You will be redirected to Google Play subscription management.',
          style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isKorean ? '돌아가기' : 'Go Back', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text(isKorean ? '구독 관리 열기' : 'Open Subscriptions'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _launchUrl('https://play.google.com/store/account/subscriptions');
    }
  }

  /// 모든 데이터 삭제 — SharedPreferences 전체 초기화
  Future<void> _deleteAllData(bool isKorean) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(
              isKorean ? '모든 데이터 삭제' : 'Delete All Data',
              style: const TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isKorean
              ? '앱에 저장된 모든 데이터를 삭제합니다.\n\n삭제 항목:\n• 학습 완료 기록\n• 즐겨찾기\n• AI 채팅 기록\n• 언어 설정\n• 페르소나 설정\n\n이 작업은 되돌릴 수 없습니다.'
              : 'Delete all data stored in the app.\n\nThis includes:\n• Completed records\n• Favorites\n• AI chat history\n• Language settings\n• Persona settings\n\nThis action cannot be undone.',
          style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isKorean ? '취소' : 'Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(isKorean ? '모두 삭제' : 'Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      setState(() {
        _completedCount = 0;
        _favoritesCount = 0;
        _adsRemoved = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isKorean ? '모든 데이터가 삭제되었습니다' : 'All data has been deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 계정 탈퇴 — 구독 취소 안내 + 모든 데이터 삭제
  Future<void> _deleteAccount(bool isKorean) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person_remove, color: Color(0xFF991B1B)),
            const SizedBox(width: 8),
            Text(
              isKorean ? '계정 탈퇴' : 'Delete Account',
              style: const TextStyle(color: AppColors.ink, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isKorean
              ? '정말로 탈퇴하시겠습니까?\n\n다음 작업이 수행됩니다:\n1. 구독이 있는 경우 Google Play에서 직접 취소해주세요\n2. 앱 내 모든 데이터가 삭제됩니다\n3. 삭제 후 앱이 초기 상태로 리셋됩니다\n\n⚠️ 이 작업은 되돌릴 수 없습니다.'
              : 'Are you sure you want to delete your account?\n\n1. If subscribed, please cancel on Google Play\n2. All app data will be deleted\n3. App will reset to initial state\n\n⚠️ This action cannot be undone.',
          style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isKorean ? '취소' : 'Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
            ),
            child: Text(isKorean ? '탈퇴하기' : 'Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      // 1. 모든 데이터 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      setState(() {
        _completedCount = 0;
        _favoritesCount = 0;
        _adsRemoved = false;
      });
      if (mounted) {
        // 2. 구독 관리 페이지로 이동 안내
        final openSubs = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isKorean ? '데이터 삭제 완료' : 'Data Deleted',
              style: const TextStyle(color: AppColors.ink, fontSize: 18),
            ),
            content: Text(
              isKorean
                  ? '모든 앱 데이터가 삭제되었습니다.\n\n구독 중이라면 Google Play에서 구독을 취소해주세요. 취소하지 않으면 자동 결제가 계속됩니다.'
                  : 'All app data has been deleted.\n\nIf subscribed, please cancel on Google Play to stop automatic billing.',
              style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isKorean ? '확인' : 'OK', style: TextStyle(color: AppColors.muted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                child: Text(isKorean ? '구독 관리 열기' : 'Open Subscriptions'),
              ),
            ],
          ),
        );
        if (openSubs == true) {
          await _launchUrl('https://play.google.com/store/account/subscriptions');
        }
      }
    }
  }

  void _showAboutDialog(BuildContext context, bool isKorean) {
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
              isKorean ? '\ubc84\uc804 1.19.2' : 'Version 1.19.2',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              isKorean
                  ? '\ub208\uc73c\ub85c \ubcf4\ub294 \uacfc\ud559 - \ubb3c\ub9ac, \uc218\ud559, AI \ub4f1\uc758 \uac1c\ub150\uc744 \uc778\ud130\ub799\ud2f0\ube0c \uc2dc\ubbac\ub808\uc774\uc158\uc73c\ub85c \ubc30\uc6cc\ubcf4\uc138\uc694.'
                  : 'See Science Come Alive - Learn physics, math, AI and more through interactive simulations.',
              style: TextStyle(color: AppColors.ink, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              isKorean ? '\ud2b9\uc9d5:' : 'Features:',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _FeatureItem(text: isKorean ? '${getSimulations().length}\uac1c \uc778\ud130\ub799\ud2f0\ube0c \uc2dc\ubbac\ub808\uc774\uc158' : '${getSimulations().length} Interactive Simulations'),
            _FeatureItem(text: isKorean ? '\ubb3c\ub9ac, \uc218\ud559, AI/ML, \uce74\uc624\uc2a4 \uc774\ub860' : 'Physics, Math, AI/ML, Chaos Theory'),
            _FeatureItem(text: isKorean ? '\uc9c1\uc811 \uc870\uc791\ud558\uba70 \uc6d0\ub9ac \uc774\ud574' : 'Learn by interacting'),
            _FeatureItem(text: isKorean ? '\uc9c0\uc18d\uc801\uc778 \uc5c5\ub370\uc774\ud2b8' : 'Continuous updates'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isKorean ? '\ub2eb\uae30' : 'Close', style: TextStyle(color: AppColors.accent)),
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
                      '\uc5b8\uc5b4 / Language',
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

/// AI 무제한 구독 카드 (₩2,990)
class _AiSubscriptionCard extends ConsumerWidget {
  final bool isKorean;
  const _AiSubscriptionCard({required this.isKorean});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final isAiPro = sub.isAiUnlimited;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isAiPro ? Colors.green.withValues(alpha: 0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isAiPro
              ? null
              : () => ref.read(subscriptionProvider.notifier).purchaseAiUnlimited(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAiPro ? Colors.green.withValues(alpha: 0.3) : AppColors.accent.withValues(alpha: 0.4),
                width: isAiPro ? 1 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAiPro
                        ? Colors.green.withValues(alpha: 0.15)
                        : AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAiPro ? Icons.check_circle : Icons.auto_awesome,
                    color: isAiPro ? Colors.green : AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isKorean ? 'AI 무제한 + 광고 제거' : 'AI Unlimited + Ad-Free',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAiPro
                            ? (isKorean ? '구독 중 — Pro 모델, AI 해설·튜터 무제한' : 'Active — Pro model, unlimited AI')
                            : (isKorean ? '₩2,990/월 — GPT-4o Pro, AI 해설·튜터 무제한' : '₩2,990/mo — GPT-4o Pro, unlimited AI'),
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isAiPro)
                  Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AI 튜터 페르소나 선택기 (Lottie 캐릭터 미리보기) — 4열 그리드
class _PersonaSelector extends ConsumerWidget {
  final bool isKorean;

  const _PersonaSelector({required this.isKorean});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedPersonaIdProvider);

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.75,
      children: aiPersonas.map((persona) {
        final isSelected = persona.id == selectedId;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(selectedPersonaIdProvider.notifier).select(persona.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? persona.color.withValues(alpha: 0.12)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? persona.color.withValues(alpha: 0.6)
                    : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: LottieCharacter(
                    personaId: persona.id,
                    mode: RiveCharacterMode.idle,
                    size: 40,
                    visible: true,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  persona.name(isKorean),
                  style: TextStyle(
                    color: isSelected ? persona.color : AppColors.muted,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle, size: 12, color: persona.color),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
