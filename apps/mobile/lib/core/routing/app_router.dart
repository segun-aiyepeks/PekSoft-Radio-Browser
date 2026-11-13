import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/features/dev_gallery/presentation/component_gallery_screen.dart';
import 'package:peksoft_radio/features/explore/presentation/country_detail_screen.dart';
import 'package:peksoft_radio/features/explore/presentation/explore_screen.dart';
import 'package:peksoft_radio/features/explore/presentation/genre_detail_screen.dart';
import 'package:peksoft_radio/features/home/presentation/home_screen.dart';
import 'package:peksoft_radio/features/library/presentation/library_screen.dart';
import 'package:peksoft_radio/features/onboarding/presentation/splash_screen.dart';
import 'package:peksoft_radio/features/onboarding/presentation/welcome_screen.dart';
import 'package:peksoft_radio/features/player/presentation/mini_player_slot.dart';
import 'package:peksoft_radio/features/profile/presentation/profile_screen.dart';
import 'package:peksoft_radio/features/search/presentation/search_screen.dart';
import 'package:peksoft_radio/features/station/presentation/station_detail_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WelcomeScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _MobileShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExploreScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => SearchScreen(
        initialQuery: state.uri.queryParameters['q'] ?? '',
        initialLanguage: state.uri.queryParameters['language'],
      ),
    ),
    GoRoute(
      path: '/country/:code',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          CountryDetailScreen(countryCode: state.pathParameters['code'] ?? ''),
    ),
    GoRoute(
      path: '/genre/:name',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => GenreDetailScreen(
        genreName: Uri.decodeComponent(state.pathParameters['name'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/station/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          StationDetailScreen(stationId: state.pathParameters['id'] ?? ''),
    ),
    if (kDebugMode)
      GoRoute(
        path: '/gallery',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ComponentGalleryScreen(),
      ),
  ],
);

class _MobileShellScaffold extends StatelessWidget {
  const _MobileShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerSlot(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
