# Phase 7 Summary — Hardening and Launch

Branch: `phase/7-launch`  
Date: 2026-11-19

## Milestones Completed
1. **Milestone 7.1 — Accessibility & Performance (`docs/performance-accessibility-audit.md`)**
   - Mobile: Fixed TalkBack labels on map cards/pins, raised map pins & controls to 48dp, added onboarding genre selection semantics & checkmarks, fixed light-mode splash logo & semantic status contrast (>= 4.5:1), scoped `liveRegion` on status banners, bounded `ImageCache` (250 items / 64 MB) + DPR-aware `cacheWidth`/`cacheHeight`, and verified zero overflow at 2.0x text scale across all 8 key screens.
   - Web: Added keyboard `Skip to main content` link + `#main-content` landmark, enabled `compress: true`, `poweredByHeader: false`, `images.formats: ['image/avif', 'image/webp']`, `experimental.optimizePackageImports`, and immutable 1-year `Cache-Control` headers on `/images/*`.
2. **Milestone 7.2 — Security Review (`docs/security-review.md`)**
   - Completed OWASP API Security Top 10 (2023) walkthrough.
   - Added baseline HTTP security headers, `bodyLimit: 256 KiB`, production Swagger disable, production wildcard CORS guard, tighter `15 req/min` rate limit on `POST /v1/reports`, expanded PII/secret redaction in Pino logs, and strict `packageName` enforcement on Google Play verification.
   - Ran `pnpm audit --prod`, `flutter pub outdated`, and git secrets scan.
3. **Milestone 7.3 — Observability (`docs/observability.md`)**
   - Verified consent-gated, PII-stripped Firebase Crashlytics on mobile.
   - Added zero-dependency PII-free Sentry reporters for API (`apps/api/src/plugins/sentry.ts`) and Web (`apps/web/src/lib/sentry.ts` + `global-error.tsx`).
   - Added readiness probe `GET /health/ready` with DB & memory checks and built the `/status` Section 11 KPI Dashboard.
4. **Milestone 7.4 — Legal & Store Assets (`docs/store-assets.md`)**
   - Published `/privacy`, `/terms`, and `/delete-account` pages linked from the global web footer alongside cookie/ad consent.
   - Drafted Play Data Safety answers, IARC Content Rating answers, Play Store listing copy, screenshot plan, and `1024×500` feature graphic (`docs/store-assets/feature-graphic-1024x500.svg`).
5. **Milestone 7.5 — Release Pipelines (`docs/release-and-rollback.md`)**
   - Added `.github/workflows/release-android.yml` (signed `.aab` + Play Internal Track upload) and `.github/workflows/deploy-api-web.yml` (Staging -> Production with Prisma migrations & `/health/ready` smoke checks), plus complete rollback runbook.
6. **Milestone 7.6 — Launch Checklist & Backlog (`docs/launch-checklist.md`)**
   - Authored full pre-launch sign-off checklist and prioritized Phase 8+ backlog (Radio Wrapped, Map Exploration v2, Alarm Clock, Android Auto, Chromecast, Home Screen Widgets, More Languages).
