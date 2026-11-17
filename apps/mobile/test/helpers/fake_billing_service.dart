import 'dart:async';

import 'package:peksoft_radio/features/subscription/domain/billing_service.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

class FakeBillingService implements BillingService {
  FakeBillingService({this.storeAvailable = true, List<StoreProduct>? products})
    : _products =
          products ??
          const <StoreProduct>[
            StoreProduct(
              id: BillingProductIds.plusMonthly,
              title: 'PekSoft Plus Monthly',
              description: 'Ad-free radio & unlimited library',
              price: '₦1,500',
              rawPrice: 1500,
              currencyCode: 'NGN',
            ),
            StoreProduct(
              id: BillingProductIds.plusAnnual,
              title: 'PekSoft Plus Annual',
              description: 'Save 33% on PekSoft Plus',
              price: '₦12,000',
              rawPrice: 12000,
              currencyCode: 'NGN',
            ),
          ];

  final bool storeAvailable;
  final List<StoreProduct> _products;
  final StreamController<BillingPurchaseUpdate> _controller =
      StreamController<BillingPurchaseUpdate>.broadcast();

  String? lastPurchasedProductId;
  int restoreCalls = 0;

  @override
  Stream<BillingPurchaseUpdate> get purchaseUpdates => _controller.stream;

  @override
  Future<bool> isStoreAvailable() async => storeAvailable;

  @override
  Future<List<StoreProduct>> loadProducts() async => _products;

  @override
  Future<void> purchaseSubscription(
    String productId, {
    String? obfuscatedAccountId,
  }) async {
    lastPurchasedProductId = productId;
    _controller.add(
      BillingPurchaseUpdate(
        state: BillingPurchaseState.verified,
        productId: productId,
        entitlement: Entitlement(
          tier: EntitlementTier.pro,
          status: EntitlementStatus.active,
          source: EntitlementSource.googlePlay,
          adsEnabled: false,
          expiresAt: DateTime.utc(2027, 11, 17),
        ),
      ),
    );
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls += 1;
    _controller.add(
      const BillingPurchaseUpdate(
        state: BillingPurchaseState.restored,
        productId: BillingProductIds.plusAnnual,
      ),
    );
  }

  void emitUpdate(BillingPurchaseUpdate update) {
    _controller.add(update);
  }

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}
