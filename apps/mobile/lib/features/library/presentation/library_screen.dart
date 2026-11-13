import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/station/presentation/mock_station_tile.dart';
import 'package:peksoft_radio/mock/mock.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Favourites'),
              Tab(text: 'Recents'),
              Tab(text: 'Collections'),
              Tab(text: 'Song History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FavouritesTab(),
            _RecentsTab(),
            _CollectionsTab(),
            _SongHistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _FavouritesTab extends StatelessWidget {
  const _FavouritesTab();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mockSessionController,
      builder: (context, _) {
        final List<MockStation> favs = mockSessionController.favourites;
        final bool isPro = mockSessionController.isPro;

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            if (!isPro)
              _FreeTierLimitCard(
                title: '${favs.length} of 10 free favourites used',
                subtitle: 'Upgrade to Pro for unlimited synced favourites.',
                onUpgrade: () => context.push('/paywall'),
              ),
            if (favs.isEmpty)
              EmptyState(
                title: 'No favourites yet',
                message: 'Tap the heart on any station to save it here.',
                icon: Icons.favorite_border_rounded,
                actionLabel: 'Explore stations',
                onAction: () => context.go('/explore'),
              )
            else
              for (final MockStation station in favs)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: MockStationTile(station: station),
                ),
          ],
        );
      },
    );
  }
}

class _RecentsTab extends StatelessWidget {
  const _RecentsTab();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mockSessionController,
      builder: (context, _) {
        final List<MockStation> recents = mockSessionController.recents;
        if (recents.isEmpty) {
          return EmptyState(
            title: 'No recent stations',
            message: 'Stations you play will appear here.',
            icon: Icons.history_rounded,
            actionLabel: 'Browse Home',
            onAction: () => context.go('/home'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: recents.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: MockStationTile(station: recents[index]),
          ),
        );
      },
    );
  }
}

class _CollectionsTab extends StatelessWidget {
  const _CollectionsTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final List<MockCuratedCollection> collections = getMockCuratedCollections();

    return ListenableBuilder(
      listenable: mockSessionController,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            if (!mockSessionController.isPro)
              _FreeTierLimitCard(
                title: '1 of 2 custom collections on Free',
                subtitle: 'Unlock unlimited playlists & cross-device sync.',
                onUpgrade: () => context.push('/paywall'),
              ),
            for (final MockCuratedCollection col in collections)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Material(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: ListTile(
                    minTileHeight: AppSpacing.touchTarget,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      side: BorderSide(color: colors.border),
                    ),
                    leading: Icon(
                      Icons.collections_bookmark_outlined,
                      color: colors.accent,
                    ),
                    title: Text(
                      col.title,
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${col.stationIds.length} stations · ${col.subtitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textMuted,
                    ),
                    onTap: () {
                      final stations = getMockStationsForCollection(col);
                      if (stations.isNotEmpty) {
                        context.push('/station/${stations.first.id}');
                      }
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SongHistoryTab extends StatelessWidget {
  const _SongHistoryTab();

  static const List<({String track, String station, String when})> _mockSongs =
      <({String track, String station, String when})>[
        (
          track: 'Burna Boy — City Boys',
          station: 'Wazobia FM: Lagos',
          when: 'Just now',
        ),
        (
          track: 'Kamasi Washington — Street Fighter Mas',
          station: 'Jazz FM London',
          when: '18 mins ago',
        ),
        (
          track: 'Air — La Femme d\'Argent',
          station: 'FIP Paris',
          when: '1 hour ago',
        ),
        (
          track: 'Nujabes — Feather',
          station: 'Nightride Lo-Fi Chill',
          when: 'Yesterday',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListenableBuilder(
      listenable: mockSessionController,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            if (!mockSessionController.isPro)
              _FreeTierLimitCard(
                title: 'Free tier keeps last 10 songs',
                subtitle: 'Go Pro for searchable unlimited song history.',
                onUpgrade: () => context.push('/paywall'),
              ),
            for (final song in _mockSongs)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Material(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: ListTile(
                    minTileHeight: AppSpacing.touchTarget,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      side: BorderSide(color: colors.border),
                    ),
                    leading: Icon(
                      Icons.music_note_rounded,
                      color: colors.accent,
                    ),
                    title: Text(
                      song.track,
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${song.station} · ${song.when}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FreeTierLimitCard extends StatelessWidget {
  const _FreeTierLimitCard({
    required this.title,
    required this.subtitle,
    required this.onUpgrade,
  });

  final String title;
  final String subtitle;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.accent),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: colors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: 'Upgrade to Pro',
            child: SizedBox(
              height: AppSpacing.touchTarget,
              child: FilledButton(
                onPressed: onUpgrade,
                child: const Text('Go Pro'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
