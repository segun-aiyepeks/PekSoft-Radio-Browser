export interface WebGenre {
  id: string;
  slug: string;
  name: string;
  tagline: string;
  stationCount: number;
  gradient: string;
}

export interface WebCountry {
  code: string;
  name: string;
  flag: string;
  stationCount: number;
  workingCount: number;
}

export interface WebStation {
  id: string;
  slug: string;
  name: string;
  streamUrl: string;
  fallbackStreamUrl?: string;
  homepage: string;
  faviconUrl: string | null;
  isHttps: boolean;
  isHttpsPlayable: boolean;
  isHls: boolean;
  isWorking: boolean;
  countryCode: string;
  countryName: string;
  countryFlag: string;
  genres: string[];
  language: string;
  codec: string;
  bitrateKbps: number;
  votes: number;
  clickCount: number;
  currentTrack?: string;
}

export interface WebCollection {
  id: string;
  title: string;
  subtitle: string;
  stationIds: string[];
  gradient: string;
  imageUrl?: string;
}

export const MOCK_COUNTRIES: WebCountry[] = [
  { code: 'NG', name: 'Nigeria', flag: '🇳🇬', stationCount: 142, workingCount: 118 },
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧', stationCount: 684, workingCount: 612 },
  { code: 'GH', name: 'Ghana', flag: '🇬🇭', stationCount: 86, workingCount: 74 },
  { code: 'FR', name: 'France', flag: '🇫🇷', stationCount: 540, workingCount: 495 },
  { code: 'US', name: 'United States', flag: '🇺🇸', stationCount: 1920, workingCount: 1710 },
  { code: 'ZA', name: 'South Africa', flag: '🇿🇦', stationCount: 164, workingCount: 141 },
  { code: 'JP', name: 'Japan', flag: '🇯🇵', stationCount: 215, workingCount: 198 },
  { code: 'BR', name: 'Brazil', flag: '🇧🇷', stationCount: 430, workingCount: 382 },
];

export const MOCK_GENRES: WebGenre[] = [
  {
    id: 'afrobeats',
    slug: 'afrobeats',
    name: 'Afrobeats & Pop',
    tagline: 'Lagos, Accra & diaspora rhythms',
    stationCount: 184,
    gradient: 'from-amber-500/35 via-orange-600/20 to-slate-900',
  },
  {
    id: 'jazz',
    slug: 'jazz',
    name: 'Jazz & Soul',
    tagline: 'Late-night standards, neo-soul & Tokyo clubs',
    stationCount: 642,
    gradient: 'from-indigo-500/35 via-blue-600/20 to-slate-900',
  },
  {
    id: 'news',
    slug: 'news',
    name: 'News & Talk',
    tagline: 'Global headlines, sports & commentary',
    stationCount: 910,
    gradient: 'from-emerald-500/30 via-teal-600/20 to-slate-900',
  },
  {
    id: 'electronic',
    slug: 'electronic',
    name: 'Electronic & Dance',
    tagline: 'House, ambient, techno & club sets',
    stationCount: 1120,
    gradient: 'from-fuchsia-500/30 via-purple-600/20 to-slate-900',
  },
  {
    id: 'classical',
    slug: 'classical',
    name: 'Classical & Acoustic',
    tagline: 'Orchestral, piano & concert halls',
    stationCount: 410,
    gradient: 'from-sky-500/30 via-cyan-600/20 to-slate-900',
  },
  {
    id: 'gospel',
    slug: 'gospel',
    name: 'Gospel & Praise',
    tagline: 'Choirs, worship & Sunday mornings',
    stationCount: 275,
    gradient: 'from-yellow-500/30 via-amber-600/20 to-slate-900',
  },
];

export const MOCK_STATIONS: WebStation[] = [
  {
    id: 'st-cool-fm',
    slug: 'cool-fm-96-9-lagos',
    name: 'Cool FM 96.9 Lagos',
    streamUrl: 'https://icestream.coolfm.ng/live.mp3',
    homepage: 'https://www.coolfm.ng',
    faviconUrl: null,
    isHttps: true,
    isHttpsPlayable: true,
    isHls: false,
    isWorking: true,
    countryCode: 'NG',
    countryName: 'Nigeria',
    countryFlag: '🇳🇬',
    genres: ['afrobeats', 'pop'],
    language: 'English, Pidgin',
    codec: 'AAC',
    bitrateKbps: 128,
    votes: 4820,
    clickCount: 3190,
    currentTrack: 'Burna Boy — City Boys',
  },
  {
    id: 'st-wazobia-fm',
    slug: 'wazobia-fm-95-1-lagos',
    name: 'Wazobia FM 95.1 Lagos',
    streamUrl: 'http://stream.wazobiafm.com:8000/lagos',
    homepage: 'https://www.wazobiafm.com',
    faviconUrl: null,
    isHttps: false,
    isHttpsPlayable: false,
    isHls: false,
    isWorking: true,
    countryCode: 'NG',
    countryName: 'Nigeria',
    countryFlag: '🇳🇬',
    genres: ['news', 'afrobeats'],
    language: 'Pidgin, Yoruba',
    codec: 'MP3',
    bitrateKbps: 96,
    votes: 3910,
    clickCount: 2840,
    currentTrack: 'Morning Tori & Traffic',
  },
  {
    id: 'st-fip-paris',
    slug: 'fip-paris',
    name: 'FIP Paris',
    streamUrl: 'https://icecast.radiofrance.fr/fip-hifi.aac',
    homepage: 'https://www.radiofrance.fr/fip',
    faviconUrl: null,
    isHttps: true,
    isHttpsPlayable: true,
    isHls: false,
    isWorking: true,
    countryCode: 'FR',
    countryName: 'France',
    countryFlag: '🇫🇷',
    genres: ['jazz', 'electronic'],
    language: 'French',
    codec: 'AAC',
    bitrateKbps: 192,
    votes: 12450,
    clickCount: 9420,
    currentTrack: 'Khruangbin — Time (You and I)',
  },
  {
    id: 'st-bbc-world',
    slug: 'bbc-world-service',
    name: 'BBC World Service',
    streamUrl: 'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service',
    homepage: 'https://www.bbc.co.uk/worldserviceradio',
    faviconUrl: null,
    isHttps: true,
    isHttpsPlayable: true,
    isHls: false,
    isWorking: true,
    countryCode: 'GB',
    countryName: 'United Kingdom',
    countryFlag: '🇬🇧',
    genres: ['news'],
    language: 'English',
    codec: 'MP3',
    bitrateKbps: 128,
    votes: 18200,
    clickCount: 15100,
    currentTrack: 'Global Newsdesk Live',
  },
  {
    id: 'st-joy-fm',
    slug: 'joy-99-7-fm-accra',
    name: 'Joy 99.7 FM Accra',
    streamUrl: 'https://stream.myjoyonline.com/joyfm.mp3',
    homepage: 'https://www.myjoyonline.com',
    faviconUrl: null,
    isHttps: true,
    isHttpsPlayable: true,
    isHls: false,
    isWorking: true,
    countryCode: 'GH',
    countryName: 'Ghana',
    countryFlag: '🇬🇭',
    genres: ['news', 'afrobeats'],
    language: 'English, Twi',
    codec: 'MP3',
    bitrateKbps: 128,
    votes: 2940,
    clickCount: 1870,
    currentTrack: 'Super Morning Show',
  },
  {
    id: 'st-jazz-tokyo',
    slug: 'tokyo-jazz-club',
    name: 'Tokyo Jazz Club FM',
    streamUrl: 'https://streams.tokyojazz.jp/live.aac',
    homepage: 'https://tokyojazz.jp',
    faviconUrl: null,
    isHttps: true,
    isHttpsPlayable: true,
    isHls: false,
    isWorking: true,
    countryCode: 'JP',
    countryName: 'Japan',
    countryFlag: '🇯🇵',
    genres: ['jazz', 'classical'],
    language: 'Japanese',
    codec: 'AAC',
    bitrateKbps: 192,
    votes: 5410,
    clickCount: 3890,
    currentTrack: 'Ryo Fukui — Scenery',
  },
  {
    id: 'st-kexp',
    slug: 'kexp-90-3-seattle',
    name: 'KEXP 90.3 Seattle',
    streamUrl: 'https://kexp-mp3-128.streamguys1.com/kexp128.mp3',
    homepage: 'https://www.kexp.org',
    faviconUrl: null,
    isHttps: true,
    isHttpsPlayable: true,
    isHls: false,
    isWorking: true,
    countryCode: 'US',
    countryName: 'United States',
    countryFlag: '🇺🇸',
    genres: ['electronic', 'jazz'],
    language: 'English',
    codec: 'MP3',
    bitrateKbps: 128,
    votes: 9840,
    clickCount: 7210,
    currentTrack: 'Little Simz — Gorilla',
  },
  {
    id: 'st-metro-fm',
    slug: 'metro-fm-south-africa',
    name: 'Metro FM Johannesburg',
    streamUrl: 'https://stream.metrofm.co.za/live.aac',
    homepage: 'https://www.metrofm.co.za',
    faviconUrl: null,
    isHttps: true,
    isHttpsPlayable: true,
    isHls: false,
    isWorking: true,
    countryCode: 'ZA',
    countryName: 'South Africa',
    countryFlag: '🇿🇦',
    genres: ['afrobeats', 'electronic'],
    language: 'English, Zulu',
    codec: 'AAC',
    bitrateKbps: 128,
    votes: 4120,
    clickCount: 2950,
    currentTrack: 'Kabza De Small — Imithandazo',
  },
];

export const MOCK_COLLECTIONS: WebCollection[] = [
  {
    id: 'col-afrobeats',
    title: 'Afrobeats Worldwide',
    subtitle: 'Lagos, Accra & London studios on air now',
    stationIds: ['st-cool-fm', 'st-joy-fm', 'st-metro-fm'],
    gradient: 'from-amber-500/40 via-orange-600/20 to-[#101A2E]',
  },
  {
    id: 'col-jazz',
    title: 'Jazz After Dark',
    subtitle: 'Tokyo clubs, Paris FM & late-night vinyl',
    stationIds: ['st-fip-paris', 'st-jazz-tokyo', 'st-kexp'],
    gradient: 'from-indigo-500/40 via-sky-600/20 to-[#101A2E]',
  },
  {
    id: 'col-news',
    title: 'Global Newsdesk',
    subtitle: 'Live breaking headlines in English & French',
    stationIds: ['st-bbc-world', 'st-wazobia-fm', 'st-joy-fm'],
    gradient: 'from-emerald-500/35 via-teal-600/20 to-[#101A2E]',
  },
];

export function getStationBySlug(slug: string): WebStation | undefined {
  return MOCK_STATIONS.find((s) => s.slug === slug || s.id === slug);
}

export function getCountryByCode(code: string): WebCountry | undefined {
  return MOCK_COUNTRIES.find(
    (c) => c.code.toLowerCase() === code.toLowerCase(),
  );
}

export function getGenreBySlug(slug: string): WebGenre | undefined {
  return MOCK_GENRES.find(
    (g) => g.slug.toLowerCase() === slug.toLowerCase() || g.id === slug,
  );
}
