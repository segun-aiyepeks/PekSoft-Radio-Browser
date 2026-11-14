import 'package:freezed_annotation/freezed_annotation.dart';

part 'song_history_entry.freezed.dart';

/// A detected ICY / stream track title logged during playback.
@freezed
abstract class SongHistoryEntry with _$SongHistoryEntry {
  const factory SongHistoryEntry({
    required String id,
    required String stationId,
    required String stationName,
    required String trackTitle,
    required DateTime playedAt,
  }) = _SongHistoryEntry;
}
