import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/station/domain/report_queue_repository.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// In-memory [ReportQueueRepository] fake for unit and widget tests.
class FakeReportQueueRepository implements ReportQueueRepository {
  final List<PendingStationReport> queued = <PendingStationReport>[];

  @override
  Future<Result<void>> enqueueReport({
    required Station station,
    required String reason,
  }) async {
    queued.insert(
      0,
      PendingStationReport(
        id: 'rep-${queued.length + 1}',
        stationId: station.id,
        stationName: station.name,
        reason: reason.trim(),
        createdAt: DateTime.now(),
      ),
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<List<PendingStationReport>>> getPendingReports() async {
    return Success<List<PendingStationReport>>(
      List<PendingStationReport>.unmodifiable(queued),
    );
  }
}
