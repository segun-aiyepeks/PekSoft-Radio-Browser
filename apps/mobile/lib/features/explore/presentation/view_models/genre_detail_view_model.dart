import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Immutable state for [GenreDetailScreen] (`/genre/:id`).
@immutable
class GenreDetailState {
  const GenreDetailState({
    required this.genreId,
    this.stations = const <Station>[],
    this.sort = StationSortOption.popular,
    this.workingNowOnly = true,
    this.error,
  });

  final String genreId;
  final List<Station> stations;
  final StationSortOption sort;
  final bool workingNowOnly;
  final AppFailure? error;
}

/// Family ViewModel for [GenreDetailScreen] (`/genre/:id`).
class GenreDetailViewModel extends AsyncNotifier<GenreDetailState> {
  GenreDetailViewModel(this.genreId);

  final String genreId;

  @override
  Future<GenreDetailState> build() =>
      _load(sort: StationSortOption.popular, workingNowOnly: true);

  Future<void> setSort(StationSortOption sort) async {
    final bool workingNow = state.asData?.value.workingNowOnly ?? true;
    state = AsyncValue<GenreDetailState>.data(
      await _load(sort: sort, workingNowOnly: workingNow),
    );
  }

  Future<void> toggleWorkingNow() async {
    final GenreDetailState? current = state.asData?.value;
    final StationSortOption sort = current?.sort ?? StationSortOption.popular;
    final bool nextWorking = !(current?.workingNowOnly ?? true);
    state = AsyncValue<GenreDetailState>.data(
      await _load(sort: sort, workingNowOnly: nextWorking),
    );
  }

  Future<void> refresh() async {
    final GenreDetailState? current = state.asData?.value;
    final StationSortOption sort = current?.sort ?? StationSortOption.popular;
    final bool workingNow = current?.workingNowOnly ?? true;
    state = const AsyncValue<GenreDetailState>.loading();
    state = AsyncValue<GenreDetailState>.data(
      await _load(sort: sort, workingNowOnly: workingNow, forceRefresh: true),
    );
  }

  Future<GenreDetailState> _load({
    required StationSortOption sort,
    required bool workingNowOnly,
    bool forceRefresh = false,
  }) async {
    final Result<List<Station>> res = await ref
        .read(catalogRepositoryProvider)
        .getStationsByGenre(
          genreId,
          filter: StationFilter(
            genreId: genreId,
            workingNowOnly: workingNowOnly,
          ),
          sort: sort,
          forceRefresh: forceRefresh,
        );
    return switch (res) {
      Success<List<Station>>(:final data) => GenreDetailState(
        genreId: genreId,
        stations: data,
        sort: sort,
        workingNowOnly: workingNowOnly,
      ),
      Failure<List<Station>>(:final error) => GenreDetailState(
        genreId: genreId,
        sort: sort,
        workingNowOnly: workingNowOnly,
        error: error,
      ),
    };
  }
}

final genreDetailViewModelProvider =
    AsyncNotifierProvider.family<
      GenreDetailViewModel,
      GenreDetailState,
      String
    >(GenreDetailViewModel.new);
