# Mobile Domain Model — PekSoft Radio Browser

All mobile domain models are immutable `@freezed` value objects with zero dependency on Flutter UI, Dio DTOs, or Drift database tables.

```mermaid
classDiagram
  direction TB

  class Station {
    +String id
    +String name
    +String streamUrl
    +String homepage
    +String? faviconUrl
    +bool usesFallbackLogo
    +bool isHttps
    +bool isHls
    +bool isWorking
    +String countryCode
    +String countryName
    +List~Genre~ genres
    +String language
    +String codec
    +int bitrateKbps
    +int votes
    +int clickCount
    +int clickTrend
    +double? geoLat
    +double? geoLong
  }

  class Country {
    +String code
    +String name
    +int stationCount
    +int workingCount
  }

  class Genre {
    +String id
    +String name
    +int stationCount
    +String tagline
  }

  class Language {
    +String code
    +String name
    +int stationCount
  }

  class Collection {
    +String id
    +String title
    +String subtitle
    +List~String~ stationIds
    +bool isCurated
    +DateTime? updatedAt
  }

  class SongHistoryEntry {
    +String id
    +String stationId
    +String stationName
    +String trackTitle
    +DateTime playedAt
  }

  class PlaybackState {
    +PlaybackStatus status
    +Station? currentStation
    +String? icyTitle
    +Duration? sleepTimerRemaining
    +AppFailure? error
  }

  class UserSettings {
    +bool dataSaver
    +int? defaultSleepMinutes
    +AppThemePreference theme
    +String languageCode
    +bool notifyCollections
    +bool workingNowDefault
    +String? homeCountryCode
    +List~String~ preferredGenreIds
  }

  class Entitlement {
    +EntitlementTier tier
    +int maxFavourites
    +int maxCollections
    +int maxSongHistory
    +bool adsEnabled
    +DateTime? expiresAt
  }

  class AppFailure {
    <<sealed>>
    +String userMessage
  }

  Station "0..*" --> "0..*" Genre : tagged with
  Station "0..*" --> "1" Country : countryCode
  Collection "0..*" --> "0..*" Station : stationIds
  SongHistoryEntry "0..*" --> "1" Station : stationId
  PlaybackState --> "0..1" Station : currentStation
  PlaybackState --> "0..1" AppFailure : error
```

## Failure & Result Model

Repositories return `Result<T>` (`Success<T>` | `Failure<T>`), mapping transport, mirror, stream, storage, or entitlement errors into the sealed `AppFailure` hierarchy:

- `NetworkFailure` (with optional `statusCode`)
- `TimeoutFailure`
- `MirrorUnavailableFailure`
- `StreamPlaybackFailure`
- `StorageFailure`
- `NotFoundFailure`
- `ValidationFailure`
- `EntitlementRequiredFailure`
- `UnknownFailure`
