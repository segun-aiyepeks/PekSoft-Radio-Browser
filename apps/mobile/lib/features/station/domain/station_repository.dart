import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Repository for single-station lookups, similarity matching, and play clicks.
abstract interface class StationRepository {
  Future<Result<Station>> getStationById(String id);

  Future<Result<List<Station>>> getSimilarStations(
    Station station, {
    int limit = 10,
  });

  Future<Result<void>> reportClick(String stationId);
}
