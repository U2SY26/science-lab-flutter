import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 구독 상품 ID
const String kRemoveAdsProductId = 'remove_ads_monthly';

/// 구독 상태 Provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

/// 구독 상태
class SubscriptionState {
  final bool isSubscribed;
  final bool isLoading;
  final String? errorMessage;
  final List<ProductDetails> products;

  const SubscriptionState({
    this.isSubscribed = false,
    this.isLoading = true,
    this.errorMessage,
    this.products = const [],
  });

  SubscriptionState copyWith({
    bool? isSubscribed,
    bool? isLoading,
    String? errorMessage,
    List<ProductDetails>? products,
  }) {
    return SubscriptionState(
      isSubscribed: isSubscribed ?? this.isSubscribed,
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
    // 웹이나 지원하지 않는 플랫폼 체크
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
    final isSubscribed = prefs.getBool('isSubscribed') ?? false;
    state = state.copyWith(isSubscribed: isSubscribed);
  }

  Future<void> _saveSubscriptionStatus(bool isSubscribed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSubscribed', isSubscribed);
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({kRemoveAdsProductId});

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
      // 결제 대기 중
      state = state.copyWith(isLoading: true);
    } else if (purchase.status == PurchaseStatus.error) {
      // 결제 오류
      state = state.copyWith(
        isLoading: false,
        errorMessage: purchase.error?.message ?? '결제 중 오류가 발생했습니다',
      );
    } else if (purchase.status == PurchaseStatus.purchased ||
               purchase.status == PurchaseStatus.restored) {
      // 결제 완료 또는 복원
      if (purchase.productID == kRemoveAdsProductId) {
        state = state.copyWith(isSubscribed: true, isLoading: false);
        await _saveSubscriptionStatus(true);
      }
    } else if (purchase.status == PurchaseStatus.canceled) {
      state = state.copyWith(isLoading: false);
    }

    // 구매 완료 처리
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// 구독 구매
  Future<void> purchaseSubscription() async {
    if (state.products.isEmpty) {
      state = state.copyWith(errorMessage: '상품 정보를 불러올 수 없습니다');
      return;
    }

    final product = state.products.firstWhere(
      (p) => p.id == kRemoveAdsProductId,
      orElse: () => state.products.first,
    );

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      // 구독 상품이므로 buyNonConsumable 사용
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
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
