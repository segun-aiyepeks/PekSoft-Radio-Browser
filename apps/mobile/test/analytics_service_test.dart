import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/analytics/analytics_service.dart';
import 'package:peksoft_radio/core/analytics/firebase_analytics_service.dart';
import 'package:peksoft_radio/features/library/presentation/view_models/library_view_model.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/subscription/presentation/view_models/subscription_view_model.dart';

import 'helpers/fake_analytics_service.dart';
import 'helpers/mock_repository_overrides.dart';

void main() {
  group('Milestone 5.5 — AnalyticsService, Section 11 Taxonomy, PII & Consent', () {
    test('sanitizeAnalyticsParams strips PII keys and email-like values', () {
      final Map<String, Object> clean =
          sanitizeAnalyticsParams(<String, Object?>{
            'station_id': 'st-1',
            'country_code': 'NG',
            'email': 'ada@example.com',
            'user_email': 'ada@example.com',
            'displayName': 'Ada',
            'uid': 'firebase-uid-123',
            'token': 'secret-jwt',
            'notes': 'Contact ada@example.com for details',
            'bitrate_kbps': 128,
          });

      expect(clean, <String, Object>{
        'station_id': 'st-1',
        'country_code': 'NG',
        'bitrate_kbps': 128,
      });
    });

    test(
      'AnalyticsService drops all events and errors when consent is not granted',
      () async {
        final FakeAnalyticsService analytics = FakeAnalyticsService(
          initialConsent: false,
        );

        await analytics.logStationPlay(
          stationId: 'st-1',
          countryCode: 'NG',
          codec: 'MP3',
          bitrateKbps: 128,
        );
        await analytics.recordError(StateError('boom'), StackTrace.current);
        expect(analytics.events, isEmpty);
        expect(analytics.recordedErrors, isEmpty);

        // Granting consent enables logging
        await analytics.setConsentGranted(true);
        await analytics.logStationPlay(
          stationId: 'st-1',
          countryCode: 'NG',
          codec: 'MP3',
          bitrateKbps: 128,
        );
        await analytics.recordError(StateError('boom'), StackTrace.current);
        expect(analytics.events.length, 1);
        expect(analytics.events.first.name, AnalyticsEvents.stationPlay);
        expect(analytics.recordedErrors.length, 1);

        // FirebaseAnalyticsService respects initialConsent = false safely
        final FirebaseAnalyticsService prodService = FirebaseAnalyticsService(
          initialConsent: false,
        );
        expect(prodService.consentGranted, isFalse);
        await prodService.logPaywallView(trigger: 'settings');
        await prodService.setConsentGranted(true);
        expect(prodService.consentGranted, isTrue);
      },
    );

    test(
      'ViewModels emit Section 11 events (station_play, favorite_add, paywall_view, purchase_success)',
      () async {
        final FakeAnalyticsService analytics = FakeAnalyticsService(
          initialConsent: true,
        );
        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(analyticsService: analytics),
        );
        addTearDown(container.dispose);

        const Station station = Station(
          id: 'st-lagos-1',
          name: 'Lagos Beat',
          streamUrl: 'https://stream.example.com/lagos.mp3',
          countryCode: 'NG',
          countryName: 'Nigeria',
          codec: 'AAC',
          bitrateKbps: 128,
        );

        await container
            .read(playerViewModelProvider.notifier)
            .playStation(station);
        await container
            .read(libraryViewModelProvider.notifier)
            .toggleFavourite(station);

        await container.read(subscriptionViewModelProvider.future);
        container
            .read(subscriptionViewModelProvider.notifier)
            .recordPaywallView(trigger: 'library_limit');
        await container
            .read(subscriptionViewModelProvider.notifier)
            .startPurchase();

        final List<String> names = analytics.events
            .map((RecordedAnalyticsEvent e) => e.name)
            .toList();

        expect(names, contains(AnalyticsEvents.stationPlay));
        expect(names, contains(AnalyticsEvents.favoriteAdd));
        expect(names, contains(AnalyticsEvents.paywallView));
        expect(names, contains(AnalyticsEvents.purchaseSuccess));
      },
    );
  });
}
