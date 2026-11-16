# PekSoft Radio Browser API (`apps/api`)

Base URL (local): `http://localhost:4000` (Android emulator: `http://10.0.2.2:4000`)  
Interactive OpenAPI 3.1 docs: `GET /docs` (`GET /docs/json` for raw OpenAPI JSON)

---

## 1. Conventions

- **Authentication**: Protected endpoints require `Authorization: Bearer <firebase-id-token>`. Tokens are verified via Firebase Admin SDK (`checkRevoked = true`).
- **Validation**: All query, param, and body payloads are validated with Zod (`@peksoft/shared`).
- **Rate Limiting**: Global window configured via `RATE_LIMIT_MAX` (default `120`) and `RATE_LIMIT_WINDOW_MS` (default `60000`). Exceeding the limit returns `429 RATE_LIMIT_EXCEEDED`. `GET /health` is exempt.
- **Error Envelope**:
  ```json
  {
    "error": {
      "code": "BAD_REQUEST",
      "message": "Human-readable message",
      "requestId": "req-1",
      "details": {}
    }
  }
  ```

---

## 2. System Endpoints

### `GET /health`
Unauthenticated health check (exempt from rate limiting).
- **200 OK**: `{ status: "ok", service: "PekSoft Radio Browser", version, uptimeSeconds, timestamp }`

---

## 3. Radio Browser Gateway (`/v1/catalog/*`, `/v1/stations/*`)

Audio is **never** proxied through this API; responses return normalised metadata and direct broadcaster stream URLs. Web clients should check `isHttpsPlayable` before attempting in-browser playback.

### `GET /v1/catalog/countries`
- **Cache-Control**: `public, max-age=3600, stale-while-revalidate=86400`
- **200 OK**: `{ items: [{ code, name, stationCount }], total }`

### `GET /v1/catalog/genres`
Canonical genres mapped via `packages/shared/genre-map.json`.
- **Cache-Control**: `public, max-age=3600, stale-while-revalidate=86400`
- **200 OK**: `{ items: [{ id, name, tagline, stationCount }], total }`

### `GET /v1/catalog/languages`
- **Cache-Control**: `public, max-age=3600, stale-while-revalidate=86400`
- **200 OK**: `{ items: [{ code?, name, stationCount }], total }`

### `GET /v1/stations/trending`
- **Query**: `limit` (1–100, default `25`), `country` (ISO code), `httpsOnly` (`true|false`), `workingOnly` (`true|false`, default `true`)
- **Cache-Control**: `public, max-age=120, stale-while-revalidate=300`
- **200 OK**: `{ items: StationDto[], total }`

### `GET /v1/stations/search`
- **Query**: `q`, `country`, `genre`, `language`, `codec`, `minBitrate`, `httpsOnly`, `workingOnly` (default `true`), `sort` (`popular|votes|recent`), `limit` (default `40`), `offset` (default `0`)
- **Cache-Control**: `public, max-age=60, stale-while-revalidate=180`
- **200 OK**: `{ items: StationDto[], total }`

### `GET /v1/stations/:id`
- **Cache-Control**: `public, max-age=300, stale-while-revalidate=600`
- **200 OK**: `{ station: StationDto }` (or `404 NOT_FOUND`)

---

## 4. Account Endpoints (`/v1/me`)

### `GET /v1/me` (Auth required)
Upserts the PostgreSQL `User` + default `FREE` `Entitlement` on first call.
- **200 OK**: `{ user: { id, firebaseUid, email, displayName, createdAt }, entitlement: { tier, status, adsEnabled, expiresAt, limits } }`

### `DELETE /v1/me` (Auth required)
Deletes the user's PostgreSQL records (cascading favourites, collections, recents, song history, entitlement; `station_reports.user_id` set to `NULL`) and deletes the Firebase Auth account.
- **204 No Content**

---

## 5. Library & Sync Endpoints (`/v1/library/*`, `/v1/sync`)

All library endpoints require `Authorization: Bearer <token>`, use per-item `updatedAt` **last-write-wins (LWW)**, and enforce free-tier limits server-side (`10` favourites, `2` collections, `10` song history entries; `PLUS` is unlimited). Exceeding free-tier limits on direct writes returns `403 TIER_LIMIT_REACHED`.

- `GET /v1/library/favorites` → `{ items }`
- `PUT /v1/library/favorites/:stationId` → `{ record, applied }`
- `DELETE /v1/library/favorites/:stationId?updatedAt=...` → `204 No Content` (soft-delete tombstone)
- `GET /v1/library/collections` → `{ items }`
- `POST /v1/library/collections` → `201 Created` `{ record, applied }`
- `PATCH /v1/library/collections/:collectionId` → `{ record, applied }`
- `DELETE /v1/library/collections/:collectionId?updatedAt=...` → `204 No Content`
- `PUT /v1/library/collections/:collectionId/items/:stationId` → `{ record, applied }`
- `DELETE /v1/library/collections/:collectionId/items/:stationId?updatedAt=...` → `204 No Content`
- `GET /v1/library/recents` → `{ items }`
- `PUT /v1/library/recents/:stationId` → `{ record, applied }`
- `GET /v1/library/song-history` → `{ items }`
- `POST /v1/library/song-history` → `201 Created` `{ record }`
- `POST /v1/sync` (Body: `{ since?, favorites?, collections?, recents?, songHistory? }`) → `{ serverTime, appliedCount, rejected, changes }`

---

## 6. Station Reports (`/v1/reports`)

### `POST /v1/reports` (Optional Auth)
Submits a broken-stream or metadata report (`reason`: `DEAD_STREAM | WRONG_INFO | OFFENSIVE | OTHER`). Attaches `userId` when a valid Bearer token is present; otherwise records anonymously.
- **201 Created**: `{ report }`

---

## 7. Environment Variables (`apps/api/.env.example`)

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `PORT` | No | `4000` | HTTP listen port |
| `HOST` | No | `0.0.0.0` | HTTP bind host |
| `NODE_ENV` | No | `development` | `development \| test \| production` |
| `LOG_LEVEL` | No | `info` | Pino log level |
| `CORS_ORIGINS` | No | `http://localhost:3000` | Comma-separated origins or `*` |
| `RATE_LIMIT_MAX` | No | `120` | Max requests per window |
| `RATE_LIMIT_WINDOW_MS` | No | `60000` | Rate limit window in ms |
| `APP_VERSION` | No | `0.1.0` | Reported in `/health` and `User-Agent` |
| `DATABASE_URL` | For DB/Sync | — | PostgreSQL connection string |
| `FIREBASE_PROJECT_ID` | For Auth | — | Firebase project ID |
| `FIREBASE_CLIENT_EMAIL` | For Auth | — | Firebase Admin service account email |
| `FIREBASE_PRIVATE_KEY` | For Auth | — | Firebase Admin private key (PEM) |


---

## 8. Staging Deployment (Render + Render Postgres)

Staging is configured via [`render.yaml`](../render.yaml) in the repository root:

1. In the **Render Dashboard**, click **New → Blueprint** and connect `segun-aiyepeks/PekSoft-Radio-Browser` (branch `phase/4-backend-auth` or `main`).
2. Render provisions:
   - **`peksoft-radio-db-staging`** (Render Postgres) and injects `DATABASE_URL`.
   - **`peksoft-radio-api-staging`** (Docker Web Service built from `apps/api/Dockerfile`).
3. Enter your Firebase Admin service account values when prompted (`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`).
4. On container startup, `apps/api/Dockerfile` automatically runs `prisma migrate deploy` when `DATABASE_URL` is set before starting the Fastify server.
5. Verify staging:
   - `GET https://<your-render-service>.onrender.com/health`
   - `GET https://<your-render-service>.onrender.com/docs`
   - Optional seed: `pnpm --filter @peksoft/api db:seed` (using the Render External Database URL)
