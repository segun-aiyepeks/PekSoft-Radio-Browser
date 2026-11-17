import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/network/api_client.dart';
import 'package:peksoft_radio/features/auth/domain/auth_repository.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';
import 'package:peksoft_radio/features/subscription/data/google_play_billing_service.dart';
import 'package:peksoft_radio/features/subscription/domain/billing_service.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

import 'helpers/fake_auth_repository.dart';

class _QueuedHttpClientAdapter implements HttpClientAdapter {
  final List<ResponseBody Function(RequestOptions options)> handlers =
      <ResponseBody Function(RequestOptions options)>[];
  final List<RequestOptions> requests = <RequestOptions>[];

  void enqueueJson(int statusCode, Map<String, dynamic> body) {
    handlers.add(
      (_) => ResponseBody.fromString(
        jsonEncode(body),
        statusCode,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (handlers.isEmpty) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Offline',
      );
    }
    return handlers.removeAt(0)(options);
  }

  @override
  void close({bool force = false}) {}
}

class _FakeInAppPurchase implements InAppPurchase {
  final StreamController<List<PurchaseDetails>> _streamController =
      StreamController<List<PurchaseDetails>>.broadcast();

  final List<PurchaseParam> buyCalls = <PurchaseParam>[];
  final List<PurchaseDetails> completedPurchases = <PurchaseDetails>[];
  int restoreCalls = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _streamController.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: <ProductDetails>[
        ProductDetails(
          id: BillingProductIds.plusMonthly,
          title: 'PekSoft Plus Monthly',
          description: 'Monthly subscription',
          price: '₦1,500',
          rawPrice: 1500,
          currencyCode: 'NGN',
        ),
        ProductDetails(
          id: BillingProductIds.plusAnnual,
          title: 'PekSoft Plus Annual',
          description: 'Annual subscription',
          price: '₦12,000',
          rawPrice: 12000,
          currencyCode: 'NGN',
        ),
      ],
      notFoundIDs: const <String>[],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCalls.add(purchaseParam);
    _streamController.add(<PurchaseDetails>[
      PurchaseDetails(
        purchaseID: 'GPA.1000-2000',
        productID: purchaseParam.productDetails.id,
        verificationData: PurchaseVerificationData(
          localVerificationData: '{}',
          serverVerificationData: 'gp-purchase-token-123456',
          source: 'google_play',
        ),
        transactionDate: '1794906000000',
        status: PurchaseStatus.purchased,
      )..pendingCompletePurchase = true,
    ]);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoreCalls += 1;
    _streamController.add(<PurchaseDetails>[
      PurchaseDetails(
        purchaseID: 'GPA.1000-2000',
        productID: BillingProductIds.plusAnnual,
        verificationData: PurchaseVerificationData(
          localVerificationData: '{}',
          serverVerificationData: 'gp-purchase-token-123456',
          source: 'google_play',
        ),
        transactionDate: '1794906000000',
        status: PurchaseStatus.restored,
      )..pendingCompletePurchase = false,
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Milestone 5.3 — GooglePlayBillingService', () {
    test(
      'loads plus_monthly/plus_annual, verifies purchases server-side, acknowledges, and restores',
      () async {
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);

        final _QueuedHttpClientAdapter adapter = _QueuedHttpClientAdapter();
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.peksoft.test'));
        dio.httpClientAdapter = adapter;

        final ApiClient apiClient = ApiClient(
          dio: dio,
          getIdToken: ({bool forceRefresh = false}) async => 'jwt-ada',
        );
        final FakeAuthRepository auth = FakeAuthRepository(
          initialUser: const AuthUser(
            uid: 'uid-ada',
            email: 'ada@example.com',
            emailVerified: true,
          ),
        );
        final EntitlementRepositoryImpl entRepo = EntitlementRepositoryImpl(
          apiClient: apiClient,
          authRepository: auth,
          database: db,
        );
        final _FakeInAppPurchase fakeIap = _FakeInAppPurchase();
        final GooglePlayBillingService billing = GooglePlayBillingService(
          apiClient: apiClient,
          entitlementRepository: entRepo,
          inAppPurchase: fakeIap,
        );
        addTearDown(billing.dispose);

        final List<BillingPurchaseUpdate> updates = <BillingPurchaseUpdate>[];
        final StreamSubscription<BillingPurchaseUpdate> sub = billing
            .purchaseUpdates
            .listen(updates.add);
        addTearDown(sub.cancel);

        // 1. Load products
        final List<StoreProduct> products = await billing.loadProducts();
        expect(products.map((StoreProduct p) => p.id), <String>[
          BillingProductIds.plusMonthly,
          BillingProductIds.plusAnnual,
        ]);

        // 2. Purchase plus_annual -> server verify -> acknowledge -> refresh entitlement
        adapter.enqueueJson(200, <String, dynamic>{
          'applied': true,
          'entitlement': <String, dynamic>{'tier': 'PLUS'},
        });
        adapter.enqueueJson(200, <String, dynamic>{
          'entitlement': <String, dynamic>{
            'tier': 'PLUS',
            'status': 'ACTIVE',
            'source': 'google_play',
            'adsEnabled': false,
            'expiresAt': '2027-11-17T09:00:00.000Z',
            'limits': <String, dynamic>{
              'maxFavorites': null,
              'maxCollections': null,
              'maxRecentlyPlayed': 200,
              'maxSongHistory': null,
            },
          },
        });

        final Future<BillingPurchaseUpdate> verifiedFuture = billing
            .purchaseUpdates
            .firstWhere((u) => u.state == BillingPurchaseState.verified);

        await billing.purchaseSubscription(
          BillingProductIds.plusAnnual,
          obfuscatedAccountId: 'uid-ada',
        );
        await verifiedFuture;

        expect(fakeIap.buyCalls.length, 1);
        expect(fakeIap.completedPurchases.length, 1);
        expect(adapter.requests.first.path, '/v1/billing/google-play/verify');
        expect(updates.last.state, BillingPurchaseState.verified);
        expect(updates.last.entitlement?.tier, EntitlementTier.pro);

        // 3. Restore purchases -> re-verifies server-side
        adapter.enqueueJson(200, <String, dynamic>{
          'applied': false,
          'entitlement': <String, dynamic>{'tier': 'PLUS'},
        });
        adapter.enqueueJson(200, <String, dynamic>{
          'entitlement': <String, dynamic>{
            'tier': 'PLUS',
            'status': 'ACTIVE',
            'source': 'google_play',
            'adsEnabled': false,
            'expiresAt': '2027-11-17T09:00:00.000Z',
            'limits': <String, dynamic>{
              'maxFavorites': null,
              'maxCollections': null,
              'maxRecentlyPlayed': 200,
              'maxSongHistory': null,
            },
          },
        });

        final Future<BillingPurchaseUpdate> restoredFuture = billing
            .purchaseUpdates
            .firstWhere((u) => u.state == BillingPurchaseState.restored);
        await billing.restorePurchases();
        await restoredFuture;
        expect(fakeIap.restoreCalls, 1);
        expect(updates.last.state, BillingPurchaseState.restored);
      },
    );
  });
}
