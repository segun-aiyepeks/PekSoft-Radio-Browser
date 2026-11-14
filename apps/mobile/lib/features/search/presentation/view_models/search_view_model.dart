import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Immutable state for [SearchScreen] (`/search`) and [FiltersBottomSheet].
@immutable
class SearchState {
  const SearchState({
    this.query = '',
    this.filter = const StationFilter(),
    this.sort = StationSortOption.popular,
    this.results = const <Station>[],
    this.isLoading = false,
    this.hasSearched = false,
    this.recentQueries = const <String>[],
    this.error,
  });

  final String query;
  final StationFilter filter;
  final StationSortOption sort;
  final List<Station> results;
  final bool isLoading;
  final bool hasSearched;
  final List<String> recentQueries;
  final AppFailure? error;

  SearchState copyWith({
    String? query,
    StationFilter? filter,
    StationSortOption? sort,
    List<Station>? results,
    bool? isLoading,
    bool? hasSearched,
    List<String>? recentQueries,
    AppFailure? error,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      recentQueries: recentQueries ?? this.recentQueries,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for [SearchScreen] (`/search`) and [FiltersBottomSheet].
class SearchViewModel extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void setQuery(String query) {
    state = state.copyWith(
      query: query,
      filter: StationFilter(
        workingNowOnly: state.filter.workingNowOnly,
        httpsOnly: state.filter.httpsOnly,
        genreId: state.filter.genreId,
        countryCode: state.filter.countryCode,
        language: state.filter.language,
        codec: state.filter.codec,
        minBitrateKbps: state.filter.minBitrateKbps,
        query: query,
      ),
      clearError: true,
    );
  }

  Future<void> submitSearch() async {
    final String trimmed = state.query.trim();
    final List<String> nextRecent = trimmed.isEmpty
        ? state.recentQueries
        : <String>[
            trimmed,
            ...state.recentQueries.where((String q) => q != trimmed),
          ].take(10).toList(growable: false);

    state = state.copyWith(
      isLoading: true,
      hasSearched: true,
      recentQueries: nextRecent,
      clearError: true,
    );

    final Result<List<Station>> res = await ref
        .read(catalogRepositoryProvider)
        .searchStations(state.filter, sort: state.sort);

    state = switch (res) {
      Success<List<Station>>(:final data) => state.copyWith(
        results: data,
        isLoading: false,
      ),
      Failure<List<Station>>(:final error) => state.copyWith(
        results: const <Station>[],
        isLoading: false,
        error: error,
      ),
    };
  }

  Future<void> applyFilter(StationFilter filter) async {
    state = state.copyWith(filter: filter);
    await submitSearch();
  }

  Future<void> setSort(StationSortOption sort) async {
    state = state.copyWith(sort: sort);
    await submitSearch();
  }

  Future<void> resetFilters() async {
    state = state.copyWith(
      filter: StationFilter(query: state.query),
      sort: StationSortOption.popular,
    );
    if (state.hasSearched) {
      await submitSearch();
    }
  }

  void clearQuery() {
    state = SearchState(
      filter: StationFilter(
        workingNowOnly: state.filter.workingNowOnly,
        httpsOnly: state.filter.httpsOnly,
        genreId: state.filter.genreId,
        countryCode: state.filter.countryCode,
        language: state.filter.language,
        codec: state.filter.codec,
        minBitrateKbps: state.filter.minBitrateKbps,
      ),
      sort: state.sort,
      recentQueries: state.recentQueries,
    );
  }
}

final NotifierProvider<SearchViewModel, SearchState> searchViewModelProvider =
    NotifierProvider<SearchViewModel, SearchState>(SearchViewModel.new);
