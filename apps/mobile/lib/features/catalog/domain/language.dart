import 'package:freezed_annotation/freezed_annotation.dart';

part 'language.freezed.dart';

/// Domain model for a broadcast language.
@freezed
abstract class Language with _$Language {
  const factory Language({
    required String code,
    required String name,
    @Default(0) int stationCount,
  }) = _Language;
}
