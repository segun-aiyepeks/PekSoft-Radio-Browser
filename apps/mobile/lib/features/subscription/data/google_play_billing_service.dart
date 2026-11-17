import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/api_client.dart';
import 'package:peksoft_radio/features/subscription/domain/billing_service.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement_repository.dart';

/// Production [BillingService] backed by `in_app_purchase` (`plus_monthly` and
/// `plus_annual`), acknowledging purchases and verifying every purchase token
/// server-side via `POST /v1/billing/google-play/verify`.
class GooglePlayBillingService implements BillingService {
  GooglePlayBillingService({
    required this.apiClient,
    required this.entitlementRepository,
    InAppPurchase? inAppPurchase,
  }) : _iapOverride = inAppPurchase;

  final ApiClient apiClient;
  final EntitlementRepository entitlementRepository;
  final InAppPurchase? _iapOverride;

  ApiClient get _apiClient => apiClient;
  EntitlementRepository get _entitlementRepository => entitlementRepository;

  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  final StreamController<BillingPurchaseUpdate> _updatesController =
      StreamController<BillingPurchaseUpdate>.broadcast();
  final Map<String, ProductDetails> _productCache = <String, ProductDetails>{};

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  void _ensureListening() {
    _purchaseSub ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _updatesController.add(
          BillingPurchaseUpdate(
            state: BillingPurchaseState.error,
            error: AppFailure.network(message: 'Billing stream error: $error'),
          ),
        );
      },
    );
  }

  @override
  Stream<BillingPurchaseUpdate> get purchaseUpdates {
    _ensureListening();
    return _updatesController.stream;
  }

  @override
  Future<bool> isStoreAvailable() async {
    try {
      return await _iap.isAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<StoreProduct>> loadProducts() async {
    _ensureListening();
    final bool available = await isStoreAvailable();
    if (!available) {
      return const <StoreProduct>[];
    }

    final ProductDetailsResponse response = await _iap.queryProductDetails(
      BillingProductIds.all,
    );
    _productCache.clear();
    for (final ProductDetails details in response.productDetails) {
      _productCache[details.id] = details;
    }

    return response.productDetails
        .map(
          (ProductDetails d) => StoreProduct(
            id: d.id,
            title: d.title,
            description: d.description,
            price: d.price,
            rawPrice: d.rawPrice,
            currencyCode: d.currencyCode,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> purchaseSubscription(
    String productId, {
    String? obfuscatedAccountId,
  }) async {
    _ensureListening();
    ProductDetails? details = _productCache[productId];
    if (details == null) {
      await loadProducts();
      details = _productCache[productId];
    }
    if (details == null) {
      _updatesController.add(
        BillingPurchaseUpdate(
          state: BillingPurchaseState.error,
          productId: productId,
          error: AppFailure.validation(
            message: 'Subscription plan "$productId" is unavailable right now.',
          ),
        ),
      );
      return;
    }

    final PurchaseParam param = PurchaseParam(
      productDetails: details,
      applicationUserName: obfuscatedAccountId,
    );
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<void> restorePurchases() async {
    _ensureListening();
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _updatesController.add(
            BillingPurchaseUpdate(
              state: BillingPurchaseState.pending,
              productId: purchase.productID,
            ),
          );
        case PurchaseStatus.canceled:
          _updatesController.add(
            BillingPurchaseUpdate(
              state: BillingPurchaseState.canceled,
              productId: purchase.productID,
            ),
          );
        case PurchaseStatus.error:
          _updatesController.add(
            BillingPurchaseUpdate(
              state: BillingPurchaseState.error,
              productId: purchase.productID,
              error: AppFailure.network(
                message:
                    purchase.error?.message ??
                    'Purchase could not be completed.',
              ),
            ),
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndAcknowledge(purchase);
      }
    }
  }

  Future<void> _verifyAndAcknowledge(PurchaseDetails purchase) async {
    final String purchaseToken =
        purchase.verificationData.serverVerificationData;
    final Result<Map<String, dynamic>> verifyRes = await _apiClient
        .verifyGooglePlayPurchase(
          productId: purchase.productID,
          purchaseToken: purchaseToken,
        );

    switch (verifyRes) {
      case Success<Map<String, dynamic>>():
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        final Result<Entitlement> refreshed = await _entitlementRepository
            .refreshEntitlement();
        final Entitlement? entitlement = switch (refreshed) {
          Success<Entitlement>(:final data) => data,
          Failure<Entitlement>() => null,
        };
        _updatesController.add(
          BillingPurchaseUpdate(
            state: purchase.status == PurchaseStatus.restored
                ? BillingPurchaseState.restored
                : BillingPurchaseState.verified,
            productId: purchase.productID,
            entitlement: entitlement,
          ),
        );
      case Failure<Map<String, dynamic>>(:final error):
        _updatesController.add(
          BillingPurchaseUpdate(
            state: BillingPurchaseState.error,
            productId: purchase.productID,
            error: error,
          ),
        );
    }
  }

  @override
  void dispose() {
    unawaited(_purchaseSub?.cancel());
    _purchaseSub = null;
    unawaited(_updatesController.close());
  }
}
