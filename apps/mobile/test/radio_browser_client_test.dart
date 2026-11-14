import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_click_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_country_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_language_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_station_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_tag_dto.dart';
import 'package:peksoft_radio/core/network/radio_browser_client.dart';
import 'package:peksoft_radio/core/network/radio_browser_mirror_service.dart';

String _readFixture(String filename) {
  final File file = File(
    '../../packages/shared/fixtures/radio-browser/$filename',
  );
  return file.readAsStringSync();
}

typedef _StubHandler =
    ResponseBody Function(RequestOptions options, int callIndex);

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final _StubHandler _handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _handler(options, requests.length - 1);
  }
}

ResponseBody _jsonResponse(String jsonBody, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonBody,
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  group('Milestone 2.2 Radio Browser Data Source', () {
    test(
      'parses real Phase 0 fixtures for stations, countries, tags, and languages',
      () async {
        final String serversJson = _readFixture('servers.json');
        final String stationsJson = _readFixture('stations-sample-200.json');
        final String countriesJson = _readFixture('countries.json');
        final String tagsJson = _readFixture('tags.json');
        final String languagesJson = _readFixture('languages.json');

        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          opts,
          _,
        ) {
          final String path = opts.uri.path;
          if (path.endsWith('/json/servers')) {
            return _jsonResponse(serversJson);
          }
          if (path.endsWith('/json/countries')) {
            return _jsonResponse(countriesJson);
          }
          if (path.endsWith('/json/tags')) {
            return _jsonResponse(tagsJson);
          }
          if (path.endsWith('/json/languages')) {
            return _jsonResponse(languagesJson);
          }
          if (path.contains('/json/stations/')) {
            return _jsonResponse(stationsJson);
          }
          return _jsonResponse('[]');
        });

        final Dio dio = Dio()..httpClientAdapter = adapter;
        final RadioBrowserClient client = RadioBrowserClient(
          dio: dio,
          appVersion: '1.2.3',
          delay: (_) async {},
        );

        final Result<List<RadioBrowserStationDto>> stationsRes = await client
            .getTopClickStations(limit: 150);
        final Result<List<RadioBrowserCountryDto>> countriesRes = await client
            .getCountries();
        final Result<List<RadioBrowserTagDto>> tagsRes = await client.getTags();
        final Result<List<RadioBrowserLanguageDto>> langsRes = await client
            .getLanguages();

        expect(stationsRes.isSuccess, isTrue);
        expect(
          (stationsRes as Success<List<RadioBrowserStationDto>>).data,
          hasLength(200),
        );
        expect(
          (countriesRes as Success<List<RadioBrowserCountryDto>>).data,
          hasLength(150),
        );
        expect(
          (tagsRes as Success<List<RadioBrowserTagDto>>).data,
          hasLength(250),
        );
        expect(
          (langsRes as Success<List<RadioBrowserLanguageDto>>).data,
          hasLength(100),
        );

        // Verify User-Agent and timeouts are configured on every request.
        for (final RequestOptions req in adapter.requests) {
          expect(req.headers['User-Agent'], 'PekSoftRadioBrowser/1.2.3');
          expect(req.connectTimeout, const Duration(seconds: 6));
          expect(req.receiveTimeout, const Duration(seconds: 10));
        }
      },
    );

    test('caches mirror list for 24 hours and refreshes after TTL', () async {
      DateTime fakeNow = DateTime.utc(2026, 11, 13, 12, 0);
      int serverCalls = 0;

      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((opts, _) {
        if (opts.uri.path.endsWith('/json/servers')) {
          serverCalls++;
          return _jsonResponse(
            jsonEncode(<Map<String, String>>[
              <String, String>{
                'ip': '1.1.1.1',
                'name': 'nl1.api.radio-browser.info',
              },
              <String, String>{
                'ip': '2.2.2.2',
                'name': 'de1.api.radio-browser.info',
              },
            ]),
          );
        }
        return _jsonResponse('[]');
      });

      final Dio dio = Dio()..httpClientAdapter = adapter;
      final RadioBrowserMirrorService mirrorService = RadioBrowserMirrorService(
        dio: dio,
        random: Random(0),
        now: () => fakeNow,
      );

      await mirrorService.getOrderedMirrors();
      fakeNow = fakeNow.add(const Duration(hours: 23));
      await mirrorService.getOrderedMirrors();
      expect(serverCalls, 1);

      fakeNow = fakeNow.add(const Duration(hours: 2));
      await mirrorService.getOrderedMirrors();
      expect(serverCalls, 2);
    });

    test(
      'retries with exponential backoff and fails over to next mirror',
      () async {
        final List<Duration> recordedDelays = <Duration>[];
        final List<String> attemptedHosts = <String>[];

        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          opts,
          _,
        ) {
          if (opts.uri.path.endsWith('/json/servers')) {
            return _jsonResponse(
              jsonEncode(<Map<String, String>>[
                <String, String>{
                  'ip': '1.1.1.1',
                  'name': 'm1.api.radio-browser.info',
                },
                <String, String>{
                  'ip': '2.2.2.2',
                  'name': 'm2.api.radio-browser.info',
                },
              ]),
            );
          }
          attemptedHosts.add(opts.uri.host);
          if (opts.uri.host == 'm1.api.radio-browser.info') {
            return _jsonResponse('{"error":"overloaded"}', statusCode: 503);
          }
          return _jsonResponse(_readFixture('stations-ng-working.json'));
        });

        final Dio dio = Dio()..httpClientAdapter = adapter;
        final RadioBrowserMirrorService mirrorService =
            RadioBrowserMirrorService(dio: dio, random: Random(1));
        final RadioBrowserClient client = RadioBrowserClient(
          dio: dio,
          mirrorService: mirrorService,
          maxRetriesPerMirror: 1,
          initialBackoff: const Duration(milliseconds: 100),
          delay: (d) async => recordedDelays.add(d),
        );

        final Result<List<RadioBrowserStationDto>> res = await client
            .searchStations(countryCode: 'NG');

        expect(res.isSuccess, isTrue);
        expect(
          (res as Success<List<RadioBrowserStationDto>>).data,
          hasLength(75),
        );
        // Mirror 1 failed twice (initial + 1 retry with 100ms delay), then Mirror 2 succeeded.
        expect(recordedDelays, <Duration>[const Duration(milliseconds: 100)]);
        expect(attemptedHosts.toSet(), <String>{
          'm1.api.radio-browser.info',
          'm2.api.radio-browser.info',
        });
      },
    );

    test(
      'falls back to hardcoded mirrors when /json/servers fails and reports clicks',
      () async {
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          opts,
          _,
        ) {
          if (opts.uri.path.endsWith('/json/servers')) {
            return _jsonResponse('error', statusCode: 500);
          }
          if (opts.uri.path.contains('/json/url/')) {
            return _jsonResponse(
              jsonEncode(<String, Object?>{
                'ok': true,
                'message': 'retrieved station url',
                'stationuuid': 'abc-123',
                'name': 'Wazobia FM',
                'url': 'https://stream.example/wazobia.mp3',
              }),
            );
          }
          return _jsonResponse('[]');
        });

        final Dio dio = Dio()..httpClientAdapter = adapter;
        final RadioBrowserClient client = RadioBrowserClient(
          dio: dio,
          delay: (_) async {},
        );

        final Result<RadioBrowserClickDto> click = await client.reportClick(
          'abc-123',
        );
        expect(click.isSuccess, isTrue);
        final RadioBrowserClickDto dto =
            (click as Success<RadioBrowserClickDto>).data;
        expect(dto.ok, isTrue);
        expect(dto.stationuuid, 'abc-123');
      },
    );

    test('returns Failure when all mirrors fail', () async {
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(
        (opts, _) => _jsonResponse('down', statusCode: 503),
      );
      final Dio dio = Dio()..httpClientAdapter = adapter;
      final RadioBrowserClient client = RadioBrowserClient(
        dio: dio,
        delay: (_) async {},
      );

      final Result<List<RadioBrowserCountryDto>> res = await client
          .getCountries();
      expect(res.isFailure, isTrue);
      expect(
        (res as Failure<List<RadioBrowserCountryDto>>).error,
        isA<NetworkFailure>(),
      );
    });
  });
}
