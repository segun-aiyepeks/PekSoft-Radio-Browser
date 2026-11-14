import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/station/domain/report_queue_repository.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Drift-backed implementation of [ReportQueueRepository].
class DriftReportQueueRepository implements ReportQueueRepository {
  const DriftReportQueueRepository({required this.database});

  final AppDatabase database;

  @override
  Future<Result<void>> enqueueReport({
    required Station station,
    required String reason,
  }) async {
    try {
      final DateTime now = DateTime.now();
      await database.enqueueStationReport(
        id: '${station.id}-${now.microsecondsSinceEpoch}',
        stationId: station.id,
        stationName: station.name,
        reason: reason.trim(),
        createdAt: now,
      );
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>(
        AppFailure.storage(message: 'Could not queue station report: $error'),
      );
    }
  }

  @override
  Future<Result<List<PendingStationReport>>> getPendingReports() async {
    try {
      final List<PendingStationReportRow> rows = await database
          .getPendingStationReports();
      return Success<List<PendingStationReport>>(
        rows
            .map(
              (PendingStationReportRow r) => PendingStationReport(
                id: r.id,
                stationId: r.stationId,
                stationName: r.stationName,
                reason: r.reason,
                createdAt: r.createdAt,
                synced: r.synced,
              ),
            )
            .toList(growable: false),
      );
    } catch (error) {
      return Failure<List<PendingStationReport>>(
        AppFailure.storage(message: 'Could not read queued reports: $error'),
      );
    }
  }
}
