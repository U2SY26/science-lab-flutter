import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 인앱 구매 서비스 - 광고 제거 구매 관리
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  // 상품 ID
  static const String removeAdsProductId = 'removeads';
  static const String _adsRemovedKey = 'ads_removed';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _adsRemoved = false;
  ProductDetails? _removeAdsProduct;

  // 구매 상태 스트림
  final _adsRemovedController = StreamController<bool>.broadcast();
  Stream<bool> get adsRemovedStream => _adsRemovedController.stream;

  bool get isAvailable => _isAvailable;
  bool get adsRemoved => _adsRemoved;
  ProductDetails? get removeAdsProduct => _removeAdsProduct;

  /// 초기화
  Future<void> initialize() async {
    // 저장된 구매 상태 로드
    final prefs = await SharedPreferences.getInstance();
    _adsRemoved = prefs.getBool(_adsRemovedKey) ?? false;
    _adsRemovedController.add(_adsRemoved);

    // 스토어 사용 가능 여부 확인
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      if (kDebugMode) print('IAP not available');
      return;
    }

    // 구매 스트림 구독
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (error) {
        if (kDebugMode) print('IAP stream error: $error');
      },
    );

    // 상품 정보 로드
    await _loadProducts();

    // 이전 구매 복원
    await restorePurchases();
  }

  /// 상품 정보 로드
  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({removeAdsProductId});

    if (response.error != null) {
      if (kDebugMode) print('IAP query error: ${response.error}');
      return;
    }

    if (response.productDetails.isEmpty) {
      if (kDebugMode) print('No products found');
      return;
    }

    for (var product in response.productDetails) {
      if (product.id == removeAdsProductId) {
        _removeAdsProduct = product;
        if (kDebugMode) print('Product loaded: ${product.title} - ${product.price}');
      }
    }
  }

  /// 구매 업데이트 처리
  void _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.productID == removeAdsProductId) {
        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _handleSuccessfulPurchase(purchase);
            break;
          case PurchaseStatus.error:
            if (kDebugMode) print('Purchase error: ${purchase.error}');
            break;
          case PurchaseStatus.pending:
            if (kDebugMode) print('Purchase pending');
            break;
          case PurchaseStatus.canceled:
            if (kDebugMode) print('Purchase canceled');
            break;
        }

        // 구매 완료 처리
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  /// 구매 성공 처리
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    _adsRemoved = true;
    _adsRemovedController.add(true);

    // 로컬 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adsRemovedKey, true);

    if (kDebugMode) print('Ads removed successfully!');
  }

  /// 광고 제거 구매
  Future<bool> purchaseRemoveAds() async {
    if (!_isAvailable || _removeAdsProduct == null) {
      if (kDebugMode) print('Cannot purchase: store not available or product not loaded');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: _removeAdsProduct!);

    try {
      // 비소모품 구매
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      if (kDebugMode) print('Purchase error: $e');
      return false;
    }
  }

  /// 구매 복원
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _iap.restorePurchases();
    } catch (e) {
      if (kDebugMode) print('Restore error: $e');
    }
  }

  /// 리소스 해제
  void dispose() {
    _subscription?.cancel();
    _adsRemovedController.close();
  }
}
