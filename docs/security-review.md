# Security Review — PekSoft Radio Browser (Milestone 7.2)

Date: 2026-11-19  
Branch: `phase/7-launch`  
Scope: `apps/api` (Fastify + Prisma + Firebase Admin + Google Play Billing + Paystack), `apps/web` (Next.js), `apps/mobile` (Flutter)

---

## 1. OWASP API Security Top 10 (2023) Walkthrough

| ID | Risk | Current Controls & Audit Findings | Status / Action Taken |
|---|---|---|---|
| **API1:2023** | Broken Object Level Authorization (BOLA) | All `/v1/me`, `/v1/library/*`, `/v1/entitlements`, and `/v1/billing/*` routes derive the user identity exclusively from the verified Firebase ID token (`request.authUser.uid`) via `requireAuth` middleware. Repository queries scope favorites, collections, recents, and song history by `userId`. | **Pass** |
| **API2:2023** | Broken Authentication | `FirebaseAuthProvider.verifyIdToken(token, true)` enforces signature verification, expiration, and **revocation checks** (`checkRevoked: true`). Missing/malformed Bearer headers return `401 Unauthorized`. | **Pass** |
| **API3:2023** | Broken Object Property Level Authorization (BOPLA) | All request bodies/params/queries are parsed through strict Zod schemas from `@peksoft/shared`. Entitlements (`tier`, `expiresAt`, `adsEnabled`) can never be set by client payloads — only by server-side Google Play / Paystack verification or webhooks. **Finding fixed**: `GooglePlayBillingService.verifyPurchase` previously accepted a client-supplied `packageName` override; now rejects any `packageName` that does not match `env.GOOGLE_PLAY_PACKAGE_NAME` (`400 INVALID_PACKAGE_NAME`). | **Fixed & Verified** |
| **API4:2023** | Unrestricted Resource Consumption | Global Fastify rate limiting (`RATE_LIMIT_MAX=120`, `RATE_LIMIT_WINDOW_MS=60000`) is enabled. **Findings fixed**: (1) Added explicit `bodyLimit: 256 * 1024` (256 KiB) to Fastify to mitigate oversized JSON DoS. (2) Added stricter route-level rate limit (`15 req/min`) on public `POST /v1/reports` to prevent spam flooding. | **Fixed & Verified** |
| **API5:2023** | Broken Function Level Authorization | No unguarded admin routes exist. Account deletion (`DELETE /v1/me`), billing verification, and subscription cancellation all require `requireAuth`. | **Pass** |
| **API6:2023** | Unrestricted Access to Sensitive Business Flows | Billing grants require server-side verification with Google Play Developer API (`purchases.subscriptionsv2.get`) or Paystack (`GET /transaction/verify/:reference`) plus idempotent `WebhookEventRepository` deduplication so replayed webhooks cannot double-grant. | **Pass** |
| **API7:2023** | Server-Side Request Forgery (SSRF) | Outbound API calls target only discovered Radio Browser mirrors (`radio-browser.info`), Google Play Developer API (`androidpublisher.googleapis.com`), and Paystack (`https://api.paystack.co`). User input is never interpolated into hostnames or raw URLs (`encodeURIComponent` is used for path segments). | **Pass** |
| **API8:2023** | Security Misconfiguration | **Findings fixed**: (1) Added baseline HTTP security headers via Fastify `onSend` hook (`X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Permissions-Policy`, `X-Permitted-Cross-Domain-Policies: none`, and `Strict-Transport-Security` in production). (2) Disabled Swagger UI (`/docs`) by default when `NODE_ENV === 'production'`. (3) Blocked `CORS_ORIGINS=*` in `production` when `credentials: true` is active. | **Fixed & Verified** |
| **API9:2023** | Improper Inventory Management | All endpoints are versioned under `/v1/*` with OpenAPI 3.1 metadata and `/health` diagnostics. No deprecated or shadow API versions exist. | **Pass** |
| **API10:2023** | Unsafe Consumption of APIs | All third-party responses (Radio Browser, Google Play, Paystack) are parsed with timeouts, error handling, and explicit schema/field checks before persisting or returning data. | **Pass** |

---

## 2. Targeted Security Checks

### Secrets Handling
- Verified `git ls-files`: **zero** `.env`, `.jks`, `.keystore`, `.pem`, or Firebase/Google Play service-account private keys are committed.
- Both `apps/api/.env.example` and `apps/web/.env.example` contain placeholders only.
- Structured Pino logger (`apps/api/src/plugins/logger.ts`) redacts `authorization`, `cookie`, `x-api-key`, `x-paystack-signature`, `x-goog-pubsub-token`, `password`, `token`, `idToken`, `purchaseToken`, `secretKey`, `privateKey`, and `email` (`[REDACTED]`) and omits client IPs.

### Rate Limits & Payload Limits
- Global default: `120 requests / 60s` per IP (`@fastify/rate-limit`).
- Public `POST /v1/reports`: tightened to `15 requests / 60s`.
- Fastify `bodyLimit`: `256 KiB`.

### CORS
- Explicit origin allowlist parsed from `CORS_ORIGINS` (`methods: GET, POST, PUT, PATCH, DELETE, OPTIONS`, `allowedHeaders: Content-Type, Authorization`, `credentials: true`).
- Production startup throws an error if `CORS_ORIGINS=*` is configured with `credentials: true`.

### Input Validation
- All startup environment variables validated with Zod (`apps/api/src/config/env.ts`).
- All route bodies, query strings, and path parameters validated with Zod schemas (`@peksoft/shared` + route-local schemas).

### Webhook Signature Verification
- **Paystack (`POST /v1/webhooks/paystack`)**: Uses a scoped raw-buffer JSON parser and verifies `x-paystack-signature` with HMAC-SHA512 (`crypto.createHmac('sha512', secretKey)`) and constant-time comparison (`crypto.timingSafeEqual`). Rejects missing/invalid signatures with `401`.
- **Google Play RTDN (`POST /v1/webhooks/google-play`)**: Verifies `GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN` using `crypto.timingSafeEqual` (`safeEqual`), parses Pub/Sub envelope with Zod, validates `packageName`, and deduplicates `messageId` via `WebhookEventRepository`.

### Firebase Configuration
- **Backend**: `FirebaseAuthProvider` initializes from `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, and `FIREBASE_PRIVATE_KEY` environment variables (never from a checked-in JSON file) and verifies tokens with `checkRevoked: true`.
- **Mobile**: `apps/mobile/android/app/google-services.json` contains standard public Android Firebase client identifiers (no admin secrets). **Pre-launch action**: restrict the Firebase Android & Web API keys in Google Cloud Console to the release Android SHA-1/SHA-256 package signature (`com.peksoft.radio`) and production web origins.

---

## 3. Dependency Audit Results

### `pnpm audit --prod` (Monorepo Node/Web)
- **`apps/api`**: **0 production vulnerabilities.**
- **`apps/web`**: **3 transitive vulnerabilities** reported:
  - **High** (`GHSA-m9gg-hp2v-232j`) & **Low** (`GHSA-f596-whhp-79r4`): `@grpc/grpc-js <1.13.6` via `firebase > @firebase/firestore` (note: Firestore gRPC server path is not used by our web app, which only uses Firebase Auth). **Action**: pin `@grpc/grpc-js >= 1.13.6` via `pnpm.overrides` before production deploy.
  - **Moderate** (`GHSA-g3hv-75wg-m249`): `minimatch` via `shadcn` CLI transitive dependency (build/CLI tooling, not executed at runtime on user input). **Action**: move `shadcn` from `dependencies` to `devDependencies` (or remove from runtime dependencies).

### `flutter pub outdated --no-dev-dependencies` (Mobile)
- **Direct dependencies with minor/patch updates available**: `drift` (`2.34.4 -> 2.35.4`), `firebase_auth` (`7.0.1 -> 7.1.0`), `firebase_core` (`5.1.0 -> 5.2.0`), `cupertino_icons` (`1.0.9 -> 2.0.0`).
- **Security posture**: All core security/auth/network packages (`firebase_auth 7.x`, `dio 5.11.1`, `just_audio 0.10.6`, `share_plus 13.3.1`) are on current supported major versions with no known critical advisories.
