import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';

/// Immutable state for the Welcome onboarding screen (`/welcome`).
@immutable
class WelcomeState {
  const WelcomeState({
    this.selectedCountryCode,
    this.selectedGenreIds = const <String>[],
    this.isSubmitting = false,
    this.completed = false,
    this.error,
  });

  final String? selectedCountryCode;
  final List<String> selectedGenreIds;
  final bool isSubmitting;
  final bool completed;
  final AppFailure? error;

  WelcomeState copyWith({
    String? selectedCountryCode,
    List<String>? selectedGenreIds,
    bool? isSubmitting,
    bool? completed,
    AppFailure? error,
    bool clearError = false,
  }) {
    return WelcomeState(
      selectedCountryCode: selectedCountryCode ?? this.selectedCountryCode,
      selectedGenreIds: selectedGenreIds ?? this.selectedGenreIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      completed: completed ?? this.completed,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for [WelcomeScreen] (`/welcome`).
class WelcomeViewModel extends Notifier<WelcomeState> {
  @override
  WelcomeState build() => const WelcomeState();

  void selectCountry(String countryCode) {
    state = state.copyWith(
      selectedCountryCode: countryCode.trim().toUpperCase(),
      clearError: true,
    );
  }

  void toggleGenre(String genreId) {
    final List<String> next = List<String>.from(state.selectedGenreIds);
    if (next.contains(genreId)) {
      next.remove(genreId);
    } else {
      next.add(genreId);
    }
    state = state.copyWith(selectedGenreIds: List<String>.unmodifiable(next));
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final repo = ref.read(settingsRepositoryProvider);
    final Result<UserSettings> currentRes = await repo.getSettings();
    final UserSettings base = switch (currentRes) {
      Success<UserSettings>(:final data) => data,
      Failure<UserSettings>() => const UserSettings(),
    };
    final Result<void> saved = await repo.saveSettings(
      base.copyWith(
        homeCountryCode: state.selectedCountryCode,
        preferredGenreIds: state.selectedGenreIds,
      ),
    );
    state = switch (saved) {
      Success<void>() => state.copyWith(isSubmitting: false, completed: true),
      Failure<void>(:final error) => state.copyWith(
        isSubmitting: false,
        error: error,
      ),
    };
  }

  void skip() {
    state = state.copyWith(completed: true, clearError: true);
  }
}

final NotifierProvider<WelcomeViewModel, WelcomeState>
welcomeViewModelProvider = NotifierProvider<WelcomeViewModel, WelcomeState>(
  WelcomeViewModel.new,
);
