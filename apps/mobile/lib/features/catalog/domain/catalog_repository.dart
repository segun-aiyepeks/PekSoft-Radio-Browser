import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Offline-first repository for discovering countries, genres, languages,
/// and stations with stale-while-revalidate caching.
abstract interface class CatalogRepository {
  Future<Result<List<Country>>> getCountries({bool forceRefresh = false});

  Future<Result<List<Genre>>> getGenres({bool forceRefresh = false});

  Future<Result<List<Language>>> getLanguages({bool forceRefresh = false});

  Future<Result<List<Station>>> getTopStations({
    int limit = 100,
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  });

  Future<Result<List<Station>>> getStationsByCountry(
    String countryCode, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  });

  Future<Result<List<Station>>> getStationsByGenre(
    String genreId, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  });

  Future<Result<List<Station>>> searchStations(
    StationFilter filter, {
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  });
}
