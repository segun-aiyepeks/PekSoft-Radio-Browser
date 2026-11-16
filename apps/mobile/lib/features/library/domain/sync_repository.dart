import 'package:flutter/foundation.dart';
import 'package:peksoft_radio/core/domain/result.dart';

@immutable
class SyncSummary {
  const SyncSummary({
    this.pushedFavorites = 0,
    this.pulledFavorites = 0,
    this.flushedReports = 0,
    this.rejectedCount = 0,
    required this.syncedAt,
  });

  final int pushedFavorites;
  final int pulledFavorites;
  final int flushedReports;
  final int rejectedCount;
  final DateTime syncedAt;
}

abstract interface class SyncRepository {
  Future<Result<SyncSummary>> syncOnSignIn();

  Future<Result<SyncSummary>> syncNow();
}
