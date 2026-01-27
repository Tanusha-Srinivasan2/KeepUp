import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ POLICY COMPLIANCE: Google Play Billing Service
/// Manages subscriptions using ONLY Google Play Billing API (no external payment processors)
class SubscriptionService {
  static const String productId = 'keepup_premium_monthly';
  static const String _premiumKey = 'is_premium';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isInitialized = false;

  /// Initialize the subscription service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;

    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify and deliver the product
        await _verifyAndDeliverProduct(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Verify and activate premium subscription
  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    // In production, verify the purchase with your backend
    // For now, we'll trust the Google Play response
    if (purchaseDetails.productID == productId) {
      await setPremiumStatus(true);
      debugPrint('✅ Premium subscription activated');
    }
  }

  /// Check if subscription products are available
  Future<bool> isAvailable() async {
    return await _inAppPurchase.isAvailable();
  }

  /// Query product details from Google Play
  Future<ProductDetails?> getProductDetails() async {
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails({productId});

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('❌ Product not found: ${response.notFoundIDs}');
      return null;
    }

    if (response.productDetails.isEmpty) {
      return null;
    }

    return response.productDetails.first;
  }

  /// Purchase the premium subscription
  Future<bool> purchaseSubscription() async {
    final ProductDetails? productDetails = await getProductDetails();

    if (productDetails == null) {
      debugPrint('❌ Cannot purchase - product not available');
      return false;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      debugPrint('❌ Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('❌ Restore error: $e');
    }
  }

  /// Check if user has active premium subscription
  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  /// Set premium status (called after successful purchase)
  Future<void> setPremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, isPremium);
  }

  /// Check subscription status by restoring purchases
  /// The result will come through purchaseStream
  Future<bool> checkSubscriptionStatus() async {
    try {
      // Trigger restore - the listener will update premium status
      await _inAppPurchase.restorePurchases();

      // Wait a moment for the stream to process
      await Future.delayed(const Duration(milliseconds: 500));

      // Return current stored status
      return await isPremium();
    } catch (e) {
      debugPrint('❌ Error checking subscription: $e');
      return await isPremium();
    }
  }

  /// Dispose the service
  void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
  }
}
