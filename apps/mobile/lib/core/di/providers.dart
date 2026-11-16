import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/ads/ad_config.dart';
import 'package:peksoft_radio/core/ads/ad_policy.dart';
import 'package:peksoft_radio/core/ads/ad_service.dart';
import 'package:peksoft_radio/core/ads/admob_ad_service.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/api_client.dart';
import 'package:peksoft_radio/core/network/connectivity_service.dart';
import 'package:peksoft_radio/core/network/radio_browser_client.dart';
import 'package:peksoft_radio/core/normalisation/genre_map.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/auth/data/firebase_auth_repository.dart';
import 'package:peksoft_radio/features/auth/domain/auth_repository.dart';
import 'package:peksoft_radio/features/catalog/data/catalog_repository_impl.dart';
import 'package:peksoft_radio/features/catalog/domain/catalog_repository.dart';
import 'package:peksoft_radio/features/library/data/library_repository_impl.dart';
import 'package:peksoft_radio/features/library/data/sync_repository_impl.dart';
import 'package:peksoft_radio/features/library/domain/library_repository.dart';
import 'package:peksoft_radio/features/library/domain/sync_repository.dart';
import 'package:peksoft_radio/features/player/data/just_audio_player_service.dart';
import 'package:peksoft_radio/features/player/domain/audio_player_service.dart';
import 'package:peksoft_radio/features/profile/data/settings_repository_impl.dart';
import 'package:peksoft_radio/features/profile/domain/settings_repository.dart';
import 'package:peksoft_radio/features/station/data/report_queue_repository_impl.dart';
import 'package:peksoft_radio/features/station/data/station_repository_impl.dart';
import 'package:peksoft_radio/features/station/domain/report_queue_repository.dart';
import 'package:peksoft_radio/features/station/domain/station_repository.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement_repository.dart';
import 'package:peksoft_radio/features/subscription/domain/feature_gate.dart';

/// App-wide Riverpod dependency injection providers for Phase 2+ data layer.
///
/// Overridden in unit tests with in-memory databases and fake repositories.
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden at app startup or in tests.',
  );
});

final Provider<GenreMap> genreMapProvider = Provider<GenreMap>((ref) {
  throw UnimplementedError(
    'genreMapProvider must be overridden with loaded genre-map.json.',
  );
});

final Provider<StationNormaliser> stationNormaliserProvider =
    Provider<StationNormaliser>((ref) {
      return StationNormaliser(genreMap: ref.watch(genreMapProvider));
    });

final Provider<RadioBrowserClient> radioBrowserClientProvider =
    Provider<RadioBrowserClient>((ref) {
      return RadioBrowserClient();
    });

final Provider<EntitlementRepository> entitlementRepositoryProvider =
    Provider<EntitlementRepository>((ref) {
      return EntitlementRepositoryImpl(
        apiClient: ref.watch(apiClientProvider),
        authRepository: ref.watch(authRepositoryProvider),
        database: ref.watch(appDatabaseProvider),
      );
    });

final FutureProvider<FeatureGate> featureGateProvider =
    FutureProvider<FeatureGate>((ref) async {
      final Result<Entitlement> res = await ref
          .watch(entitlementRepositoryProvider)
          .getEntitlement();
      final Entitlement entitlement = switch (res) {
        Success<Entitlement>(:final data) => data,
        Failure<Entitlement>() => const Entitlement(),
      };
      return FeatureGate(entitlement);
    });

final Provider<CatalogRepository> catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) {
      return CatalogRepositoryImpl(
        database: ref.watch(appDatabaseProvider),
        client: ref.watch(radioBrowserClientProvider),
        normaliser: ref.watch(stationNormaliserProvider),
      );
    });

final Provider<StationRepository> stationRepositoryProvider =
    Provider<StationRepository>((ref) {
      return StationRepositoryImpl(
        database: ref.watch(appDatabaseProvider),
        client: ref.watch(radioBrowserClientProvider),
        normaliser: ref.watch(stationNormaliserProvider),
      );
    });

final Provider<LibraryRepository> libraryRepositoryProvider =
    Provider<LibraryRepository>((ref) {
      return LibraryRepositoryImpl(
        database: ref.watch(appDatabaseProvider),
        entitlementRepository: ref.watch(entitlementRepositoryProvider),
      );
    });

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) {
      return SettingsRepositoryImpl(database: ref.watch(appDatabaseProvider));
    });

final Provider<AudioPlayerService> audioPlayerServiceProvider =
    Provider<AudioPlayerService>((ref) {
      final JustAudioPlayerService service = JustAudioPlayerService();
      ref.onDispose(service.dispose);
      return service;
    });

final Provider<ReportQueueRepository> reportQueueRepositoryProvider =
    Provider<ReportQueueRepository>((ref) {
      return DriftReportQueueRepository(
        database: ref.watch(appDatabaseProvider),
      );
    });

final Provider<ConnectivityService> connectivityServiceProvider =
    Provider<ConnectivityService>((ref) {
      return ConnectivityPlusService();
    });

/// Back-off delays for the 3 stream reconnect retries (overridable in tests).
final Provider<List<Duration>> playbackRetryDelaysProvider =
    Provider<List<Duration>>(
      (ref) => const <Duration>[
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
      ],
    );

/// Tick interval for sleep timer countdown (overridable in tests).
final Provider<Duration> sleepTimerTickProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

/// Fade-out duration at the end of the sleep timer (overridable in tests).
final Provider<Duration> sleepFadeDurationProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 10),
);

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) => FirebaseAuthRepository());

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final AuthRepository auth = ref.watch(authRepositoryProvider);
  return ApiClient(getIdToken: auth.getIdToken);
});

final Provider<SyncRepository> syncRepositoryProvider =
    Provider<SyncRepository>((ref) {
      return SyncRepositoryImpl(
        apiClient: ref.watch(apiClientProvider),
        libraryRepository: ref.watch(libraryRepositoryProvider),
        reportQueueRepository: ref.watch(reportQueueRepositoryProvider),
      );
    });

final Provider<AdConfig> adConfigProvider = Provider<AdConfig>(
  (ref) => const AdConfig(),
);

final Provider<AdPolicy> adPolicyProvider = Provider<AdPolicy>(
  (ref) => AdPolicy(),
);

final Provider<AdService> adServiceProvider = Provider<AdService>((ref) {
  return AdMobAdService(
    config: ref.watch(adConfigProvider),
    policy: ref.watch(adPolicyProvider),
  );
});
