import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/profile/domain/settings_repository.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';

/// Local Drift-backed implementation of [SettingsRepository].
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  @override
  Future<Result<UserSettings>> getSettings() async {
    try {
      return Success<UserSettings>(await _db.getUserSettings());
    } catch (error) {
      return Failure<UserSettings>(
        AppFailure.storage(message: 'Failed to load settings: $error'),
      );
    }
  }

  @override
  Future<Result<void>> saveSettings(UserSettings settings) async {
    try {
      await _db.saveUserSettings(settings);
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>(
        AppFailure.storage(message: 'Failed to save settings: $error'),
      );
    }
  }
}
