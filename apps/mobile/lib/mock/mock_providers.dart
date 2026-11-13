import 'package:flutter/foundation.dart';

import 'mock_collections.dart';
import 'mock_countries.dart';
import 'mock_genres.dart';
import 'mock_models.dart';
import 'mock_stations.dart';

/// Sort options supported by the Phase 1 mock discovery and filter flows.
enum MockStationSort { popular, votes, name, bitrate }

/// Simple provider functions backing Phase 1 UI screens.
///
/// Phase 3 will replace these functions with Riverpod ViewModels and repository
/// streams without changing screen-facing data shapes.

/// Returns all mock stations (including non-working entries when
/// `workingOnly` is false).
List<MockStation> getMockStations({bool workingOnly = true}) {
  if (!workingOnly) return mockStations;
  return mockStations.where((MockStation s) => s.isWorking).toList();
}

/// Returns stations matching [countryCode] (case-insensitive).
List<MockStation> getMockStationsByCountry(
  String countryCode, {
  bool workingOnly = true,
}) {
  final String normalized = countryCode.trim().toUpperCase();
  return getMockStations(workingOnly: workingOnly)
      .where((MockStation s) => s.countryCode.toUpperCase() == normalized)
      .toList();
}

/// Returns stations tagged with [genre] (case-insensitive).
List<MockStation> getMockStationsByGenre(
  String genre, {
  bool workingOnly = true,
}) {
  final String normalized = genre.trim().toLowerCase();
  return getMockStations(workingOnly: workingOnly)
      .where(
        (MockStation s) =>
            s.genres.any((String g) => g.toLowerCase() == normalized),
      )
      .toList();
}

/// Returns stations matching [language] (case-insensitive substring match).
List<MockStation> getMockStationsByLanguage(
  String language, {
  bool workingOnly = true,
}) {
  final String normalized = language.trim().toLowerCase();
  return getMockStations(workingOnly: workingOnly)
      .where((MockStation s) => s.language.toLowerCase().contains(normalized))
      .toList();
}

/// Looks up a single station by [id], or `null` if not found.
MockStation? getMockStationById(String id) {
  for (final MockStation station in mockStations) {
    if (station.id == id) return station;
  }
  return null;
}

/// Returns up to [limit] working stations similar to [station] by shared genre
/// or country, excluding [station] itself.
List<MockStation> getMockSimilarStations(MockStation station, {int limit = 5}) {
  final Set<String> targetGenres = station.genres
      .map((String g) => g.toLowerCase())
      .toSet();
  final List<MockStation> candidates = getMockStations(
    workingOnly: true,
  ).where((MockStation s) => s.id != station.id).toList();

  candidates.sort((MockStation a, MockStation b) {
    int score(MockStation candidate) {
      int value = 0;
      for (final String g in candidate.genres) {
        if (targetGenres.contains(g.toLowerCase())) value += 2;
      }
      if (candidate.countryCode == station.countryCode) value += 1;
      return value;
    }

    final int diff = score(b) - score(a);
    return diff != 0 ? diff : b.clickCount.compareTo(a.clickCount);
  });

  return candidates.take(limit).toList();
}

/// Filters and sorts mock stations for Search and Filters bottom sheet.
List<MockStation> searchMockStations({
  String query = '',
  bool workingOnly = true,
  String? countryCode,
  String? genre,
  String? language,
  String? codec,
  int? minBitrateKbps,
  MockStationSort sort = MockStationSort.popular,
}) {
  final String q = query.trim().toLowerCase();
  final List<MockStation> filtered = getMockStations(workingOnly: workingOnly)
      .where((MockStation s) {
        if (q.isNotEmpty) {
          final bool matchesQuery =
              s.name.toLowerCase().contains(q) ||
              s.country.toLowerCase().contains(q) ||
              s.language.toLowerCase().contains(q) ||
              s.genres.any((String g) => g.toLowerCase().contains(q));
          if (!matchesQuery) return false;
        }
        if (countryCode != null &&
            countryCode.isNotEmpty &&
            s.countryCode.toUpperCase() != countryCode.toUpperCase()) {
          return false;
        }
        if (genre != null &&
            genre.isNotEmpty &&
            !s.genres.any(
              (String g) => g.toLowerCase() == genre.toLowerCase(),
            )) {
          return false;
        }
        if (language != null &&
            language.isNotEmpty &&
            !s.language.toLowerCase().contains(language.toLowerCase())) {
          return false;
        }
        if (codec != null &&
            codec.isNotEmpty &&
            s.codec.toUpperCase() != codec.toUpperCase()) {
          return false;
        }
        if (minBitrateKbps != null && s.bitrateKbps < minBitrateKbps) {
          return false;
        }
        return true;
      })
      .toList();

  switch (sort) {
    case MockStationSort.popular:
      filtered.sort(
        (MockStation a, MockStation b) => b.clickCount.compareTo(a.clickCount),
      );
    case MockStationSort.votes:
      filtered.sort(
        (MockStation a, MockStation b) => b.votes.compareTo(a.votes),
      );
    case MockStationSort.name:
      filtered.sort((MockStation a, MockStation b) => a.name.compareTo(b.name));
    case MockStationSort.bitrate:
      filtered.sort(
        (MockStation a, MockStation b) =>
            b.bitrateKbps.compareTo(a.bitrateKbps),
      );
  }
  return filtered;
}

/// Returns all 30 mock countries.
List<MockCountry> getMockCountries() => mockCountries;

/// Returns all 20 canonical mock genres.
List<MockGenre> getMockGenres() => mockGenres;

/// Returns all 10 mock languages.
List<MockLanguage> getMockLanguages() => mockLanguages;

/// Returns all 6 curated mock collections.
List<MockCuratedCollection> getMockCuratedCollections() =>
    mockCuratedCollections;

/// Resolves the [MockStation] list for a given [MockCuratedCollection].
List<MockStation> getMockStationsForCollection(
  MockCuratedCollection collection,
) {
  return collection.stationIds
      .map(getMockStationById)
      .whereType<MockStation>()
      .toList();
}

/// Visual playback states previewable in Phase 1 (Milestone 1.4 dev switcher).
enum MockPlaybackStatus {
  idle,
  playing,
  paused,
  buffering,
  reconnecting,
  unavailable,
}

/// Local UI-only session state for Phase 1 (no networking, no DB, no audio).
///
/// Tracks favourites, recently played stations, and the currently selected
/// station/playback state so widgets can toggle interactively during review.
class MockSessionController extends ChangeNotifier {
  MockStation _currentStation = mockStations.first;
  MockPlaybackStatus _playbackStatus = MockPlaybackStatus.playing;
  final Set<String> _favouriteIds = <String>{
    'mock-ng-wazobia-lagos',
    'mock-gb-jazz-fm',
    'mock-fr-fip',
  };
  final List<String> _recentIds = <String>[
    'mock-ng-wazobia-lagos',
    'mock-gb-bbc-radio-1',
    'mock-us-kexp',
    'mock-jp-shonan-beach',
  ];

  MockStation get currentStation => _currentStation;
  MockPlaybackStatus get playbackStatus => _playbackStatus;
  List<MockStation> get favourites =>
      _favouriteIds.map(getMockStationById).whereType<MockStation>().toList();
  List<MockStation> get recents =>
      _recentIds.map(getMockStationById).whereType<MockStation>().toList();

  bool isFavourite(String stationId) => _favouriteIds.contains(stationId);

  void toggleFavourite(String stationId) {
    if (_favouriteIds.contains(stationId)) {
      _favouriteIds.remove(stationId);
    } else {
      _favouriteIds.add(stationId);
    }
    notifyListeners();
  }

  void playStation(MockStation station) {
    _currentStation = station;
    _playbackStatus = station.isWorking
        ? MockPlaybackStatus.playing
        : MockPlaybackStatus.unavailable;
    _recentIds.remove(station.id);
    _recentIds.insert(0, station.id);
    notifyListeners();
  }

  void togglePlayPause() {
    if (_playbackStatus == MockPlaybackStatus.playing) {
      _playbackStatus = MockPlaybackStatus.paused;
    } else {
      _playbackStatus = _currentStation.isWorking
          ? MockPlaybackStatus.playing
          : MockPlaybackStatus.unavailable;
    }
    notifyListeners();
  }

  void setPlaybackStatus(MockPlaybackStatus status) {
    _playbackStatus = status;
    notifyListeners();
  }
}

/// Shared UI-only mock session controller for Phase 1 screens.
final MockSessionController mockSessionController = MockSessionController();
