import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/features/library/data/library_repository_impl.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';
import 'package:peksoft_radio/features/subscription/domain/billing_service.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement_repository.dart';
import 'package:peksoft_radio/features/subscription/domain/feature_gate.dart';
import 'package:peksoft_radio/features/subscription/presentation/paywall_screen.dart';
import 'package:peksoft_radio/features/subscription/presentation/subscription_management_screen.dart';

import 'helpers/fake_billing_service.dart';
import 'helpers/mock_repository_overrides.dart';

class _MutableEntitlementRepo implements EntitlementRepository {
  _MutableEntitlementRepo(this.current);

  Entitlement current;

  @override
  Future<Result<Entitlement>> getEntitlement() async =>
      Success<Entitlement>(current);

  @override
  Future<Result<Entitlement>> refreshEntitlement() async =>
      Success<Entitlement>(current);

  @override
  Future<Result<Entitlement>> grantTemporaryRewardedPass({
    Duration duration = const Duration(hours: 24),
  }) async {
    current = current.copyWith(
      source: EntitlementSource.rewardedAd,
      adsEnabled: false,
      rewardedPlusExpiresAt: DateTime.now().add(duration),
    );
    return Success<Entitlement>(current);
  }
}

Station _station(String id) => Station(
  id: id,
  name: 'Station $id',
  streamUrl: 'https://stream.example.com/$id.mp3',
  countryCode: 'NG',
  countryName: 'Nigeria',
);

void main() {
  group('Milestone 5.4 — Paywall & Subscription Lifecycle UI', () {
    testWidgets(
      'PaywallScreen shows store local-currency prices, completes purchase into success state, and supports restore',
      (tester) async {
        final FakeBillingService billing = FakeBillingService();
        final _MutableEntitlementRepo entRepo = _MutableEntitlementRepo(
          const Entitlement(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...mockRepositoryOverrides(billingService: billing),
              entitlementRepositoryProvider.overrideWithValue(entRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const PaywallScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Store-provided local-currency prices (NGN)
        expect(find.text('₦1,500 / mo'), findsOneWidget);
        expect(find.text('₦12,000 / yr'), findsOneWidget);

        // Restore Purchases triggers BillingService.restorePurchases
        await tester.scrollUntilVisible(find.text('Restore Purchases'), 200);
        await tester.tap(find.text('Restore Purchases'));
        await tester.pumpAndSettle();
        expect(billing.restoreCalls, 1);

        // Purchase Annual Plus -> shows success state immediately
        await tester.scrollUntilVisible(
          find.text('Continue with Annual (₦12,000 / yr)'),
          -200,
        );
        await tester.tap(find.text('Continue with Annual (₦12,000 / yr)'));
        await tester.pumpAndSettle();

        expect(billing.lastPurchasedProductId, BillingProductIds.plusAnnual);
        expect(find.text('PekSoft Plus Active'), findsOneWidget);
        expect(find.text('Start Listening'), findsOneWidget);
      },
    );

    testWidgets(
      'SubscriptionManagementScreen displays billing-problem grace banner and manage-subscription deep link',
      (tester) async {
        Uri? launchedUri;
        final _MutableEntitlementRepo graceRepo = _MutableEntitlementRepo(
          Entitlement(
            tier: EntitlementTier.pro,
            status: EntitlementStatus.grace,
            source: EntitlementSource.googlePlay,
            adsEnabled: false,
            expiresAt: DateTime.utc(2027, 1, 1),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...mockRepositoryOverrides(),
              entitlementRepositoryProvider.overrideWithValue(graceRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: SubscriptionManagementScreen(
                onOpenManageSubscription: (Uri uri) async {
                  launchedUri = uri;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Billing problem — grace period active'),
          findsOneWidget,
        );
        expect(find.text('Fix Payment'), findsOneWidget);

        await tester.tap(find.text('Manage Subscription'));
        await tester.pumpAndSettle();
        expect(launchedUri, isNotNull);
        expect(launchedUri!.host, 'play.google.com');
        expect(launchedUri!.queryParameters['package'], 'com.peksoft.radio');
      },
    );

    testWidgets(
      'Graceful downgrade on expiry keeps saved library intact while locking Plus extras',
      (tester) async {
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);

        // User was Plus and saved 35 favourites and 3 custom collections
        final _MutableEntitlementRepo entRepo = _MutableEntitlementRepo(
          Entitlement(
            tier: EntitlementTier.pro,
            status: EntitlementStatus.active,
            source: EntitlementSource.googlePlay,
            adsEnabled: false,
            expiresAt: DateTime.utc(2027, 1, 1),
          ),
        );
        final LibraryRepositoryImpl library = LibraryRepositoryImpl(
          database: db,
          entitlementRepository: entRepo,
        );

        for (int i = 1; i <= 35; i++) {
          expect(
            await library.addFavourite(_station('st-$i')),
            isA<Success<void>>(),
          );
        }
        for (int i = 1; i <= 3; i++) {
          expect(
            await library.saveCollection(
              Collection(id: 'col-$i', title: 'Collection $i'),
            ),
            isA<Success<void>>(),
          );
        }

        // Subscription expires -> graceful downgrade
        entRepo.current = Entitlement(
          tier: EntitlementTier.free,
          status: EntitlementStatus.expired,
          source: EntitlementSource.googlePlay,
          adsEnabled: true,
          expiresAt: DateTime.utc(2026, 11, 1),
        );

        // Nothing is deleted
        final List<Station> savedFavs =
            (await library.getFavourites() as Success<List<Station>>).data;
        final List<Collection> savedCols =
            (await library.getCollections() as Success<List<Collection>>).data;
        expect(savedFavs.length, 35);
        expect(savedCols.length, 3);

        // Plus extras lock: adding a 36th favourite or 4th collection is blocked
        final Result<void> extraFav = await library.addFavourite(
          _station('st-36'),
        );
        expect(extraFav, isA<Failure<void>>());
        expect(
          (extraFav as Failure<void>).error,
          isA<EntitlementRequiredFailure>(),
        );
        expect(FeatureGate(entRepo.current).canUseCustomSleepTimer, isFalse);

        // UI renders the expired notice + Renew Plus CTA
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...mockRepositoryOverrides(),
              entitlementRepositoryProvider.overrideWithValue(entRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const SubscriptionManagementScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Subscription expired'), findsOneWidget);
        expect(find.text('Renew Plus'), findsOneWidget);
      },
    );
  });
}
