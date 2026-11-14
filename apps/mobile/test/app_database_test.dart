import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Station _station(String id, {String name = 'Station'}) {
  return Station(
    id: id,
    name: '$name $id',
    streamUrl: 'https://stream.example.com/$id',
    countryCode: 'NG',
    countryName: 'Nigeria',
    isHttps: true,
    isWorking: true,
    genres: const <Genre>[Genre(id: 'afrobeats', name: 'Afrobeats')],
    codec: 'MP3',
    bitrateKbps: 128,
    clickCount: 250,
  );
}

void main() {
  group('Milestone 2.4 Drift AppDatabase', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.inMemory();
    });

    tearDown(() async {
      await db.close();
    });

    test('caches and retrieves stations and TTL catalog lists', () async {
      final Station s1 = _station('s1');
      final Station s2 = _station('s2');
      await db.upsertStations(<Station>[s1, s2]);

      expect(await db.getCachedStationById('s1'), s1);
      expect(await db.getCachedStationsByIds(<String>['s2', 's1']), <Station>[
        s2,
        s1,
      ]);

      final DateTime t0 = DateTime.utc(2026, 11, 13, 12, 0);
      await db.saveCachedList(
        cacheKey: 'countries',
        payloadJson: '[{"code":"NG","name":"Nigeria"}]',
        ttl: const Duration(hours: 24),
        now: t0,
      );

      final CachedListRecord? cached = await db.getCachedList('countries');
      expect(cached, isNotNull);
      expect(cached!.isExpiredAt(t0.add(const Duration(hours: 23))), isFalse);
      expect(cached.isExpiredAt(t0.add(const Duration(hours: 24))), isTrue);
    });

    test('manages favourites and caps recents at 50 entries', () async {
      final DateTime base = DateTime.utc(2026, 11, 13, 10, 0);
      await db.addFavourite('s1', now: base);
      await db.addFavourite('s2', now: base.add(const Duration(minutes: 1)));
      expect(await db.getFavouriteIds(), <String>['s2', 's1']);

      await db.removeFavourite('s1');
      expect(await db.getFavouriteIds(), <String>['s2']);

      for (int i = 1; i <= 55; i++) {
        await db.recordRecent(
          'station-$i',
          now: base.add(Duration(minutes: i)),
        );
      }

      final List<String> recents = await db.getRecentIds();
      expect(recents.length, 50);
      expect(recents.first, 'station-55');
      expect(recents.last, 'station-6');
    });

    test('persists collections, song history, and user settings', () async {
      final Collection col = Collection(
        id: 'col-1',
        title: 'Morning Lagos',
        subtitle: 'News + Afrobeats',
        stationIds: const <String>['s2', 's1'],
        isCurated: false,
        updatedAt: DateTime.utc(2026, 11, 13, 8, 0),
      );
      await db.upsertCollection(col);
      final List<Collection> loadedCollections = await db.getCollections();
      expect(loadedCollections.length, 1);
      expect(loadedCollections.first.stationIds, <String>['s2', 's1']);

      await db.deleteCollection('col-1');
      expect(await db.getCollections(), isEmpty);

      await db.insertSongHistory(
        SongHistoryEntry(
          id: 'h1',
          stationId: 's1',
          stationName: 'Cool FM',
          trackTitle: 'Burna Boy - Last Last',
          playedAt: DateTime.utc(2026, 11, 13, 9, 0),
        ),
      );
      final List<SongHistoryEntry> history = await db.getSongHistory();
      expect(history.length, 1);
      expect(history.first.trackTitle, 'Burna Boy - Last Last');

      await db.clearSongHistory();
      expect(await db.getSongHistory(), isEmpty);

      expect(await db.getUserSettings(), const UserSettings());
      const UserSettings updated = UserSettings(
        dataSaver: true,
        defaultSleepMinutes: 30,
        theme: AppThemePreference.light,
        languageCode: 'yo',
        notifyCollections: false,
        workingNowDefault: false,
        homeCountryCode: 'NG',
        preferredGenreIds: <String>['afrobeats', 'news'],
      );
      await db.saveUserSettings(updated);
      expect(await db.getUserSettings(), updated);
    });

    test('migrates existing v1 database to v2 preserving data', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'peksoft_drift_migration_',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final File dbFile = File('${tempDir.path}/test_v1.sqlite');
      final sqlite.Database rawV1 = sqlite.sqlite3.open(dbFile.path);
      try {
        rawV1.execute('''
          CREATE TABLE cached_stations (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            stream_url TEXT NOT NULL,
            homepage TEXT NOT NULL DEFAULT '',
            favicon_url TEXT NULL,
            uses_fallback_logo INTEGER NOT NULL DEFAULT 1,
            is_https INTEGER NOT NULL DEFAULT 0,
            is_hls INTEGER NOT NULL DEFAULT 0,
            is_working INTEGER NOT NULL DEFAULT 1,
            country_code TEXT NOT NULL,
            country_name TEXT NOT NULL,
            genres_json TEXT NOT NULL DEFAULT '[]',
            language TEXT NOT NULL DEFAULT '',
            codec TEXT NOT NULL DEFAULT 'UNKNOWN',
            bitrate_kbps INTEGER NOT NULL DEFAULT 0,
            votes INTEGER NOT NULL DEFAULT 0,
            click_count INTEGER NOT NULL DEFAULT 0,
            click_trend INTEGER NOT NULL DEFAULT 0,
            geo_lat REAL NULL,
            geo_long REAL NULL,
            updated_at INTEGER NOT NULL
          );
          CREATE TABLE cached_catalog_lists (
            cache_key TEXT NOT NULL PRIMARY KEY,
            payload_json TEXT NOT NULL,
            cached_at INTEGER NOT NULL,
            ttl_seconds INTEGER NOT NULL
          );
          CREATE TABLE favourites (
            station_id TEXT NOT NULL PRIMARY KEY,
            created_at INTEGER NOT NULL
          );
          CREATE TABLE recents (
            station_id TEXT NOT NULL PRIMARY KEY,
            played_at INTEGER NOT NULL
          );
          CREATE TABLE collections (
            id TEXT NOT NULL PRIMARY KEY,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL DEFAULT '',
            is_curated INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NULL
          );
          CREATE TABLE collection_stations (
            collection_id TEXT NOT NULL,
            station_id TEXT NOT NULL,
            added_at INTEGER NOT NULL,
            PRIMARY KEY (collection_id, station_id)
          );
          CREATE TABLE song_history_entries (
            id TEXT NOT NULL PRIMARY KEY,
            station_id TEXT NOT NULL,
            station_name TEXT NOT NULL,
            track_title TEXT NOT NULL,
            played_at INTEGER NOT NULL
          );
          CREATE TABLE user_settings_table (
            id INTEGER NOT NULL PRIMARY KEY,
            data_saver INTEGER NOT NULL DEFAULT 0,
            default_sleep_minutes INTEGER NULL,
            theme TEXT NOT NULL DEFAULT 'dark',
            language_code TEXT NOT NULL DEFAULT 'en',
            notify_collections INTEGER NOT NULL DEFAULT 1,
            working_now_default INTEGER NOT NULL DEFAULT 1,
            home_country_code TEXT NULL,
            preferred_genre_ids_json TEXT NOT NULL DEFAULT '[]'
          );
          INSERT INTO collections (id, title, subtitle, is_curated, updated_at)
          VALUES ('v1-col', 'Legacy Collection', 'Saved on v1', 0, 1700000000);
          INSERT INTO collection_stations (collection_id, station_id, added_at)
          VALUES ('v1-col', 's1', 1700000001);
          PRAGMA user_version = 1;
        ''');
      } finally {
        rawV1.close();
      }

      final AppDatabase migratedDb = AppDatabase.openFile(dbFile);
      try {
        final List<Collection> cols = await migratedDb.getCollections();
        expect(cols.length, 1);
        expect(cols.first.id, 'v1-col');
        expect(cols.first.title, 'Legacy Collection');
        expect(cols.first.stationIds, <String>['s1']);
      } finally {
        await migratedDb.close();
      }

      final sqlite.Database verifyRaw = sqlite.sqlite3.open(dbFile.path);
      try {
        final sqlite.ResultSet versionRows = verifyRaw.select(
          'PRAGMA user_version;',
        );
        expect(versionRows.first['user_version'], 2);

        final sqlite.ResultSet tableInfo = verifyRaw.select(
          'PRAGMA table_info(collections);',
        );
        final List<String> columnNames = tableInfo
            .map((sqlite.Row r) => r['name'] as String)
            .toList();
        expect(columnNames, contains('sort_order'));
      } finally {
        verifyRaw.close();
      }
    });
  });
}
