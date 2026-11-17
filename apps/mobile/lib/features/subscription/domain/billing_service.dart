import 'package:flutter/foundation.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

/// Canonical Google Play subscription product IDs (created as base plans in
/// Google Play Console).
abstract final class BillingProductIds {
  static const String plusMonthly = 'plus_monthly';
  static const String plusAnnual = 'plus_annual';

  static const Set<String> all = <String>{plusMonthly, plusAnnual};
}

/// Store-provided product details with local currency pricing from Google Play.
@immutable
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final String currencyCode;
}

/// Lifecycle state emitted during a Google Play purchase or restore flow.
enum BillingPurchaseState { pending, verified, restored, canceled, error }

@immutable
class BillingPurchaseUpdate {
  const BillingPurchaseUpdate({
    required this.state,
    this.productId,
    this.entitlement,
    this.error,
  });

  final BillingPurchaseState state;
  final String? productId;
  final Entitlement? entitlement;
  final AppFailure? error;
}

/// Abstraction over `in_app_purchase` for Google Play Billing.
abstract interface class BillingService {
  Stream<BillingPurchaseUpdate> get purchaseUpdates;

  Future<bool> isStoreAvailable();

  Future<List<StoreProduct>> loadProducts();

  Future<void> purchaseSubscription(
    String productId, {
    String? obfuscatedAccountId,
  });

  Future<void> restorePurchases();

  void dispose();
}
