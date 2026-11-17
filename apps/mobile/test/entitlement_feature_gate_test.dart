import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/api_client.dart';
import 'package:peksoft_radio/features/auth/domain/auth_repository.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/feature_gate.dart';

import 'helpers/fake_auth_repository.dart';

class _QueuedHttpClientAdapter implements HttpClientAdapter {
  final List<ResponseBody Function(RequestOptions options)> handlers =
      <ResponseBody Function(RequestOptions options)>[];

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

void main() {
  group('Milestone 5.1 — Shared FeatureGate & EntitlementRepositoryImpl', () {
    test(
      'PlanFeatureGates.free and PlanFeatureGates.plus match packages/shared/feature-gates.json',
      () {
        final File sharedFile = File(
          '../../packages/shared/feature-gates.json',
        );
        final Map<String, dynamic> raw =
            jsonDecode(sharedFile.readAsStringSync()) as Map<String, dynamic>;
        final Map<String, dynamic> plans = raw['plans'] as Map<String, dynamic>;

        final PlanFeatureGates parsedFree = PlanFeatureGates.fromJson(
          plans['FREE'] as Map<String, dynamic>,
        );
        final PlanFeatureGates parsedPlus = PlanFeatureGates.fromJson(
          plans['PLUS'] as Map<String, dynamic>,
        );

        expect(parsedFree, PlanFeatureGates.free);
        expect(parsedPlus, PlanFeatureGates.plus);
      },
    );

    test(
      'FeatureGate enforces Free vs Plus rules and 24h rewarded-ad pass',
      () {
        final DateTime now = DateTime.utc(2026, 11, 16, 12);
        const FeatureGate freeGate = FeatureGate(Entitlement());

        expect(freeGate.isPlus, isFalse);
        expect(freeGate.adsEnabled, isTrue);
        expect(freeGate.maxFavourites, 30);
        expect(freeGate.canAddFavourite(29), isTrue);
        expect(freeGate.canAddFavourite(30), isFalse);
        expect(freeGate.maxCollections, 2);
        expect(freeGate.canCreateCollection(1), isTrue);
        expect(freeGate.canCreateCollection(2), isFalse);
        expect(freeGate.maxRecentlyPlayed, 20);
        expect(freeGate.maxSongHistory, 10);
        expect(freeGate.canUseCustomSleepTimer, isFalse);
        expect(freeGate.canUseSleepTimerFadeOut, isFalse);
        expect(freeGate.canUseAdvancedFilters, isFalse);
        expect(freeGate.canUseAlarmClock, isFalse);
        expect(freeGate.canUseEqualizer, isFalse);
        expect(freeGate.canUseAllThemesAndWidgets, isFalse);

        final FeatureGate plusGate = FeatureGate(
          Entitlement(
            tier: EntitlementTier.pro,
            status: EntitlementStatus.active,
            source: EntitlementSource.googlePlay,
            adsEnabled: false,
            expiresAt: now.add(const Duration(days: 30)),
          ),
          now: now,
        );
        expect(plusGate.isPlus, isTrue);
        expect(plusGate.isPaidPlus, isTrue);
        expect(plusGate.adsEnabled, isFalse);
        expect(plusGate.maxFavourites, isNull);
        expect(plusGate.canAddFavourite(500), isTrue);
        expect(plusGate.maxCollections, isNull);
        expect(plusGate.canCreateCollection(50), isTrue);
        expect(plusGate.maxRecentlyPlayed, 200);
        expect(plusGate.maxSongHistory, isNull);
        expect(plusGate.canUseCustomSleepTimer, isTrue);
        expect(plusGate.canUseSleepTimerFadeOut, isTrue);
        expect(plusGate.canUseAdvancedFilters, isTrue);

        // Rewarded ad 24h pass unlocks Plus convenience features temporarily
        final FeatureGate rewardedGate = FeatureGate(
          Entitlement(
            tier: EntitlementTier.free,
            source: EntitlementSource.rewardedAd,
            adsEnabled: false,
            rewardedPlusExpiresAt: now.add(const Duration(hours: 24)),
          ),
          now: now,
        );
        expect(rewardedGate.isPlus, isTrue);
        expect(rewardedGate.isPaidPlus, isFalse);
        expect(rewardedGate.adsEnabled, isFalse);
        expect(rewardedGate.canUseCustomSleepTimer, isTrue);
        expect(rewardedGate.canUseAdvancedFilters, isTrue);

        // Once 24 hours pass, rewarded pass expires automatically
        final FeatureGate expiredRewardGate = FeatureGate(
          rewardedGate.entitlement,
          now: now.add(const Duration(hours: 25)),
        );
        expect(expiredRewardGate.isPlus, isFalse);
        expect(expiredRewardGate.adsEnabled, isTrue);
        expect(expiredRewardGate.canUseCustomSleepTimer, isFalse);
      },
    );

    test(
      'EntitlementRepositoryImpl fetches GET /v1/entitlements, caches offline in AppDatabase, and grants temporary rewarded pass',
      () async {
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);

        final _QueuedHttpClientAdapter adapter = _QueuedHttpClientAdapter();
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.peksoft.test'));
        dio.httpClientAdapter = adapter;

        final FakeAuthRepository auth = FakeAuthRepository(
          initialUser: const AuthUser(
            uid: 'uid-ada',
            email: 'ada@example.com',
            emailVerified: true,
          ),
        );
        final ApiClient apiClient = ApiClient(
          dio: dio,
          getIdToken: ({bool forceRefresh = false}) async => 'jwt-ada',
        );

        DateTime currentClock = DateTime.utc(2026, 11, 16, 12);
        final EntitlementRepositoryImpl repo = EntitlementRepositoryImpl(
          apiClient: apiClient,
          authRepository: auth,
          database: db,
          now: () => currentClock,
        );

        adapter.enqueueJson(200, <String, dynamic>{
          'entitlement': <String, dynamic>{
            'tier': 'PLUS',
            'status': 'ACTIVE',
            'source': 'google_play',
            'adsEnabled': false,
            'expiresAt': '2026-12-16T12:00:00.000Z',
            'limits': <String, dynamic>{
              'maxFavorites': null,
              'maxCollections': null,
              'maxRecentlyPlayed': 200,
              'maxSongHistory': null,
            },
          },
        });

        final Result<Entitlement> first = await repo.refreshEntitlement();
        expect(first, isA<Success<Entitlement>>());
        final Entitlement plusEnt = (first as Success<Entitlement>).data;
        expect(plusEnt.tier, EntitlementTier.pro);
        expect(plusEnt.source, EntitlementSource.googlePlay);
        expect(plusEnt.adsEnabled, isFalse);
        expect(plusEnt.maxRecentlyPlayed, 200);

        // Next call while offline falls back to cached entitlement in AppDatabase
        final Result<Entitlement> offlineFallback = await repo
            .refreshEntitlement();
        expect(offlineFallback, isA<Success<Entitlement>>());
        expect(
          (offlineFallback as Success<Entitlement>).data.tier,
          EntitlementTier.pro,
        );

        // When clock passes expiresAt, cached entitlement gracefully downgrades to Free
        currentClock = DateTime.utc(2026, 12, 17, 12);
        final Result<Entitlement> lapsed = await repo.getEntitlement();
        final Entitlement lapsedEnt = (lapsed as Success<Entitlement>).data;
        expect(lapsedEnt.tier, EntitlementTier.free);
        expect(lapsedEnt.status, EntitlementStatus.expired);
        expect(lapsedEnt.adsEnabled, isTrue);
        expect(lapsedEnt.maxFavourites, 30);

        // Granting 24h rewarded pass works and persists locally
        final Result<Entitlement> rewarded = await repo
            .grantTemporaryRewardedPass();
        final Entitlement rewardedEnt = (rewarded as Success<Entitlement>).data;
        expect(FeatureGate(rewardedEnt, now: currentClock).isPlus, isTrue);
        expect(rewardedEnt.source, EntitlementSource.rewardedAd);
      },
    );
  });
}
