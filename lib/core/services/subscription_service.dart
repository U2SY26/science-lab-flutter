import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 구독 상품 ID (Google Play Console 기준)
const String kRemoveAdsProductId = 'remove_ads_monthly';
const String kAiUnlimitedProductId = 'ai';       // AI 해설 무제한 ₩2,990/월
const String kAiAssistProductId = 'aiassist';     // AI 챗봇 ₩4,990/월 (해설 무제한 포함)

/// 모든 구독 상품 ID 목록
const Set<String> kAllSubscriptionIds = {
  kRemoveAdsProductId,
  kAiUnlimitedProductId,
  kAiAssistProductId,
};

/// 구독 상태 Provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

/// 편의 Provider: AI 해설 무제한 여부 (ai 또는 aiassist 구독 시)
final isAiUnlimitedProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub.isAiUnlimited || sub.isAiAssist;
});

/// 편의 Provider: AI 챗봇 사용 가능 여부 (aiassist 구독 시)
final isAiAssistProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub.isAiAssist;
});

/// 구독 상태
class SubscriptionState {
  final bool isSubscribed;    // 광고 제거 구독
  final bool isAiUnlimited;   // AI 해설 무제한 구독
  final bool isAiAssist;      // AI 챗봇 구독 (해설 무제한 포함)
  final bool isLoading;
  final String? errorMessage;
  final List<ProductDetails> products;

  const SubscriptionState({
    this.isSubscribed = false,
    this.isAiUnlimited = false,
    this.isAiAssist = false,
    this.isLoading = true,
    this.errorMessage,
    this.products = const [],
  });

  SubscriptionState copyWith({
    bool? isSubscribed,
    bool? isAiUnlimited,
    bool? isAiAssist,
    bool? isLoading,
    String? errorMessage,
    List<ProductDetails>? products,
  }) {
    return SubscriptionState(
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isAiUnlimited: isAiUnlimited ?? this.isAiUnlimited,
      isAiAssist: isAiAssist ?? this.isAiAssist,
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

    // 구매 스트림 리스닝
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        state = state.copyWith(errorMessage: error.toString());
      },
    );

    // 저장된 구독 상태 확인
    await _loadSubscriptionStatus();

    // 상품 정보 로드
    await _loadProducts();

    // 이전 구매 복원
    await _restorePurchases();
  }

  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      isSubscribed: prefs.getBool('isSubscribed') ?? false,
      isAiUnlimited: prefs.getBool('isAiUnlimited') ?? false,
      isAiAssist: prefs.getBool('isAiAssist') ?? false,
    );
  }

  Future<void> _saveSubscriptionStatus({
    bool? isSubscribed,
    bool? isAiUnlimited,
    bool? isAiAssist,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (isSubscribed != null) await prefs.setBool('isSubscribed', isSubscribed);
    if (isAiUnlimited != null) await prefs.setBool('isAiUnlimited', isAiUnlimited);
    if (isAiAssist != null) await prefs.setBool('isAiAssist', isAiAssist);
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(kAllSubscriptionIds);

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

    // 구매 완료 처리
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// 상품별 활성화 처리
  Future<void> _activateProduct(String productId) async {
    switch (productId) {
      case kRemoveAdsProductId:
        state = state.copyWith(isSubscribed: true);
        await _saveSubscriptionStatus(isSubscribed: true);
        break;
      case kAiUnlimitedProductId:
        state = state.copyWith(isAiUnlimited: true);
        await _saveSubscriptionStatus(isAiUnlimited: true);
        break;
      case kAiAssistProductId:
        // AI 챗봇은 AI 해설 무제한 포함
        state = state.copyWith(isAiAssist: true, isAiUnlimited: true);
        await _saveSubscriptionStatus(isAiAssist: true, isAiUnlimited: true);
        break;
    }
  }

  /// 구독 구매 (상품 ID 지정)
  Future<void> purchaseProduct(String productId) async {
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

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// 기존 호환: 광고 제거 구독 구매
  Future<void> purchaseSubscription() async {
    await purchaseProduct(kRemoveAdsProductId);
  }

  /// AI 해설 무제한 구독 구매
  Future<void> purchaseAiUnlimited() async {
    await purchaseProduct(kAiUnlimitedProductId);
  }

  /// AI 챗봇 구독 구매
  Future<void> purchaseAiAssist() async {
    await purchaseProduct(kAiAssistProductId);
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
