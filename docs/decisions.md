# Architecture Decision Records (ADRs)

All technology choices below were verified during **Phase 0 (Foundations)** (`2026-11-13`). Versions listed under **Verified** were directly observed in tool output or `package.json`; packages scheduled for later phases are marked as targets to be verified at install time.

---

## ADR-001: Monorepo with `pnpm` Workspaces & Turborepo
- **Status:** Accepted
- **Verified:** `pnpm@12.18.0`, `turbo@2.11.11`, `typescript@7.0.2`, `node@v24.18.0`
- **Context:** We have a Flutter mobile app (`apps/mobile`), a Next.js web app (`apps/web`), a Fastify API (`apps/api`), shared TypeScript schemas (`packages/shared`), and design tokens (`packages/design-tokens`).
- **Decision:** Use one Git repository with `pnpm` workspaces + Turborepo for all TypeScript projects, while keeping `apps/mobile` outside `pnpm`.
- **Reason:** Keeps shared schemas, fixtures, and design tokens in sync across web, API, and mobile without cross-repo drift, while avoiding mixing Dart/Pub with Node tooling.

## ADR-002: Flutter (Android First) with Strict MVVM + Riverpod
- **Status:** Accepted
- **Verified:** `Flutter 3.44.7` (stable), `Dart 3.12.2`, Android `applicationId = "com.peksoft.radio"`
- **Context:** Mobile needs rock-solid background audio playback, lock-screen/Bluetooth/Android Auto controls, offline library caching, and 60fps UI.
- **Decision:** Build `apps/mobile` in Flutter using strict feature-first MVVM + Riverpod (`presentation -> domain <- data`, immutable `freezed` state, repository interfaces, sealed failures). Target `just_audio` + `audio_service`, `go_router`, `dio`, and `drift` (exact versions to be verified in Phases 1–3).
- **Reason:** Clean separation of UI from data/audio logic enables UI-first Phase 1 prototyping with mock data and full unit testing with fakes in Phase 2+.

## ADR-003: Next.js (App Router, TypeScript, Tailwind CSS) + shadcn/ui + Motion Primitives
- **Status:** Accepted
- **Verified:** `next@16.4.6`, `react@19.3.1`, `react-dom@19.3.1`, `tailwindcss@4.3.5`, `@tailwindcss/postcss@4.3.5`
- **Context:** The web app needs both a persistent single-page audio player and public, crawlable SEO pages (`/country/<iso>`, `/genre/<slug>`, `/station/<slug>`) for search traffic and web ad-network approval.
- **Decision:** Use Next.js App Router with Server Components by default, Tailwind CSS v4 styled via `@peksoft/design-tokens`, `shadcn/ui` components owned in `components/ui`, and `motion` / Motion Primitives for UI animation (exact `shadcn` and `motion` versions to be verified in Phase 6).
- **Reason:** Server-rendered public pages satisfy SEO and AdSense content requirements while preserving a persistent client audio bar across navigations.

## ADR-004: Node.js + Fastify + TypeScript + Zod for Backend API
- **Status:** Accepted
- **Verified:** `fastify@5.12.8`, `zod@4.6.7`, `vitest@5.1.0`, `tsx@4.23.15`
- **Context:** Web browsers cannot perform DNS SRV lookups or play plain-HTTP streams on HTTPS pages, and we need a central backend for caching, normalisation, library sync, and payment/entitlement verification.
- **Decision:** Use Fastify with layered architecture (`routes -> services -> repositories`) and Zod validation shared via `@peksoft/shared`.
- **Reason:** Fastify offers low overhead, strong TypeScript support, built-in Pino structured logging, and seamless schema sharing with Next.js.

## ADR-005: PostgreSQL for Persistent Server Data
- **Status:** Accepted
- **Target:** PostgreSQL (managed instance + driver/ORM to be verified in Phase 4)
- **Context:** We need relational storage for user accounts, synced favourites/collections/history (with per-item timestamps), curated collections, and subscription entitlements.
- **Decision:** Use PostgreSQL as the primary backend database.
- **Reason:** Strong transactional guarantees for entitlement/webhook state and straightforward querying for library sync.

## ADR-006: Firebase Authentication (Email + Google)
- **Status:** Accepted
- **Target:** Firebase Auth SDKs for Flutter & Web + Firebase Admin SDK in `apps/api` (versions to be verified in Phase 4)
- **Context:** Users want painless sign-in (Google native picker / One Tap + Email with password reset and verification) and one account across mobile and web.
- **Decision:** Use Firebase Authentication on Flutter and Next.js; `apps/api` verifies Firebase ID tokens on authenticated requests.
- **Reason:** Eliminates building custom password hashing, email verification, OAuth token handling, and reset flows from scratch.

## ADR-007: Radio Browser Integration & Normalisation
- **Status:** Accepted
- **Verified:** Live API spike (`docs/api-spike.md`, `2026-11-13`)
- **Context:** Radio Browser is community-maintained: 30.5% of sampled stations are HTTP-only, 21% lack favicons, and tags contain synonyms/noise.
- **Decision:**
  - Discover mirrors via `/json/servers` (cached 24h) with DNS A fallback; never hard-code one server.
  - Send `User-Agent: PekSoftRadioBrowser/<version>`.
  - Cache countries/tags/languages for 24h and search results short-term.
  - Normalise tags via a shared `genre-map.json`, flag `isHttps` and `hasLogo`, and keep `Working now` (`lastcheckok === 1`) ON by default.
  - Report play clicks directly from clients (`GET /json/url/<stationuuid>`) so Radio Browser's per-IP 24h aggregation stays accurate.
  - **Never proxy audio streams** through `apps/api`; mark HTTP-only stations as *"Best in the mobile app"* on web.
- **Reason:** Respects community server etiquette, avoids legal/bandwidth risks of audio proxying, and protects playback UX.

## ADR-008: Subscriptions & Server-Side Entitlements
- **Status:** Accepted
- **Context:** Mobile and web have different payment rails and store policies.
- **Decision:**
  - **Android:** Google Play Billing only.
  - **Web:** Paystack hosted checkout (Stripe may be evaluated later for diaspora currencies).
  - **Entitlements:** Verified server-side in `apps/api` via Play Real-Time Developer Notifications (RTDN) and Paystack webhooks; never trust client-only unlock state.
- **Reason:** Complies with Google Play billing policy and prevents client-side entitlement tampering.

## ADR-009: Ad Monetisation & Placement Rules
- **Status:** Accepted
- **Context:** Free tier is ad-supported while Plus removes all ads.
- **Decision:** Use **AdMob** (+ Google UMP consent for EEA/UK) on Android and **Google AdSense** (+ cookie consent) on web. Strictly enforce: no ads before first sound, no ads over playback controls, and no ads on auth or paywall screens.
- **Reason:** Protects core listening UX and store/ad-network policy compliance.

## ADR-010: Single-Source Design Tokens
- **Status:** Accepted
- **Verified:** `packages/design-tokens/tokens.json` → `design_tokens.dart` & `tokens.css`
- **Context:** Mobile (Flutter) and web (Next.js + Tailwind + shadcn/ui) must share one visual language (dark-first `#0A0F1C`, `#101A2E`, Signal Amber `#FFB020`, Space Grotesk).
- **Decision:** Maintain all colour, typography, spacing, radius, elevation, and motion tokens in `packages/design-tokens/tokens.json` and generate platform outputs via `scripts/generate.mjs`.
- **Reason:** Guarantees visual consistency and prevents hard-coded colour drift across platforms.


---

## ADR-011 — Phase 4 Backend API, Database, Auth & Staging Hosting
- **Date:** 2026-11-16
- **Verified Packages:**
  - `apps/api`: `@fastify/cors` `11.4.3`, `@fastify/rate-limit` `11.2.2`, `@fastify/swagger` `9.9.4`, `@fastify/swagger-ui` `6.1.4`, `prisma` / `@prisma/client` / `@prisma/adapter-pg` `7.10.1`, `pg` `8.23.1`, `firebase-admin` `14.5.1`.
  - `apps/mobile`: `firebase_core` `5.1.0`, `firebase_auth` `7.0.1`, `google_sign_in` `7.2.0`.
- **Decision:** Fastify 5 API with `CacheStore` abstraction (`InMemoryLruCache` replaceable by Redis), Prisma 7 + PostgreSQL (`0001_init`), Firebase Admin token verification (`checkRevoked: true`), LWW delta-sync (`POST /v1/sync`) with server-side `Entitlement` enforcement, and Render Web Service + Render Postgres staging via `render.yaml` (`frankfurt` region).
- **Reason:** Keeps audio streaming direct to broadcasters (zero proxy cost), enforces free-tier limits authoritatively on the server, and provides one-click Render Blueprint staging with automatic `prisma migrate deploy`.


---

## ADR-012 — Mobile Ads & Consent (`google_mobile_ads` + Google UMP)

- **Status:** Accepted (Phase 5)
- **Verified Versions:**
  - `google_mobile_ads`: `9.2.0` (`webview_flutter: 4.14.1`)
- **Decision:**
  - Use `google_mobile_ads` (`^9.2.0`) with Google's built-in **User Messaging Platform (UMP)** (`ConsentInformation` + `ConsentForm`) at launch before initializing `MobileAds.instance`.
  - Keep real AdMob App IDs and Ad Unit IDs out of source control (`ADMOB_APP_ID` Gradle/env property + `--dart-define=ADMOB_*_AD_UNIT_ID`), falling back to Google's official Android test ad unit IDs **only** in debug builds (`kDebugMode`).
  - Enforce all UX placement rules in a pure-Dart `AdPolicy` engine (no ad before first sound, none on auth/paywall/player surfaces, 10-minute interstitial cooldown at natural breaks only, native ad card every 8 rows, zero ads for Plus users).
  - Grant the 24-hour rewarded-ad convenience pass (`EntitlementSource.rewardedAd`) client-side with an automatic 24-hour expiry timestamp (`rewardedPlusExpiresAt`) persisted in `AppDatabase`.
- **Reason:** Protects AdMob accounts from invalid traffic penalties in development, satisfies EEA/UK GDPR consent rules via UMP, and keeps ad frequency and placement rules 100% unit-testable in pure Dart.


---

## ADR-013 — Google Play Billing & Server-Side RTDN Verification (`in_app_purchase` + Subscriptions v2)

- **Status:** Accepted (Phase 5)
- **Verified Versions:**
  - `in_app_purchase`: `3.3.1` (`in_app_purchase_android: 0.5.5`, `in_app_purchase_platform_interface: 1.4.1`)
- **Decision:**
  - Use Flutter's official `in_app_purchase` (`^3.3.1`) plugin with subscription product IDs `plus_monthly` and `plus_annual`.
  - Verify every purchase and restore server-side on `POST /v1/billing/google-play/verify` using the Google Play Developer API **Subscriptions v2** (`purchases.subscriptionsv2.get`) authenticated via RS256 JWT service-account assertions (`GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY`).
  - Only call `completePurchase` (acknowledgement) after the backend confirms verification, preventing unverified client-side unlocks.
  - Process Google Cloud Pub/Sub Real-Time Developer Notifications on `POST /v1/webhooks/google-play` with shared-secret authenticity checking (`GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN`) and `WebhookEvent` (`provider + eventId`) idempotency.
- **Reason:** Google Play refunds unacknowledged purchases after 3 days, client-only receipts can be spoofed, and Pub/Sub delivers notifications at-least-once—making server verification + `WebhookEvent` deduplication mandatory for production billing.


---

## ADR-014 — Privacy-Preserving Analytics & Crash Reporting (`firebase_analytics` + `firebase_crashlytics`)

- **Status:** Accepted (Phase 5)
- **Verified Versions:**
  - `firebase_analytics`: `13.1.0`
  - `firebase_crashlytics`: `6.1.0`
- **Decision:**
  - Use a shared Section 11 event taxonomy (`packages/shared/src/analytics.ts` and `AnalyticsEvents` in `apps/mobile/lib/core/analytics/analytics_service.dart`: `station_play`, `station_fail`, `favorite_add`, `paywall_view`, `purchase_success`, `first_audio_reached`, `ad_rewarded_completed`, `restore_purchases`).
  - Route all events and non-fatal/fatal error reports through `AnalyticsService` / `FirebaseAnalyticsService`, gating collection on Google UMP consent (`setConsentGranted`) and scrubbing all PII keys/email patterns via `sanitizeAnalyticsParams`.
- **Reason:** Satisfies GDPR / UK / Nigeria NDPA 2023 consent and data-minimisation requirements while keeping product funnel and playback-quality metrics consistent across mobile and web.


---

## ADR-015 — Web UI & Motion Stack (`shadcn/ui` + Tailwind CSS v4 + `motion` + Motion Primitives)

- **Status:** Accepted (Phase 6)
- **Verified Versions:**
  - `next`: `16.4.6` · `react` / `react-dom`: `19.3.1` · `tailwindcss`: `4.3.5`
  - `motion`: `14.14.0` · `lucide-react`: `1.73.0` · `react-use-measure`: `2.1.7`
  - `shadcn/ui`: Base UI (`@base-ui/react`) + `class-variance-authority` + `tw-animate-css`
- **Decision:**
  - Initialise `shadcn/ui` in `apps/web/src/components/ui/` with `--radius: 0.875rem`, dark-first theme mapped directly to `packages/design-tokens` CSS variables (`tokens.css` -> `globals.css`), and `Space Grotesk` + `Inter` loaded via `next/font/google`.
  - Add custom `signal` button variant and `live` / `quality` badge variants.
  - Install `motion` (`14.14.0`) and copy 13 Motion Primitives (`text-effect`, `animated-group`, `in-view`, `infinite-slider`, `magnetic`, `border-trail`, `spotlight`, `tilt`, `animated-background`, `sliding-number`, `morphing-dialog`, `scroll-progress`, `text-shimmer`) into `src/components/motion-primitives/`, governed by shared tokens in `src/lib/motion.ts` and `<MotionConfig reducedMotion="user">`.
- **Reason:** Owning the UI and motion source files inside `apps/web/src/components/` gives zero black-box styling lock-in, automatic propagation of token updates from `packages/design-tokens`, and strict reduced-motion / zero-layout-shift control.
