import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/mock/mock.dart';

void main() {
  group('Milestone 1.2 Mock Data Catalog', () {
    test('contains 40 stations spanning all 10 required countries', () {
      expect(mockStations, hasLength(40));

      const Set<String> requiredCountryCodes = <String>{
        'NG',
        'GH',
        'ZA',
        'GB',
        'US',
        'FR',
        'DE',
        'JP',
        'BR',
        'IN',
      };
      final Set<String> actualCodes = mockStations
          .map((MockStation s) => s.countryCode)
          .toSet();
      expect(actualCodes, containsAll(requiredCountryCodes));

      // Verify unique station IDs and varied stream/health states.
      expect(
        mockStations.map((MockStation s) => s.id).toSet(),
        hasLength(mockStations.length),
      );
      expect(mockStations.any((MockStation s) => !s.isWorking), isTrue);
      expect(mockStations.any((MockStation s) => s.isHls), isTrue);
      expect(mockStations.any((MockStation s) => !s.isHttps), isTrue);
      expect(mockStations.any((MockStation s) => s.faviconUrl == null), isTrue);
    });

    test(
      'contains 30 countries, 20 genres, 10 languages, and 6 collections',
      () {
        expect(getMockCountries(), hasLength(30));
        expect(getMockGenres(), hasLength(20));
        expect(getMockLanguages(), hasLength(10));
        expect(getMockCuratedCollections(), hasLength(6));
      },
    );

    test('every curated collection references valid mock station IDs', () {
      final Set<String> validIds = mockStations
          .map((MockStation s) => s.id)
          .toSet();
      for (final MockCuratedCollection col in getMockCuratedCollections()) {
        expect(col.stationIds, isNotEmpty);
        for (final String id in col.stationIds) {
          expect(validIds, contains(id));
        }
        expect(
          getMockStationsForCollection(col),
          hasLength(col.stationIds.length),
        );
      }
    });

    test('provider filters respect workingOnly and search criteria', () {
      final List<MockStation> working = getMockStations(workingOnly: true);
      final List<MockStation> all = getMockStations(workingOnly: false);
      expect(working.length, lessThan(all.length));
      expect(working.every((MockStation s) => s.isWorking), isTrue);

      final List<MockStation> ngStations = getMockStationsByCountry('ng');
      expect(ngStations, hasLength(4));

      final List<MockStation> afrobeats = getMockStationsByGenre('Afrobeats');
      expect(afrobeats, isNotEmpty);

      final List<MockStation> search = searchMockStations(
        query: 'Wazobia',
        workingOnly: true,
      );
      expect(search.single.id, 'mock-ng-wazobia-lagos');
    });

    test('MockSessionController toggles favourites and playback state', () {
      final MockSessionController controller = MockSessionController();
      final bool wasFav = controller.isFavourite('mock-gb-classic-fm');
      controller.toggleFavourite('mock-gb-classic-fm');
      expect(controller.isFavourite('mock-gb-classic-fm'), !wasFav);

      controller.playStation(mockStations[1]);
      expect(controller.currentStation.id, mockStations[1].id);
      expect(controller.playbackStatus, MockPlaybackStatus.playing);

      controller.togglePlayPause();
      expect(controller.playbackStatus, MockPlaybackStatus.paused);
    });
  });
}
