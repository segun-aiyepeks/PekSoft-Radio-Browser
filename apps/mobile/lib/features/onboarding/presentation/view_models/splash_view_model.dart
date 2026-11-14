import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';

/// Immutable state for the Splash screen (`/splash`).
@immutable
class SplashState {
  const SplashState({
    this.isInitialized = false,
    this.hasHomeCountry = false,
    this.destinationRoute = '/welcome',
  });

  final bool isInitialized;
  final bool hasHomeCountry;
  final String destinationRoute;

  SplashState copyWith({
    bool? isInitialized,
    bool? hasHomeCountry,
    String? destinationRoute,
  }) {
    return SplashState(
      isInitialized: isInitialized ?? this.isInitialized,
      hasHomeCountry: hasHomeCountry ?? this.hasHomeCountry,
      destinationRoute: destinationRoute ?? this.destinationRoute,
    );
  }
}

/// ViewModel for [SplashScreen] (`/splash`).
class SplashViewModel extends AsyncNotifier<SplashState> {
  @override
  Future<SplashState> build() => initialize();

  Future<SplashState> initialize() async {
    final Result<UserSettings> res = await ref
        .read(settingsRepositoryProvider)
        .getSettings();
    final bool hasHomeCountry = switch (res) {
      Success<UserSettings>(:final data) =>
        (data.homeCountryCode ?? '').isNotEmpty,
      Failure<UserSettings>() => false,
    };
    return SplashState(
      isInitialized: true,
      hasHomeCountry: hasHomeCountry,
      destinationRoute: hasHomeCountry ? '/home' : '/welcome',
    );
  }
}

final AsyncNotifierProvider<SplashViewModel, SplashState>
splashViewModelProvider = AsyncNotifierProvider<SplashViewModel, SplashState>(
  SplashViewModel.new,
);
