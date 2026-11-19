# Launch Checklist & Post-Launch Backlog — PekSoft Radio Browser (Milestone 7.6)

Date: 2026-11-19  
Branch: `phase/7-launch`

---

## Part 1: Pre-Launch Checklist

### 1. Mobile (Android / Flutter)
- [ ] Release upload keystore created and backed up securely offline; `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` added to GitHub Environment `android-release`.
- [ ] Firebase Android API key restricted to `com.peksoft.radio` + release SHA-1/SHA-256 fingerprint in Google Cloud Console.
- [ ] Production AdMob App ID & Ad Unit IDs configured (no Google test IDs in release builds — verified by `AdConfig`).
- [ ] Google Play Billing product IDs (`plus_monthly`, `plus_annual`) created in Play Console and Pub/Sub RTDN topic pointed to `https://api.peksoft.radio/v1/webhooks/google-play`.
- [ ] Smoke-tested release `.aab` on a physical Android device (Splash, 3-page Onboarding, Spotify-style Home shelves, Live audio playback, World Radio Map, Native Share, Favourites, Search persistent mini-player, Sleep Timer, Profile).
- [ ] `flutter analyze` (0 issues) and `flutter test` (all green) verified on release commit.

### 2. Backend API (`apps/api`)
- [ ] `NODE_ENV=production`, `DATABASE_URL`, `CORS_ORIGINS` (explicit production domains — never `*`), `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` set in production host.
- [ ] `PAYSTACK_SECRET_KEY`, `PAYSTACK_PLAN_MONTHLY`, `PAYSTACK_PLAN_ANNUAL` (live keys) configured and Paystack webhook pointed to `https://api.peksoft.radio/v1/webhooks/paystack`.
- [ ] `GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY`, `GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN` configured.
- [ ] `SENTRY_DSN` and `SENTRY_ENVIRONMENT=production` configured.
- [ ] `prisma migrate deploy` executed cleanly against production PostgreSQL.
- [ ] `GET https://api.peksoft.radio/health/ready` returns `200 OK` with `checks.database: "ok"`, and Swagger `/docs` returns `404` in production.

### 3. Web App (`apps/web`)
- [ ] Production environment variables set (`NEXT_PUBLIC_API_URL`, Firebase Web config, `NEXT_PUBLIC_SENTRY_DSN`, AdSense publisher ID).
- [ ] Legal & compliance routes verified live: `/privacy`, `/terms`, `/delete-account`, `/status`, `/robots.txt`, `/sitemap.xml`, `/ads.txt`.
- [ ] Cookie/ad consent banner verified in fresh incognito session.
- [ ] Responsive layout verified on mobile (375px), tablet (768px), and desktop (1440px).

### 4. Observability & Security
- [ ] UptimeRobot / BetterStack monitoring `https://api.peksoft.radio/health/ready` and `https://radio.peksoft.com/` every 60s with email/Slack alerts.
- [ ] Firebase Crashlytics verified receiving test non-fatal event on internal track build.
- [ ] Sentry verified receiving test error from staging API & Web with zero PII.
- [ ] OWASP review (`docs/security-review.md`) and Rollback runbook (`docs/release-and-rollback.md`) reviewed by team.

### 5. Legal & Google Play Console
- [ ] Lawyer review completed for `/privacy` and `/terms` templates.
- [ ] Play Console Data Safety form & IARC Content Rating submitted using `docs/store-assets.md`.
- [ ] Store listing copy, 6 phone + 2 tablet screenshots, and `1024×500` feature graphic (exported from `docs/store-assets/feature-graphic-1024x500.svg`) uploaded.
- [ ] Internal Track tested by at least 2 testers -> promote to Closed Beta / Production staged rollout (10% -> 25% -> 50% -> 100%).

---

## Part 2: Post-Launch Backlog (Phase 8+)

| Priority | Feature | Description & Technical Direction |
|---|---|---|
| **P1** | **Map Exploration v2** | Upgrade `WorldRadioMapTab` (mobile) and add a Web World Map with marker clustering (`flutter_map_marker_cluster`), "Search this area" viewport queries, city/country station drawers, and genre filter overlays. |
| **P1** | **More Languages (i18n)** | Localize mobile (`flutter_localizations` + `.arb` files) and web (`next-intl`) into French, Yoruba, Igbo, Hausa, Nigerian Pidgin, Spanish, Portuguese, and Arabic (RTL). |
| **P1** | **Home Screen Widgets** | Build Android Jetpack Glance and iOS WidgetKit home-screen widgets showing the currently playing station, quick Play/Pause, and top 4 favourite station shortcuts. |
| **P2** | **Alarm Clock (Wake-Up Radio)** | Schedule recurring wake-up alarms that start a chosen live radio station with gentle volume fade-in, automatic offline fallback chime if the stream cannot connect, and snooze controls. |
| **P2** | **Android Auto** | Extend `audio_service` (`AudioHandler`) with `getChildren` media library browsing (Favourites, Recents, Top Local Stations, Genres) so listeners can browse and play stations safely in-car via Android Auto. |
| **P2** | **Chromecast & AirPlay** | Integrate Google Cast SDK (Android/Web) and iOS AirPlay route picker so listeners can cast live radio streams to smart TVs and speakers. |
| **P3** | **Radio Wrapped** | Annual and monthly personalized listening recap (top stations, countries explored, genres discovered, total hours streamed, shareable social cards) computed from synced listening history. |
