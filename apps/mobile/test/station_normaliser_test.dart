import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_station_dto.dart';
import 'package:peksoft_radio/core/normalisation/genre_map.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

String _readRepoFile(String relativeFromRepoRoot) {
  final File file = File('../../$relativeFromRepoRoot');
  if (!file.existsSync()) {
    throw StateError('Missing file: ${file.absolute.path}');
  }
  return file.readAsStringSync();
}

RadioBrowserStationDto _dto({
  required String uuid,
  String name = 'Test FM',
  String url = 'https://stream.example.com/live',
  String urlResolved = 'https://stream.example.com/live',
  String favicon = 'https://stream.example.com/logo.png',
  String tags = 'pop',
  String country = 'Nigeria',
  String countrycode = 'NG',
  String language = 'english',
  String codec = 'MP3',
  int bitrate = 128,
  int lastcheckok = 1,
  int clickcount = 100,
  int clicktrend = 5,
  int votes = 20,
}) {
  return RadioBrowserStationDto.fromJson(<String, dynamic>{
    'stationuuid': uuid,
    'name': name,
    'url': url,
    'url_resolved': urlResolved,
    'homepage': 'https://example.com',
    'favicon': favicon,
    'tags': tags,
    'country': country,
    'countrycode': countrycode,
    'language': language,
    'codec': codec,
    'bitrate': bitrate,
    'lastcheckok': lastcheckok,
    'clickcount': clickcount,
    'clicktrend': clicktrend,
    'votes': votes,
    'hls': 0,
  });
}

void main() {
  late GenreMap genreMap;
  late StationNormaliser normaliser;

  setUpAll(() {
    genreMap = GenreMap.fromJsonString(
      _readRepoFile('packages/shared/genre-map.json'),
    );
    normaliser = StationNormaliser(genreMap: genreMap);
  });

  group('Milestone 2.3 Normalisation', () {
    test('maps messy spike tags to canonical genres and strips noise', () {
      expect(genreMap.definitions.length, 20);

      // Synonyms & multilingual duplicates from docs/api-spike.md
      expect(
        genreMap
            .mapTags('pop, pop music, música pop, hits, top 40')
            .map((Genre g) => g.id)
            .toList(),
        <String>['pop'],
      );
      expect(
        genreMap
            .mapTags('news, talk, local news, noticias, information, news talk')
            .map((Genre g) => g.id)
            .toList(),
        <String>['news'],
      );
      expect(
        genreMap
            .mapTags('christian, gospel, gospel music, afro-gospel, religion')
            .map((Genre g) => g.id)
            .toList(),
        <String>['gospel'],
      );
      expect(
        genreMap
            .mapTags(
              'regional mexican, regional mexicana, música popular mexicana',
            )
            .map((Genre g) => g.id)
            .toList(),
        <String>['latin'],
      );

      // Non-genre / meta / submitter noise
      expect(
        genreMap.mapTags(
          'music, radio, fm, estación, moi merino, variety, general, various, nigeria, ibadan',
        ),
        isEmpty,
      );

      // Empty tags
      expect(genreMap.mapTags('   '), isEmpty);

      // Max 2 canonical genres cap
      expect(
        genreMap
            .mapTags('afrobeats, jazz, rock, classical')
            .map((Genre g) => g.id)
            .toList(),
        <String>['afrobeats', 'jazz'],
      );
    });

    test('computes HTTPS, fallback logo, and working-now flags accurately', () {
      final Station httpNoLogoBroken = normaliser.normalize(
        _dto(
          uuid: 's1',
          url: 'http://radio.example.com/stream',
          urlResolved: 'http://radio.example.com/stream',
          favicon: '',
          lastcheckok: 0,
        ),
      );
      expect(httpNoLogoBroken.isHttps, isFalse);
      expect(httpNoLogoBroken.usesFallbackLogo, isTrue);
      expect(httpNoLogoBroken.faviconUrl, isNull);
      expect(httpNoLogoBroken.isWorking, isFalse);

      final Station httpsWithLogo = normaliser.normalize(
        _dto(
          uuid: 's2',
          url: 'http://legacy.example.com/stream',
          urlResolved: 'https://cdn.example.com/stream',
          favicon: 'https://cdn.example.com/icon.png',
          lastcheckok: 1,
        ),
      );
      expect(httpsWithLogo.isHttps, isTrue);
      expect(httpsWithLogo.usesFallbackLogo, isFalse);
      expect(httpsWithLogo.faviconUrl, 'https://cdn.example.com/icon.png');
      expect(httpsWithLogo.isWorking, isTrue);
    });

    test('deduplicates by UUID and (name, country, host) preferring HTTPS', () {
      final List<RadioBrowserStationDto> raw = <RadioBrowserStationDto>[
        _dto(
          uuid: 'dup-uuid',
          name: 'Cool FM',
          urlResolved: 'http://stream.coolfm.ng/live',
          url: 'http://stream.coolfm.ng/live',
          clickcount: 100,
        ),
        _dto(
          uuid: 'dup-uuid',
          name: 'Cool FM',
          urlResolved: 'https://stream.coolfm.ng/live',
          url: 'https://stream.coolfm.ng/live',
          clickcount: 150,
        ),
        _dto(
          uuid: 'other-uuid-http',
          name: 'Wazobia FM',
          urlResolved: 'http://stream.wazobia.ng/aac',
          url: 'http://stream.wazobia.ng/aac',
          countrycode: 'NG',
          clickcount: 900,
        ),
        _dto(
          uuid: 'other-uuid-https',
          name: '  wazobia   fm ',
          urlResolved: 'https://stream.wazobia.ng/mp3',
          url: 'https://stream.wazobia.ng/mp3',
          countrycode: 'NG',
          clickcount: 500,
        ),
      ];

      final List<Station> deduped = normaliser.normalizeAndDeduplicate(raw);
      expect(deduped.length, 2);
      final Station wazobia = deduped.firstWhere(
        (Station s) => s.name.toLowerCase().contains('wazobia'),
      );
      expect(wazobia.id, 'other-uuid-https');
      expect(wazobia.isHttps, isTrue);
    });

    test('filters working-now by default and sorts by all options', () {
      final List<Station> stations = <Station>[
        normaliser.normalize(
          _dto(
            uuid: 'a',
            name: 'Beta Jazz',
            tags: 'jazz',
            clickcount: 500,
            clicktrend: 10,
            votes: 30,
            bitrate: 192,
            lastcheckok: 1,
          ),
        ),
        normaliser.normalize(
          _dto(
            uuid: 'b',
            name: 'Alpha Pop',
            tags: 'pop',
            clickcount: 900,
            clicktrend: 2,
            votes: 10,
            bitrate: 128,
            lastcheckok: 1,
          ),
        ),
        normaliser.normalize(
          _dto(
            uuid: 'c',
            name: 'Offline FM',
            tags: 'pop',
            clickcount: 9999,
            lastcheckok: 0,
          ),
        ),
      ];

      // Default filter excludes lastcheckok == 0.
      final List<Station> popular = normaliser.filterAndSort(stations);
      expect(popular.map((Station s) => s.id).toList(), <String>['b', 'a']);

      // Including offline stations works when workingNowOnly = false.
      final List<Station> allPopular = normaliser.filterAndSort(
        stations,
        filter: const StationFilter(workingNowOnly: false),
      );
      expect(allPopular.map((Station s) => s.id).toList(), <String>[
        'c',
        'b',
        'a',
      ]);

      expect(
        normaliser
            .filterAndSort(stations, sort: StationSortOption.trending)
            .first
            .id,
        'a',
      );
      expect(
        normaliser
            .filterAndSort(stations, sort: StationSortOption.votes)
            .first
            .id,
        'a',
      );
      expect(
        normaliser
            .filterAndSort(stations, sort: StationSortOption.bitrate)
            .first
            .id,
        'a',
      );
      expect(
        normaliser
            .filterAndSort(stations, sort: StationSortOption.nameAsc)
            .first
            .id,
        'b',
      );
    });

    test('normalises real Phase 0 Nigeria fixture and enforces workingNow', () {
      final List<dynamic> decoded =
          jsonDecode(
                _readRepoFile(
                  'packages/shared/fixtures/radio-browser/stations-ng-working.json',
                ),
              )
              as List<dynamic>;
      final List<RadioBrowserStationDto> dtos = decoded
          .whereType<Map<String, dynamic>>()
          .map(RadioBrowserStationDto.fromJson)
          .toList();

      final List<Station> normalised = normaliser.normalizeAndDeduplicate(dtos);
      final List<Station> workingOnly = normaliser.filterAndSort(normalised);

      expect(normalised, isNotEmpty);
      expect(workingOnly.every((Station s) => s.isWorking), isTrue);
      expect(workingOnly.every((Station s) => s.genres.length <= 2), isTrue);
    });
  });
}
