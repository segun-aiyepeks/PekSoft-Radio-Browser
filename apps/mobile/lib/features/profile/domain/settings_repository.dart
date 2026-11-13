import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';

/// Repository for persisting local user preferences.
abstract interface class SettingsRepository {
  Future<Result<UserSettings>> getSettings();

  Future<Result<void>> saveSettings(UserSettings settings);
}
