import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';

/// Immutable state for [ProfileScreen] (`/profile`), [SettingsScreen]
/// (`/settings`), [DeleteAccountScreen] (`/delete-account`), and
/// [AboutLegalScreen] (`/about`).
@immutable
class SettingsState {
  const SettingsState({
    this.settings = const UserSettings(),
    this.isOfflineSimulated = false,
    this.isDeletingAccount = false,
    this.accountDeleted = false,
    this.error,
  });

  final UserSettings settings;
  final bool isOfflineSimulated;
  final bool isDeletingAccount;
  final bool accountDeleted;
  final AppFailure? error;

  SettingsState copyWith({
    UserSettings? settings,
    bool? isOfflineSimulated,
    bool? isDeletingAccount,
    bool? accountDeleted,
    AppFailure? error,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isOfflineSimulated: isOfflineSimulated ?? this.isOfflineSimulated,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      accountDeleted: accountDeleted ?? this.accountDeleted,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for Profile, Settings, Delete Account, and About/Legal screens.
class SettingsViewModel extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() => _load();

  Future<void> toggleDataSaver(bool enabled) =>
      _updateSettings((UserSettings s) => s.copyWith(dataSaver: enabled));

  Future<void> setDefaultSleepMinutes(int? minutes) => _updateSettings(
    (UserSettings s) => s.copyWith(defaultSleepMinutes: minutes),
  );

  Future<void> setTheme(AppThemePreference theme) =>
      _updateSettings((UserSettings s) => s.copyWith(theme: theme));

  Future<void> setLanguage(String languageCode) => _updateSettings(
    (UserSettings s) => s.copyWith(languageCode: languageCode),
  );

  Future<void> toggleNotifyCollections(bool enabled) => _updateSettings(
    (UserSettings s) => s.copyWith(notifyCollections: enabled),
  );

  Future<void> toggleWorkingNowDefault(bool enabled) => _updateSettings(
    (UserSettings s) => s.copyWith(workingNowDefault: enabled),
  );

  void toggleOfflineSimulated() {
    final SettingsState? current = state.asData?.value;
    if (current == null) return;
    state = AsyncValue<SettingsState>.data(
      current.copyWith(isOfflineSimulated: !current.isOfflineSimulated),
    );
  }

  Future<void> requestDeleteAccount() async {
    final SettingsState current = state.asData?.value ?? const SettingsState();
    state = AsyncValue<SettingsState>.data(
      current.copyWith(isDeletingAccount: true, clearError: true),
    );
    await ref.read(libraryRepositoryProvider).clearSongHistory();
    state = AsyncValue<SettingsState>.data(
      current.copyWith(isDeletingAccount: false, accountDeleted: true),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<SettingsState>.loading();
    state = AsyncValue<SettingsState>.data(await _load());
  }

  Future<void> _updateSettings(
    UserSettings Function(UserSettings current) transform,
  ) async {
    final SettingsState current = state.asData?.value ?? const SettingsState();
    final UserSettings next = transform(current.settings);
    final Result<void> res = await ref
        .read(settingsRepositoryProvider)
        .saveSettings(next);
    state = AsyncValue<SettingsState>.data(switch (res) {
      Success<void>() => current.copyWith(settings: next, clearError: true),
      Failure<void>(:final error) => current.copyWith(error: error),
    });
  }

  Future<SettingsState> _load() async {
    final Result<UserSettings> res = await ref
        .read(settingsRepositoryProvider)
        .getSettings();
    return switch (res) {
      Success<UserSettings>(:final data) => SettingsState(settings: data),
      Failure<UserSettings>(:final error) => SettingsState(error: error),
    };
  }
}

final AsyncNotifierProvider<SettingsViewModel, SettingsState>
settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, SettingsState>(
      SettingsViewModel.new,
    );
