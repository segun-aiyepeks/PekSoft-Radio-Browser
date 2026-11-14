import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';

/// Immutable state for the Explore screen (`/explore`).
@immutable
class ExploreState {
  const ExploreState({
    this.activeTabIndex = 0,
    this.countries = const <Country>[],
    this.genres = const <Genre>[],
    this.languages = const <Language>[],
    this.error,
  });

  final int activeTabIndex;
  final List<Country> countries;
  final List<Genre> genres;
  final List<Language> languages;
  final AppFailure? error;

  ExploreState copyWith({
    int? activeTabIndex,
    List<Country>? countries,
    List<Genre>? genres,
    List<Language>? languages,
    AppFailure? error,
    bool clearError = false,
  }) {
    return ExploreState(
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      countries: countries ?? this.countries,
      genres: genres ?? this.genres,
      languages: languages ?? this.languages,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for [ExploreScreen] (`/explore`).
class ExploreViewModel extends AsyncNotifier<ExploreState> {
  @override
  Future<ExploreState> build() => _load();

  void selectTab(int index) {
    final ExploreState? current = state.asData?.value;
    if (current == null) return;
    state = AsyncValue<ExploreState>.data(
      current.copyWith(activeTabIndex: index),
    );
  }

  Future<void> refresh() async {
    final int tab = state.asData?.value.activeTabIndex ?? 0;
    state = const AsyncValue<ExploreState>.loading();
    state = AsyncValue<ExploreState>.data(
      await _load(activeTabIndex: tab, forceRefresh: true),
    );
  }

  Future<ExploreState> _load({
    int activeTabIndex = 0,
    bool forceRefresh = false,
  }) async {
    final catalog = ref.read(catalogRepositoryProvider);
    final Result<List<Country>> countriesRes = await catalog.getCountries(
      forceRefresh: forceRefresh,
    );
    final Result<List<Genre>> genresRes = await catalog.getGenres(
      forceRefresh: forceRefresh,
    );
    final Result<List<Language>> languagesRes = await catalog.getLanguages(
      forceRefresh: forceRefresh,
    );

    AppFailure? firstError;
    final List<Country> countries = switch (countriesRes) {
      Success<List<Country>>(:final data) => data,
      Failure<List<Country>>(:final error) => () {
        firstError ??= error;
        return const <Country>[];
      }(),
    };
    final List<Genre> genres = switch (genresRes) {
      Success<List<Genre>>(:final data) => data,
      Failure<List<Genre>>(:final error) => () {
        firstError ??= error;
        return const <Genre>[];
      }(),
    };
    final List<Language> languages = switch (languagesRes) {
      Success<List<Language>>(:final data) => data,
      Failure<List<Language>>(:final error) => () {
        firstError ??= error;
        return const <Language>[];
      }(),
    };

    return ExploreState(
      activeTabIndex: activeTabIndex,
      countries: countries,
      genres: genres,
      languages: languages,
      error: firstError,
    );
  }
}

final AsyncNotifierProvider<ExploreViewModel, ExploreState>
exploreViewModelProvider =
    AsyncNotifierProvider<ExploreViewModel, ExploreState>(ExploreViewModel.new);
