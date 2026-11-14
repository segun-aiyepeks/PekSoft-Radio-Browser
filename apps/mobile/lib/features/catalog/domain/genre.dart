import 'package:freezed_annotation/freezed_annotation.dart';

part 'genre.freezed.dart';

/// Canonical normalised genre (never raw Radio Browser tag noise).
@freezed
abstract class Genre with _$Genre {
  const factory Genre({
    required String id,
    required String name,
    @Default(0) int stationCount,
    @Default('') String tagline,
  }) = _Genre;
}
