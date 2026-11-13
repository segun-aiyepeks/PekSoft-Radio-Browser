import 'package:flutter/foundation.dart';

/// Mock domain models for Phase 1 UI development.
/// Replaced by freezed domain models and Riverpod ViewModels in Phases 2–3.
@immutable
class MockStation {
  const MockStation({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.flagEmoji,
    required this.genres,
    required this.language,
    required this.codec,
    required this.bitrateKbps,
    this.isHls = false,
    this.isWorking = true,
    this.isHttps = true,
    this.faviconUrl,
    this.clickCount = 0,
    this.votes = 0,
    this.homepage = '',
    this.currentTrack,
  });

  final String id;
  final String name;
  final String country;
  final String countryCode;
  final String flagEmoji;
  final List<String> genres;
  final String language;
  final String codec;
  final int bitrateKbps;
  final bool isHls;
  final bool isWorking;
  final bool isHttps;
  final String? faviconUrl;
  final int clickCount;
  final int votes;
  final String homepage;
  final String? currentTrack;
}

@immutable
class MockCountry {
  const MockCountry({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.stationCount,
    required this.workingCount,
  });

  final String code;
  final String name;
  final String flagEmoji;
  final int stationCount;
  final int workingCount;
}

@immutable
class MockGenre {
  const MockGenre({
    required this.id,
    required this.name,
    required this.stationCount,
    required this.tagline,
  });

  final String id;
  final String name;
  final int stationCount;
  final String tagline;
}

@immutable
class MockLanguage {
  const MockLanguage({
    required this.code,
    required this.name,
    required this.stationCount,
  });

  final String code;
  final String name;
  final int stationCount;
}

@immutable
class MockCuratedCollection {
  const MockCuratedCollection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.stationIds,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> stationIds;
}
