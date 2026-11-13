import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';

/// Persisted theme preference. Dark-first by default.
enum AppThemePreference { dark, light, system }

/// Immutable user preferences domain model.
@freezed
abstract class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default(false) bool dataSaver,
    int? defaultSleepMinutes,
    @Default(AppThemePreference.dark) AppThemePreference theme,
    @Default('en') String languageCode,
    @Default(true) bool notifyCollections,
    @Default(true) bool workingNowDefault,
    String? homeCountryCode,
    @Default(<String>[]) List<String> preferredGenreIds,
  }) = _UserSettings;
}
