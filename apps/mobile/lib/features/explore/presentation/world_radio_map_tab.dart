import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_station_dto.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Fetches live geo-located stations from Radio Browser (`has_geo_info=true`),
/// falling back to top cached/catalog stations with coordinates if offline.
final FutureProvider<List<Station>> mapStationsProvider =
    FutureProvider<List<Station>>((ref) async {
      final client = ref.read(radioBrowserClientProvider);
      final normaliser = ref.read(stationNormaliserProvider);

      try {
        final Result<List<RadioBrowserStationDto>> res = await client
            .searchStations(
              hasGeoInfo: true,
              hideBroken: true,
              order: 'clickcount',
              reverse: true,
              limit: 250,
            );
        if (res case Success<List<RadioBrowserStationDto>>(:final data)) {
          final List<Station> geoStations = data
              .map(normaliser.normalize)
              .where(
                (Station s) =>
                    s.geoLat != null &&
                    s.geoLong != null &&
                    s.geoLat!.abs() <= 90 &&
                    s.geoLong!.abs() <= 180 &&
                    (s.geoLat != 0 || s.geoLong != 0),
              )
              .toList(growable: false);
          if (geoStations.isNotEmpty) {
            return geoStations;
          }
        }
      } catch (_) {
        // Fall back to catalog repository below.
      }

      final Result<List<Station>> fallback = await ref
          .read(catalogRepositoryProvider)
          .getTopStations(limit: 150);
      return switch (fallback) {
        Success<List<Station>>(:final data) =>
          data
              .where(
                (Station s) =>
                    s.geoLat != null &&
                    s.geoLong != null &&
                    (s.geoLat != 0 || s.geoLong != 0),
              )
              .toList(growable: false),
        Failure<List<Station>>() => const <Station>[],
      };
    });

/// Interactive World Radio Map powered by `flutter_map` + free CARTO / OSM
/// tiles and live Radio Browser `geo_lat` / `geo_long` coordinates.
class WorldRadioMapTab extends ConsumerStatefulWidget {
  const WorldRadioMapTab({super.key});

  @override
  ConsumerState<WorldRadioMapTab> createState() => _WorldRadioMapTabState();
}

class _WorldRadioMapTabState extends ConsumerState<WorldRadioMapTab> {
  static const List<({String code, String label, LatLng center, double zoom})>
  _hubs = [
    (
      code: 'WORLD',
      label: 'World',
      center: LatLng(16.0, 12.0),
      zoom: 2.2,
    ),
    (
      code: 'NG',
      label: 'Lagos',
      center: LatLng(6.5244, 3.3792),
      zoom: 7.5,
    ),
    (
      code: 'GH',
      label: 'Accra',
      center: LatLng(5.6037, -0.1870),
      zoom: 7.5,
    ),
    (
      code: 'GB',
      label: 'London',
      center: LatLng(51.5072, -0.1276),
      zoom: 7.5,
    ),
    (
      code: 'US',
      label: 'New York',
      center: LatLng(40.7128, -74.0060),
      zoom: 6.5,
    ),
    (
      code: 'JP',
      label: 'Tokyo',
      center: LatLng(35.6762, 139.6503),
      zoom: 7.0,
    ),
    (
      code: 'BR',
      label: 'São Paulo',
      center: LatLng(-23.5505, -46.6333),
      zoom: 6.5,
    ),
  ];

  final MapController _mapController = MapController();
  String _activeHub = 'WORLD';
  Station? _selectedStation;

  void _jumpToHub(({String code, String label, LatLng center, double zoom}) hub) {
    setState(() {
      _activeHub = hub.code;
    });
    _mapController.move(hub.center, hub.zoom);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(2.0, 16.0);
    _mapController.move(camera.center, nextZoom);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final AsyncValue<List<Station>> stationsAsync = ref.watch(
      mapStationsProvider,
    );
    final PlayerState playerState = ref.watch(playerViewModelProvider);
    final List<Station> stations = stationsAsync.value ?? const <Station>[];

    return Column(
      children: [
        // Hub quick-jump strip (clean solid chips, Hick's Law)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final hub in _hubs) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(hub.label),
                      selected: _activeHub == hub.code,
                      onSelected: (_) => _jumpToHub(hub),
                      selectedColor: colors.accent,
                      backgroundColor: colors.surface,
                      side: BorderSide(
                        color: _activeHub == hub.code
                            ? colors.accent
                            : colors.border,
                      ),
                      labelStyle: AppTypography.caption.copyWith(
                        color: _activeHub == hub.code
                            ? colors.onAccent
                            : colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      showCheckmark: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(16.0, 12.0),
                  initialZoom: 2.2,
                  minZoom: 2.0,
                  maxZoom: 16.0,
                  backgroundColor: colors.background,
                  onTap: (_, _) {
                    if (_selectedStation != null) {
                      setState(() => _selectedStation = null);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.peksoft.radio',
                    maxZoom: 18,
                    tileBuilder: isDark
                        ? (context, tileWidget, tile) => ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              -0.85, 0, 0, 0, 232,
                              0, -0.85, 0, 0, 236,
                              0, 0, -0.80, 0, 246,
                              0, 0, 0, 1, 0,
                            ]),
                            child: tileWidget,
                          )
                        : null,
                  ),
                  MarkerLayer(
                    markers: [
                      for (final Station station in stations)
                        Marker(
                          point: LatLng(station.geoLat!, station.geoLong!),
                          width: AppSpacing.touchTarget,
                          height: AppSpacing.touchTarget,
                          child: _StationPin(
                            isSelected: _selectedStation?.id == station.id,
                            isPlaying:
                                playerState.playback.currentStation?.id ==
                                    station.id &&
                                playerState.playback.status ==
                                    PlaybackStatus.playing,
                            stationName: station.name,
                            onTap: () {
                              setState(() => _selectedStation = station);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Loading pill when fetching live geo stations
              if (stationsAsync.isLoading)
                Positioned(
                  top: AppSpacing.md,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.accentText,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Loading global stations…',
                            style: AppTypography.caption.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Station count badge (top-left)
              if (!stationsAsync.isLoading)
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      '${stations.length} stations on map',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Zoom controls (top-right, clean solid Material 3 buttons)
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: Column(
                  children: [
                    _MapControlButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Zoom in',
                      onPressed: () => _zoomBy(1.5),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MapControlButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Zoom out',
                      onPressed: () => _zoomBy(-1.5),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MapControlButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Refresh stations',
                      onPressed: () => ref.invalidate(mapStationsProvider),
                    ),
                  ],
                ),
              ),

              // Attribution (bottom-right, tucked above card if open)
              Positioned(
                bottom: _selectedStation == null ? AppSpacing.sm : 148,
                right: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),

              // Selected station card (solid surface, no glassmorphism)
              if (_selectedStation != null)
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: _MapStationCard(
                    station: _selectedStation!,
                    isPlaying:
                        playerState.playback.currentStation?.id ==
                            _selectedStation!.id &&
                        playerState.playback.status == PlaybackStatus.playing,
                    onPlayToggle: () {
                      final notifier = ref.read(
                        playerViewModelProvider.notifier,
                      );
                      if (playerState.playback.currentStation?.id ==
                          _selectedStation!.id) {
                        notifier.togglePlayPause();
                      } else {
                        notifier.playStation(_selectedStation!);
                      }
                    },
                    onOpenDetails: () =>
                        context.push('/station/${_selectedStation!.id}'),
                    onClose: () => setState(() => _selectedStation = null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StationPin extends StatelessWidget {
  const _StationPin({
    required this.isSelected,
    required this.isPlaying,
    required this.stationName,
    required this.onTap,
  });

  final bool isSelected;
  final bool isPlaying;
  final String stationName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final Color fill = isPlaying
        ? colors.success
        : (isSelected ? colors.accent : colors.accent);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Map pin for $stationName${isPlaying ? ", playing" : ""}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: isSelected ? 26 : 16,
            height: isSelected ? 26 : 16,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 3 : 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.radio_rounded, size: 13, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: colors.border),
      ),
      child: SizedBox(
        width: AppSpacing.touchTarget,
        height: AppSpacing.touchTarget,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 20, color: colors.textPrimary),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _MapStationCard extends StatelessWidget {
  const _MapStationCard({
    required this.station,
    required this.isPlaying,
    required this.onPlayToggle,
    required this.onOpenDetails,
    required this.onClose,
  });

  final Station station;
  final bool isPlaying;
  final VoidCallback onPlayToggle;
  final VoidCallback onOpenDetails;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            StationLogo(
              stationName: station.name,
              faviconUrl: station.usesFallbackLogo ? null : station.faviconUrl,
              hasLogo: !station.usesFallbackLogo,
              genres: station.genres.map((g) => g.id).toList(),
              size: 52,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Open details for ${station.name}',
                child: InkWell(
                  onTap: onOpenDetails,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        CountryFlagImage(
                          countryCode: station.countryCode,
                          width: 16,
                          height: 12,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            station.countryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    QualityBadge(
                      codec: station.codec,
                      bitrateKbps: station.bitrateKbps,
                    ),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              toggled: isPlaying,
              label: isPlaying
                  ? 'Pause ${station.name}'
                  : 'Play ${station.name}',
              excludeSemantics: true,
              child: SizedBox(
                width: AppSpacing.touchTarget,
                height: AppSpacing.touchTarget,
                child: FilledButton(
                  onPressed: onPlayToggle,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
