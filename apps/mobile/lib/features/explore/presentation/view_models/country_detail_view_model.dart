import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Immutable state for [CountryDetailScreen] (`/country/:code`).
@immutable
class CountryDetailState {
  const CountryDetailState({
    required this.countryCode,
    this.stations = const <Station>[],
    this.sort = StationSortOption.popular,
    this.workingNowOnly = true,
    this.error,
  });

  final String countryCode;
  final List<Station> stations;
  final StationSortOption sort;
  final bool workingNowOnly;
  final AppFailure? error;

  CountryDetailState copyWith({
    List<Station>? stations,
    StationSortOption? sort,
    bool? workingNowOnly,
    AppFailure? error,
    bool clearError = false,
  }) {
    return CountryDetailState(
      countryCode: countryCode,
      stations: stations ?? this.stations,
      sort: sort ?? this.sort,
      workingNowOnly: workingNowOnly ?? this.workingNowOnly,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Family ViewModel for [CountryDetailScreen] (`/country/:code`).
class CountryDetailViewModel extends AsyncNotifier<CountryDetailState> {
  CountryDetailViewModel(this.countryCode);

  final String countryCode;

  @override
  Future<CountryDetailState> build() =>
      _load(sort: StationSortOption.popular, workingNowOnly: true);

  Future<void> setSort(StationSortOption sort) async {
    final CountryDetailState? current = state.asData?.value;
    final bool workingNow = current?.workingNowOnly ?? true;
    state = AsyncValue<CountryDetailState>.data(
      await _load(sort: sort, workingNowOnly: workingNow),
    );
  }

  Future<void> toggleWorkingNow() async {
    final CountryDetailState? current = state.asData?.value;
    final StationSortOption sort = current?.sort ?? StationSortOption.popular;
    final bool nextWorking = !(current?.workingNowOnly ?? true);
    state = AsyncValue<CountryDetailState>.data(
      await _load(sort: sort, workingNowOnly: nextWorking),
    );
  }

  Future<void> refresh() async {
    final CountryDetailState? current = state.asData?.value;
    final StationSortOption sort = current?.sort ?? StationSortOption.popular;
    final bool workingNow = current?.workingNowOnly ?? true;
    state = const AsyncValue<CountryDetailState>.loading();
    state = AsyncValue<CountryDetailState>.data(
      await _load(sort: sort, workingNowOnly: workingNow, forceRefresh: true),
    );
  }

  Future<CountryDetailState> _load({
    required StationSortOption sort,
    required bool workingNowOnly,
    bool forceRefresh = false,
  }) async {
    final Result<List<Station>> res = await ref
        .read(catalogRepositoryProvider)
        .getStationsByCountry(
          countryCode,
          filter: StationFilter(
            countryCode: countryCode,
            workingNowOnly: workingNowOnly,
          ),
          sort: sort,
          forceRefresh: forceRefresh,
        );
    return switch (res) {
      Success<List<Station>>(:final data) => CountryDetailState(
        countryCode: countryCode,
        stations: data,
        sort: sort,
        workingNowOnly: workingNowOnly,
      ),
      Failure<List<Station>>(:final error) => CountryDetailState(
        countryCode: countryCode,
        sort: sort,
        workingNowOnly: workingNowOnly,
        error: error,
      ),
    };
  }
}

final countryDetailViewModelProvider =
    AsyncNotifierProvider.family<
      CountryDetailViewModel,
      CountryDetailState,
      String
    >(CountryDetailViewModel.new);
