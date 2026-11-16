import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/library/presentation/view_models/library_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/presentation/station_list_tile.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LibraryState> libraryAsync = ref.watch(
      libraryViewModelProvider,
    );

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
        body: libraryAsync.when(
          loading: () => const SkeletonList(itemCount: 5),
          error: (Object error, StackTrace _) => ErrorState(
            title: 'Could not load library',
            message: error.toString(),
            onRetry: () =>
                ref.read(libraryViewModelProvider.notifier).refresh(),
          ),
          data: (LibraryState libState) => TabBarView(
            children: [
              _FavouritesTab(libState: libState),
              _RecentsTab(libState: libState),
              _CollectionsTab(libState: libState),
              _SongHistoryTab(libState: libState),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavouritesTab extends StatelessWidget {
  const _FavouritesTab({required this.libState});

  final LibraryState libState;

  @override
  Widget build(BuildContext context) {
    final List<Station> favs = libState.favourites;
    final Entitlement entitlement = libState.entitlement;
    final bool isPro = entitlement.tier == EntitlementTier.pro;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (!isPro)
          _FreeTierLimitCard(
            title:
                '${favs.length} of ${entitlement.maxFavourites} free favourites used',
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
          for (final Station station in favs)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: StationListTile(station: station),
            ),
      ],
    );
  }
}

class _RecentsTab extends StatelessWidget {
  const _RecentsTab({required this.libState});

  final LibraryState libState;

  @override
  Widget build(BuildContext context) {
    final List<Station> recents = libState.recents;
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
        child: StationListTile(station: recents[index]),
      ),
    );
  }
}

class _CollectionsTab extends ConsumerWidget {
  const _CollectionsTab({required this.libState});

  final LibraryState libState;

  Future<void> _promptNewCollection(BuildContext context, WidgetRef ref) async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('New collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Collection name',
            hintText: 'E.g. Morning Focus',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await ref
        .read(libraryViewModelProvider.notifier)
        .createCollection(name, subtitle: 'Custom collection');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final List<Collection> collections = libState.collections;
    final Entitlement entitlement = libState.entitlement;
    final bool isPro = entitlement.tier == EntitlementTier.pro;
    final int customCount = collections
        .where((Collection c) => !c.isCurated)
        .length;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (!isPro)
          _FreeTierLimitCard(
            title:
                '$customCount of ${entitlement.maxCollections} custom collections on Free',
            subtitle: 'Unlock unlimited playlists & cross-device sync.',
            onUpgrade: () => context.push('/paywall'),
          ),
        if (libState.limitReachedFailure != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Material(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: ListTile(
                leading: Icon(Icons.lock_outline_rounded, color: colors.accent),
                title: Text(libState.limitReachedFailure!.message),
                trailing: TextButton(
                  onPressed: () => context.push('/paywall'),
                  child: const Text('Go Pro'),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _promptNewCollection(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New collection'),
            ),
          ),
        ),
        if (collections.isEmpty)
          const EmptyState(
            title: 'No collections yet',
            message: 'Create a collection to group your favourite stations.',
            icon: Icons.collections_bookmark_outlined,
          )
        else
          for (final Collection col in collections)
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
                    '${col.stationIds.length} stations${col.subtitle.isNotEmpty ? ' · ${col.subtitle}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  trailing: col.isCurated
                      ? Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textMuted,
                        )
                      : IconButton(
                          tooltip: 'Delete collection',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colors.textMuted,
                          ),
                          onPressed: () => ref
                              .read(libraryViewModelProvider.notifier)
                              .deleteCollection(col.id),
                        ),
                  onTap: () {
                    if (col.stationIds.isNotEmpty) {
                      context.push('/station/${col.stationIds.first}');
                    }
                  },
                ),
              ),
            ),
      ],
    );
  }
}

class _SongHistoryTab extends ConsumerWidget {
  const _SongHistoryTab({required this.libState});

  final LibraryState libState;

  static String _formatTime(DateTime dt) {
    final Duration diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final List<SongHistoryEntry> songs = libState.songHistory;
    final Entitlement entitlement = libState.entitlement;
    final bool isPro = entitlement.tier == EntitlementTier.pro;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (!isPro)
          _FreeTierLimitCard(
            title: 'Free tier keeps last ${entitlement.maxSongHistory} songs',
            subtitle: 'Go Pro for searchable unlimited song history.',
            onUpgrade: () => context.push('/paywall'),
          ),
        if (songs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ref
                    .read(libraryViewModelProvider.notifier)
                    .clearSongHistory(),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Clear history'),
              ),
            ),
          ),
        if (songs.isEmpty)
          const EmptyState(
            title: 'No song history yet',
            message: 'Track titles detected from live streams appear here.',
            icon: Icons.music_note_outlined,
          )
        else
          for (final SongHistoryEntry song in songs)
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
                  leading: Icon(Icons.music_note_rounded, color: colors.accent),
                  title: Text(
                    song.trackTitle,
                    style: AppTypography.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${song.stationName} · ${_formatTime(song.playedAt)}',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  onTap: () => context.push('/station/${song.stationId}'),
                ),
              ),
            ),
      ],
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
