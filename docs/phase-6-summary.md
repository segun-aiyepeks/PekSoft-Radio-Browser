# Phase 6 Summary — The Web App (`apps/web`)

## Branch
- `phase/6-web`

## Completed Milestones
1. **Milestone 6.1 — Design system setup** (`4379d68`):
   - Initialised shadcn/ui with Tailwind v4, mapping PekSoft design tokens (`packages/design-tokens/tokens.json` -> `apps/web/src/app/tokens.css` & `globals.css`) in dark-first (`#0A0F1C`) and light (`#F6F4EE`) themes with `Space Grotesk` and `Inter` via `next/font` and `0.875rem` radius.
   - Added base shadcn components, `signal` button variant, `live` and `quality` badge variants, Motion Primitives, `apps/web/src/lib/motion.ts`, root `MotionConfig reducedMotion="user"`, and `/dev/components` gallery.
2. **Milestone 6.2 — Web UI with mock data** (`fd010cd`):
   - Built `AppShell` (collapsible sidebar + mobile bottom nav + top search), `PlayerBar`, `NowPlayingSheet`, `StationCard`, `StationRow`, `CountryCard`, `FilterBar`, `PlanToggle`, `StationArtwork`, and all routes (`/`, `/home`, `/explore`, `/country/[code]`, `/genre/[slug]`, `/station/[slug]`, `/library`, `/pricing`, `/account`, `/auth`).
3. **Milestone 6.3 — Motion pass** (`ff917fa`):
   - Added `template.tsx` route transitions, `LazyInfiniteSlider` / `LazyTilt` / `LazySpotlight` / `LazyBorderTrail` (`next/dynamic` with `ssr: false`), `TextEffect`, `Magnetic`, `InView` + `AnimatedGroup`, `AnimatedBackground`, `SlidingNumber`, `ScrollProgress`, and `docs/motion-report.md`.
4. **Milestone 6.4 — Player** (`bdec8d2`):
   - Added `PlayerProvider` with direct HTML5 `<audio>` playback (never proxied), lazy `hls.js` loading for `.m3u8` streams, `runWithFailoverAndRetries` backoff matching mobile, Media Session API, global keyboard shortcuts (`k`/`Space`, `m`, `Shift+ArrowUp`/`ArrowDown`), live tab title, `'Best in the mobile app'` badge for `!isHttpsPlayable` stations, and a CORS-probed `AudioVisualizer` that never connects Web Audio API to non-CORS streams.
5. **Milestone 6.5 — Real data and SEO** (`01fd3a7`):
   - Added typed `@peksoft/shared` API client (`api-client.ts`) with graceful build-time fallback, ISR server-rendered public pages (`revalidate = 120` / `300`), `generateMetadata`, canonical URLs, `robots.ts`, `sitemap.ts`, JSON-LD (`WebSite` & `RadioStation`), and dynamic Open Graph images (`/opengraph-image`, `/station/[slug]/opengraph-image`).
6. **Milestone 6.6 — Authentication and library** (`4073206`):
   - Added Firebase Web SDK (`AuthProvider` with Google + email/password sign-in/up, email verification, password reset), animated validation states (`AnimatePresence`), `Authorization: Bearer <idToken>` transport, and library sync (`GET/PUT/DELETE /v1/library/*`, `POST /v1/sync`).
7. **Milestone 6.7 — Ads** (`5aedce6`):
   - Added `AdConsentProvider` + consent banner, non-animated zero-CLS `AdSlot` components (`min-h-[90px]` / `min-h-[250px]`), `ad-policy.ts` blocking ads on `/auth`, `/pricing`, `/checkout`, and hiding all ads/scripts for Plus users, plus `public/ads.txt`.
8. **Milestone 6.8 — Payments** (`e929302`):
   - Added `PaymentProvider` interface, `PaystackProvider` (initialize, verify, HMAC-SHA512 webhook verification, cancel), `StripeProvider` stub, idempotent `WebBillingService` backed by `WebhookEventRepository` & `EntitlementService`, `FEATURE_FLAGS.crossPlatformEntitlements: false` (default OFF), and `/pricing`, `/checkout`, `/checkout/callback`, and `/account` manage/cancel UI.
9. **Milestone 6.9 — PWA and finish**:
   - Added `app/manifest.ts`, `public/sw.js` (caching only `/_next/static/*` shell assets and explicitly never caching audio/stream/range/cross-origin requests), engagement-gated `PwaProvider` ("Get the PekSoft Radio app" install banner), reduced-motion compliance (`MotionConfig reducedMotion="user"`), and accessibility/PWA unit tests.
