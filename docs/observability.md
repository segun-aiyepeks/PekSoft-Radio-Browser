# Observability Runbook — PekSoft Radio Browser (Milestone 7.3)

Date: 2026-11-19  
Branch: `phase/7-launch`

---

## 1. Mobile Crashlytics & Analytics (Flutter)
- **Package**: `firebase_crashlytics` (`^6.1.0`) + `firebase_analytics` (`^13.1.0`).
- **Wiring**: `apps/mobile/lib/main.dart` forwards both `FlutterError.onError` and `PlatformDispatcher.instance.onError` into `FirebaseAnalyticsService.recordError(...)`.
- **Privacy & Consent**:
  - `FirebaseAnalyticsService` (`apps/mobile/lib/core/analytics/firebase_analytics_service.dart`) gates both Analytics and Crashlytics collection on `setConsentGranted(bool)`.
  - All event parameters pass through `sanitizeAnalyticsParams(...)` to strip emails, tokens, and PII keys.

## 2. Sentry Error Tracking (API & Web)
- **API (`apps/api/src/plugins/sentry.ts`)**:
  - Configure `SENTRY_DSN` and `SENTRY_ENVIRONMENT` in production environment variables.
  - Unhandled `5xx` errors in `apps/api/src/plugins/error-handler.ts` are automatically forwarded to Sentry with `requestId`, `http_method`, sanitized URL path (query strings stripped), `release`, and `environment`.
  - No-op when `SENTRY_DSN` is unset (zero overhead in local dev and CI tests).
- **Web (`apps/web/src/lib/sentry.ts` & `apps/web/src/app/global-error.tsx`)**:
  - Configure `NEXT_PUBLIC_SENTRY_DSN` and `NEXT_PUBLIC_SENTRY_ENVIRONMENT`.
  - `global-error.tsx` captures uncaught React/Next.js errors and sends PII-free error payloads using `keepalive: true`.

## 3. Uptime Monitoring & Health Checks
- **Liveness Probe**: `GET /health` -> returns `200 OK` (`{ status: "ok", service, version, uptimeSeconds, timestamp }`). Exempt from rate limiting.
- **Readiness Probe**: `GET /health/ready` -> returns `200 OK` (or `503 Service Unavailable` if PostgreSQL probe fails) with `{ status, version, uptimeSeconds, memoryRssMb, checks: { process, database } }`.
- **Recommended External Monitor (UptimeRobot / BetterStack)**:
  - Check `https://api.peksoft.radio/health/ready` every **60 seconds** from 2+ regions.
  - Alert if 2 consecutive checks fail (`HTTP != 200` or latency `> 3000ms`).
  - Also monitor `https://radio.peksoft.com/` every **60 seconds**.

## 4. Structured Logs Without Personal Data
- `apps/api/src/plugins/logger.ts` emits structured JSON via Pino.
- Redacted paths (`[REDACTED]`): `authorization`, `cookie`, `x-api-key`, `x-paystack-signature`, `x-goog-pubsub-token`, `password`, `token`, `idToken`, `purchaseToken`, `secretKey`, `privateKey`, `email`.
- Custom `req` serializer logs only `{ method, url }` — client IP addresses and headers are omitted.

## 5. Section 11 KPI Dashboard
- Live web dashboard available at `/status` (`apps/web/src/app/status/page.tsx`) showing real-time `/health/ready` status and all 8 Section 11 product KPIs (Time to First Sound, Stream Start Success Rate, Crash-Free Sessions, API Uptime, D7 Retention, Favourites per Active User, Free -> Plus Conversion, and Broken Station Report Rate).
