import 'package:peksoft_radio/core/network/dto/radio_browser_country_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_language_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_station_dto.dart';
import 'package:peksoft_radio/core/normalisation/genre_map.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Supported station sort orders in discovery and search views.
enum StationSortOption { popular, trending, votes, bitrate, nameAsc }

/// Filter criteria applied to normalised [Station] lists.
///
/// [workingNowOnly] defaults to `true` per `docs/api-spike.md`.
class StationFilter {
  const StationFilter({
    this.workingNowOnly = true,
    this.httpsOnly = false,
    this.genreId,
    this.countryCode,
    this.language,
    this.codec,
    this.minBitrateKbps,
    this.query,
  });

  final bool workingNowOnly;
  final bool httpsOnly;
  final String? genreId;
  final String? countryCode;
  final String? language;
  final String? codec;
  final int? minBitrateKbps;
  final String? query;
}

/// Normalises, deduplicates, filters, and sorts Radio Browser DTOs into
/// canonical domain models according to `docs/api-spike.md`.
class StationNormaliser {
  const StationNormaliser({required this.genreMap});

  final GenreMap genreMap;

  /// Converts a raw [RadioBrowserStationDto] into a normalised [Station].
  Station normalize(RadioBrowserStationDto dto) {
    final String resolved = dto.urlResolved.trim();
    final String rawUrl = dto.url.trim();
    final String streamUrl = resolved.isNotEmpty ? resolved : rawUrl;

    final bool isHttps =
        resolved.toLowerCase().startsWith('https://') ||
        rawUrl.toLowerCase().startsWith('https://');

    final String trimmedFavicon = dto.favicon.trim();
    final String lowerFavicon = trimmedFavicon.toLowerCase();
    final bool hasValidLogo =
        trimmedFavicon.isNotEmpty &&
        (lowerFavicon.startsWith('https://') ||
            lowerFavicon.startsWith('http://'));

    final bool isWorking = dto.lastcheckok == 1 && streamUrl.isNotEmpty;
    final String normalizedCodec = dto.codec.trim().isEmpty
        ? 'UNKNOWN'
        : dto.codec.trim().toUpperCase();

    final List<Genre> genres = genreMap.mapTags(dto.tags);

    return Station(
      id: dto.stationuuid.trim(),
      name: dto.name.trim(),
      streamUrl: streamUrl,
      homepage: dto.homepage.trim(),
      faviconUrl: hasValidLogo ? trimmedFavicon : null,
      usesFallbackLogo: !hasValidLogo,
      isHttps: isHttps,
      isHls: dto.hls == 1,
      isWorking: isWorking,
      countryCode: dto.countrycode.trim().toUpperCase(),
      countryName: dto.country.trim(),
      genres: genres,
      language: _primaryLanguage(dto.language),
      codec: normalizedCodec,
      bitrateKbps: dto.bitrate < 0 ? 0 : dto.bitrate,
      votes: dto.votes < 0 ? 0 : dto.votes,
      clickCount: dto.clickcount < 0 ? 0 : dto.clickcount,
      clickTrend: dto.clicktrend,
      geoLat: dto.geoLat,
      geoLong: dto.geoLong,
    );
  }

  /// Normalises a batch of DTOs and merges duplicates by `stationuuid` first,
  /// then by `(normalizedName, countryCode, resolvedHost)`.
  List<Station> normalizeAndDeduplicate(List<RadioBrowserStationDto> dtos) {
    final Map<String, Station> byUuid = <String, Station>{};

    for (final RadioBrowserStationDto dto in dtos) {
      final Station candidate = normalize(dto);
      if (candidate.id.isEmpty) {
        continue;
      }
      final Station? existing = byUuid[candidate.id];
      if (existing == null || _isBetterCandidate(candidate, existing)) {
        byUuid[candidate.id] = candidate;
      }
    }

    final Map<String, Station> bySignature = <String, Station>{};
    for (final Station station in byUuid.values) {
      final String signature = _duplicateSignature(station);
      final Station? existing = bySignature[signature];
      if (existing == null || _isBetterCandidate(station, existing)) {
        bySignature[signature] = station;
      }
    }

    return List<Station>.unmodifiable(bySignature.values);
  }

  /// Filters and sorts a list of [Station]s.
  List<Station> filterAndSort(
    List<Station> stations, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
  }) {
    final String? normalizedQuery = _normalizeNullable(filter.query);
    final String? normalizedGenre = _normalizeNullable(filter.genreId);
    final String? normalizedCountry = filter.countryCode?.trim().toUpperCase();
    final String? normalizedLanguage = _normalizeNullable(filter.language);
    final String? normalizedCodec = filter.codec?.trim().toUpperCase();

    final List<Station> filtered = stations
        .where((Station s) {
          if (filter.workingNowOnly && !s.isWorking) {
            return false;
          }
          if (filter.httpsOnly && !s.isHttps) {
            return false;
          }
          if (normalizedGenre != null &&
              !s.genres.any((Genre g) => g.id == normalizedGenre)) {
            return false;
          }
          if (normalizedCountry != null &&
              normalizedCountry.isNotEmpty &&
              s.countryCode != normalizedCountry) {
            return false;
          }
          if (normalizedLanguage != null &&
              s.language.toLowerCase() != normalizedLanguage) {
            return false;
          }
          if (normalizedCodec != null &&
              normalizedCodec.isNotEmpty &&
              s.codec.toUpperCase() != normalizedCodec) {
            return false;
          }
          if (filter.minBitrateKbps != null &&
              s.bitrateKbps < filter.minBitrateKbps!) {
            return false;
          }
          if (normalizedQuery != null && !_matchesQuery(s, normalizedQuery)) {
            return false;
          }
          return true;
        })
        .toList(growable: true);

    filtered.sort((Station a, Station b) => _compareStations(a, b, sort));
    return List<Station>.unmodifiable(filtered);
  }

  /// Converts a [RadioBrowserCountryDto] to a domain [Country].
  Country normalizeCountry(RadioBrowserCountryDto dto) {
    return Country(
      code: dto.iso31661.trim().toUpperCase(),
      name: dto.name.trim(),
      stationCount: dto.stationcount < 0 ? 0 : dto.stationcount,
    );
  }

  /// Converts a [RadioBrowserLanguageDto] to a domain [Language].
  Language normalizeLanguage(RadioBrowserLanguageDto dto) {
    final String name = dto.name.trim();
    final String code = (dto.iso639 ?? '').trim().toLowerCase();
    return Language(
      code: code.isNotEmpty ? code : name.toLowerCase(),
      name: name,
      stationCount: dto.stationcount < 0 ? 0 : dto.stationcount,
    );
  }

  static int _compareStations(Station a, Station b, StationSortOption sort) {
    switch (sort) {
      case StationSortOption.popular:
        final int clicks = b.clickCount.compareTo(a.clickCount);
        if (clicks != 0) return clicks;
        return b.votes.compareTo(a.votes);
      case StationSortOption.trending:
        final int trend = b.clickTrend.compareTo(a.clickTrend);
        if (trend != 0) return trend;
        return b.clickCount.compareTo(a.clickCount);
      case StationSortOption.votes:
        final int votes = b.votes.compareTo(a.votes);
        if (votes != 0) return votes;
        return b.clickCount.compareTo(a.clickCount);
      case StationSortOption.bitrate:
        final int bitrate = b.bitrateKbps.compareTo(a.bitrateKbps);
        if (bitrate != 0) return bitrate;
        return b.clickCount.compareTo(a.clickCount);
      case StationSortOption.nameAsc:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
  }

  static bool _matchesQuery(Station station, String query) {
    if (station.name.toLowerCase().contains(query)) return true;
    if (station.countryName.toLowerCase().contains(query)) return true;
    if (station.language.toLowerCase().contains(query)) return true;
    return station.genres.any(
      (Genre g) => g.name.toLowerCase().contains(query),
    );
  }

  static String? _normalizeNullable(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim().toLowerCase();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _primaryLanguage(String rawLanguage) {
    final String trimmed = rawLanguage.trim();
    if (trimmed.isEmpty) return '';
    final String first = trimmed.split(',').first.trim();
    if (first.isEmpty) return '';
    return '${first[0].toUpperCase()}${first.substring(1)}';
  }

  static String _duplicateSignature(Station station) {
    final String normalizedName = station.name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final Uri? uri = Uri.tryParse(station.streamUrl);
    final String host = (uri?.host ?? station.streamUrl).toLowerCase();
    return '$normalizedName|${station.countryCode}|$host';
  }

  static bool _isBetterCandidate(Station candidate, Station existing) {
    if (candidate.isWorking != existing.isWorking) {
      return candidate.isWorking;
    }
    if (candidate.isHttps != existing.isHttps) {
      return candidate.isHttps;
    }
    if (candidate.clickCount != existing.clickCount) {
      return candidate.clickCount > existing.clickCount;
    }
    if (candidate.bitrateKbps != existing.bitrateKbps) {
      return candidate.bitrateKbps > existing.bitrateKbps;
    }
    return !candidate.usesFallbackLogo && existing.usesFallbackLogo;
  }
}
