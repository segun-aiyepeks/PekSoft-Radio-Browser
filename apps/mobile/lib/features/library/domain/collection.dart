import 'package:freezed_annotation/freezed_annotation.dart';

part 'collection.freezed.dart';

/// User-created or curated station collection.
@freezed
abstract class Collection with _$Collection {
  const factory Collection({
    required String id,
    required String title,
    @Default('') String subtitle,
    @Default(<String>[]) List<String> stationIds,
    @Default(false) bool isCurated,
    DateTime? updatedAt,
  }) = _Collection;
}
