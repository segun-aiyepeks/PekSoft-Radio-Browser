import 'dart:convert';

import 'package:peksoft_radio/features/catalog/domain/genre.dart';

/// Definition of a canonical genre loaded from `packages/shared/genre-map.json`.
class GenreDefinition {
  const GenreDefinition({
    required this.id,
    required this.name,
    required this.tagline,
    required this.aliases,
  });

  factory GenreDefinition.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawAliases =
        json['aliases'] as List<dynamic>? ?? const <dynamic>[];
    return GenreDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      aliases: rawAliases
          .map((dynamic item) => item.toString().trim().toLowerCase())
          .where((String s) => s.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String id;
  final String name;
  final String tagline;
  final List<String> aliases;

  Genre toGenre({int stationCount = 0}) {
    return Genre(
      id: id,
      name: name,
      stationCount: stationCount,
      tagline: tagline,
    );
  }
}

/// Canonical genre mapping loaded from `packages/shared/genre-map.json`.
class GenreMap {
  GenreMap({
    required this.version,
    required this.maxGenresPerStation,
    required Set<String> noiseTags,
    required this.definitions,
  }) : noiseTags = Set<String>.unmodifiable(
         noiseTags.map((String s) => s.trim().toLowerCase()),
       ) {
    final Map<String, GenreDefinition> exact = <String, GenreDefinition>{};
    final List<MapEntry<String, GenreDefinition>> sortedAliases =
        <MapEntry<String, GenreDefinition>>[];

    for (final GenreDefinition def in definitions) {
      exact[def.id.toLowerCase()] = def;
      exact[def.name.toLowerCase()] = def;
      for (final String alias in def.aliases) {
        exact.putIfAbsent(alias, () => def);
        sortedAliases.add(MapEntry<String, GenreDefinition>(alias, def));
      }
    }

    // Longer aliases match first when checking compound tags.
    sortedAliases.sort((a, b) => b.key.length.compareTo(a.key.length));
    _exactLookup = exact;
    _sortedAliases = sortedAliases;
  }

  /// Parses the shared `packages/shared/genre-map.json` document.
  factory GenreMap.fromJsonString(String rawJson) {
    final Map<String, dynamic> json =
        jsonDecode(rawJson) as Map<String, dynamic>;
    final List<dynamic> rawNoise =
        json['noiseTags'] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> rawGenres =
        json['genres'] as List<dynamic>? ?? const <dynamic>[];

    return GenreMap(
      version: (json['version'] as num?)?.toInt() ?? 1,
      maxGenresPerStation: (json['maxGenresPerStation'] as num?)?.toInt() ?? 2,
      noiseTags: rawNoise.map((dynamic item) => item.toString()).toSet(),
      definitions: rawGenres
          .whereType<Map<String, dynamic>>()
          .map(GenreDefinition.fromJson)
          .where((GenreDefinition g) => g.id.isNotEmpty)
          .toList(growable: false),
    );
  }

  final int version;
  final int maxGenresPerStation;
  final Set<String> noiseTags;
  final List<GenreDefinition> definitions;

  late final Map<String, GenreDefinition> _exactLookup;
  late final List<MapEntry<String, GenreDefinition>> _sortedAliases;

  /// Returns all canonical [Genre]s in definition order.
  List<Genre> allCanonicalGenres() =>
      definitions.map((GenreDefinition d) => d.toGenre()).toList();

  /// Maps a raw comma-separated Radio Browser `tags` string into at most
  /// [maxGenresPerStation] canonical, deduplicated [Genre] values.
  List<Genre> mapTags(String rawTags) {
    if (rawTags.trim().isEmpty) {
      return const <Genre>[];
    }

    final List<String> tokens = rawTags
        .split(',')
        .map((String token) => token.trim().toLowerCase())
        .where((String token) => token.isNotEmpty && !noiseTags.contains(token))
        .toList(growable: false);

    final List<Genre> matched = <Genre>[];
    final Set<String> seenIds = <String>{};

    for (final String token in tokens) {
      final GenreDefinition? def = _matchToken(token);
      if (def == null || seenIds.contains(def.id)) {
        continue;
      }
      seenIds.add(def.id);
      matched.add(def.toGenre());
      if (matched.length >= maxGenresPerStation) {
        break;
      }
    }

    return List<Genre>.unmodifiable(matched);
  }

  GenreDefinition? _matchToken(String token) {
    final GenreDefinition? exact = _exactLookup[token];
    if (exact != null) {
      return exact;
    }

    // Compound tag fallback (e.g. "90s pop hits" or "afro-gospel praise").
    for (final MapEntry<String, GenreDefinition> entry in _sortedAliases) {
      if (entry.key.length < 3) {
        continue;
      }
      if (token.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
