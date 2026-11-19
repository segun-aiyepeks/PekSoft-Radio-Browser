# Release Pipelines & Rollback Runbook (Milestone 7.5)

Date: 2026-11-19  
Branch: `phase/7-launch`

---

## 1. Automated Release Pipelines (GitHub Actions)

### Android Play Internal Track (`.github/workflows/release-android.yml`)
- **Trigger**: Tag push matching `v*` (e.g., `v1.0.0`) or manual `workflow_dispatch`.
- **Flow**:
  1. Runs `flutter analyze` and `flutter test` quality gate.
  2. Decodes `ANDROID_KEYSTORE_BASE64` and generates `android/key.properties` from GitHub Secrets (cleaned up automatically in `if: always()`).
  3. Builds a signed, obfuscated App Bundle (`flutter build appbundle --release --obfuscate --split-debug-info=...`).
  4. Uploads `.aab` and debug symbols as a 30-day workflow artifact.
  5. Uploads the `.aab` + ProGuard mapping file to the **Google Play Internal Track** via `r0adkll/upload-google-play@v1`.

### API & Web Staging -> Production (`.github/workflows/deploy-api-web.yml`)
- **Trigger**:
  - Push to `main` touching `apps/api/**`, `apps/web/**`, or `packages/**` -> automatically runs the quality gate and deploys to **staging**.
  - Manual `workflow_dispatch` with `deploy_production=true` -> promotes through **staging** and requires **GitHub Environment (`production`) reviewer approval** before deploying to **production**.
- **Flow**:
  1. **Verify**: `pnpm lint`, `test`, and `build` for both `@peksoft/api` and `@peksoft/web`.
  2. **Staging**: Runs `prisma migrate deploy` against `STAGING_DATABASE_URL`, triggers `STAGING_API_DEPLOY_HOOK` and `STAGING_WEB_DEPLOY_HOOK`, and verifies `${STAGING_API_URL}/health/ready` returns `200 OK`.
  3. **Production**: Runs `prisma migrate deploy` against `PROD_DATABASE_URL`, triggers `PROD_API_DEPLOY_HOOK` and `PROD_WEB_DEPLOY_HOOK`, and verifies `${PROD_API_URL}/health/ready`.

---

## 2. Required GitHub Environments & Secrets

| Environment | Secrets / Variables | Purpose |
|---|---|---|
| `android-release` | `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`, `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Signed `.aab` build & Play Internal Track upload |
| `staging` | Secrets: `STAGING_DATABASE_URL`, `STAGING_API_DEPLOY_HOOK`, `STAGING_WEB_DEPLOY_HOOK` · Vars: `STAGING_API_URL`, `STAGING_WEB_URL` | Automated staging deploy + DB migrations |
| `production` | Secrets: `PROD_DATABASE_URL`, `PROD_API_DEPLOY_HOOK`, `PROD_WEB_DEPLOY_HOOK` · Vars: `PROD_API_URL`, `PROD_WEB_URL` | Approval-gated production deploy + DB migrations |

---

## 3. Rollback Procedures

### A. Web App Rollback (Vercel / Netlify / Railway — < 2 minutes)
1. Open the hosting dashboard -> **Deployments**.
2. Select the last known-good production deployment and click **Instant Rollback / Promote to Production**.
3. Verify `https://radio.peksoft.com/` and `https://radio.peksoft.com/status` load cleanly.

### B. API Rollback (Railway / Render / Cloud Run — < 3 minutes)
1. Re-activate the previous healthy container/release in your API host dashboard.
2. Verify `GET https://api.peksoft.radio/health/ready` returns `200 OK` with `checks.database: "ok"`.
3. Check Sentry error rate returns to baseline.

### C. Database Migration Rollback (Prisma / PostgreSQL)
- **Rule**: Always write **expand-and-contract** (backward-compatible) migrations — add nullable columns or new tables first; never drop/rename columns in the same release as code changes.
- Because migrations are backward-compatible, rolling back the API container works immediately **without** reverting the database schema.
- If a bad migration must be reverted:
  1. Take an immediate snapshot/backup of PostgreSQL before touching data.
  2. Run a forward **compensating migration** (preferable over destructive `DROP`) or restore from the pre-deploy automated snapshot if data integrity was affected.
  3. Mark failed migrations cleanly with `prisma migrate resolve --rolled-back <migration_name>` only after verifying DB state.

### D. Android App Rollback (Google Play Console)
- Google Play does not allow downgrading a `versionCode` on devices that already updated.
- **If in staged rollout (< 100%)**: Click **Halt rollout** in Play Console immediately so no further devices receive the faulty release.
- **To recover affected users**: Revert the offending commit on `main`, bump `versionCode` in `apps/mobile/pubspec.yaml` (e.g., `1.0.0+1` -> `1.0.1+2`), tag `v1.0.1`, and let `release-android.yml` ship the fixed `.aab`.
