import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:peksoft_radio/core/ads/ad_policy.dart';
import 'package:peksoft_radio/core/ads/ad_service.dart';
import 'package:peksoft_radio/core/ads/admob_ad_service.dart';
import 'package:peksoft_radio/core/analytics/firebase_analytics_service.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/normalisation/genre_map.dart';
import 'package:peksoft_radio/core/routing/app_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped (guest mode): $e');
  }

  final Future<AppDatabase> databaseFuture = AppDatabase.openDefault();
  final Future<GenreMap> genreMapFuture = _loadGenreMap();
  final AppDatabase database = await databaseFuture;
  final GenreMap genreMap = await genreMapFuture;
  final AdPolicy adPolicy = AdPolicy();
  final AdMobAdService adService = AdMobAdService(policy: adPolicy);
  final FirebaseAnalyticsService analyticsService = FirebaseAnalyticsService();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    unawaited(
      analyticsService.recordError(
        details.exception,
        details.stack,
        reason: details.context?.toDescription(),
        fatal: true,
      ),
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    unawaited(analyticsService.recordError(error, stack, fatal: true));
    return false;
  };

  unawaited(
    adService.runConsentFlowIfRequired().then((AdConsentStatus status) {
      final bool granted =
          status == AdConsentStatus.notRequired ||
          status == AdConsentStatus.obtained;
      return analyticsService.setConsentGranted(granted);
    }),
  );

  runApp(
    PekSoftRadioApp(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        genreMapProvider.overrideWithValue(genreMap),
        adPolicyProvider.overrideWithValue(adPolicy),
        adServiceProvider.overrideWithValue(adService),
        analyticsServiceProvider.overrideWithValue(analyticsService),
      ],
    ),
  );
}

Future<GenreMap> _loadGenreMap() async {
  for (final assetPath in const <String>[
    'assets/config/genre-map.json',
    '../../packages/shared/genre-map.json',
  ]) {
    try {
      final String raw = await rootBundle.loadString(assetPath);
      return GenreMap.fromJsonString(raw);
    } catch (_) {
      // Try next candidate path.
    }
  }
  return GenreMap(
    version: 1,
    maxGenresPerStation: 2,
    noiseTags: const <String>{},
    definitions: const <GenreDefinition>[],
  );
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
