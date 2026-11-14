import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/normalisation/genre_map.dart';
import 'package:peksoft_radio/core/routing/app_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppDatabase database = await AppDatabase.openDefault();
  final GenreMap genreMap = await _loadGenreMap();

  runApp(
    PekSoftRadioApp(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        genreMapProvider.overrideWithValue(genreMap),
      ],
    ),
  );
}

Future<GenreMap> _loadGenreMap() async {
  try {
    final String raw = await rootBundle.loadString(
      '../../packages/shared/genre-map.json',
    );
    return GenreMap.fromJsonString(raw);
  } catch (_) {
    return GenreMap(
      version: 1,
      maxGenresPerStation: 2,
      noiseTags: const <String>{},
      definitions: const <GenreDefinition>[],
    );
  }
}

class PekSoftRadioApp extends StatelessWidget {
  const PekSoftRadioApp({super.key, this.overrides = const <Override>[]});

  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: appThemeController,
        builder: (context, themeMode, _) {
          return MaterialApp.router(
            title: 'PekSoft Radio Browser',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
