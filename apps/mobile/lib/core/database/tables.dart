import 'package:drift/drift.dart';

/// Cached normalised stations keyed by Radio Browser `stationuuid`.
class CachedStations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get streamUrl => text()();
  TextColumn get homepage => text().withDefault(const Constant(''))();
  TextColumn get faviconUrl => text().nullable()();
  BoolColumn get usesFallbackLogo =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isHttps => boolean().withDefault(const Constant(false))();
  BoolColumn get isHls => boolean().withDefault(const Constant(false))();
  BoolColumn get isWorking => boolean().withDefault(const Constant(true))();
  TextColumn get countryCode => text()();
  TextColumn get countryName => text()();
  TextColumn get genresJson => text().withDefault(const Constant('[]'))();
  TextColumn get language => text().withDefault(const Constant(''))();
  TextColumn get codec => text().withDefault(const Constant('UNKNOWN'))();
  IntColumn get bitrateKbps => integer().withDefault(const Constant(0))();
  IntColumn get votes => integer().withDefault(const Constant(0))();
  IntColumn get clickCount => integer().withDefault(const Constant(0))();
  IntColumn get clickTrend => integer().withDefault(const Constant(0))();
  RealColumn get geoLat => real().nullable()();
  RealColumn get geoLong => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Cached catalog & search response payloads with TTL metadata.
class CachedCatalogLists extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get ttlSeconds => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{cacheKey};
}

/// User favourite station IDs.
class Favourites extends Table {
  TextColumn get stationId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{stationId};
}

/// Recently played stations (bounded to the last 50 entries).
class Recents extends Table {
  TextColumn get stationId => text()();
  DateTimeColumn get playedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{stationId};
}

/// User-created or curated station collections.
@DataClassName('CollectionRow')
class Collections extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().withDefault(const Constant(''))();
  BoolColumn get isCurated => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Added in schema v2 to support custom ordering.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Join table mapping collections to station IDs in insertion order.
class CollectionStations extends Table {
  TextColumn get collectionId => text()();
  TextColumn get stationId => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    collectionId,
    stationId,
  };
}

/// Detected ICY / stream track titles logged during playback.
@DataClassName('SongHistoryRow')
class SongHistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get stationId => text()();
  TextColumn get stationName => text()();
  TextColumn get trackTitle => text()();
  DateTimeColumn get playedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Singleton row (id = 1) storing local user preferences.
class UserSettingsTable extends Table {
  IntColumn get id => integer()();
  BoolColumn get dataSaver => boolean().withDefault(const Constant(false))();
  IntColumn get defaultSleepMinutes => integer().nullable()();
  TextColumn get theme => text().withDefault(const Constant('dark'))();
  TextColumn get languageCode => text().withDefault(const Constant('en'))();
  BoolColumn get notifyCollections =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get workingNowDefault =>
      boolean().withDefault(const Constant(true))();
  TextColumn get homeCountryCode => text().nullable()();
  TextColumn get preferredGenreIdsJson =>
      text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
