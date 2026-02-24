import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/subscription_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/language_provider.dart';

/// 구독 구매 다이얼로그
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
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            const SizedBox(height: 24),

            // 아이콘
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                subscription.isSubscribed ? Icons.check_circle : Icons.block,
                size: 48,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),

            // 제목
            Text(
              subscription.isSubscribed
                  ? (isKorean ? '광고 제거 활성화됨' : 'Ads Removed')
                  : (isKorean ? '광고 제거' : 'Remove Ads'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // 설명
            Text(
              subscription.isSubscribed
                  ? (isKorean ? '광고 없이 앱을 즐기고 계십니다' : 'You are enjoying the app ad-free')
                  : (isKorean ? '월 990원으로 모든 광고를 제거하세요' : 'Remove all ads for \u20a9990/month'),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 혜택 목록
            if (!subscription.isSubscribed) ...[
              _buildBenefit(Icons.block, isKorean ? '배너 광고 제거' : 'Remove banner ads'),
              _buildBenefit(Icons.speed, isKorean ? '더 빠른 앱 실행' : 'Faster app performance'),
              _buildBenefit(Icons.favorite, isKorean ? '개발자 지원' : 'Support the developer'),
              const SizedBox(height: 24),
            ],

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
              const SizedBox(height: 16),
            ],

            // 버튼
            if (!subscription.isSubscribed) ...[
              // 구독 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: subscription.isLoading
                      ? null
                      : () => notifier.purchaseSubscription(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: subscription.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isKorean ? '월 \u20a9990 구독하기' : 'Subscribe \u20a9990/month',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // 구매 복원 버튼
              TextButton(
                onPressed: subscription.isLoading
                    ? null
                    : () => notifier.restorePurchases(),
                child: Text(
                  isKorean ? '구매 복원' : 'Restore Purchases',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ] else ...[
              // 닫기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isKorean ? '확인' : 'OK'),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // 약관
            if (!subscription.isSubscribed)
              Text(
                isKorean ? '구독은 언제든지 취소할 수 있습니다' : 'You can cancel your subscription at any time',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.muted.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
