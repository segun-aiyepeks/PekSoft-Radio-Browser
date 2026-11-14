import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/radio_browser_client.dart';
import 'package:peksoft_radio/core/network/radio_browser_mirror_service.dart';
import 'package:peksoft_radio/core/normalisation/genre_map.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/catalog/data/catalog_repository_impl.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/library/data/library_repository_impl.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/profile/data/settings_repository_impl.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';
import 'package:peksoft_radio/features/station/data/station_repository_impl.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(String jsonText, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonText,
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

String _readRepoFile(String relativeFromRepoRoot) {
  return File('../../$relativeFromRepoRoot').readAsStringSync();
}

Station _station(String id, {String country = 'NG'}) {
  return Station(
    id: id,
    name: 'Radio $id',
    streamUrl: 'https://stream.example.com/$id',
    countryCode: country,
    countryName: country == 'NG' ? 'Nigeria' : 'Ghana',
    isHttps: true,
    isWorking: true,
  );
}

void main() {
  late String serversJson;
  late String countriesJson;
  late String ngStationsJson;
  late GenreMap genreMap;
  late StationNormaliser normaliser;

  setUpAll(() {
    serversJson = _readRepoFile(
      'packages/shared/fixtures/radio-browser/servers.json',
    );
    countriesJson = _readRepoFile(
      'packages/shared/fixtures/radio-browser/countries.json',
    );
    ngStationsJson = _readRepoFile(
      'packages/shared/fixtures/radio-browser/stations-ng-working.json',
    );
    genreMap = GenreMap.fromJsonString(
      _readRepoFile('packages/shared/genre-map.json'),
    );
    normaliser = StationNormaliser(genreMap: genreMap);
  });

  group('Milestone 2.5 Repositories', () {
    test(
      'CatalogRepositoryImpl uses 24h list TTL, 5m search TTL, and SWR',
      () async {
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);

        DateTime now = DateTime.utc(2026, 11, 13, 12, 0);
        int countriesRequests = 0;
        int searchRequests = 0;
        String countriesResponse = countriesJson;

        final Dio dio = Dio()
          ..httpClientAdapter = _FakeAdapter((RequestOptions opts) {
            final String path = opts.uri.path;
            if (path.endsWith('/json/servers')) {
              return _jsonBody(serversJson);
            }
            if (path.endsWith('/json/countries')) {
              countriesRequests++;
              return _jsonBody(countriesResponse);
            }
            if (path.contains('/json/stations/search')) {
              searchRequests++;
              return _jsonBody(ngStationsJson);
            }
            return _jsonBody('[]');
          });

        final List<Future<void>> backgroundTasks = <Future<void>>[];
        final RadioBrowserClient client = RadioBrowserClient(
          dio: dio,
          mirrorService: RadioBrowserMirrorService(dio: dio, now: () => now),
          maxRetriesPerMirror: 0,
          delay: (_) async {},
        );
        final CatalogRepositoryImpl repo = CatalogRepositoryImpl(
          database: db,
          client: client,
          normaliser: normaliser,
          now: () => now,
          onBackgroundRevalidation: backgroundTasks.add,
        );

        // 1. Cold fetch hits network once and caches for 24h.
        final Result<List<Country>> first = await repo.getCountries();
        expect(first, isA<Success<List<Country>>>());
        expect(countriesRequests, 1);

        // 2. Within 24h returns cached without network call.
        now = now.add(const Duration(hours: 23));
        final Result<List<Country>> cached = await repo.getCountries();
        expect(cached, isA<Success<List<Country>>>());
        expect(countriesRequests, 1);

        // 3. Past 24h returns stale data immediately AND revalidates in background.
        countriesResponse =
            '[{"name":"Nigeria","iso_3166_1":"NG","stationcount":999}]';
        now = now.add(const Duration(hours: 2));
        final Result<List<Country>> stale = await repo.getCountries();
        expect(stale, isA<Success<List<Country>>>());
        expect((stale as Success<List<Country>>).data.length, greaterThan(1));

        await Future.wait(backgroundTasks);
        expect(countriesRequests, 2);

        final Result<List<Country>> refreshed = await repo.getCountries();
        expect((refreshed as Success<List<Country>>).data.length, 1);
        expect(refreshed.data.first.stationCount, 999);

        // 4. Search uses 5-minute TTL.
        const StationFilter searchFilter = StationFilter(query: 'Lagos');
        await repo.searchStations(searchFilter);
        expect(searchRequests, 1);

        now = now.add(const Duration(minutes: 4));
        await repo.searchStations(searchFilter);
        expect(searchRequests, 1);

        now = now.add(const Duration(minutes: 2));
        await repo.searchStations(searchFilter);
        await Future.wait(backgroundTasks);
        expect(searchRequests, 2);
      },
    );

    test(
      'StationRepositoryImpl resolves from cache/remote and reports clicks',
      () async {
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);

        final List<dynamic> ngDecoded =
            jsonDecode(ngStationsJson) as List<dynamic>;
        final Map<String, dynamic> firstRaw =
            ngDecoded.first as Map<String, dynamic>;
        final String targetUuid = firstRaw['stationuuid'] as String;
        bool clicked = false;

        final Dio dio = Dio()
          ..httpClientAdapter = _FakeAdapter((RequestOptions opts) {
            final String path = opts.uri.path;
            if (path.endsWith('/json/servers')) return _jsonBody(serversJson);
            if (path.endsWith('/json/stations/byuuid')) {
              return _jsonBody(jsonEncode(<dynamic>[firstRaw]));
            }
            if (path.endsWith('/json/url/$targetUuid')) {
              clicked = true;
              return _jsonBody(
                jsonEncode(<String, dynamic>{
                  'ok': true,
                  'message': 'retrieved station url',
                  'stationuuid': targetUuid,
                  'name': firstRaw['name'],
                  'url': firstRaw['url_resolved'],
                }),
              );
            }
            return _jsonBody('[]');
          });

        final RadioBrowserClient client = RadioBrowserClient(
          dio: dio,
          maxRetriesPerMirror: 0,
          delay: (_) async {},
        );
        final StationRepositoryImpl repo = StationRepositoryImpl(
          database: db,
          client: client,
          normaliser: normaliser,
        );

        final Result<Station> fetched = await repo.getStationById(targetUuid);
        expect(fetched, isA<Success<Station>>());
        expect((fetched as Success<Station>).data.id, targetUuid);

        // Subsequent lookup reads directly from Drift cache.
        expect(await db.getCachedStationById(targetUuid), isNotNull);

        final Result<void> clickResult = await repo.reportClick(targetUuid);
        expect(clickResult, isA<Success<void>>());
        expect(clicked, isTrue);
      },
    );

    test(
      'LibraryRepositoryImpl enforces free-tier limits via EntitlementRepository',
      () async {
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);

        const EntitlementRepositoryImpl entitlements =
            EntitlementRepositoryImpl();
        final LibraryRepositoryImpl library = LibraryRepositoryImpl(
          database: db,
          entitlementRepository: entitlements,
        );

        final Result<Entitlement> ent = await entitlements.getEntitlement();
        expect((ent as Success<Entitlement>).data.tier, EntitlementTier.free);

        // Free tier allows 10 favourites; 11th returns EntitlementRequiredFailure.
        for (int i = 1; i <= 10; i++) {
          final Result<void> added = await library.addFavourite(
            _station('s$i'),
          );
          expect(added, isA<Success<void>>());
        }
        final Result<void> eleventh = await library.addFavourite(
          _station('s11'),
        );
        expect(eleventh, isA<Failure<void>>());
        expect(
          (eleventh as Failure<void>).error,
          isA<EntitlementRequiredFailure>(),
        );

        // Free tier allows 2 custom collections; 3rd returns EntitlementRequiredFailure.
        expect(
          await library.saveCollection(
            const Collection(id: 'c1', title: 'One'),
          ),
          isA<Success<void>>(),
        );
        expect(
          await library.saveCollection(
            const Collection(id: 'c2', title: 'Two'),
          ),
          isA<Success<void>>(),
        );
        final Result<void> thirdCol = await library.saveCollection(
          const Collection(id: 'c3', title: 'Three'),
        );
        expect(thirdCol, isA<Failure<void>>());
        expect(
          (thirdCol as Failure<void>).error,
          isA<EntitlementRequiredFailure>(),
        );

        // Song history respects free-tier cap (10).
        for (int i = 1; i <= 12; i++) {
          await library.logSongHistory(
            SongHistoryEntry(
              id: 'h$i',
              stationId: 's1',
              stationName: 'Radio s1',
              trackTitle: 'Track $i',
              playedAt: DateTime.utc(2026, 11, 13, 12, i),
            ),
          );
        }
        final Result<List<SongHistoryEntry>> history = await library
            .getSongHistory();
        expect((history as Success<List<SongHistoryEntry>>).data.length, 10);
      },
    );

    test(
      'SettingsRepositoryImpl reads defaults and persists updates',
      () async {
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);

        final SettingsRepositoryImpl repo = SettingsRepositoryImpl(
          database: db,
        );
        expect(
          (await repo.getSettings() as Success<UserSettings>).data,
          const UserSettings(),
        );

        const UserSettings custom = UserSettings(
          dataSaver: true,
          theme: AppThemePreference.light,
          homeCountryCode: 'GH',
        );
        await repo.saveSettings(custom);
        expect(
          (await repo.getSettings() as Success<UserSettings>).data,
          custom,
        );
      },
    );
  });
}
