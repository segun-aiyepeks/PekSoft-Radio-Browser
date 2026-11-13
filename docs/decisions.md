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
