import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/api_client.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/library/domain/library_repository.dart';
import 'package:peksoft_radio/features/library/domain/sync_repository.dart';
import 'package:peksoft_radio/features/station/domain/report_queue_repository.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required this.apiClient,
    required LibraryRepository libraryRepository,
    required ReportQueueRepository reportQueueRepository,
  }) : _library = libraryRepository,
       _reports = reportQueueRepository;

  final ApiClient apiClient;
  final LibraryRepository _library;
  final ReportQueueRepository _reports;
  DateTime? _lastSyncedAt;

  @override
  Future<Result<SyncSummary>> syncOnSignIn() => _performSync(fullMerge: true);

  @override
  Future<Result<SyncSummary>> syncNow() => _performSync(fullMerge: false);

  Future<Result<SyncSummary>> _performSync({required bool fullMerge}) async {
    final Result<Map<String, dynamic>> meRes = await apiClient.getMe();
    if (meRes case Failure<Map<String, dynamic>>(:final error)) {
      return Failure<SyncSummary>(error);
    }

    final Result<List<Station>> favsRes = await _library.getFavourites();
    final List<Station> localFavs = switch (favsRes) {
      Success<List<Station>>(:final data) => data,
      Failure<List<Station>>() => <Station>[],
    };

    final Result<List<Station>> recentsRes = await _library.getRecents();
    final List<Station> localRecents = switch (recentsRes) {
      Success<List<Station>>(:final data) => data,
      Failure<List<Station>>() => <Station>[],
    };

    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> payload = <String, dynamic>{
      if (!fullMerge && _lastSyncedAt != null)
        'since': _lastSyncedAt!.toUtc().toIso8601String(),
      'favorites': localFavs
          .map(
            (Station s) => <String, dynamic>{
              'stationId': s.id,
              'stationName': s.name,
              'streamUrl': s.streamUrl,
              'countryCode': s.countryCode,
              if (s.faviconUrl != null && s.faviconUrl!.isNotEmpty)
                'faviconUrl': s.faviconUrl,
              if (s.codec.isNotEmpty) 'codec': s.codec,
              'bitrateKbps': s.bitrateKbps,
              'isDeleted': false,
              'updatedAt': nowIso,
            },
          )
          .toList(growable: false),
      'recents': localRecents
          .map(
            (Station s) => <String, dynamic>{
              'stationId': s.id,
              'stationName': s.name,
              'streamUrl': s.streamUrl,
              'countryCode': s.countryCode,
              'playedAt': nowIso,
              'updatedAt': nowIso,
            },
          )
          .toList(growable: false),
    };

    final Result<Map<String, dynamic>> syncRes = await apiClient.deltaSync(
      payload,
    );
    final Map<String, dynamic> data;
    switch (syncRes) {
      case Success<Map<String, dynamic>>(data: final d):
        data = d;
      case Failure<Map<String, dynamic>>(error: final error):
        return Failure<SyncSummary>(error);
    }

    final Map<String, dynamic> changes =
        (data['changes'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final List<dynamic> remoteFavs =
        (changes['favorites'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> rejected =
        (data['rejected'] as List<dynamic>?) ?? const <dynamic>[];

    final Set<String> localIds = localFavs.map((Station s) => s.id).toSet();
    int pulledCount = 0;

    for (final dynamic raw in remoteFavs) {
      if (raw is! Map<String, dynamic>) continue;
      final String? stationId = raw['stationId'] as String?;
      final bool isDeleted = raw['isDeleted'] == true;
      if (stationId == null) continue;

      if (isDeleted && localIds.contains(stationId)) {
        await _library.removeFavourite(stationId);
      } else if (!isDeleted && !localIds.contains(stationId)) {
        await _library.addFavourite(
          Station(
            id: stationId,
            name: (raw['stationName'] as String?) ?? 'Synced Station',
            streamUrl: (raw['streamUrl'] as String?) ?? '',
            countryCode: (raw['countryCode'] as String?) ?? '',
            countryName: (raw['countryCode'] as String?) ?? '',
            faviconUrl: raw['faviconUrl'] as String?,
            usesFallbackLogo: raw['faviconUrl'] == null,
            codec: (raw['codec'] as String?) ?? 'MP3',
            bitrateKbps: (raw['bitrateKbps'] as int?) ?? 128,
            genres: const <Genre>[],
            isWorking: true,
          ),
        );
        pulledCount++;
      }
    }

    int flushedReports = 0;
    final Result<List<PendingStationReport>> queuedRes = await _reports
        .getPendingReports();
    if (queuedRes case Success<List<PendingStationReport>>(
      data: final queued,
    )) {
      for (final PendingStationReport item in queued) {
        final Result<void> sent = await apiClient
            .submitStationReport(<String, dynamic>{
              'stationId': item.stationId,
              'stationName': item.stationName,
              'reason': _mapReportReason(item.reason),
            });
        if (sent is Success<void>) {
          await _reports.markReportSynced(item.id);
          flushedReports++;
        }
      }
    }

    final DateTime now = DateTime.now();
    _lastSyncedAt = now;

    return Success<SyncSummary>(
      SyncSummary(
        pushedFavorites: localFavs.length,
        pulledFavorites: pulledCount,
        flushedReports: flushedReports,
        rejectedCount: rejected.length,
        syncedAt: now,
      ),
    );
  }

  String _mapReportReason(String raw) {
    final String upper = raw.toUpperCase();
    if (upper.contains('DEAD') || upper.contains('OFFLINE')) {
      return 'DEAD_STREAM';
    }
    if (upper.contains('WRONG') || upper.contains('METADATA')) {
      return 'WRONG_INFO';
    }
    if (upper.contains('OFFENSIVE')) {
      return 'OFFENSIVE';
    }
    return 'OTHER';
  }
}
