import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_service.dart';

/// 상품 ID (Google Play Console 기준)
const String kRemoveAdsProductId = 'remove_ads';  // 광고 제거 (일회성)
const String kAiUnlimitedProductId = 'ai';         // AI 무제한 + 광고제거 (구독)

/// 모든 상품 ID 목록
const Set<String> kAllProductIds = {
  kRemoveAdsProductId,   // 일회성
  kAiUnlimitedProductId, // 구독
};

/// 구독 상태 Provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

/// 편의 Provider: AI 해설 무제한 여부 (ai 구독 시)
final isAiUnlimitedProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isAiUnlimited;
});

/// 편의 Provider: AI PRO 모델 사용 여부 (ai 구독 시)
final isAiProProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isAiUnlimited;
});

/// 편의 Provider: 광고 제거 여부 (광고제거 또는 ai 구독 시)
final isAdsRemovedProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub.isSubscribed || sub.isAiUnlimited;
});

/// 구독 상태
class SubscriptionState {
  final bool isSubscribed;    // 광고 제거 구독
  final bool isAiUnlimited;   // AI 무제한 구독 (광고제거 포함)
  final bool isLoading;
  final String? errorMessage;
  final List<ProductDetails> products;

  const SubscriptionState({
    this.isSubscribed = false,
    this.isAiUnlimited = false,
    this.isLoading = true,
    this.errorMessage,
    this.products = const [],
  });

  SubscriptionState copyWith({
    bool? isSubscribed,
    bool? isAiUnlimited,
    bool? isLoading,
    String? errorMessage,
    List<ProductDetails>? products,
  }) {
    return SubscriptionState(
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isAiUnlimited: isAiUnlimited ?? this.isAiUnlimited,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      products: products ?? this.products,
    );
  }
}

/// 구독 관리 Notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    _init();
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> _init() async {
    if (kIsWeb) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '인앱 구매를 사용할 수 없습니다',
      );
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        state = state.copyWith(errorMessage: error.toString());
      },
    );

    await _loadSubscriptionStatus();
    await _loadProducts();
    await _restorePurchases();
  }

  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isAiUnlimited = prefs.getBool('isAiUnlimited') ?? false;
    state = state.copyWith(
      isSubscribed: prefs.getBool('isSubscribed') ?? false,
      isAiUnlimited: isAiUnlimited,
    );
    // ai 구독 시 IAPService에도 광고 제거 전파
    if (isAiUnlimited) {
      await IAPService().markAdsRemoved();
    }
  }

  Future<void> _saveSubscriptionStatus({
    bool? isSubscribed,
    bool? isAiUnlimited,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (isSubscribed != null) await prefs.setBool('isSubscribed', isSubscribed);
    if (isAiUnlimited != null) await prefs.setBool('isAiUnlimited', isAiUnlimited);
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(kAllProductIds);

    if (response.error != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: response.error!.message,
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      products: response.productDetails,
    );
  }

  Future<void> _restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) {
      state = state.copyWith(isLoading: true);
    } else if (purchase.status == PurchaseStatus.error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: purchase.error?.message ?? '결제 중 오류가 발생했습니다',
      );
    } else if (purchase.status == PurchaseStatus.purchased ||
               purchase.status == PurchaseStatus.restored) {
      await _activateProduct(purchase.productID);
      state = state.copyWith(isLoading: false);
    } else if (purchase.status == PurchaseStatus.canceled) {
      state = state.copyWith(isLoading: false);
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// 상품별 활성화
  Future<void> _activateProduct(String productId) async {
    switch (productId) {
      case kRemoveAdsProductId:
        state = state.copyWith(isSubscribed: true);
        await _saveSubscriptionStatus(isSubscribed: true);
        await IAPService().markAdsRemoved();
        break;
      case kAiUnlimitedProductId:
        // AI 무제한 구독: 광고제거 포함
        state = state.copyWith(isAiUnlimited: true, isSubscribed: true);
        await _saveSubscriptionStatus(isAiUnlimited: true, isSubscribed: true);
        await IAPService().markAdsRemoved();
        break;
    }
  }

  /// 광고 제거 구독 구매
  Future<void> purchaseSubscription() async {
    await _purchaseProduct(kRemoveAdsProductId);
  }

  /// AI 무제한 구독 구매 (광고 제거 포함)
  Future<void> purchaseAiUnlimited() async {
    await _purchaseProduct(kAiUnlimitedProductId);
  }

  Future<void> _purchaseProduct(String productId) async {
    if (state.products.isEmpty) {
      state = state.copyWith(errorMessage: '상품 정보를 불러올 수 없습니다');
      return;
    }

    final product = state.products.cast<ProductDetails?>().firstWhere(
      (p) => p!.id == productId,
      orElse: () => null,
    );

    if (product == null) {
      state = state.copyWith(errorMessage: '상품을 찾을 수 없습니다');
      return;
    }

    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// 구매 복원
  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true);
    await _iap.restorePurchases();
    state = state.copyWith(isLoading: false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
