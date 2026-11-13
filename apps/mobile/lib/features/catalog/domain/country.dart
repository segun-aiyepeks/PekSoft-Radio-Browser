import 'package:freezed_annotation/freezed_annotation.dart';

part 'country.freezed.dart';

/// Domain model for a radio-broadcasting country.
@freezed
abstract class Country with _$Country {
  const factory Country({
    required String code,
    required String name,
    @Default(0) int stationCount,
    @Default(0) int workingCount,
  }) = _Country;
}
