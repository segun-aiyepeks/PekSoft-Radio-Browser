import 'package:flutter/foundation.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// A locally queued broken-station report awaiting Phase 4 backend sync.
@immutable
class PendingStationReport {
  const PendingStationReport({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.reason,
    required this.createdAt,
    this.synced = false,
  });

  final String id;
  final String stationId;
  final String stationName;
  final String reason;
  final DateTime createdAt;
  final bool synced;
}

/// Local queue repository for "Report broken" submissions.
///
/// Reports are stored locally in Drift for the Phase 4 backend; no invented
/// Radio Browser endpoints are ever called.
abstract interface class ReportQueueRepository {
  Future<Result<void>> enqueueReport({
    required Station station,
    required String reason,
  });

  Future<Result<List<PendingStationReport>>> getPendingReports();
}
