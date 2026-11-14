import 'dart:async';
import 'dart:convert';

import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_country_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_language_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_station_dto.dart';
import 'package:peksoft_radio/core/network/radio_browser_client.dart';
import 'package:peksoft_radio/core/normalisation/genre_map.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/catalog/domain/catalog_repository.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Offline-first [CatalogRepository] backed by [AppDatabase] and
/// [RadioBrowserClient] with stale-while-revalidate (SWR).
///
/// Catalog lists use a 24-hour TTL; search results use a 5-minute TTL.
class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({
    required AppDatabase database,
    required this._client,
    required this._normaliser,
    DateTime Function()? now,
    this.onBackgroundRevalidation,
  }) : _db = database,
       _now = now ?? DateTime.now;

  static const Duration listTtl = Duration(hours: 24);
  static const Duration searchTtl = Duration(minutes: 5);

  final AppDatabase _db;
  final RadioBrowserClient _client;
  final StationNormaliser _normaliser;
  final DateTime Function() _now;

  /// Optional hook used in tests to observe/await background SWR tasks.
  final void Function(Future<void> task)? onBackgroundRevalidation;

  @override
  Future<Result<List<Country>>> getCountries({
    bool forceRefresh = false,
  }) async {
    return _fetchWithSwr<List<Country>>(
      cacheKey: 'catalog:countries',
      ttl: listTtl,
      forceRefresh: forceRefresh,
      decode: _decodeCountries,
      encode: _encodeCountries,
      fetchRemote: () async {
        final Result<List<RadioBrowserCountryDto>> res = await _client
            .getCountries();
        return switch (res) {
          Success<List<RadioBrowserCountryDto>>(:final data) =>
            Success<List<Country>>(
              data
                  .map(_normaliser.normalizeCountry)
                  .where((Country c) => c.code.isNotEmpty && c.name.isNotEmpty)
                  .toList(growable: false),
            ),
          Failure<List<RadioBrowserCountryDto>>(:final error) =>
            Failure<List<Country>>(error),
        };
      },
    );
  }

  @override
  Future<Result<List<Genre>>> getGenres({bool forceRefresh = false}) async {
    // Canonical genres come from packages/shared/genre-map.json; counts are
    // enriched from cached stations when available.
    final List<Station> cachedStations = await _db.getAllCachedStations();
    final Map<String, int> counts = <String, int>{};
    for (final Station station in cachedStations) {
      for (final Genre g in station.genres) {
        counts[g.id] = (counts[g.id] ?? 0) + 1;
      }
    }

    final List<Genre> genres = _normaliser.genreMap.definitions
        .map(
          (GenreDefinition def) =>
              def.toGenre(stationCount: counts[def.id] ?? 0),
        )
        .toList(growable: false);
    return Success<List<Genre>>(genres);
  }

  @override
  Future<Result<List<Language>>> getLanguages({
    bool forceRefresh = false,
  }) async {
    return _fetchWithSwr<List<Language>>(
      cacheKey: 'catalog:languages',
      ttl: listTtl,
      forceRefresh: forceRefresh,
      decode: _decodeLanguages,
      encode: _encodeLanguages,
      fetchRemote: () async {
        final Result<List<RadioBrowserLanguageDto>> res = await _client
            .getLanguages();
        return switch (res) {
          Success<List<RadioBrowserLanguageDto>>(:final data) =>
            Success<List<Language>>(
              data
                  .map(_normaliser.normalizeLanguage)
                  .where((Language l) => l.name.isNotEmpty)
                  .toList(growable: false),
            ),
          Failure<List<RadioBrowserLanguageDto>>(:final error) =>
            Failure<List<Language>>(error),
        };
      },
    );
  }

  @override
  Future<Result<List<Station>>> getTopStations({
    int limit = 100,
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    final Result<List<Station>> base = await _fetchStationListWithSwr(
      cacheKey: 'stations:top:$limit',
      ttl: listTtl,
      forceRefresh: forceRefresh,
      fetchDtos: () => _client.getTopClickStations(limit: limit),
    );
    return _applyFilterAndSort(base, filter: filter, sort: sort);
  }

  @override
  Future<Result<List<Station>>> getStationsByCountry(
    String countryCode, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    final String normalizedCode = countryCode.trim().toUpperCase();
    final Result<List<Station>> base = await _fetchStationListWithSwr(
      cacheKey: 'stations:country:$normalizedCode',
      ttl: listTtl,
      forceRefresh: forceRefresh,
      fetchDtos: () =>
          _client.searchStations(countryCode: normalizedCode, limit: 150),
    );
    return _applyFilterAndSort(
      base,
      filter: StationFilter(
        workingNowOnly: filter.workingNowOnly,
        httpsOnly: filter.httpsOnly,
        genreId: filter.genreId,
        countryCode: normalizedCode,
        language: filter.language,
        codec: filter.codec,
        minBitrateKbps: filter.minBitrateKbps,
        query: filter.query,
      ),
      sort: sort,
    );
  }

  @override
  Future<Result<List<Station>>> getStationsByGenre(
    String genreId, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    final String normalizedGenre = genreId.trim().toLowerCase();
    final Result<List<Station>> base = await _fetchStationListWithSwr(
      cacheKey: 'stations:genre:$normalizedGenre',
      ttl: listTtl,
      forceRefresh: forceRefresh,
      fetchDtos: () => _client.searchStations(tag: normalizedGenre, limit: 150),
    );
    return _applyFilterAndSort(
      base,
      filter: StationFilter(
        workingNowOnly: filter.workingNowOnly,
        httpsOnly: filter.httpsOnly,
        genreId: normalizedGenre,
        countryCode: filter.countryCode,
        language: filter.language,
        codec: filter.codec,
        minBitrateKbps: filter.minBitrateKbps,
        query: filter.query,
      ),
      sort: sort,
    );
  }

  @override
  Future<Result<List<Station>>> searchStations(
    StationFilter filter, {
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    final String queryKey =
        '${filter.query ?? ''}|${filter.countryCode ?? ''}|'
        '${filter.genreId ?? ''}|${filter.language ?? ''}|'
        '${filter.codec ?? ''}|${filter.minBitrateKbps ?? ''}|'
        '${filter.httpsOnly}|${filter.workingNowOnly}';

    final Result<List<Station>> base = await _fetchStationListWithSwr(
      cacheKey: 'stations:search:$queryKey',
      ttl: searchTtl,
      forceRefresh: forceRefresh,
      fetchDtos: () => _client.searchStations(
        name: filter.query,
        countryCode: filter.countryCode,
        tag: filter.genreId,
        language: filter.language,
        limit: 100,
      ),
    );
    return _applyFilterAndSort(base, filter: filter, sort: sort);
  }

  Future<Result<List<Station>>> _fetchStationListWithSwr({
    required String cacheKey,
    required Duration ttl,
    required bool forceRefresh,
    required Future<Result<List<RadioBrowserStationDto>>> Function() fetchDtos,
  }) {
    return _fetchWithSwr<List<Station>>(
      cacheKey: cacheKey,
      ttl: ttl,
      forceRefresh: forceRefresh,
      decode: (String jsonStr) async {
        final List<dynamic> ids = jsonDecode(jsonStr) as List<dynamic>;
        return _db.getCachedStationsByIds(
          ids.map((dynamic e) => e.toString()).toList(growable: false),
        );
      },
      encode: (List<Station> stations) =>
          jsonEncode(stations.map((Station s) => s.id).toList(growable: false)),
      fetchRemote: () async {
        final Result<List<RadioBrowserStationDto>> res = await fetchDtos();
        switch (res) {
          case Success<List<RadioBrowserStationDto>>(:final data):
            final List<Station> normalised = _normaliser
                .normalizeAndDeduplicate(data);
            await _db.upsertStations(normalised, now: _now());
            return Success<List<Station>>(normalised);
          case Failure<List<RadioBrowserStationDto>>(:final error):
            return Failure<List<Station>>(error);
        }
      },
    );
  }

  Future<Result<T>> _fetchWithSwr<T>({
    required String cacheKey,
    required Duration ttl,
    required bool forceRefresh,
    required FutureOr<T> Function(String payloadJson) decode,
    required String Function(T data) encode,
    required Future<Result<T>> Function() fetchRemote,
  }) async {
    try {
      if (!forceRefresh) {
        final CachedListRecord? cached = await _db.getCachedList(cacheKey);
        if (cached != null) {
          final T decoded = await decode(cached.payloadJson);
          if (cached.isExpiredAt(_now())) {
            _scheduleRevalidation(() async {
              final Result<T> refreshed = await fetchRemote();
              if (refreshed case Success<T>(:final data)) {
                await _db.saveCachedList(
                  cacheKey: cacheKey,
                  payloadJson: encode(data),
                  ttl: ttl,
                  now: _now(),
                );
              }
            });
          }
          return Success<T>(decoded);
        }
      }

      final Result<T> remote = await fetchRemote();
      if (remote case Success<T>(:final data)) {
        await _db.saveCachedList(
          cacheKey: cacheKey,
          payloadJson: encode(data),
          ttl: ttl,
          now: _now(),
        );
      }
      return remote;
    } catch (error) {
      return Failure<T>(
        AppFailure.storage(message: 'Failed to read catalog cache: $error'),
      );
    }
  }

  void _scheduleRevalidation(Future<void> Function() action) {
    final Future<void> task = action().catchError((Object _) {
      // Background SWR failures are non-fatal; stale cache was already served.
    });
    if (onBackgroundRevalidation != null) {
      onBackgroundRevalidation!(task);
    } else {
      unawaited(task);
    }
  }

  Result<List<Station>> _applyFilterAndSort(
    Result<List<Station>> result, {
    required StationFilter filter,
    required StationSortOption sort,
  }) {
    return switch (result) {
      Success<List<Station>>(:final data) => Success<List<Station>>(
        _normaliser.filterAndSort(data, filter: filter, sort: sort),
      ),
      Failure<List<Station>>(:final error) => Failure<List<Station>>(error),
    };
  }

  static List<Country> _decodeCountries(String jsonStr) {
    final List<dynamic> raw = jsonDecode(jsonStr) as List<dynamic>;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> m) => Country(
            code: m['code'] as String? ?? '',
            name: m['name'] as String? ?? '',
            stationCount: (m['stationCount'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList(growable: false);
  }

  static String _encodeCountries(List<Country> countries) {
    return jsonEncode(
      countries
          .map(
            (Country c) => <String, dynamic>{
              'code': c.code,
              'name': c.name,
              'stationCount': c.stationCount,
            },
          )
          .toList(growable: false),
    );
  }

  static List<Language> _decodeLanguages(String jsonStr) {
    final List<dynamic> raw = jsonDecode(jsonStr) as List<dynamic>;
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> m) => Language(
            code: m['code'] as String? ?? '',
            name: m['name'] as String? ?? '',
            stationCount: (m['stationCount'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList(growable: false);
  }

  static String _encodeLanguages(List<Language> languages) {
    return jsonEncode(
      languages
          .map(
            (Language l) => <String, dynamic>{
              'code': l.code,
              'name': l.name,
              'stationCount': l.stationCount,
            },
          )
          .toList(growable: false),
    );
  }
}
