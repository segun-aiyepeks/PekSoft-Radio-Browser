import 'mock_models.dart';

/// Mock catalog of 6 curated editorial collections.
///
/// Every `stationIds` entry references a valid ID in `mockStations`.
/// All entries are MOCK data.
const List<MockCuratedCollection> mockCuratedCollections =
    <MockCuratedCollection>[
      MockCuratedCollection(
        id: 'mock-col-west-africa-pulse',
        title: 'West Africa Pulse',
        subtitle: 'Afrobeats, Highlife & Lagos-Accra talk',
        stationIds: <String>[
          'mock-ng-wazobia-lagos',
          'mock-ng-cool-fm',
          'mock-ng-lagos-jump',
          'mock-gh-joy-fm',
          'mock-gh-citi-fm',
        ],
      ),
      MockCuratedCollection(
        id: 'mock-col-global-news-desk',
        title: 'Global News Desk',
        subtitle: 'Trusted live journalism from 5 continents',
        stationIds: <String>[
          'mock-gb-bbc-world',
          'mock-us-npr-news',
          'mock-fr-rtl',
          'mock-de-dlf',
          'mock-ng-nigeria-info',
          'mock-in-air-fm-gold',
        ],
      ),
      MockCuratedCollection(
        id: 'mock-col-late-night-focus',
        title: 'Late-Night Focus & Lo-Fi',
        subtitle: 'Instrumental beats, jazz & calm ambient',
        stationIds: <String>[
          'mock-us-lofi-beats',
          'mock-jp-shonan-beach',
          'mock-fr-fip',
          'mock-gb-classic-fm',
          'mock-de-klassik-radio',
        ],
      ),
      MockCuratedCollection(
        id: 'mock-col-jazz-and-bossa',
        title: 'Jazz & Bossa Classics',
        subtitle: 'Warm horns, bossa nova & soulful grooves',
        stationIds: <String>[
          'mock-gb-jazz-fm',
          'mock-br-bossa-jazz',
          'mock-za-kaya-959',
          'mock-jp-shonan-beach',
          'mock-fr-fip',
        ],
      ),
      MockCuratedCollection(
        id: 'mock-col-weekend-club',
        title: 'Weekend Energy & Electronic',
        subtitle: 'High-tempo sets from Berlin, London & Tokyo',
        stationIds: <String>[
          'mock-gb-bbc-radio-1',
          'mock-de-sunshine-live',
          'mock-de-flux-fm',
          'mock-za-5fm',
          'mock-jp-jwave',
        ],
      ),
      MockCuratedCollection(
        id: 'mock-col-bollywood-and-latin',
        title: 'Mumbai to São Paulo',
        subtitle: 'Bollywood hits, MPB & Latin rhythms',
        stationIds: <String>[
          'mock-in-radio-mirchi',
          'mock-in-radio-city-hindi',
          'mock-br-nova-brasil',
          'mock-br-89-rock',
          'mock-fr-radio-nova',
        ],
      ),
    ];
