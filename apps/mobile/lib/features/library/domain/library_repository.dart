import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Local-first repository for favourites, recents, collections, and song history.
abstract interface class LibraryRepository {
  Future<Result<List<Station>>> getFavourites();

  Future<Result<bool>> isFavourite(String stationId);

  Future<Result<void>> addFavourite(Station station);

  Future<Result<void>> removeFavourite(String stationId);

  Future<Result<List<Station>>> getRecents({int limit = 50});

  Future<Result<void>> recordRecent(Station station);

  Future<Result<List<Collection>>> getCollections();

  Future<Result<void>> saveCollection(Collection collection);

  Future<Result<void>> deleteCollection(String collectionId);

  Future<Result<List<SongHistoryEntry>>> getSongHistory({int limit = 100});

  Future<Result<void>> logSongHistory(SongHistoryEntry entry);

  Future<Result<void>> clearSongHistory();
}
