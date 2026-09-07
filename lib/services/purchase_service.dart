import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PurchaseService {
  static const String monthlySubscriptionId = 'ahang_premium_monthly';

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  static Future<bool> isAvailable() async {
    return await _iap.isAvailable();
  }

  static Future<ProductDetailsResponse> getProducts() async {
    return await _iap.queryProductDetails({monthlySubscriptionId});
  }

  static void startListening({
    required Function(String message) onError,
    required Function() onSuccess,
  }) {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
          (purchases) => _handlePurchaseUpdates(purchases, onError, onSuccess),
      onError: (error) => onError(error.toString()),
    );
  }

  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  static Future<void> buySubscription(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases,
      Function(String) onError,
      Function() onSuccess,
      ) async {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        onError(purchase.error?.message ?? 'Naməlum xəta');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _grantPremium();
        onSuccess();
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  static Future<void> _grantPremium() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isPremium': true,
      'premiumSince': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
}