# Build Log — PekSoft Radio Browser

## Milestone 0.1 — Understand and plan (Phase 0: Foundations)

### What I did
- Read `Agents.md` and the attached `PekSoft Radio Browser — User Journey & UX Document` (Version 1.0, 11 November 2026, 13 pages) in full.
- Initialised the local Git repository on branch `main` with `Agents.md` and created the phase branch `phase/0-foundations`.
- Summarised the product, tech stack, and monorepo plan, identified ambiguities and risks in the UX document and workspace, and drafted the full Phase 0 implementation plan (Milestones 0.2–0.6).

### Why
- Establishing a shared understanding of the product rules, architecture, and risks before writing code prevents rework across mobile, web, and backend.
- Creating `phase/0-foundations` from `main` follows the Git protocol in `Agents.md` so all Phase 0 work is isolated and reviewable via a pull request.

### How it works (plain English)
- `main` holds the baseline (`Agents.md`). All Phase 0 foundation work happens on `phase/0-foundations`.
- Each milestone follows the loop: plan, implement, commit with Conventional Commits, log in `docs/build-log.md`, explain in chat, and stop for review.

### Files created or changed
- `Agents.md` (committed to `main` as initial commit `380812e`)
- `docs/build-log.md` (created on `phase/0-foundations`)

### How to run and verify
- Run `git status` and `git branch -a` to confirm you are on `phase/0-foundations` branched from `main`.
- Note: No remote `origin` is configured yet, so `git push` cannot run until a GitHub repository URL is added.

### Concepts worth learning
- **Phase branch workflow**: Keeping all work for one phase on a dedicated branch (`phase/0-foundations`) and merging into `main` via a Pull Request keeps `main` clean and gives a clear review checkpoint at the end of the phase.
- **Conventional Commits**: Using prefixes like `chore:`, `docs:`, `feat:`, `ci:` makes commit history readable and helps automate changelogs later.

### Decisions and alternatives
- **Initialised `main` with `Agents.md`**: Since the folder was not yet a Git repository, `main` was created with `Agents.md` so `phase/0-foundations` could branch cleanly from it. Alternative: wait for a remote clone, which would block local commits in Milestone 0.1.
- **Pending items for upcoming milestones**: `docs/ux-document.md` is not yet saved inside `docs/`, `brand/logo-mark.svg` and `brand/palette.md` (needed for Milestone 0.3) are not yet in `brand/`, and no GitHub remote URL is configured yet.

---

## Milestone 0.2 — Monorepo scaffold (Phase 0: Foundations)

### What I did
- Scaffolded the Flutter Android app in `apps/mobile` (`com.peksoft.radio`, outside `pnpm`).
- Configured `pnpm` workspaces (`pnpm-workspace.yaml`) and Turborepo (`turbo.json`) at the root, plus shared TypeScript strict config (`tsconfig.base.json`).
- Created `apps/web` (Next.js 16, React 19, TypeScript, Tailwind CSS v4, App Router), `apps/api` (Node.js, TypeScript, Fastify 5, Zod env validation, `GET /health`), `packages/shared`, `packages/design-tokens`, `brand/`, and `docs/index.md`.
- Added root `README.md` with prerequisites, layout, and run/test instructions.
- Verified `pnpm install`, `pnpm build`, `pnpm lint`, `pnpm typecheck`, `pnpm test`, `dart format`, `flutter analyze`, and `flutter test` all pass.

### Why
- Keeping mobile, web, API, shared schemas, and design tokens in one monorepo lets shared contracts and design tokens stay in sync while allowing each app to build and test independently.

### How it works (plain English)
- **What a monorepo is**: One Git repository containing multiple apps (`apps/*`) and shared libraries (`packages/*`).
- **`pnpm` workspaces**: Manages dependencies for all TypeScript projects (`apps/web`, `apps/api`, `packages/*`) from one lockfile (`pnpm-lock.yaml`) using a fast content-addressable store.
- **Turborepo**: Runs `build`, `lint`, `typecheck`, and `test` across TypeScript packages in dependency order (building `packages/*` before `apps/*`) and caches unchanged results.
- **`apps/mobile` outside `pnpm`**: Flutter uses Pub (`pubspec.yaml`) and Gradle rather than npm, so it lives in `apps/mobile` and is excluded from `pnpm-workspace.yaml`.
- **Tool choices**:
  - *Flutter*: Single codebase for Android-first mobile with strong background audio support.
  - *Next.js (App Router + Tailwind)*: Server-rendered public SEO pages (`/country/*`, `/genre/*`, `/station/*`) needed for search traffic and ad-network approval, plus an interactive web player.
  - *Fastify + Zod*: Lightweight, fast TypeScript HTTP server with strict runtime schema validation shared via `@peksoft/shared`.

### Files created or changed
- Root: `package.json`, `pnpm-workspace.yaml`, `pnpm-lock.yaml`, `turbo.json`, `tsconfig.base.json`, `README.md`
- Mobile: `apps/mobile/` (Flutter Android project with `applicationId = "com.peksoft.radio"`)
- Web: `apps/web/` (Next.js App Router + Tailwind v4 starter + `.env.example`)
- API: `apps/api/` (Fastify server + Zod env loader + `/health` test + `.env.example`)
- Packages: `packages/shared/`, `packages/design-tokens/`
- Docs & Brand: `brand/README.md`, `docs/index.md`, `docs/build-log.md`

### How to run and verify
- TypeScript workspaces:
  - `pnpm install`
  - `pnpm build`
  - `pnpm lint`
  - `pnpm typecheck`
  - `pnpm test`
- Mobile (`apps/mobile`):
  - `dart format --output=none --set-exit-if-changed .`
  - `flutter analyze`
  - `flutter test`

### Concepts worth learning
- **Workspace protocol (`workspace:*`)**: Tells `pnpm` to link `@peksoft/shared` and `@peksoft/design-tokens` directly from the local monorepo rather than downloading from npm.
- **Task dependency graph (`^build` in `turbo.json`)**: Means "build my workspace dependencies first before building/testing me."

### Decisions and alternatives
- **Excluded `apps/mobile` from `pnpm-workspace.yaml`**: Keeps Dart/Flutter tooling completely separate from Node.js tooling. Alternative: three separate Git repositories, which makes sharing design tokens and API contracts much harder.
- **Placed `allowBuilds` in `pnpm-workspace.yaml`**: Required by `pnpm` v12 so `esbuild` can run its postinstall script non-interactively in local and CI environments.

---

## Milestone 0.3 — Brand and design tokens (Phase 0: Foundations)

### What I did
- Created `brand/palette.md`, `brand/logo-mark.svg`, `brand/app-icon-square.svg`, and exported `brand/app-icon-1024.png` (1024×1024) from the square icon.
- Created `packages/design-tokens/tokens.json` with dark & light theme colours, a Space Grotesk type scale, spacing (including 48dp touch targets), radii, elevation, and motion durations.
- Built `packages/design-tokens/scripts/generate.mjs` to output Dart constants (`apps/mobile/lib/core/theme/design_tokens.dart`) and CSS variables + Tailwind v4 `@theme` (`apps/web/src/app/tokens.css`, `packages/design-tokens/dist/tokens.css`) plus typed TS exports (`packages/design-tokens/src/generated.ts`).
- Generated Android launcher icons (`apps/mobile/android/app/src/main/res/mipmap-*/ic_launcher.png`) and web favicons (`apps/web/src/app/favicon.ico`, `icon.png`, `apple-icon.png`, `apps/web/public/icons/*`) via `packages/design-tokens/scripts/generate-icons.mjs`.
- Wired `apps/web/src/app/globals.css` to import `tokens.css`.

### Why
- Keeping `tokens.json` as the single source of truth guarantees Flutter and Next.js share identical colours, typography, spacing, and motion without hard-coded values.
- Using a full-bleed square icon (`app-icon-square.svg` → `app-icon-1024.png`) prevents double-rounding or corner clipping when Google Play and Android launchers apply their own adaptive masks.

### How it works (plain English)
- **Token pipeline**:
  1. `packages/design-tokens/tokens.json` defines raw design values once.
  2. `pnpm --filter @peksoft/design-tokens build` runs `scripts/generate.mjs`, which transforms those JSON values into:
     - `apps/mobile/lib/core/theme/design_tokens.dart` (`AppDarkColors`, `AppLightColors`, `AppTypography`, `AppSpacing`, `AppRadii`, `AppElevation`, `AppDurations`) for Flutter `ThemeData`.
     - `apps/web/src/app/tokens.css` (CSS custom properties for `[data-theme='dark']` / `[data-theme='light']` + Tailwind v4 `@theme inline` variables).
     - `packages/design-tokens/src/generated.ts` for TypeScript consumers.
  3. Any future change to `tokens.json` propagates to both mobile and web automatically on rebuild.

### Files created or changed
- Brand: `brand/palette.md`, `brand/logo-mark.svg`, `brand/app-icon-square.svg`, `brand/app-icon-1024.png`
- Design tokens: `packages/design-tokens/tokens.json`, `packages/design-tokens/scripts/generate.mjs`, `packages/design-tokens/scripts/generate-icons.mjs`, `packages/design-tokens/package.json`, `packages/design-tokens/src/index.ts`, `packages/design-tokens/src/index.test.ts`, `packages/design-tokens/src/generated.ts`
- Mobile: `apps/mobile/lib/core/theme/design_tokens.dart`, `apps/mobile/android/app/src/main/res/mipmap-*/ic_launcher.png`
- Web: `apps/web/src/app/tokens.css`, `apps/web/src/app/globals.css`, `apps/web/src/app/favicon.ico`, `apps/web/src/app/icon.png`, `apps/web/src/app/apple-icon.png`, `apps/web/public/icons/*`
- Docs: `docs/build-log.md`

### How to run and verify
- Regenerate tokens and build: `pnpm --filter @peksoft/design-tokens build`
- Verify all checks: `pnpm build && pnpm lint && pnpm typecheck && pnpm test`
- Verify mobile: `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

### Concepts worth learning
- **Single source of truth for design tokens**: Storing colours/type/spacing in platform-neutral JSON and code-generating Dart + CSS prevents drift between Flutter and React UIs.
- **Full-bleed store icons**: Play Store and Android OEM launchers apply squircle/circle masks dynamically; providing rounded corners inside the source PNG leaves unwanted transparent/dark fringes.

### Decisions and alternatives
- **Pure Node.js generator script over Style Dictionary**: Kept zero extra runtime/build dependencies in `packages/design-tokens` while producing idiomatic Flutter `BoxShadow`/`TextStyle` and Tailwind v4 `@theme` CSS. Can swap to Style Dictionary later without changing `tokens.json`.
- **Deep Amber (`#B45309`) for light-mode accent**: Sampled `#FFB020` works on `#0A0F1C` dark backgrounds (~10.3:1), whereas `#B45309` maintains > 5:1 WCAG AA contrast on `#F6F4EE` light backgrounds.

---

## Milestone 0.4 — CI (Phase 0: Foundations)

### What I did
- Added `.github/workflows/ci.yml` with two parallel jobs running on every pull request and every push to `main`:
  - **Mobile (Flutter)**: checks `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, and `flutter test` with Flutter + pub dependency caching.
  - **Web, API & Packages (TypeScript)**: runs `pnpm install --frozen-lockfile`, `pnpm lint`, `pnpm typecheck`, `pnpm test`, and `pnpm build` with `pnpm` store and `.turbo` caching.
- Added `.github/PULL_REQUEST_TEMPLATE.md` with *What changed*, *Why*, *How to verify*, and *Screenshots*.

### Why
- Automated CI catches formatting, type, lint, test, and build regressions on every PR before code reaches `main`.
- A consistent PR template keeps phase reviews clear and ensures verification steps and UI screenshots are never forgotten.

### How it works (plain English)
- Whenever a PR is opened/updated or code is pushed to `main`, GitHub Actions spins up two clean Ubuntu runners in parallel: one for `apps/mobile` and one for the TypeScript monorepo.
- `concurrency` cancels superseded runs on the same branch/PR so you don't waste CI minutes when pushing follow-up commits.
- Dependency caches (`subosito/flutter-action` cache, `setup-node` pnpm cache, and `.turbo` cache) speed up repeat runs.

### Files created or changed
- `.github/workflows/ci.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `docs/build-log.md`

### How to run and verify
- Push or open a PR on GitHub and check the **Actions** tab for the **CI** workflow (`Mobile (Flutter)` and `Web, API & Packages (TypeScript)`).
- Locally, run the exact same gates:
  - `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`
  - `pnpm lint && pnpm typecheck && pnpm test && pnpm build`

### Concepts worth learning
- **`--frozen-lockfile`**: Ensures CI installs the exact dependency versions recorded in `pnpm-lock.yaml` instead of silently resolving newer ones.
- **Concurrency groups**: Cancelling older in-flight CI runs for the same PR keeps feedback fast.

### Decisions and alternatives
- **Pinned Flutter `3.44.7` in CI**: Matches the local verified Flutter SDK version so CI and local checks behave identically. Alternative: floating `channel: stable`, which can introduce unexpected analyzer rules when Flutter releases a new minor version.

---

## Milestone 0.5 — Radio Browser API spike (Phase 0: Foundations)

### What I did
- Created `apps/api/scripts/radio-browser-spike.ts` and ran it against the live Radio Browser API using `User-Agent: PekSoftRadioBrowser/0.1.0`.
- Measured mirror discovery via DNS A+PTR (`147 ms`), DNS SRV, and `https://all.api.radio-browser.info/json/servers` (`1,279 ms`), plus `/json/stats` ping (`990 ms` on `de1.api.radio-browser.info`).
- Fetched live countries (`225`), tags (`500`), languages (`200`), top stations by clickcount (`150`), and working Nigerian stations (`75`).
- Saved trimmed real fixtures to `packages/shared/fixtures/radio-browser/` (`servers.json`, `countries.json`, `tags.json`, `languages.json`, `stations-topclick.json`, `stations-ng-working.json`, `stations-sample-200.json`, `spike-report.json`).
- Documented all real field names/types, HTTPS vs HTTP-only percentages, missing favicon %, codec/bitrate distributions, HLS count, messy tag examples, and normalisation recommendations in `docs/api-spike.md`.

### Why
- Inspecting live responses prevents inventing field names, types, or assumptions about stream availability before building mobile/backend models.

### How it works (plain English)
- The spike script queries `all.api.radio-browser.info` via DNS and `/json/servers`, selects the fastest healthy mirror, downloads real catalog and station data, saves JSON fixtures for offline unit tests in Phase 2+, and computes exact statistics.
- Key real-world discoveries: `hls`, `lastcheckok`, and `ssl_error` are integers (`0`/`1`), not booleans; `30.5%` of the 200-station sample (`39.3%` of top-150 global) are HTTP-only; `21%` (`32%` in Nigeria) lack a `favicon`; and tags are comma-separated strings with heavy synonym/language noise.

### Files created or changed
- `apps/api/scripts/radio-browser-spike.ts`
- `apps/api/package.json` (added `"spike"` script)
- `packages/shared/fixtures/radio-browser/*`
- `docs/api-spike.md`, `docs/index.md`, `docs/build-log.md`

### How to run and verify
- Re-run the live spike: `pnpm --filter @peksoft/api spike`
- Verify TypeScript checks: `pnpm lint && pnpm typecheck && pnpm test && pnpm build`

### Concepts worth learning
- **Real API fixtures**: Saving real responses as local JSON fixtures lets Phase 2+ tests run fast and deterministically offline without hitting community servers.
- **Client-side click reporting**: Radio Browser deduplicates clicks per station per IP per 24h, so clients should report plays directly rather than funneling through one backend IP.

### Decisions and alternatives
- **Use `/json/servers` + 24h cache on Android with DNS A fallback**: Dart lacks built-in DNS SRV support, while `/json/servers` works cleanly over HTTPS in Dio.
- **Direct client click reporting**: Preserves accurate per-user IP counting on Radio Browser.

---

## Milestone 0.6 — Decisions and architecture (Phase 0: Foundations)

### What I did
- Created `docs/decisions.md` with 10 Architecture Decision Records (`ADR-001` to `ADR-010`) recording every verified tool/package version and rationale.
- Created `docs/architecture.md` with a Mermaid system diagram covering `apps/mobile`, `apps/web`, `apps/api`, Firebase, PostgreSQL, Radio Browser mirrors, third-party streams, Google Play Billing, Paystack, AdMob, and AdSense.
- Updated `docs/index.md` and ran the full Phase 0 quality gate (`pnpm lint`, `pnpm typecheck`, `pnpm test`, `pnpm build`, `dart format`, `flutter analyze`, `flutter test`).

### Why
- Recording verified versions and architectural boundaries before Phase 1 prevents drift and keeps every future phase aligned on where auth, audio, caching, payments, and ads live.

### How it works (plain English)
- `docs/decisions.md` is the durable record of *why* each technology was chosen and what exact version was verified in Phase 0.
- `docs/architecture.md` visualises how data flows: audio streams directly to devices (never proxied), metadata is cached/normalised respectfully, and entitlements are verified server-side.

### Files created or changed
- `docs/decisions.md`
- `docs/architecture.md`
- `docs/index.md`
- `docs/build-log.md`

### How to run and verify
- Full monorepo quality gate:
  - `pnpm lint && pnpm typecheck && pnpm test && pnpm build`
  - `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

### Concepts worth learning
- **Architecture Decision Records (ADRs)**: Short, immutable-style notes capturing context, decision, and consequences so future contributors (and AI sessions) understand *why* things are built a certain way.
- **No-proxy audio architecture**: Streaming directly from broadcaster URLs avoids massive server bandwidth costs and legal rebroadcasting issues.

### Decisions and alternatives
- **Unverified future-phase packages marked as targets**: Rather than guessing versions for Phase 1–5 libraries (`riverpod`, `drift`, `just_audio`, `shadcn`, `motion`), `docs/decisions.md` separates verified Phase 0 versions from Phase 1+ targets to be verified at install time.

---

## Phase 0 Summary — Ready for Review

**Branch:** `phase/0-foundations` → `main`  
**Milestones completed:** `0.1` Understand & Plan · `0.2` Monorepo Scaffold · `0.3` Brand & Design Tokens · `0.4` CI & PR Template · `0.5` Radio Browser API Spike · `0.6` Decisions & Architecture

All Phase 0 foundations are in place with zero product features built:
- `pnpm` + Turborepo monorepo (`apps/web`, `apps/api`, `packages/shared`, `packages/design-tokens`) + Flutter Android app (`apps/mobile`, `com.peksoft.radio`).
- Brand assets (`brand/`) and automated token pipeline (`tokens.json` → Dart constants + Tailwind/CSS variables) + Android launcher icons & web favicons.
- GitHub Actions CI (`.github/workflows/ci.yml`) and PR template.
- Live Radio Browser API spike (`docs/api-spike.md`) and 8 real JSON fixtures (`packages/shared/fixtures/radio-browser/`).
- ADRs (`docs/decisions.md`) and Mermaid system architecture (`docs/architecture.md`).
