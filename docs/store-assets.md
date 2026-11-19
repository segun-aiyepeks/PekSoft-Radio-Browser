# Legal & Store Assets — PekSoft Radio Browser (Milestone 7.4)

Date: 2026-11-19  
Branch: `phase/7-launch`

---

## 1. Public Legal & Account-Deletion URLs (Web)
- **Privacy Policy (lawyer-review template)**: `/privacy` (`apps/web/src/app/privacy/page.tsx`)
- **Terms of Service (lawyer-review template)**: `/terms` (`apps/web/src/app/terms/page.tsx`)
- **Public Account Deletion Page (Google Play requirement)**: `/delete-account` (`apps/web/src/app/delete-account/page.tsx`)
- **Cookie & Ad Consent Banner**: `apps/web/src/components/ads/ad-consent-banner.tsx` (gates personalized AdSense/analytics cookies; links directly to `/privacy`).

---

## 2. Google Play Data Safety Form — Draft Answers

| Question | Draft Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** (optional account info for signed-in users; anonymized diagnostics & ad identifiers for free-tier users with consent). |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS / TLS 1.2+ for API, Firebase, Radio Browser, Google Play Billing). |
| Do you provide a way for users to request that their data is deleted? | **Yes** — in-app (`Profile -> Delete Account`) AND web URL: `https://radio.peksoft.com/delete-account`. |
| **Personal info -> Email address / Name / User IDs** | Collected (Optional — only if user creates an account). Used for: App functionality (cloud library sync), Account management. Not shared with third parties. |
| **Financial info -> Purchase history** | Collected (via Google Play Billing). Used for: App functionality (PekSoft Plus entitlement verification). |
| **App activity -> App interactions / In-app search history** | Collected (Optional, consent-gated via Firebase Analytics). Used for: Analytics & stream reliability. |
| **App info and performance -> Crash logs / Diagnostics** | Collected (Consent-gated via Firebase Crashlytics). Used for: Analytics & stability. |
| **Device or other IDs** | Collected (Free tier only, consent-gated via Google AdMob). Used for: Advertising or marketing. |

---

## 3. Google Play Content Rating Questionnaire (IARC) — Draft Answers

- **Category**: Utility, Productivity, Communication, or Other (Music & Audio — Radio Player).
- **Violence / Fear / Sexuality / Gambling / Controlled Substances**: **No** (app itself contains none).
- **User-Generated Content / User Interaction**: **No** (no user chat, comments, or social posting).
- **Shares user physical location**: **No** (country selection is manual; map shows radio station coordinates only).
- **Digital purchases**: **Yes** (PekSoft Plus subscriptions via Google Play Billing).
- **Unrestricted Web / Live Broadcast Audio Disclaimer**: Note that PekSoft Radio Browser streams live third-party public radio broadcasts worldwide; content varies by broadcaster (typical IARC rating: **Teen / PEGI 12** due to unmoderated live radio broadcasts).

---

## 4. Google Play Store Listing Copy

- **App Name (<= 30 chars)**: `PekSoft Radio Browser` (21 chars)
- **Short Description (<= 80 chars)**:
  `Stream 40,000+ live FM & internet radio stations worldwide. Free, fast, clean.` (78 chars)
- **Full Description**:
  > Tune into the world with **PekSoft Radio Browser** — a fast, clean, guest-first live radio player powered by the global Radio Browser directory.
  >
  > **Instant Listening — No Account Required**
  > Open the app and press Play. Every station list defaults to **Working Now** so you spend time listening, not hitting dead links.
  >
  > **Key Features**
  > - **40,000+ Live Stations across 195+ Countries**: Afrobeats, Highlife, Pop, Gospel & Christian, News & Talk, Sports, Jazz, Classical, Electronic, and more.
  > - **Interactive World Radio Map**: Explore live stations across the globe on an interactive OpenStreetMap view and play directly from any pin.
  > - **Smart Stream Failover & Data Saver**: Automatic retry and lower-bitrate selection when you're on mobile data.
  > - **Sleep Timer & Native Sharing**: Fall asleep to your favourite station or share live channels directly to WhatsApp, Telegram, Facebook, and Messages.
  > - **Favourites, Collections & Cloud Sync**: Save stations locally as a guest, or sign in with Email or Google to sync across Android and Web.
  > - **PekSoft Plus (Optional)**: Upgrade for ad-free listening, unlimited favourites and collections, and full song history.
  >
  > *Station directory metadata powered by Radio Browser (radio-browser.info).*
- **Category**: Music & Audio
- **Tags**: Radio, FM Radio, Live Radio, World Radio, Internet Radio, Music

---

## 5. Screenshot Plan (Phone & Tablet)

Capture in Dark Mode (primary brand look) at `1080×1920` (9:16 phone) and `1600×2560` (tablet):
1. **Home (Spotify-style Shelves)**: *"40,000+ live stations worldwide — tap & play instantly"*
2. **Now Playing**: *"Crystal-clear live streams with sleep timer & instant sharing"*
3. **Explore -> Genres**: *"Discover Afrobeats, News, Gospel, Sports, Jazz & 20+ genres"*
4. **Explore -> World Radio Map**: *"Explore live radio pins across the globe"*
5. **Search & Filters**: *"Find any station by name, country, language, or bitrate"*
6. **Library & Favourites**: *"Your favourites, recents & collections — synced everywhere"*

---

## 6. Feature Graphic (`1024×500`)
- Vector source: `docs/store-assets/feature-graphic-1024x500.svg`
- Uses exact PekSoft brand palette (`#0B0E17` background, `#131826` card surface, `#8A2BE2` accent, `#FFB020` signal waves, `#10B981` live badge — clean flat/solid Material 3 design with zero glow or glassmorphism).
