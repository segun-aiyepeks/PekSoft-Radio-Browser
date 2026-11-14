import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Immutable state for [StationDetailScreen] (`/station/:id`).
@immutable
class StationDetailState {
  const StationDetailState({
    this.station,
    this.similarStations = const <Station>[],
    this.isFavourite = false,
    this.isReportSubmitting = false,
    this.reportSubmitted = false,
    this.error,
  });

  final Station? station;
  final List<Station> similarStations;
  final bool isFavourite;
  final bool isReportSubmitting;
  final bool reportSubmitted;
  final AppFailure? error;

  StationDetailState copyWith({
    Station? station,
    List<Station>? similarStations,
    bool? isFavourite,
    bool? isReportSubmitting,
    bool? reportSubmitted,
    AppFailure? error,
    bool clearError = false,
  }) {
    return StationDetailState(
      station: station ?? this.station,
      similarStations: similarStations ?? this.similarStations,
      isFavourite: isFavourite ?? this.isFavourite,
      isReportSubmitting: isReportSubmitting ?? this.isReportSubmitting,
      reportSubmitted: reportSubmitted ?? this.reportSubmitted,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Family ViewModel for [StationDetailScreen] (`/station/:id`).
class StationDetailViewModel extends AsyncNotifier<StationDetailState> {
  StationDetailViewModel(this.stationId);

  final String stationId;

  @override
  Future<StationDetailState> build() => _load();

  Future<void> toggleFavourite() async {
    final StationDetailState? current = state.asData?.value;
    final Station? station = current?.station;
    if (current == null || station == null) return;

    final library = ref.read(libraryRepositoryProvider);
    final Result<void> res = current.isFavourite
        ? await library.removeFavourite(station.id)
        : await library.addFavourite(station);

    state = AsyncValue<StationDetailState>.data(switch (res) {
      Success<void>() => current.copyWith(
        isFavourite: !current.isFavourite,
        clearError: true,
      ),
      Failure<void>(:final error) => current.copyWith(error: error),
    });
  }

  void submitReport(String reason) {
    final StationDetailState? current = state.asData?.value;
    if (current == null || reason.trim().isEmpty) return;
    state = AsyncValue<StationDetailState>.data(
      current.copyWith(isReportSubmitting: false, reportSubmitted: true),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<StationDetailState>.loading();
    state = AsyncValue<StationDetailState>.data(await _load());
  }

  Future<StationDetailState> _load() async {
    final stationRepo = ref.read(stationRepositoryProvider);
    final libraryRepo = ref.read(libraryRepositoryProvider);

    final Result<Station> stationRes = await stationRepo.getStationById(
      stationId,
    );
    switch (stationRes) {
      case Failure<Station>(:final error):
        return StationDetailState(error: error);
      case Success<Station>(:final data):
        final Result<List<Station>> similarRes = await stationRepo
            .getSimilarStations(data);
        final Result<bool> favRes = await libraryRepo.isFavourite(data.id);
        return StationDetailState(
          station: data,
          similarStations: switch (similarRes) {
            Success<List<Station>>(:final data) => data,
            Failure<List<Station>>() => const <Station>[],
          },
          isFavourite: switch (favRes) {
            Success<bool>(:final data) => data,
            Failure<bool>() => false,
          },
        );
    }
  }
}

final stationDetailViewModelProvider =
    AsyncNotifierProvider.family<
      StationDetailViewModel,
      StationDetailState,
      String
    >(StationDetailViewModel.new);
