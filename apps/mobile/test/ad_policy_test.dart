import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/ads/ad_config.dart';
import 'package:peksoft_radio/core/ads/ad_policy.dart';
import 'package:peksoft_radio/core/ads/ad_service.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/feature_gate.dart';

import 'helpers/fake_ad_service.dart';

void main() {
  group('Milestone 5.2 — AdConfig, AdPolicy & 24h Rewarded Ad Pass', () {
    test(
      'AdConfig uses Google test unit IDs only in debug builds and never in release without overrides',
      () {
        const AdConfig debugConfig = AdConfig(isDebugMode: true);
        expect(debugConfig.bannerAdUnitId, AdConfig.googleTestAdaptiveBannerId);
        expect(debugConfig.nativeAdUnitId, AdConfig.googleTestNativeAdvancedId);
        expect(
          debugConfig.interstitialAdUnitId,
          AdConfig.googleTestInterstitialId,
        );
        expect(debugConfig.rewardedAdUnitId, AdConfig.googleTestRewardedId);

        const AdConfig releaseNoEnv = AdConfig(isDebugMode: false);
        expect(releaseNoEnv.bannerAdUnitId, isNull);
        expect(releaseNoEnv.nativeAdUnitId, isNull);
        expect(releaseNoEnv.interstitialAdUnitId, isNull);
        expect(releaseNoEnv.rewardedAdUnitId, isNull);

        const AdConfig releaseWithEnv = AdConfig(
          isDebugMode: false,
          bannerAdUnitId: 'ca-app-pub-1111/2222',
          nativeAdUnitId: 'ca-app-pub-1111/3333',
          interstitialAdUnitId: 'ca-app-pub-1111/4444',
          rewardedAdUnitId: 'ca-app-pub-1111/5555',
        );
        expect(releaseWithEnv.bannerAdUnitId, 'ca-app-pub-1111/2222');
        expect(releaseWithEnv.nativeAdUnitId, 'ca-app-pub-1111/3333');
        expect(releaseWithEnv.interstitialAdUnitId, 'ca-app-pub-1111/4444');
        expect(releaseWithEnv.rewardedAdUnitId, 'ca-app-pub-1111/5555');
      },
    );

    test('AdPolicy blocks ALL ads before first sound is reached', () {
      final AdPolicy policy = AdPolicy(
        now: () => DateTime.utc(2026, 11, 16, 12),
      );
      const Entitlement freeEnt = Entitlement();

      expect(policy.hasReachedFirstSound, isFalse);
      expect(
        policy.canShowBanner(entitlement: freeEnt, route: '/home'),
        isFalse,
      );
      expect(
        policy.shouldInsertNativeAdAfterRow(
          entitlement: freeEnt,
          route: '/home',
          stationRowIndex: 7,
          totalStationRows: 20,
        ),
        isFalse,
      );
      expect(
        policy.canShowInterstitial(
          entitlement: freeEnt,
          route: '/home',
          trigger: AdBreakTrigger.completedBrowseFlow,
        ),
        isFalse,
      );

      // Once first sound is recorded, browse/list ads become eligible
      policy.recordFirstSound();
      expect(policy.hasReachedFirstSound, isTrue);
      expect(
        policy.canShowBanner(entitlement: freeEnt, route: '/home'),
        isTrue,
      );
    });

    test(
      'AdPolicy blocks ads on auth, onboarding, paywall, and player-control screens',
      () {
        final AdPolicy policy = AdPolicy(
          now: () => DateTime.utc(2026, 11, 16, 12),
        )..recordFirstSound();
        const Entitlement freeEnt = Entitlement();

        const List<String> bannedRoutes = <String>[
          '/',
          '/splash',
          '/welcome',
          '/auth',
          '/auth/sign-in',
          '/auth/sign-up',
          '/auth/verify-email',
          '/auth/forgot-password',
          '/auth/reset-password',
          '/paywall',
          '/subscription',
          '/player',
          '/now-playing',
          '/mini-player',
          '/delete-account',
        ];

        for (final String route in bannedRoutes) {
          expect(
            policy.canShowBanner(entitlement: freeEnt, route: route),
            isFalse,
            reason: 'Expected banner blocked on $route',
          );
          expect(
            policy.canShowInterstitial(
              entitlement: freeEnt,
              route: route,
              trigger: AdBreakTrigger.completedBrowseFlow,
            ),
            isFalse,
            reason: 'Expected interstitial blocked on $route',
          );
        }

        // Also blocked near player controls even on an otherwise allowed route
        expect(
          policy.canShowBanner(
            entitlement: freeEnt,
            route: '/home',
            isNearPlayerControls: true,
          ),
          isFalse,
        );

        // Allowed on browse/list routes
        for (final String route in const <String>[
          '/home',
          '/explore',
          '/country/NG',
          '/genre/afrobeats',
          '/search',
          '/library',
        ]) {
          expect(
            policy.canShowBanner(entitlement: freeEnt, route: route),
            isTrue,
            reason: 'Expected banner allowed on $route',
          );
        }
      },
    );

    test(
      'AdPolicy enforces 10-minute interstitial cooldown and natural-break triggers only',
      () {
        DateTime currentClock = DateTime.utc(2026, 11, 16, 12, 0);
        final AdPolicy policy = AdPolicy(now: () => currentClock)
          ..recordFirstSound();
        const Entitlement freeEnt = Entitlement();

        // Non-natural breaks (launch, firstPlay, startingPlayback) are always blocked
        expect(
          policy.canShowInterstitial(
            entitlement: freeEnt,
            route: '/home',
            trigger: AdBreakTrigger.appLaunch,
          ),
          isFalse,
        );
        expect(
          policy.canShowInterstitial(
            entitlement: freeEnt,
            route: '/home',
            trigger: AdBreakTrigger.firstPlay,
          ),
          isFalse,
        );
        expect(
          policy.canShowInterstitial(
            entitlement: freeEnt,
            route: '/home',
            trigger: AdBreakTrigger.startingPlayback,
          ),
          isFalse,
        );

        // Natural break is allowed initially
        expect(
          policy.canShowInterstitial(
            entitlement: freeEnt,
            route: '/explore',
            trigger: AdBreakTrigger.completedBrowseFlow,
          ),
          isTrue,
        );

        policy.recordInterstitialShown();

        // 9m 59s later: still inside 10-minute cooldown -> blocked
        currentClock = currentClock.add(
          const Duration(minutes: 9, seconds: 59),
        );
        expect(
          policy.canShowInterstitial(
            entitlement: freeEnt,
            route: '/explore',
            trigger: AdBreakTrigger.completedBrowseFlow,
          ),
          isFalse,
        );

        // Exactly 10 minutes later: allowed again
        currentClock = currentClock.add(const Duration(seconds: 1));
        expect(
          policy.canShowInterstitial(
            entitlement: freeEnt,
            route: '/explore',
            trigger: AdBreakTrigger.finishedCollectionEdit,
          ),
          isTrue,
        );
      },
    );

    test(
      'AdPolicy places native ad cards every 8 station rows in long lists only',
      () {
        final AdPolicy policy = AdPolicy(
          now: () => DateTime.utc(2026, 11, 16, 12),
        )..recordFirstSound();
        const Entitlement freeEnt = Entitlement();

        // Short list (< 8 rows) has no native ads
        expect(
          policy.nativeAdInsertionRows(
            entitlement: freeEnt,
            route: '/country/NG',
            totalStationRows: 7,
          ),
          isEmpty,
        );

        // 25 station rows -> native card after 0-based rows 7, 15, 23 (8th, 16th, 24th rows)
        expect(
          policy.nativeAdInsertionRows(
            entitlement: freeEnt,
            route: '/country/NG',
            totalStationRows: 25,
          ),
          <int>[7, 15, 23],
        );

        expect(
          policy.shouldInsertNativeAdAfterRow(
            entitlement: freeEnt,
            route: '/country/NG',
            stationRowIndex: 6,
            totalStationRows: 25,
          ),
          isFalse,
        );
        expect(
          policy.shouldInsertNativeAdAfterRow(
            entitlement: freeEnt,
            route: '/country/NG',
            stationRowIndex: 7,
            totalStationRows: 25,
          ),
          isTrue,
        );
      },
    );

    test(
      'AdPolicy shows nothing at all for Plus users and rewarded ad grants 24h Plus convenience pass that expires on its own',
      () async {
        DateTime currentClock = DateTime.utc(2026, 11, 16, 12, 0);
        final AdPolicy policy = AdPolicy(now: () => currentClock)
          ..recordFirstSound();

        final Entitlement paidPlus = Entitlement(
          tier: EntitlementTier.pro,
          status: EntitlementStatus.active,
          source: EntitlementSource.googlePlay,
          adsEnabled: false,
          expiresAt: currentClock.add(const Duration(days: 30)),
        );

        expect(
          policy.canShowBanner(entitlement: paidPlus, route: '/home'),
          isFalse,
        );
        expect(
          policy.nativeAdInsertionRows(
            entitlement: paidPlus,
            route: '/home',
            totalStationRows: 30,
          ),
          isEmpty,
        );
        expect(
          policy.canShowInterstitial(
            entitlement: paidPlus,
            route: '/home',
            trigger: AdBreakTrigger.completedBrowseFlow,
          ),
          isFalse,
        );
        expect(policy.canOfferRewardedAd(entitlement: paidPlus), isFalse);

        // Free user watches rewarded ad -> unlocks 24 hours of Plus features + ad removal
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);
        final EntitlementRepositoryImpl repo = EntitlementRepositoryImpl(
          database: db,
          now: () => currentClock,
        );
        final FakeAdService adService = FakeAdService(policy: policy);
        expect(
          await adService.runConsentFlowIfRequired(),
          AdConsentStatus.notRequired,
        );

        final Result<Entitlement> rewardRes = await adService
            .showRewardedAdForPlusPass(entitlementRepository: repo);
        expect(rewardRes, isA<Success<Entitlement>>());
        final Entitlement rewardedEnt =
            (rewardRes as Success<Entitlement>).data;

        expect(adService.rewardedAdsShown, 1);
        expect(FeatureGate(rewardedEnt, now: currentClock).isPlus, isTrue);
        expect(
          policy.canShowBanner(entitlement: rewardedEnt, route: '/home'),
          isFalse,
        );

        // 24 hours + 1 minute later: client-side pass expires automatically
        currentClock = currentClock.add(const Duration(hours: 24, minutes: 1));
        final Entitlement after24h =
            (await repo.getEntitlement() as Success<Entitlement>).data;
        expect(FeatureGate(after24h, now: currentClock).isPlus, isFalse);
        expect(
          policy.canShowBanner(entitlement: after24h, route: '/home'),
          isTrue,
        );
      },
    );
  });
}
