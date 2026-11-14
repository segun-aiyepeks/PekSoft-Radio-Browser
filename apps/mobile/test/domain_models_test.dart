import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

void main() {
  group('Milestone 2.1 Domain Models', () {
    test('Station supports value equality and copyWith', () {
      const Genre afrobeats = Genre(id: 'afrobeats', name: 'Afrobeats');
      const Station station = Station(
        id: 'uuid-1',
        name: 'Wazobia FM: Lagos',
        streamUrl: 'https://stream.example/wazobia.mp3',
        countryCode: 'NG',
        countryName: 'Nigeria',
        genres: <Genre>[afrobeats],
        codec: 'MP3',
        bitrateKbps: 128,
        isHttps: true,
        usesFallbackLogo: true,
      );

      final Station updated = station.copyWith(bitrateKbps: 192);
      expect(updated.bitrateKbps, 192);
      expect(updated == station, isFalse);
      expect(station.copyWith(), equals(station));
    });

    test('Catalog and Library models hold expected values', () {
      const Country ng = Country(
        code: 'NG',
        name: 'Nigeria',
        stationCount: 75,
        workingCount: 70,
      );
      const Language en = Language(
        code: 'en',
        name: 'English',
        stationCount: 12000,
      );
      final DateTime now = DateTime.utc(2026, 11, 13);
      final Collection col = Collection(
        id: 'col-1',
        title: 'West Africa Pulse',
        stationIds: const <String>['uuid-1'],
        isCurated: true,
        updatedAt: now,
      );
      final SongHistoryEntry song = SongHistoryEntry(
        id: 'song-1',
        stationId: 'uuid-1',
        stationName: 'Wazobia FM: Lagos',
        trackTitle: 'Burna Boy — City Boys',
        playedAt: now,
      );

      expect(ng.workingCount, 70);
      expect(en.code, 'en');
      expect(col.stationIds, <String>['uuid-1']);
      expect(song.trackTitle, 'Burna Boy — City Boys');
    });

    test('Entitlement defaults to Free tier with free limits', () {
      const Entitlement entitlement = Entitlement();
      expect(entitlement.tier, EntitlementTier.free);
      expect(entitlement.maxFavourites, 10);
      expect(entitlement.maxCollections, 2);
      expect(entitlement.maxSongHistory, 10);
      expect(entitlement.adsEnabled, isTrue);
    });

    test('UserSettings defaults to dark theme and workingNowDefault ON', () {
      const UserSettings settings = UserSettings();
      expect(settings.theme, AppThemePreference.dark);
      expect(settings.workingNowDefault, isTrue);
      expect(settings.dataSaver, isFalse);
    });

    test(
      'PlaybackState and sealed AppFailure/Result work with pattern matching',
      () {
        const PlaybackState initial = PlaybackState();
        expect(initial.status, PlaybackStatus.idle);
        expect(initial.currentStation, isNull);

        const AppFailure failure = AppFailure.network(
          message: 'Mirror unreachable',
          statusCode: 503,
        );
        const Result<String> res = Failure<String>(failure);

        final String output = res.when(
          success: (data) => data,
          failure: (err) => err.userMessage,
        );
        expect(output, 'Mirror unreachable');
        expect(res.isFailure, isTrue);
      },
    );
  });
}
