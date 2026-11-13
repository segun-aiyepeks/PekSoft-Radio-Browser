import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';

part 'station.freezed.dart';

/// Canonical domain model for a live radio station.
@freezed
abstract class Station with _$Station {
  const factory Station({
    required String id,
    required String name,
    required String streamUrl,
    @Default('') String homepage,
    String? faviconUrl,
    @Default(true) bool usesFallbackLogo,
    @Default(false) bool isHttps,
    @Default(false) bool isHls,
    @Default(true) bool isWorking,
    required String countryCode,
    required String countryName,
    @Default(<Genre>[]) List<Genre> genres,
    @Default('') String language,
    @Default('UNKNOWN') String codec,
    @Default(0) int bitrateKbps,
    @Default(0) int votes,
    @Default(0) int clickCount,
    @Default(0) int clickTrend,
    double? geoLat,
    double? geoLong,
  }) = _Station;
}
