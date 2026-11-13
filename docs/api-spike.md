# Radio Browser API Spike — Findings & Normalisation Recommendations

**Run timestamp:** `2026-11-13T13:51:07.326Z`  
**Script:** [`apps/api/scripts/radio-browser-spike.ts`](../apps/api/scripts/radio-browser-spike.ts)  
**User-Agent:** `PekSoftRadioBrowser/0.1.0`  
**Saved fixtures:** [`packages/shared/fixtures/radio-browser/`](../packages/shared/fixtures/radio-browser/)

---

## 1. Mirror Discovery & Latency

| Method | Result | Latency |
| --- | --- | --- |
| DNS A + PTR (`all.api.radio-browser.info`) | `91.98.4.78` → `de1.api.radio-browser.info` | `147 ms` |
| DNS SRV (`_api._tcp.radio-browser.info`) | `de1.api.radio-browser.info:443` (priority 1, weight 1) | — |
| Server-list (`GET https://all.api.radio-browser.info/json/servers`) | 2 entries (IPv4 `91.98.4.78` + IPv6 `2a01:4f8:1c1d:699::1`), both `de1.api.radio-browser.info` | `1,279 ms` |
| Mirror health ping (`GET https://de1.api.radio-browser.info/json/stats`) | HTTP 200 OK | `990 ms` |

### Recommendation for Mobile & Backend
- **Primary discovery**: `GET https://all.api.radio-browser.info/json/servers`, deduplicated by `name`, cached for **24 hours**.
- **Fallback**: Direct DNS A lookup (`all.api.radio-browser.info`) + fallback hostname list (`de1.api.radio-browser.info`, `all.api.radio-browser.info`) if `/json/servers` is unreachable.
- **Why `/json/servers` over DNS SRV on Android**: Dart's `dart:io` does not expose DNS SRV queries natively, whereas `/json/servers` works over standard HTTPS in `Dio` and Node `fetch`.

---

## 2. Live Response Counts & Saved Fixtures

- **Countries** (`/json/countries?order=stationcount&reverse=true`): `225` total (saved top 150 in `countries.json`)
- **Tags** (`/json/tags?order=stationcount&reverse=true&limit=500`): `500` fetched (saved top 250 in `tags.json`)
- **Languages** (`/json/languages?order=stationcount&reverse=true&limit=200`): `200` fetched (saved top 100 in `languages.json`)
- **Top stations by clickcount** (`/json/stations/topclick/150`): `150` fetched (saved 120 in `stations-topclick.json`)
- **Nigerian working stations** (`/json/stations/search?countrycode=NG&lastcheckok=1&order=clickcount&reverse=true&limit=100`): `75` fetched (saved 75 in `stations-ng-working.json`)
- **Combined deduplicated sample**: `200` stations (`stations-sample-200.json`)

---

## 3. Real Field Names & Observed Types

### Station record (`stations-sample-200.json`, 37 fields)

| Field | Observed JSON Type(s) | Empty / Null in 200 | Notes |
| --- | --- | --- | --- |
| `stationuuid` | `string` | 0 | Primary unique station ID (UUID) |
| `changeuuid` | `string` | 0 | Revision UUID |
| `serveruuid` | `null` | 200 | Always `null` in sample; treat as `string \| null` |
| `name` | `string` | 0 | Station display name (can contain colons/emojis) |
| `url` | `string` | 0 | Submitted stream/playlist URL |
| `url_resolved` | `string` | 1 | Final resolved stream URL (prefer for playback) |
| `homepage` | `string` | 8 | Station website URL |
| `favicon` | `string` | 42 | Logo image URL (`""` when missing) |
| `tags` | `string` | 57 | Comma-separated tag string (not an array!) |
| `country` | `string` | 1 | Human-readable country name |
| `countrycode` | `string` | 1 | ISO 3166-1 alpha-2 code (e.g. `NG`, `US`) |
| `iso_3166_2` | `string \| null` | 180 | Optional subdivision code (e.g. `IT-SO`) |
| `state` | `string` | 102 | State / region string |
| `language` | `string` | 63 | Comma-separated or single language string |
| `languagecodes` | `string` | 66 | ISO 639 codes (e.g. `en`) |
| `votes` | `number` | 0 | Integer vote count |
| `clickcount` | `number` | 0 | Integer 24h click count |
| `clicktrend` | `number` | 0 | Signed integer click trend |
| `codec` | `string` | 1 | e.g. `MP3`, `AAC`, `AAC+`, `OGG`, `UNKNOWN` |
| `bitrate` | `number` | 0 | Integer kbps (`0` when unknown) |
| `hls` | `number` | 0 | **`0` or `1`** (integer, NOT boolean) |
| `lastcheckok` | `number` | 0 | **`0` or `1`** (integer, NOT boolean) |
| `ssl_error` | `number` | 0 | **`0` or `1`** (integer, NOT boolean) |
| `geo_lat` / `geo_long` | `number \| null` | 149 | Coordinates (missing on 74.5% of stations) |
| `geo_distance` | `null` | 200 | Always `null` unless geo-search is used |
| `has_extended_info` | `boolean` | 0 | True boolean |
| `lastchangetime`, `lastchecktime`, `lastcheckoktime`, `lastlocalchecktime`, `clicktimestamp` | `string` | 0–1 | Space-separated UTC timestamps (`YYYY-MM-DD HH:mm:ss`) |
| `*_iso8601` variants | `string \| null` | 0–1 | Prefer the `*_iso8601` fields for parsing |

### Country, Tag & Language records
- **Country**: `{ name: string, iso_3166_1: string, stationcount: number }`
- **Tag**: `{ name: string, stationcount: number }`
- **Language**: `{ name: string, iso_639: string | null, stationcount: number }` (`iso_639` was `null` in 14/50 sampled languages).

---

## 4. Stream Health, HTTPS, Favicons, Codecs & Bitrates

| Metric | Sample 200 | Top-150 Global | NG Working (75) |
| --- | --- | --- | --- |
| `url_resolved` is `https://` | **69.0%** (138) | **60.7%** (91) | **88.0%** (66) |
| **HTTP-only** (neither `url` nor `url_resolved` is `https://`) | **30.5%** (61) | **39.3%** (59) | **10.7%** (8) |
| Missing `favicon` (`""`) | **21.0%** (42) | **16.0%** (24) | **32.0%** (24) |
| HLS (`hls === 1`) | **5.5%** (11) | **8.0%** (12) | **2.7%** (2) |
| `lastcheckok === 1` | **97.5%** (195) | **100%** (150) | **93.3%** (70) |

> **Note:** Even when querying `lastcheckok=1` on Nigerian stations, 5 of 75 returned `lastcheckok: 0` (and 1 had an empty `url_resolved`). Always enforce `lastcheckok === 1` and non-empty playable URL in our own filter layer.

### Codec Distribution (Sample 200)
- `MP3`: **157** (78.5%)
- `AAC`: **22** (11.0%)
- `AAC+`: **12** (6.0%)
- `UNKNOWN`: **6** (3.0%)
- `OGG`: **2** (1.0%)
- `(empty)`: **1** (0.5%)

### Bitrate Distribution (Sample 200)
- `0` (unknown): **24** (12.0%)
- `1–64 kbps`: **33** (16.5%)
- `65–128 kbps`: **119** (59.5%)
- `129–192 kbps`: **16** (8.0%)
- `>192 kbps`: **8** (4.0%)
- **Median non-zero bitrate**: **128 kbps**

---

## 5. Messy & Duplicate Tag Examples

The Radio Browser API already lowercases tag strings in `/json/tags`, so the primary issues are **synonym sprawl, multilingual duplicates, compound tags, and non-genre noise**:

1. **Synonyms & multilingual duplicates**:
   - Pop: `"pop"` (5,188), `"pop music"` (777), `"música pop"` (373), `"hits"` (1,431), `"top 40"` (806)
   - News & Talk: `"news"` (2,728), `"talk"` (1,639), `"local news"` (642), `"noticias"` (458), `"information"` (428), `"news talk"` (364)
   - Gospel / Christian: `"christian"` (870), `"gospel"` (376), `"gospel music"`, `"afro-gospel"`, `"religion"` (357)
   - Regional Mexican: `"regional mexican"` (414), `"regional mexicana"` (372), `"música popular mexicana"` (354)
2. **Non-genre / meta / submitter noise**:
   - `"music"` (3,657), `"radio"` (1,169), `"fm"` (876), `"estación"` (1,033), `"moi merino"` (848 — submitter name), `"variety"` (451), `"general"`, `"various"`, `"nigeria"`, `"ibadan"`
3. **Missing tags**: `57 / 200` stations (28.5%) have an empty `tags` string.

---

## 6. Normalisation Recommendations (for Phase 2 & Phase 4)

1. **Canonical genre mapping (`packages/shared/genre-map.json`)**:
   - Map raw comma-separated `tags` (trimmed, lowercased) to a clean set of ~20 canonical genres (e.g. `Pop`, `News & Talk`, `Afrobeats`, `Gospel & Christian`, `Jazz`, `Rock`, `Hip-Hop & R&B`, `Electronic & Dance`, `Classical`, `Oldies`, `Country`, `Sports`, etc.).
   - Drop noise tags (`music`, `radio`, `fm`, `estación`, `moi merino`, `general`, `various`) from display chips; limit station row display to max 2 canonical genre tags.
2. **HTTPS & Web playability flag**:
   - Compute `isHttps = urlResolved.startsWith('https://') || url.startsWith('https://')`.
   - On **web**, mark `!isHttps` stations as *"Best in the mobile app"* and never attempt mixed-content playback.
   - On **Android**, configure `network_security_config.xml` to permit cleartext HTTP for audio streams.
3. **Fallback logo flag**:
   - Compute `hasLogo = favicon.trim().isNotEmpty && (favicon.startsWith('https://') || favicon.startsWith('http://'))` (prefer `https://` or flag fallback when empty/broken) so the UI renders a deterministic monogram/brand fallback.
4. **Working-now filter (ON by default)**:
   - Require `lastcheckok === 1 && (urlResolved.isNotEmpty || url.isNotEmpty)`.
5. **Duplicate station merging**:
   - Deduplicate by `stationuuid` first, then optionally collapse identical `(normalizedName, countrycode, resolvedHost)` entries keeping the highest `clickcount` / HTTPS variant.
6. **Click reporting decision**:
   - Send `GET /json/url/<stationuuid>` **directly from the client** (mobile & web) when playback starts, because Radio Browser aggregates clicks once per station per IP per 24h — relaying all clicks through our Node backend would collapse all users onto one server IP.
