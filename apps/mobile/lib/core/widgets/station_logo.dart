import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';

const List<String> _kFallbackGenreAssets = [
  'assets/images/genres/afrobeats.jpg',
  'assets/images/genres/jazz.jpg',
  'assets/images/genres/electronic.jpg',
  'assets/images/genres/news.jpg',
  'assets/images/genres/classical.jpg',
  'assets/images/genres/gospel.jpg',
  'assets/images/genres/pop.jpg',
  'assets/images/genres/rock.jpg',
  'assets/images/genres/sports.jpg',
  'assets/images/genres/hiphop.jpg',
];

const Map<String, String> _kGenreAssetMap = {
  'afrobeats': 'assets/images/genres/afrobeats.jpg',
  'bollywood': 'assets/images/genres/bollywood.jpg',
  'classical': 'assets/images/genres/classical.jpg',
  'country': 'assets/images/genres/country.jpg',
  'electronic': 'assets/images/genres/electronic.jpg',
  'gospel': 'assets/images/genres/gospel.jpg',
  'highlife': 'assets/images/genres/highlife.jpg',
  'hiphop': 'assets/images/genres/hiphop.jpg',
  'islamic': 'assets/images/genres/islamic.jpg',
  'jazz': 'assets/images/genres/jazz.jpg',
  'jpop': 'assets/images/genres/jpop.jpg',
  'latin': 'assets/images/genres/latin.jpg',
  'lounge': 'assets/images/genres/lounge.jpg',
  'news': 'assets/images/genres/news.jpg',
  'oldies': 'assets/images/genres/oldies.jpg',
  'pop': 'assets/images/genres/pop.jpg',
  'reggae': 'assets/images/genres/reggae.jpg',
  'rock': 'assets/images/genres/rock.jpg',
  'soul': 'assets/images/genres/soul.jpg',
  'sports': 'assets/images/genres/sports.jpg',
};

final List<({RegExp pattern, String asset})> _kNameThemeRules = [
  (
    pattern: RegExp(
      r'\b(gospel|praise|worship|christian|church|jesus|christ|bible|faith|grace|hymn|choir)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/gospel.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(sport|sports|football|soccer|premier|nba|nfl|espn|brila|stadium|athletic)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/sports.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(news|talk|info|bbc|npr|cnn|rfi|rmc|rtl|headline|parliament|world service)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/news.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(quran|koran|islamic|islam|mosque|sunnah|ramadan)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/islamic.jpg',
  ),
  (
    pattern: RegExp(r'\b(jazz|swing|bossa|sax)\b', caseSensitive: false),
    asset: 'assets/images/genres/jazz.jpg',
  ),
  (
    pattern: RegExp(r'\b(soul|funk|motown|r&b|rnb)\b', caseSensitive: false),
    asset: 'assets/images/genres/soul.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(hiphop|hip-hop|hip hop|rap|trap|urban)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/hiphop.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(rock|metal|punk|indie|alt|alternative|grunge)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/rock.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(pop|hits|top 40|top40|chart|charts|hot)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/pop.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(reggae|dancehall|dub|ska|jamaica)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/reggae.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(latin|salsa|samba|bachata|reggaeton|cumbia|tango)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/latin.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(country|nashville|bluegrass|folk|americana)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/country.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(oldies|retro|80s|70s|60s|golden|nostalgia|vintage)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/oldies.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(lounge|chill|ambient|lofi|lo-fi|relax|zen|cafe|smooth)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/lounge.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(classic|classical|symphony|philharmonic|orchestra|piano|opera|baroque|mozart|bach|concert)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/classical.jpg',
  ),
  (
    pattern: RegExp(r'\b(highlife|juju|fuji)\b', caseSensitive: false),
    asset: 'assets/images/genres/highlife.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(afro|afrobeats|naija|lagos|abuja|ghana|accra|amapiano|wazobia)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/afrobeats.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(jpop|j-pop|anime|tokyo|shibuya)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/jpop.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(bollywood|desi|hindi|bhangra|punjabi)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/bollywood.jpg',
  ),
  (
    pattern: RegExp(
      r'\b(electronic|dance|house|techno|trance|edm|club|synth|rave|disco)\b',
      caseSensitive: false,
    ),
    asset: 'assets/images/genres/electronic.jpg',
  ),
];

/// Resolves the closest bundled genre/theme artwork asset for a station or genre.
String resolveStationThemeAsset(
  String stationName, {
  List<String> genres = const [],
}) {
  for (final g in genres) {
    final key = g.trim().toLowerCase();
    final direct = _kGenreAssetMap[key];
    if (direct != null) return direct;
  }

  for (final rule in _kNameThemeRules) {
    if (rule.pattern.hasMatch(stationName)) {
      return rule.asset;
    }
  }

  final hash = stationName.codeUnits.fold<int>(0, (acc, c) => acc + c);
  return _kFallbackGenreAssets[hash % _kFallbackGenreAssets.length];
}

/// Displays a station's own logo (`faviconUrl`) when available, falling back
/// to the closest bundled genre/theme photograph instead of letter monograms.
class StationLogo extends StatelessWidget {
  const StationLogo({
    super.key,
    required this.stationName,
    this.faviconUrl,
    this.genres = const [],
    this.size = AppSpacing.touchTarget,
    this.hasLogo = false,
  });

  final String stationName;
  final String? faviconUrl;
  final List<String> genres;
  final double size;
  final bool hasLogo;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themeAsset = resolveStationThemeAsset(stationName, genres: genres);
    final url = faviconUrl?.trim();
    final canLoadNetwork =
        url != null &&
        url.isNotEmpty &&
        (url.startsWith('https://') || url.startsWith('http://'));

    Widget fallbackImage() => Image.asset(
      themeAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        color: colors.surfaceElevated,
        alignment: Alignment.center,
        child: Icon(
          Icons.radio_rounded,
          size: size * 0.45,
          color: colors.textSecondary,
        ),
      ),
    );

    return Semantics(
      image: true,
      label: '$stationName artwork',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: canLoadNetwork
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallbackImage(),
              )
            : fallbackImage(),
      ),
    );
  }
}
