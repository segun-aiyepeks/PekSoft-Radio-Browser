import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_station_dto.dart';
import 'package:peksoft_radio/core/network/radio_browser_client.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/domain/station_repository.dart';

/// Offline-first [StationRepository] backed by [AppDatabase] and
/// [RadioBrowserClient].
class StationRepositoryImpl implements StationRepository {
  StationRepositoryImpl({
    required AppDatabase database,
    required this._client,
    required this._normaliser,
    DateTime Function()? now,
  }) : _db = database,
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final RadioBrowserClient _client;
  final StationNormaliser _normaliser;
  final DateTime Function() _now;

  @override
  Future<Result<Station>> getStationById(String id) async {
    final Station? cached = await _db.getCachedStationById(id);
    if (cached != null) {
      return Success<Station>(cached);
    }

    final Result<List<RadioBrowserStationDto>> remote = await _client
        .getStationsByUuids(<String>[id]);
    switch (remote) {
      case Success<List<RadioBrowserStationDto>>(:final data):
        final List<Station> normalised = _normaliser.normalizeAndDeduplicate(
          data,
        );
        if (normalised.isEmpty) {
          return Failure<Station>(
            AppFailure.notFound(message: 'Station "$id" was not found.'),
          );
        }
        await _db.upsertStations(normalised, now: _now());
        return Success<Station>(normalised.first);
      case Failure<List<RadioBrowserStationDto>>(:final error):
        return Failure<Station>(error);
    }
  }

  @override
  Future<Result<List<Station>>> getSimilarStations(
    Station station, {
    int limit = 10,
  }) async {
    final Set<String> targetGenreIds = station.genres
        .map((Genre g) => g.id)
        .toSet();
    final List<Station> cached = await _db.getAllCachedStations();
    List<Station> candidates = _rankSimilar(
      cached,
      station: station,
      targetGenreIds: targetGenreIds,
    );

    if (candidates.length < limit) {
      final Result<List<RadioBrowserStationDto>> remote = await _client
          .searchStations(
            countryCode: station.countryCode,
            tag: targetGenreIds.isNotEmpty ? targetGenreIds.first : null,
            limit: limit * 2,
          );
      if (remote case Success<List<RadioBrowserStationDto>>(:final data)) {
        final List<Station> normalised = _normaliser.normalizeAndDeduplicate(
          data,
        );
        await _db.upsertStations(normalised, now: _now());
        final Map<String, Station> merged = <String, Station>{
          for (final Station s in candidates) s.id: s,
          for (final Station s in normalised) s.id: s,
        };
        candidates = _rankSimilar(
          merged.values.toList(growable: false),
          station: station,
          targetGenreIds: targetGenreIds,
        );
      }
    }

    return Success<List<Station>>(
      candidates.take(limit).toList(growable: false),
    );
  }

  @override
  Future<Result<void>> reportClick(String stationId) async {
    final res = await _client.reportClick(stationId);
    return switch (res) {
      Success() => const Success<void>(null),
      Failure(:final error) => Failure<void>(error),
    };
  }

  List<Station> _rankSimilar(
    List<Station> pool, {
    required Station station,
    required Set<String> targetGenreIds,
  }) {
    final List<Station> filtered = _normaliser
        .filterAndSort(pool)
        .where((Station s) {
          if (s.id == station.id) return false;
          final bool sameGenre = s.genres.any(
            (Genre g) => targetGenreIds.contains(g.id),
          );
          final bool sameCountry = s.countryCode == station.countryCode;
          return sameGenre || sameCountry;
        })
        .toList(growable: true);

    filtered.sort((Station a, Station b) {
      final int scoreA = _similarityScore(a, station, targetGenreIds);
      final int scoreB = _similarityScore(b, station, targetGenreIds);
      final int cmp = scoreB.compareTo(scoreA);
      if (cmp != 0) return cmp;
      return b.clickCount.compareTo(a.clickCount);
    });
    return filtered;
  }

  static int _similarityScore(
    Station candidate,
    Station reference,
    Set<String> targetGenreIds,
  ) {
    int score = 0;
    for (final Genre g in candidate.genres) {
      if (targetGenreIds.contains(g.id)) score += 2;
    }
    if (candidate.countryCode == reference.countryCode) score += 1;
    return score;
  }
}
