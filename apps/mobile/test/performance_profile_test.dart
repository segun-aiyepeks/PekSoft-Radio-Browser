import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/catalog_repository.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/home/presentation/home_screen.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/main.dart';

import 'helpers/mock_repository_overrides.dart';

class _LargeCatalogRepository implements CatalogRepository {
  _LargeCatalogRepository(this._stations);

  final List<Station> _stations;

  @override
  Future<Result<List<Country>>> getCountries({
    bool forceRefresh = false,
  }) async => const Success<List<Country>>(<Country>[
    Country(code: 'FR', name: 'France', stationCount: 120),
  ]);

  @override
  Future<Result<List<Genre>>> getGenres({bool forceRefresh = false}) async =>
      const Success<List<Genre>>(<Genre>[
        Genre(id: 'jazz', name: 'Jazz', stationCount: 60),
        Genre(id: 'rock', name: 'Rock', stationCount: 60),
      ]);

  @override
  Future<Result<List<Language>>> getLanguages({
    bool forceRefresh = false,
  }) async => const Success<List<Language>>(<Language>[]);

  @override
  Future<Result<List<Station>>> getTopStations({
    int limit = 100,
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async => Success<List<Station>>(_stations.take(limit).toList());

  @override
  Future<Result<List<Station>>> getStationsByCountry(
    String countryCode, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async => Success<List<Station>>(_stations);

  @override
  Future<Result<List<Station>>> getStationsByGenre(
    String genreId, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async => Success<List<Station>>(_stations);

  @override
  Future<Result<List<Station>>> searchStations(
    StationFilter filter, {
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async => Success<List<Station>>(_stations);
}

List<Station> _generateStations(int count) {
  return List<Station>.generate(
    count,
    (int i) => Station(
      id: 'perf-$i',
      name: 'Perf Radio $i',
      streamUrl: 'https://stream.example.com/perf-$i.mp3',
      countryCode: 'FR',
      countryName: 'France',
      genres: const <Genre>[Genre(id: 'jazz', name: 'Jazz')],
      codec: 'MP3',
      bitrateKbps: 128,
      isHttps: true,
      isWorking: true,
    ),
  );
}

void main() {
  testWidgets(
    'Cold start shell and HomeScreen lazy SliverList scroll without jank',
    (WidgetTester tester) async {
      // Measure initial cold-start app pump.
      final Stopwatch coldStartWatch = Stopwatch()..start();
      await tester.pumpWidget(
        PekSoftRadioApp(overrides: mockRepositoryOverrides()),
      );
      await tester.pump();
      coldStartWatch.stop();

      // Verify initial widget tree builds without throwing or stalling.
      expect(tester.takeException(), isNull);
      expect(coldStartWatch.elapsedMilliseconds, lessThan(15000));

      // Now profile HomeScreen with 120 stations to verify lazy SliverList.builder.
      final List<Station> largeList = _generateStations(120);
      await tester.pumpWidget(
        ProviderScope(
          overrides: mockRepositoryOverrides(
            catalogRepository: _LargeCatalogRepository(largeList),
          ),
          child: MaterialApp(theme: AppTheme.dark(), home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Lazy horizontal & vertical builders should only materialize visible viewport cards.
      final int builtInitially = find.byType(StationLogo).evaluate().length;
      expect(builtInitially, greaterThan(0));
      expect(builtInitially, lessThan(25));

      // Fling-scroll down and verify new shelves scroll smoothly without jank.
      final Stopwatch scrollWatch = Stopwatch()..start();
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -2000),
        3000,
      );
      await tester.pumpAndSettle();
      scrollWatch.stop();

      expect(tester.takeException(), isNull);
      expect(scrollWatch.elapsedMilliseconds, lessThan(15000));
    },
  );
}
