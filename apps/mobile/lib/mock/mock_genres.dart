import 'package:peksoft_radio/mock/mock_models.dart';

/// 20 canonical genres for Phase 1 UI (mock).
const List<MockGenre> mockGenres = [
  MockGenre(
    id: 'afrobeats',
    name: 'Afrobeats',
    stationCount: 184,
    tagline: 'Lagos, Accra & diaspora rhythms',
  ),
  MockGenre(
    id: 'highlife',
    name: 'Highlife',
    stationCount: 62,
    tagline: 'West African guitar & brass classics',
  ),
  MockGenre(
    id: 'pop',
    name: 'Pop',
    stationCount: 5188,
    tagline: 'Chart hits & mainstream radio',
  ),
  MockGenre(
    id: 'news',
    name: 'News & Talk',
    stationCount: 2728,
    tagline: 'Breaking news, current affairs & debate',
  ),
  MockGenre(
    id: 'gospel',
    name: 'Gospel & Christian',
    stationCount: 870,
    tagline: 'Praise, worship & gospel stations',
  ),
  MockGenre(
    id: 'jazz',
    name: 'Jazz',
    stationCount: 1076,
    tagline: 'Smooth, bebop, contemporary & Tokyo jazz',
  ),
  MockGenre(
    id: 'hiphop',
    name: 'Hip-Hop & R&B',
    stationCount: 940,
    tagline: 'Rap, R&B, soul & grime',
  ),
  MockGenre(
    id: 'rock',
    name: 'Rock',
    stationCount: 2654,
    tagline: 'Classic, indie & alternative rock',
  ),
  MockGenre(
    id: 'electronic',
    name: 'Electronic & Dance',
    stationCount: 1418,
    tagline: 'House, techno, club & ambient',
  ),
  MockGenre(
    id: 'classical',
    name: 'Classical',
    stationCount: 1171,
    tagline: 'Orchestral, chamber & opera',
  ),
  MockGenre(
    id: 'oldies',
    name: 'Oldies',
    stationCount: 1213,
    tagline: '70s, 80s & 90s nostalgia',
  ),
  MockGenre(
    id: 'sports',
    name: 'Sports',
    stationCount: 345,
    tagline: 'Live football commentary & sports talk',
  ),
  MockGenre(
    id: 'lounge',
    name: 'Lounge & Chill',
    stationCount: 387,
    tagline: 'Downtempo, chillout & study beats',
  ),
  MockGenre(
    id: 'reggae',
    name: 'Reggae & Dancehall',
    stationCount: 412,
    tagline: 'Roots, dub & Caribbean vibes',
  ),
  MockGenre(
    id: 'latin',
    name: 'Latin & Samba',
    stationCount: 809,
    tagline: 'Salsa, MPB, samba & reggaeton',
  ),
  MockGenre(
    id: 'country',
    name: 'Country',
    stationCount: 633,
    tagline: 'Nashville, Americana & folk',
  ),
  MockGenre(
    id: 'soul',
    name: 'Soul & Funk',
    stationCount: 426,
    tagline: 'Motown, neo-soul & funk grooves',
  ),
  MockGenre(
    id: 'bollywood',
    name: 'Bollywood & Desi',
    stationCount: 310,
    tagline: 'Hindi film hits & South Asian radio',
  ),
  MockGenre(
    id: 'jpop',
    name: 'J-Pop & Anime',
    stationCount: 245,
    tagline: 'Tokyo pop, city pop & soundtracks',
  ),
  MockGenre(
    id: 'islamic',
    name: 'Islamic & Quran',
    stationCount: 290,
    tagline: 'Recitations & community broadcasts',
  ),
];

/// 10 languages for Phase 1 UI (mock).
const List<MockLanguage> mockLanguages = [
  MockLanguage(code: 'en', name: 'English', stationCount: 11463),
  MockLanguage(code: 'yo', name: 'Yoruba', stationCount: 42),
  MockLanguage(code: 'pcm', name: 'Nigerian Pidgin', stationCount: 28),
  MockLanguage(code: 'fr', name: 'French', stationCount: 2180),
  MockLanguage(code: 'de', name: 'German', stationCount: 2940),
  MockLanguage(code: 'pt', name: 'Portuguese', stationCount: 1620),
  MockLanguage(code: 'ja', name: 'Japanese', stationCount: 390),
  MockLanguage(code: 'hi', name: 'Hindi', stationCount: 410),
  MockLanguage(code: 'ar', name: 'Arabic', stationCount: 520),
  MockLanguage(code: 'ha', name: 'Hausa', stationCount: 31),
];
