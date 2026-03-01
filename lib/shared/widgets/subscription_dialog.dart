import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/subscription_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/language_provider.dart';

/// 구독 구매 다이얼로그 (3-tier)
class SubscriptionDialog extends ConsumerWidget {
  const SubscriptionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SubscriptionDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final notifier = ref.read(subscriptionProvider.notifier);
    final isKorean = ref.watch(isKoreanProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // 타이틀
            Text(
              isKorean ? '구독 플랜' : 'Subscription Plans',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isKorean ? '학습 경험을 업그레이드하세요' : 'Upgrade your learning experience',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            // 에러 메시지
            if (subscription.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subscription.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Tier 1: 광고 제거
            _SubscriptionTier(
              icon: Icons.block,
              iconColor: AppColors.accent,
              title: isKorean ? '광고 제거' : 'Remove Ads',
              price: isKorean ? '월 ₩990' : '₩990/mo',
              benefits: [
                isKorean ? '배너·전면 광고 제거' : 'Remove banner & interstitial ads',
                isKorean ? '더 깔끔한 학습 환경' : 'Cleaner learning experience',
              ],
              isActive: subscription.isSubscribed,
              isLoading: subscription.isLoading,
              onTap: () => notifier.purchaseSubscription(),
              activeLabel: isKorean ? '활성화됨' : 'Active',
            ),
            const SizedBox(height: 12),

            // Tier 2: AI 해설 무제한
            _SubscriptionTier(
              icon: Icons.auto_awesome,
              iconColor: const Color(0xFF7C3AED),
              title: isKorean ? 'AI 해설 무제한' : 'AI Unlimited',
              price: isKorean ? '월 ₩2,990' : '₩2,990/mo',
              benefits: [
                isKorean ? 'AI 해설 무제한 사용' : 'Unlimited AI explanations',
                isKorean ? '4단계 수준별 해설' : '4-level explanations',
              ],
              isActive: subscription.isAiUnlimited && !subscription.isAiAssist,
              isLoading: subscription.isLoading,
              onTap: () => notifier.purchaseAiUnlimited(),
              activeLabel: isKorean ? '활성화됨' : 'Active',
            ),
            const SizedBox(height: 12),

            // Tier 3: AI 챗봇 (추천)
            _SubscriptionTier(
              icon: Icons.smart_toy,
              iconColor: const Color(0xFF3B82F6),
              title: isKorean ? 'AI 챗봇' : 'AI Chatbot',
              price: isKorean ? '월 ₩4,990' : '₩4,990/mo',
              benefits: [
                isKorean ? 'AI 해설 무제한 포함' : 'Includes unlimited AI explanations',
                isKorean ? 'AI 채팅 에이전트' : 'AI chat agent',
                isKorean ? '시뮬레이션 맞춤 Q&A' : 'Simulation-aware Q&A',
              ],
              isActive: subscription.isAiAssist,
              isLoading: subscription.isLoading,
              onTap: () => notifier.purchaseAiAssist(),
              isRecommended: true,
              activeLabel: isKorean ? '활성화됨' : 'Active',
            ),
            const SizedBox(height: 16),

            // 구매 복원
            TextButton(
              onPressed: subscription.isLoading
                  ? null
                  : () => notifier.restorePurchases(),
              child: Text(
                isKorean ? '구매 복원' : 'Restore Purchases',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),

            // 약관
            Text(
              isKorean ? '구독은 언제든지 취소할 수 있습니다' : 'You can cancel your subscription at any time',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.muted.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 구독 티어 카드
class _SubscriptionTier extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String price;
  final List<String> benefits;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isRecommended;
  final String activeLabel;

  const _SubscriptionTier({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.price,
    required this.benefits,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
    this.isRecommended = false,
    required this.activeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecommended
            ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
            : AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? iconColor.withValues(alpha: 0.6)
              : isRecommended
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                  : AppColors.cardBorder,
          width: isActive || isRecommended ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              // 타이틀 + 가격
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BEST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      price,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // 버튼
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activeLabel,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.arrow_forward, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 혜택 목록
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: iconColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
