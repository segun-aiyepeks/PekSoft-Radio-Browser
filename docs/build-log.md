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

---

## Milestone 1.1 — Shell and design system (Phase 1: Mobile UI with mock data)

### What I did
- Created branch `phase/1-mobile-ui` from `main`.
- Added `go_router` (`18.1.4`) to `apps/mobile/pubspec.yaml`.
- Built `ThemeData` for dark (default) and light modes in `apps/mobile/lib/core/theme/app_theme.dart` + `theme_controller.dart`, driven 100% by `design_tokens.dart` (no hard-coded colours or sizes).
- Built all 11 reusable shared widgets in `apps/mobile/lib/core/widgets/`: `StationLogo` (with deterministic generated fallback), `StationTile`, `GenreChip`, `FilterChipBar`, `SectionHeader`, `EmptyState`, `ErrorState`, `SkeletonList` (respects reduced motion), `PrimaryButton`, `QualityBadge`, and `AdSlotPlaceholder`.
- Configured `go_router` (`app_router.dart`) with `StatefulShellRoute.indexedStack` for 4 tabs (`Home`, `Explore`, `Library`, `Profile`), a persistent `MiniPlayerSlot` above the bottom navigation bar, and a dev-only `/gallery` route (`ComponentGalleryScreen`, guarded by `kDebugMode`).
- Added widget tests verifying the 4-tab shell + persistent mini-player, dark/light design tokens, 48dp touch targets, and `ComponentGalleryScreen` at `1.3x` text scale.
- Ran `dart format`, `flutter analyze` (zero issues), and `flutter test` (4/4 passed).

### Why
- Establishing the token-driven theme, shared component library, and navigation shell first ensures every screen in Milestones 1.3–1.5 looks cohesive, meets accessibility rules (48dp touch targets, `Semantics`, `1.3x` text scaling), and avoids duplicating UI code.

### How it works (plain English)
- `AppTheme.dark()` and `AppTheme.light()` map `AppDarkColors` / `AppLightColors`, `AppTypography`, `AppSpacing`, and `AppRadii` into Material `ThemeData` plus a custom `AppSemanticColors` `ThemeExtension` (`context.appColors`).
- `StatefulShellRoute.indexedStack` keeps each tab's navigation state alive while keeping `MiniPlayerSlot` docked above the `NavigationBar` across all tabs.

### Files created or changed
- `apps/mobile/pubspec.yaml`, `apps/mobile/pubspec.lock`
- `apps/mobile/lib/main.dart`
- `apps/mobile/lib/core/theme/app_theme.dart`, `theme_controller.dart`
- `apps/mobile/lib/core/routing/app_router.dart`
- `apps/mobile/lib/core/widgets/` (`station_logo.dart`, `station_tile.dart`, `genre_chip.dart`, `filter_chip_bar.dart`, `section_header.dart`, `empty_state.dart`, `error_state.dart`, `skeleton_list.dart`, `primary_button.dart`, `quality_badge.dart`, `ad_slot_placeholder.dart`, `widgets.dart`)
- `apps/mobile/lib/features/{home,explore,library,profile,player,dev_gallery}/presentation/`
- `apps/mobile/test/widget_test.dart`, `apps/mobile/test/shared_widgets_test.dart`
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`
- Run the app with `flutter run` and tap the top-right widgets icon on Home (or the button on Profile) in debug mode to open the Component Gallery and toggle dark/light themes.

### Concepts worth learning
- **`ThemeExtension<T>`**: Lets us expose semantic design tokens (`surfaceElevated`, `border`, `textMuted`, `accent`) cleanly via `context.appColors` beyond Material's default `ColorScheme`.
- **`StatefulShellRoute.indexedStack`**: Preserves each bottom-tab's scroll/navigation state while keeping the mini-player persistent above the tab bar.

### Decisions and alternatives
- **Used `AppTypography.fontFamily` directly without `google_fonts`**: Prevents runtime network font fetches (which violate offline test rules and add an unrequested dependency). Font assets for Space Grotesk can be bundled locally in Phase 7 if desired.
- **Used `ThemeController` (`ValueNotifier<ThemeMode>`)**: Keeps Milestone 1.1 free of extra state-management packages until Riverpod is introduced in Phase 2.


---

## Milestone 1.2 — Mock data (Phase 1: Mobile UI with mock data)

### What I did
- Created typed `const` mock models in `apps/mobile/lib/mock/mock_models.dart` (`MockStation`, `MockCountry`, `MockGenre`, `MockLanguage`, `MockCuratedCollection`).
- Built `mock_stations.dart` with **40 realistic `const` stations** (4 each across Nigeria, Ghana, South Africa, the UK, the USA, France, Germany, Japan, Brazil, and India), grounded in Phase 0 Radio Browser fixtures where available (`Wazobia FM: Lagos`, `Cool FM`, `Nigeria Info`, `RTL`) and covering varied codecs (`MP3`, `AAC`, `AAC+`, `OGG`), `isHls`, `isWorking`, `isHttps`, and missing-favicon (`null`) edge cases.
- Built `mock_countries.dart` (**30 countries**), `mock_genres.dart` (**20 canonical genres** + **10 languages**), and `mock_collections.dart` (**6 curated collections** referencing valid station IDs).
- Created `mock_providers.dart` (plus barrel `mock.dart`) exposing simple provider functions (`getMockStations`, `getMockStationsByCountry`, `getMockStationsByGenre`, `getMockStationsByLanguage`, `getMockStationById`, `getMockSimilarStations`, `searchMockStations`, `getMockCountries`, `getMockGenres`, `getMockLanguages`, `getMockCuratedCollections`, `getMockStationsForCollection`) and a UI-only `MockSessionController` for favourites, recents, and playback preview state.
- Added unit tests in `apps/mobile/test/mock_data_test.dart` and ran `dart format`, `flutter analyze` (zero issues), and `flutter test` (9/9 passed).

### Why
- Putting all mock datasets behind simple provider functions in `lib/mock/` lets Milestones 1.3–1.5 build realistic, interactive screens offline today while making the Phase 3 swap to real Riverpod ViewModels and Drift/API repositories clean and localized.

### How it works (plain English)
- All catalog lists are compile-time `const` Dart objects—zero network calls, zero database reads.
- `searchMockStations(...)` and `getMockStations(workingOnly: true)` enforce the product's **Working now ON by default** rule while letting filter sheets toggle `workingOnly: false` to test unavailable/broken-stream states.
- `MockSessionController` extends `ChangeNotifier` to track in-memory favourites, recents, and the active mock playback status for UI-only interactivity.

### Files created or changed
- `apps/mobile/lib/mock/mock_models.dart`
- `apps/mobile/lib/mock/mock_countries.dart`
- `apps/mobile/lib/mock/mock_genres.dart`
- `apps/mobile/lib/mock/mock_stations.dart`
- `apps/mobile/lib/mock/mock_collections.dart`
- `apps/mobile/lib/mock/mock_providers.dart`
- `apps/mobile/lib/mock/mock.dart`
- `apps/mobile/test/mock_data_test.dart`
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

### Concepts worth learning
- **Compile-time `const` fixtures**: Making mock models `const` ensures zero runtime allocation overhead and catches invalid data shapes at compile time.
- **Provider-function boundary**: Screens call `getMockStations(...)` instead of reading raw lists directly, creating a seam where Phase 3 Riverpod providers can drop in cleanly.

### Decisions and alternatives
- **Kept `MockSessionController` with `ChangeNotifier` instead of adding `flutter_riverpod` now**: Keeps Phase 1 strictly within the Milestone 1.1–1.2 dependency scope until Riverpod is introduced in Phase 2/3.


---

## Milestone 1.3 — Discovery screens (Phase 1: Mobile UI with mock data)

### What I did
- Built `SplashScreen` (`/splash`) and `WelcomeScreen` (`/welcome`) in `apps/mobile/lib/features/onboarding/presentation/` with country selection, optional taste chips, and a visible `Skip` action.
- Built the `HomeScreen` (`/home`) with quick search entry, `FilterChipBar`, horizontal curated collections carousel, `AdSlotPlaceholder`, and live/working stations list backed by `mock_providers.dart`.
- Built `ExploreScreen` (`/explore`) with 4 tabs (`Countries`, `Genres`, `Languages`, `Map` placeholder) plus `CountryDetailScreen` (`/country/:code`) and `GenreDetailScreen` (`/genre/:name`).
- Built `SearchScreen` (`/search`) covering empty, typing, results, and no-results states, along with `filters_bottom_sheet.dart` (`StationFilterState` with **Working now ON by default**, genre, language, codec, minimum bitrate, and sort).
- Built `StationDetailScreen` (`/station/:id`) and reusable `MockStationTile` (`apps/mobile/lib/features/station/presentation/`), and synced `MiniPlayerSlot` with `mockSessionController`.
- Wired all routes in `apps/mobile/lib/core/routing/app_router.dart`, added widget tests in `test/discovery_screens_test.dart` at `1.3x` text scale, and verified `dart format`, `flutter analyze` (`No issues found`), and `flutter test` (`15/15 passed`).

### Why
- Completing every discovery surface with token-driven UI, `48dp` touch targets, `Semantics`, and `Working now ON` defaults lets us review the full browse-and-search experience before adding the full player UI (Milestone 1.4).

### How it works (plain English)
- `MockStationTile` and `MiniPlayerSlot` both listen to `mockSessionController` via `ListenableBuilder`, so tapping Play or Favourite anywhere immediately updates all visible tiles and the persistent mini-player.
- `StationFilterState` defaults `workingOnly: true` and passes parameters straight into `searchMockStations(...)`.

### Files created or changed
- `apps/mobile/lib/core/routing/app_router.dart`
- `apps/mobile/lib/features/onboarding/presentation/{splash_screen.dart,welcome_screen.dart}`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `apps/mobile/lib/features/explore/presentation/{explore_screen.dart,country_detail_screen.dart,genre_detail_screen.dart}`
- `apps/mobile/lib/features/search/presentation/{search_screen.dart,filters_bottom_sheet.dart}`
- `apps/mobile/lib/features/station/presentation/{mock_station_tile.dart,station_detail_screen.dart}`
- `apps/mobile/lib/features/player/presentation/mini_player_slot.dart`
- `apps/mobile/test/{widget_test.dart,discovery_screens_test.dart}`
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

### Concepts worth learning
- **`ListenableBuilder` with `ChangeNotifier`**: Lightweight built-in Flutter reactive binding for local UI-only state in Phase 1 before Riverpod is introduced in Phase 2/3.
- **Immutable filter state (`StationFilterState`)**: Returning a new `StationFilterState` from `showModalBottomSheet` keeps filter edits cancelable until the user taps **Apply Filters**.

### Decisions and alternatives
- **Kept `/home` as `initialLocation` while exposing `/splash` and `/welcome` as routes**: Lets `PekSoftRadioApp` boot directly into the 4-tab shell during development and preserves shell smoke tests while keeping Splash/Welcome fully navigable.


---

## Milestone 1.4 — Player UI (Phase 1: Mobile UI with mock data)

### What I did
- Built `NowPlayingScreen` (`/player`) in `apps/mobile/lib/features/player/presentation/now_playing_screen.dart` with station artwork, track title, `QualityBadge`, play/pause, favourite toggle, sleep-timer trigger, share action, report trigger, similar stations, and a dev-only playback state switcher (`kDebugMode`).
- Added `sleep_timer_sheet.dart` (`Off`, `15–90 min`) and `report_station_sheet.dart` (issue reason chips, optional notes, mock submission confirmation).
- Updated `MiniPlayerSlot` (`mini_player_slot.dart`) to reflect all playback states (`idle`, `playing`, `paused`, `buffering`, `reconnecting`, `unavailable`) and open `/player` on tap.
- Extended `MockSessionController` in `mock_providers.dart` with UI-only sleep timer state, wired `/player` in `app_router.dart`, and added `test/player_ui_test.dart` at `1.3x` text scale.
- Ran `dart format`, `flutter analyze`, and `flutter test`.

### Why
- Giving every playback state (including buffering, reconnecting, and station-unavailable) a clear visual and accessible representation—plus a debug-only state switcher—lets us verify edge-case UX before integrating `just_audio` in Phase 4.

### How it works (plain English)
- `MiniPlayerSlot` and `NowPlayingScreen` both subscribe to `mockSessionController` via `ListenableBuilder`, keeping play/pause, favourites, sleep timer, and simulated error states synchronized across the app.

### Files created or changed
- `apps/mobile/lib/core/routing/app_router.dart`
- `apps/mobile/lib/mock/mock_providers.dart`
- `apps/mobile/lib/features/player/presentation/{mini_player_slot.dart,now_playing_screen.dart,sleep_timer_sheet.dart,report_station_sheet.dart}`
- `apps/mobile/test/player_ui_test.dart`
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

### Concepts worth learning
- **`Semantics(liveRegion: true)`**: Announces playback status transitions (such as buffering or station unavailable) to screen readers automatically.
- **`kDebugMode` dev state switcher**: Lets developers and reviewers preview rare network/stream failure states on demand without shipping debug UI in release builds.

### Decisions and alternatives
- **Kept playback state switcher inside `kDebugMode` on `NowPlayingScreen`**: Matches the `ComponentGalleryScreen` pattern so release builds stay clean while debug builds offer instant state previews.


---

## Milestone 1.5 — Account and money screens (UI only) (Phase 1: Mobile UI with mock data)

### What I did
- Built `LibraryScreen` (`/library`) with 4 tabs (`Favourites`, `Recents`, `Collections`, `Song History`) and free-tier limit upgrade prompts (`Go Pro` → `/paywall`).
- Built the Auth flow (`AuthLandingScreen`, `SignInScreen`, `SignUpScreen`, `VerifyEmailScreen`, `ForgotPasswordScreen`, `ResetPasswordScreen`) with Google & email entry points, guest skip, and visual `Form` validation only.
- Built `PaywallScreen` (`/paywall`) with Monthly/Annual toggle (`Save 33%`), benefits list, Restore Purchases, Terms & Privacy links, and a visible Close button, plus `SubscriptionManagementScreen` (`/subscription`).
- Built `ProfileScreen` (`/profile`), `SettingsScreen` (`/settings` with data saver, sleep-timer default, theme, language, notifications), `DeleteAccountScreen` (`/delete-account` requiring `DELETE` confirmation), and `AboutLegalScreen` (`/about` including **Station data by Radio Browser**).
- Added a token-driven `OfflineBanner` (`offline_banner.dart`) wired into `_MobileShellScaffold` and toggleable from Profile (`Simulate Offline Banner`), plus unit/widget tests in `test/account_money_screens_test.dart` at `1.3x` text scale.

### Why
- Completing all account, monetization, settings, legal, and offline-state UI with mock data ensures every screen in the mobile user journey is reviewable and accessible before backend/Firebase/billing integrations begin in Phases 5–6.

### How it works (plain English)
- `MockSessionController` tracks UI-only guest/signed-in status, mock Pro entitlement, simulated offline banner state, and Settings preferences (`dataSaver`, `defaultSleepMinutes`, `appLanguage`, `notifyCollections`).
- `_MobileShellScaffold` listens to `mockSessionController` and renders `OfflineBanner` above the active tab whenever offline simulation is enabled.

### Files created or changed
- `apps/mobile/lib/core/routing/app_router.dart`
- `apps/mobile/lib/core/widgets/{offline_banner.dart,widgets.dart}`
- `apps/mobile/lib/mock/mock_providers.dart`
- `apps/mobile/lib/features/library/presentation/library_screen.dart`
- `apps/mobile/lib/features/auth/presentation/{auth_landing_screen.dart,sign_in_screen.dart,sign_up_screen.dart,verify_email_screen.dart,forgot_password_screen.dart,reset_password_screen.dart}`
- `apps/mobile/lib/features/subscription/presentation/{paywall_screen.dart,subscription_management_screen.dart}`
- `apps/mobile/lib/features/profile/presentation/{profile_screen.dart,settings_screen.dart,delete_account_screen.dart,about_legal_screen.dart}`
- `apps/mobile/test/{widget_test.dart,account_money_screens_test.dart}`
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

### Concepts worth learning
- **Visual-only `Form` validation**: Using `GlobalKey<FormState>` and `TextFormField.validator` validates input formatting and feedback in UI-only prototypes without touching any auth backend.
- **Explicit destructive confirmation (`DELETE`)**: Requiring a typed confirmation keyword before enabling account deletion prevents accidental taps.

### Decisions and alternatives
- **Kept Auth, Paywall, and Delete Account state inside `MockSessionController`**: Lets reviewers toggle signed-in, Pro, and offline states live across all tabs without adding Firebase or billing SDKs prematurely.


---

## Milestone 1.6 — Polish and review (Phase 1: Mobile UI with mock data)

### What I did
- Ran an automated accessibility, contrast, tap-target, and `1.3x` text-scale audit (`test/polish_accessibility_test.dart`) across 8 key screens (`Home`, `Explore`, `Search`, `NowPlaying`, `Library`, `Paywall`, `Profile`, `Settings`) in both dark and light themes (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`), plus landscape (`844x390`) and tablet (`1024x768`) layout checks.
- Fixed a tap-target finding caught by the audit on `NowPlayingScreen`'s dev state switcher (`compact: true` chips were `28dp` tall; switched to full `48dp` `GenreChip` targets) and added **Replay Welcome & Splash** to `ProfileScreen` so onboarding is reachable from the UI.
- Added golden tests (`test/golden_screens_test.dart`) and generated 5 baseline golden PNGs (`HomeScreen`, `ExploreScreen`, `SearchScreen`, `NowPlayingScreen` in dark mode; `PaywallScreen` in light mode).
- Created `docs/ui-walkthrough.md` listing every Phase 1 screen, route, file path, and navigation path, and linked it from `docs/index.md`.
- Ran the full quality gate (`dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`).

### Why
- Automated guideline tests + golden snapshots + a complete UI walkthrough ensure Phase 1 meets accessibility, responsiveness, and visual consistency requirements before Phase 2 adds real networking and persistence.

### How it works (plain English)
- `polish_accessibility_test.dart` enables Flutter's `SemanticsHandle` and verifies every tappable element meets `48x48dp`, has an accessible label, and passes text contrast in both dark and light themes, while also testing landscape and tablet viewports for overflows.
- `golden_screens_test.dart` compares rendered pixels of 5 flagship screens against saved PNG baselines in `apps/mobile/test/goldens/`.

### Files created or changed
- `apps/mobile/lib/features/player/presentation/now_playing_screen.dart`
- `apps/mobile/lib/features/profile/presentation/profile_screen.dart`
- `apps/mobile/test/polish_accessibility_test.dart`
- `apps/mobile/test/golden_screens_test.dart`, `apps/mobile/test/goldens/*.png`
- `docs/ui-walkthrough.md`, `docs/index.md`, `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

### Concepts worth learning
- **Flutter accessibility guidelines (`meetsGuideline`)**: Built-in `flutter_test` matchers (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) catch real a11y regressions automatically in CI.
- **Golden testing**: Pixel-snapshot tests (`matchesGoldenFile`) catch unintended layout or token regressions on key screens.

### Decisions and alternatives
- **Kept 5 flagship golden screens (4 dark, 1 light) rather than snapshotting all 24 screens**: Covers every major layout archetype (feed, tabs, search list, player, paywall) while keeping golden maintenance fast.

---

## Phase 1 Summary — Ready for Review

**Branch:** `phase/1-mobile-ui` → `main`  
**Milestones completed:** `1.1` Shell & Design System · `1.2` Mock Data · `1.3` Discovery Screens · `1.4` Player UI · `1.5` Account & Money Screens · `1.6` Polish & Review

Every mobile screen is built with token-driven dark & light themes, `Semantics`, `>= 48dp` touch targets, and `1.3x` text-scale support—backed by `const` mock data in `apps/mobile/lib/mock/` with zero networking, database, Firebase, or real audio.


---

## Milestone 2.1 — Domain models (Phase 2: Mobile data layer)

### What I did
- Created branch `phase/2-mobile-data` from `main` and added `freezed_annotation` (`3.1.0`), `freezed` (`3.2.5`), and `build_runner` (`2.15.1`) to `apps/mobile/pubspec.yaml`.
- Created immutable `@freezed` domain models across `apps/mobile/lib/features/*/domain/` and `apps/mobile/lib/core/domain/`:
  - `Station`, `Country`, `Genre`, `Language`, `Collection`, `SongHistoryEntry`, `PlaybackState`, `UserSettings` (`workingNowDefault: true`, `AppThemePreference.dark`), and `Entitlement` (`EntitlementTier.free` by default with `maxFavourites: 10`, `maxCollections: 2`, `maxSongHistory: 10`, `adsEnabled: true`).
- Created the sealed `AppFailure` hierarchy (`NetworkFailure`, `TimeoutFailure`, `MirrorUnavailableFailure`, `StreamPlaybackFailure`, `StorageFailure`, `NotFoundFailure`, `ValidationFailure`, `EntitlementRequiredFailure`, `UnknownFailure`) and `Result<T>` (`Success` | `Failure`) in `apps/mobile/lib/core/domain/`.
- Added `docs/domain-model.md` with a Mermaid `classDiagram`, linked it from `docs/index.md`, and added unit tests in `apps/mobile/test/domain_models_test.dart`.

### Why
- Keeping pure, immutable `@freezed` domain models and explicit `Result`/`AppFailure` types separate from Dio DTOs and Drift tables enforces clean dependency direction (`presentation -> domain <- data`) and prevents transport or storage bugs from leaking into ViewModels.

### How it works (plain English)
- `freezed` generates value equality (`==`/`hashCode`), `copyWith`, and pattern matching for every domain class.
- Repositories will return `Future<Result<T>>` so errors are always handled explicitly rather than swallowed.

### Files created or changed
- `apps/mobile/pubspec.yaml`, `apps/mobile/pubspec.lock`
- `apps/mobile/lib/core/domain/{app_failure.dart,app_failure.freezed.dart,result.dart}`
- `apps/mobile/lib/features/station/domain/{station.dart,station.freezed.dart}`
- `apps/mobile/lib/features/catalog/domain/{country.dart,country.freezed.dart,genre.dart,genre.freezed.dart,language.dart,language.freezed.dart}`
- `apps/mobile/lib/features/library/domain/{collection.dart,collection.freezed.dart,song_history_entry.dart,song_history_entry.freezed.dart}`
- `apps/mobile/lib/features/player/domain/{playback_state.dart,playback_state.freezed.dart}`
- `apps/mobile/lib/features/profile/domain/{user_settings.dart,user_settings.freezed.dart}`
- `apps/mobile/lib/features/subscription/domain/{entitlement.dart,entitlement.freezed.dart}`
- `apps/mobile/test/domain_models_test.dart`
- `docs/{domain-model.md,index.md,build-log.md}`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

### Concepts worth learning
- **Value equality (`==`) with `freezed`**: Two `Station` instances with identical fields compare equal without manual boilerplate, which prevents unnecessary Riverpod widget rebuilds.
- **Sealed failure unions**: Exhaustive `switch` expressions on `AppFailure` guarantee every failure case maps to a clear user-facing message.

### Decisions and alternatives
- **Committed generated `.freezed.dart` files**: Lets `flutter analyze` and `flutter test` run immediately in CI without adding a slow `build_runner` step to every CI job.


---

## Milestone 2.2 — Radio Browser data source (Phase 2: Mobile data layer)

### What I did
- Added `dio` (`5.11.1`) to `apps/mobile/pubspec.yaml`.
- Created Radio Browser DTOs matching the real Phase 0 fixture fields in `apps/mobile/lib/core/network/dto/`:
  - `RadioBrowserServerDto`, `RadioBrowserCountryDto`, `RadioBrowserTagDto`, `RadioBrowserLanguageDto`, `RadioBrowserStationDto` (all 37 fields including `0`/`1` integer flags `hls`, `lastcheckok`, `ssl_error`), and `RadioBrowserClickDto`.
- Built `RadioBrowserMirrorService` (`apps/mobile/lib/core/network/radio_browser_mirror_service.dart`) with `/json/servers` discovery, random starting mirror selection, 24-hour in-memory cache, and hard-coded fallback (`de1.api.radio-browser.info`, `all.api.radio-browser.info`).
- Built `RadioBrowserClient` (`apps/mobile/lib/core/network/radio_browser_client.dart`) on `Dio` with `User-Agent: PekSoftRadioBrowser/<version>`, connect/receive timeouts (`6s`/`10s`), exponential back-off retries per mirror, automatic failover to the next mirror on error, and click reporting (`/json/url/{stationuuid}`).
- Added unit tests in `apps/mobile/test/radio_browser_client_test.dart` using saved Phase 0 fixtures (`packages/shared/fixtures/radio-browser/*.json`) via a fake `HttpClientAdapter` (zero live network calls).

### Why
- Radio Browser is a community-run mirror pool where individual servers can be slow or unreachable; mirror discovery + 24h caching + exponential back-off + failover keeps discovery resilient while respecting server etiquette.

### How it works (plain English)
- On the first request, `RadioBrowserMirrorService` queries `https://all.api.radio-browser.info/json/servers`, shuffles/rotates from a random index, and caches the list for 24 hours. If discovery fails, it falls back to `de1.api.radio-browser.info` and `all.api.radio-browser.info`.
- `RadioBrowserClient` sends requests with the required `User-Agent` header. Transient errors or 5xx responses retry with exponential back-off (`250ms` base) before failing over to the next mirror, returning `Failure<T>` with a typed `AppFailure` if all mirrors fail.

### Files created or changed
- `apps/mobile/pubspec.yaml`, `apps/mobile/pubspec.lock`
- `apps/mobile/lib/core/network/dto/{radio_browser_server_dto.dart,radio_browser_country_dto.dart,radio_browser_tag_dto.dart,radio_browser_language_dto.dart,radio_browser_station_dto.dart,radio_browser_click_dto.dart}`
- `apps/mobile/lib/core/network/{radio_browser_mirror_service.dart,radio_browser_client.dart}`
- `apps/mobile/test/radio_browser_client_test.dart`
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test test/radio_browser_client_test.dart`

### Concepts worth learning
- **Fake `HttpClientAdapter` in Dio**: Swapping Dio's transport adapter in tests lets us test real request headers, retry delays, mirror failover, and fixture JSON parsing deterministically with zero network calls.
- **Mirror rotation + 24h cache**: Picks a random starting mirror to distribute load across Radio Browser servers while avoiding repeated `/json/servers` lookups.

### Decisions and alternatives
- **HTTPS `/json/servers` discovery with hard-coded fallback**: Chosen over DNS SRV because Dart's `dart:io` lacks native SRV record lookup, matching the Phase 0 spike findings (`docs/api-spike.md`).


---

## Milestone 2.3 — Normalisation (Phase 2: Mobile data layer)

### What I did
- Created `packages/shared/genre-map.json` containing the 20 canonical genres (matching Phase 1 UI IDs), `maxGenresPerStation: 2`, `noiseTags` (submitter/meta/city noise from `docs/api-spike.md`), and multilingual/synonym aliases.
- Registered `../../packages/shared/genre-map.json` as a Flutter asset in `apps/mobile/pubspec.yaml`.
- Created `GenreMap` (`apps/mobile/lib/core/normalisation/genre_map.dart`) to parse `genre-map.json` and map raw comma-separated `tags` into deduplicated canonical `Genre` objects (capped at 2).
- Created `StationNormaliser` (`apps/mobile/lib/core/normalisation/station_normaliser.dart`) implementing:
  - `isHttps` (`url_resolved` or `url` starts with `https://`)
  - `usesFallbackLogo` (`favicon` empty or non-HTTP(S))
  - `isWorking` (`lastcheckok == 1` and non-empty stream URL)
  - Duplicate merging by `stationuuid` first, then `(normalizedName, countryCode, resolvedHost)` keeping the working/HTTPS/highest-click variant
  - `StationFilter` (`workingNowOnly: true` by default) and `StationSortOption` (`popular`, `trending`, `votes`, `bitrate`, `nameAsc`)
- Added unit tests in `apps/mobile/test/station_normaliser_test.dart` covering all messy-tag examples from `docs/api-spike.md` and the real Phase 0 Nigeria fixture.

### Why
- Raw Radio Browser `tags` contain synonyms, multilingual duplicates, and submitter noise (`moi merino`, `estación`, `fm`), and even `lastcheckok=1` queries can return broken or duplicate streams. Normalising in one shared place keeps UI rows clean and lets `apps/api` reuse `packages/shared/genre-map.json` in Phase 4.

### How it works (plain English)
- `GenreMap` loads `packages/shared/genre-map.json`, strips noise tags, checks exact alias matches first and longest-substring compound matches second, and stops after 2 unique canonical genres.
- `StationNormaliser` converts `RadioBrowserStationDto` into immutable `Station` domain models, deduplicates mirrors/re-submissions, filters out non-working streams by default, and sorts cleanly.

### Files created or changed
- `packages/shared/genre-map.json`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/lib/core/normalisation/{genre_map.dart,station_normaliser.dart}`
- `apps/mobile/test/station_normaliser_test.dart`
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test test/station_normaliser_test.dart`

### Concepts worth learning
- **Shared JSON mapping across platforms**: Storing `genre-map.json` in `packages/shared/` guarantees Flutter mobile (Dart) and Node API (TypeScript) classify stations identically without duplicating alias tables.
- **Signature-based deduplication**: Collapsing `(normalizedName, countryCode, resolvedHost)` catches duplicate broadcaster entries across multiple `stationuuid`s while preferring the HTTPS variant.

### Decisions and alternatives
- **Longest-alias substring fallback after exact lookup**: Handles compound tags like `"90s pop hits"` without misclassifying short tokens.


---

## Milestone 2.4 — Local storage with Drift (Phase 2: Mobile data layer)

### What I did
- Added `drift` (`2.34.4`), `sqlite3_flutter_libs` (`0.6.0+eol`), `path_provider` (`2.1.6`), `path` (`1.9.1`), and `drift_dev` (`2.34.0`) to `apps/mobile/pubspec.yaml`.
- Created Drift tables in `apps/mobile/lib/core/database/tables.dart`:
  - `CachedStations`, `CachedCatalogLists` (with `cachedAt` and `ttlSeconds`), `Favourites`, `Recents`, `Collections`, `CollectionStations`, `SongHistoryEntries`, and `UserSettingsTable`.
- Built `AppDatabase` (`apps/mobile/lib/core/database/app_database.dart` + generated `app_database.g.dart`) at `schemaVersion = 2` with `onCreate` and `onUpgrade` (`from < 2` adding `collections.sort_order`), enforcing the 50-entry cap on `Recents`.
- Added unit and migration tests in `apps/mobile/test/app_database_test.dart`, including a real SQLite v1 -> v2 file migration test verifying preserved collections and schema version `2`.

### Why
- Offline-first caching, favourites, recents, collections, song history, and user preferences need fast, strongly typed local persistence with safe schema upgrades across app updates.

### How it works (plain English)
- `AppDatabase` stores normalised `Station` rows in `cached_stations` and JSON list snapshots with TTLs in `cached_catalog_lists` so repositories can return cached data immediately while revalidating in the background.
- `recordRecent` runs inside a SQLite transaction, ordering by `played_at DESC` and pruning entries beyond the 50 most recent.

### Files created or changed
- `apps/mobile/pubspec.yaml`, `apps/mobile/pubspec.lock`
- `apps/mobile/lib/core/database/{tables.dart,app_database.dart,app_database.g.dart}`
- `apps/mobile/test/app_database_test.dart`
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test test/app_database_test.dart`

### Concepts worth learning
- **Versioned SQLite migrations**: Testing `onUpgrade` against a real v1 SQLite file proves existing user collections and favourites survive schema changes without data loss.
- **Transactional pruning**: Wrapping `insert` + `delete` in `transaction(...)` guarantees `Recents` never temporarily exceeds 50 rows on concurrent updates.

### Decisions and alternatives
- **Committed `app_database.g.dart`**: Matches our `.freezed.dart` workflow so CI runs `flutter analyze` and `flutter test` without needing `build_runner` on every run.


---

## Milestone 2.5 — Repositories (Phase 2: Mobile data layer)

### What I did
- Created repository interfaces (`features/*/domain/`) and implementations (`features/*/data/`):
  - `CatalogRepository` / `CatalogRepositoryImpl`: countries, canonical genres, languages, top stations, stations by country/genre, and search with offline-first stale-while-revalidate (24-hour TTL for lists, 5-minute TTL for search results).
  - `StationRepository` / `StationRepositoryImpl`: station lookup (cache-first with `/json/stations/byuuid` fallback), similar-station ranking by shared genre + country, and direct click reporting.
  - `LibraryRepository` / `LibraryRepositoryImpl`: local-first Drift persistence for favourites, recents (50 cap), collections, and song history, enforcing free-tier limits (`maxFavourites: 10`, `maxCollections: 2`, `maxSongHistory: 10`) via `EntitlementRepository`.
  - `SettingsRepository` / `SettingsRepositoryImpl`: Drift-backed `UserSettings` read/write.
  - `EntitlementRepository` / `EntitlementRepositoryImpl`: Phase 2 stub returning `EntitlementTier.free` by default.
- Added unit tests in `apps/mobile/test/repositories_test.dart` using `AppDatabase.inMemory()` and fake `HttpClientAdapter` responses from Phase 0 fixtures.

### Why
- Separating domain repository interfaces from Drift/Dio implementations lets ViewModels stay completely independent of storage and network mechanics while keeping offline-first caching and free-tier rules testable with fakes.

### How it works (plain English)
- When `CatalogRepositoryImpl` reads a cached list whose TTL has expired, it returns the stale cached list immediately so the UI renders with zero wait, while scheduling a background refresh that updates Drift for the next read.
- `LibraryRepositoryImpl` consults `EntitlementRepository` before adding a new favourite or custom collection, returning `Failure(EntitlementRequiredFailure(...))` when a free-tier limit is reached.

### Files created or changed
- `apps/mobile/lib/features/catalog/{domain/catalog_repository.dart,data/catalog_repository_impl.dart}`
- `apps/mobile/lib/features/station/{domain/station_repository.dart,data/station_repository_impl.dart}`
- `apps/mobile/lib/features/library/{domain/library_repository.dart,data/library_repository_impl.dart}`
- `apps/mobile/lib/features/profile/{domain/settings_repository.dart,data/settings_repository_impl.dart}`
- `apps/mobile/lib/features/subscription/{domain/entitlement_repository.dart,data/entitlement_repository_impl.dart}`
- `apps/mobile/test/repositories_test.dart`
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test test/repositories_test.dart`

### Concepts worth learning
- **Stale-while-revalidate (SWR)**: Returning slightly expired local data immediately while refreshing asynchronously eliminates loading spinners on repeat visits while keeping catalogs fresh.
- **Dependency inversion**: ViewModels depend only on `abstract interface class` repositories, making them trivial to unit-test with in-memory fakes.

### Decisions and alternatives
- **Injected `onBackgroundRevalidation` test hook**: Lets deterministic unit tests await background SWR tasks without flaky `Future.delayed` timers.


---

## Milestone 2.6 — ViewModels (Phase 2: Mobile data layer)

### What I did
- Added `flutter_riverpod` (`3.5.0`) to `apps/mobile/pubspec.yaml` and created shared DI providers in `apps/mobile/lib/core/di/providers.dart`.
- Created immutable state classes and Riverpod `Notifier` / `AsyncNotifier` ViewModels for every Phase 1 screen (without modifying or wiring up any Phase 1 UI):
  - `SplashViewModel`, `WelcomeViewModel`, `HomeViewModel`, `ExploreViewModel`, `CountryDetailViewModel`, `GenreDetailViewModel`, `SearchViewModel`, `StationDetailViewModel`, `PlayerViewModel`, `LibraryViewModel`, `AuthViewModel`, `SubscriptionViewModel`, `SettingsViewModel`.
- Documented the screen-to-ViewModel mapping, state fields, and event methods in `docs/viewmodels.md` and linked it from `docs/index.md`.
- Added unit tests for every ViewModel in `apps/mobile/test/view_models_test.dart` using `ProviderContainer` with fake repositories.

### Why
- Riverpod `Notifier` and `AsyncNotifier` ViewModels isolate screen state transitions and repository calls from Flutter widgets, making every screen's logic testable without pumping UI.

### How it works (plain English)
- Each screen reads a single Riverpod provider (`homeViewModelProvider`, `playerViewModelProvider`, etc.) and invokes explicit event methods (`selectGenre`, `playStation`, `toggleFavourite`, etc.) that update immutable state classes.

### Files created or changed
- `apps/mobile/pubspec.yaml`, `apps/mobile/pubspec.lock`
- `apps/mobile/lib/core/di/providers.dart`
- `apps/mobile/lib/features/*/presentation/view_models/*_view_model.dart` (13 ViewModel files)
- `apps/mobile/test/view_models_test.dart`
- `docs/{viewmodels.md,index.md,build-log.md}`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

### Concepts worth learning
- **`ProviderContainer` overrides**: Riverpod lets tests override repository providers with fast in-memory fakes so ViewModels are tested in milliseconds.
- **Family `AsyncNotifier`**: Parameterized screens (`/country/:code`, `/genre/:id`, `/station/:id`) receive their route argument cleanly via `AsyncNotifierProvider.family`.

### Decisions and alternatives
- **`@immutable` manual `copyWith` classes for ViewModel states**: Avoids extra `build_runner` overhead while keeping every ViewModel state immutable and explicit; domain entities continue using `@freezed`.

---

## Phase 2 Summary — Ready for Review

**Branch:** `phase/2-mobile-data` → `main`  
**Milestones completed:** `2.1` Domain Models · `2.2` Radio Browser Data Source · `2.3` Normalisation · `2.4` Local Storage with Drift · `2.5` Repositories · `2.6` ViewModels

The complete mobile MVVM + Riverpod data layer is built and verified offline with zero UI modifications:
- Pure `@freezed` domain models and sealed `AppFailure`/`Result<T>` (`docs/domain-model.md`)
- `RadioBrowserClient` on `Dio` with `/json/servers` mirror discovery, 24h mirror cache, exponential back-off retries, failover, `User-Agent`, and click reporting
- Shared `packages/shared/genre-map.json` + `StationNormaliser` (20 canonical genres, noise stripping, duplicate merging, HTTPS/fallback-logo/working-now flags, sort/filter)
- Versioned Drift SQLite database (`schemaVersion = 2`) with v1 → v2 migration test and 50-item recents cap
- Offline-first SWR repositories (`CatalogRepository`, `StationRepository`, `LibraryRepository`, `SettingsRepository`, `EntitlementRepository` stub) with 24h list / 5m search TTLs
- 13 Riverpod `Notifier`/`AsyncNotifier` ViewModels covering every Phase 1 screen (`docs/viewmodels.md`)


---

## Milestone 3.1 — Wire discovery (Phase 3: Wire & Audio)

### What I did
- Created branch `phase/3-wire-and-audio` from `main`.
- Updated `apps/mobile/lib/main.dart` to open `AppDatabase.openDefault()`, load `packages/shared/genre-map.json` into `GenreMap`, and wrap `PekSoftRadioApp` in `ProviderScope` (accepting optional test `overrides`).
- Added `apps/mobile/lib/core/utils/country_flag.dart` (`countryFlagEmoji`) and `apps/mobile/lib/features/station/presentation/station_list_tile.dart` (`StationListTile` backed by `playerViewModelProvider` and `libraryViewModelProvider`).
- Wired all 8 discovery screens to their Phase 2 Riverpod ViewModels while preserving the Phase 1 UI, `Semantics`, `48dp` touch targets, and `1.3x` text scaling:
  - `WelcomeScreen` → `welcomeViewModelProvider` + `exploreViewModelProvider`
  - `HomeScreen` → `homeViewModelProvider` (loading `SkeletonList`, `ErrorState`, `EmptyState`, `AdSlotPlaceholder` gated on `entitlement.adsEnabled`)
  - `ExploreScreen` → `exploreViewModelProvider` (Countries, Genres, Languages, Map)
  - `CountryDetailScreen` → `countryDetailViewModelProvider(countryCode)`
  - `GenreDetailScreen` → `genreDetailViewModelProvider(genreId)`
  - `SearchScreen` & `FiltersBottomSheet` → `searchViewModelProvider` (`Working now only` ON by default)
  - `StationDetailScreen` → `stationDetailViewModelProvider(stationId)` + `playerViewModelProvider`
- Wired `_MobileShellScaffold` in `apps/mobile/lib/core/routing/app_router.dart` to `settingsViewModelProvider` for `OfflineBanner`.
- Added `apps/mobile/test/helpers/mock_repository_overrides.dart` so mock data acts purely as test fixtures, updated existing Phase 1 widget/golden tests, and added `apps/mobile/test/wired_discovery_test.dart` covering loading, loaded, empty, and error states with fake repositories.

### Why
- Connecting discovery screens to Riverpod ViewModels replaces mock data calls with real offline-first repositories while keeping the UI layout and accessibility guarantees intact.

### How it works (plain English)
- Each discovery screen watches its Riverpod provider (`AsyncNotifier` or `Notifier`) and renders `SkeletonList` while loading, `ErrorState` with retry on failure, `EmptyState` when no results match, and `StationListTile` rows on success.

### Files created or changed
- `apps/mobile/lib/main.dart`, `apps/mobile/lib/core/routing/app_router.dart`
- `apps/mobile/lib/core/utils/country_flag.dart`
- `apps/mobile/lib/features/station/presentation/station_list_tile.dart`
- `apps/mobile/lib/features/onboarding/presentation/welcome_screen.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `apps/mobile/lib/features/explore/presentation/{explore_screen.dart,country_detail_screen.dart,genre_detail_screen.dart}`
- `apps/mobile/lib/features/search/presentation/{search_screen.dart,filters_bottom_sheet.dart}`
- `apps/mobile/lib/features/station/presentation/station_detail_screen.dart`
- `apps/mobile/test/{helpers/mock_repository_overrides.dart,wired_discovery_test.dart,discovery_screens_test.dart,widget_test.dart,polish_accessibility_test.dart,golden_screens_test.dart}` + updated goldens
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`

### Concepts worth learning
- **Mock data as test fixtures**: Wrapping `lib/mock/*` behind `mockRepositoryOverrides()` lets widget and golden tests run deterministically without keeping mock calls in production screens.

### Decisions and alternatives
- **Kept `PekSoftRadioApp(overrides: ...)` parameter**: Allows `main()` to inject real Drift + `GenreMap` while tests pass fast in-memory repository overrides cleanly.

---

## Milestone 3.2 — Audio engine (Phase 3: Wire & Audio)

### What I did
- Defined `AudioPlayerService` and `AudioPlaybackSnapshot` in `apps/mobile/lib/features/player/domain/audio_player_service.dart`.
- Implemented `RadioAudioHandler` (`BaseAudioHandler` using `just_audio`, `audio_service`, and `audio_session`) and `JustAudioPlayerService` in `apps/mobile/lib/features/player/data/`.
- Configured Android foreground service (`mediaPlayback`), `MediaButtonReceiver`, `WAKE_LOCK`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS`, `AudioServiceActivity` in `MainActivity.kt`, and `android/app/src/main/res/xml/network_security_config.xml`.
- Wired `PlayerViewModel` (`PlaybackViewModel` / `playbackViewModelProvider`) to `audioPlayerServiceProvider`, driving both `MiniPlayerSlot` and `NowPlayingScreen` (plus `SleepTimerSheet` and `ReportStationSheet`) with live ICY track title updates and Song History logging.
- Added `FakeAudioPlayerService` and unit/widget tests in `apps/mobile/test/audio_engine_test.dart`, and updated `player_ui_test.dart`, `widget_test.dart`, and `golden_screens_test.dart`.

### Why Android blocks cleartext traffic by default & what we allowed
- Since Android 9 (API 28), `usesCleartextTraffic` defaults to `false` to protect users against eavesdropping and tampering on unencrypted `http://` connections.
- Radio Browser indexes thousands of independent broadcasters worldwide, many of whom serve Shoutcast/Icecast audio streams over plain `http://` rather than `https://`, and those domains cannot be enumerated statically in `<domain-config>`.
- We added `network_security_config.xml` with `<base-config cleartextTrafficPermitted="true">` (with system trust anchors) for audio stream playback, while `RadioBrowserClient` continues to use `https://` for all Radio Browser API discovery and metadata requests.

---

## Milestone 3.3 — Resilience (UX journey J4) (Phase 3: Wire & Audio)

### What I did
- Added `connectivity_plus` and `ConnectivityService` (`ConnectivityPlusService`) in `apps/mobile/lib/core/network/connectivity_service.dart`.
- Preserved `fallbackStreamUrl` (original `url` when distinct from `urlResolved`) on `Station` and in `StationNormaliser.normalize`.
- Bumped `AppDatabase.schemaVersion` to `3` with migration adding `cached_stations.fallback_stream_url` and `pending_station_reports`, plus `DriftReportQueueRepository` (`ReportQueueRepository`) for locally queuing "Report broken" submissions for Phase 4 backend sync without inventing Radio Browser endpoints.
- Implemented J4 resilience in `PlayerViewModel`: primary-to-fallback URL failover (`urlResolved -> url`), 3 retries with configurable back-off (`1s, 2s, 4s`), mid-stream drop recovery, automatic reconnect when `connectivity_plus` reports network return, Radio Browser click reporting on every play, and friendly non-blocking `unavailable` banner with similar-station suggestions.
- Wired `StationDetailViewModel.submitReport` and `PlayerViewModel.reportCurrentStation` to `reportQueueRepositoryProvider`.
- Added `apps/mobile/test/resilience_test.dart`, `FakeConnectivityService`, `FakeReportQueueRepository`, and updated `app_database_test.dart` migration assertions.

---

## Milestone 3.4 — Listening features (Phase 3: Wire & Audio)

### What I did
- Implemented sleep timer countdown and smooth volume fade-out (`sleepTimerTickProvider`, `sleepFadeDurationProvider`) in `PlayerViewModel`, pausing playback and restoring volume on expiry or cancellation.
- Added `selectBitrateVariant` (`apps/mobile/lib/features/player/domain/stream_variant_selector.dart`) and wired Data Saver mode in `PlayerViewModel` + `SettingsScreen` (`settingsViewModelProvider`) to prefer lower-bitrate working variants when available.
- Wired `LibraryScreen` (Favourites, Recents, Collections, Song History) to `libraryViewModelProvider` and `Entitlement` limits (`maxFavourites`, `maxCollections`, `maxSongHistory`), including `+ New collection`, limit-reached prompts, and `Clear history`.
- Added `playSurpriseMe` to `PlayerViewModel` and a `Surprise me` action button in `HomeScreen`.
- Added `Clipboard.setData` for the placeholder share link (`https://peksoft.radio/station/<id>`) in `NowPlayingScreen`.
- Added `apps/mobile/test/listening_features_test.dart` and updated `account_money_screens_test.dart`.

---

## Milestone 3.5 — Tests and release prep (Phase 3: Wire & Audio)

### What I did
- Added end-to-end play-flow integration test (`apps/mobile/integration_test/play_flow_test.dart`, backed by shared `apps/mobile/test/helpers/play_flow_runner.dart` and `apps/mobile/test/play_flow_integration_test.dart`) exercising `Welcome -> Home -> Play -> MiniPlayer -> Now Playing -> ICY -> Favourite -> Library (Favourites & Song History)` with `FakeAudioPlayerService`.
- Profiled cold start and list scrolling and applied two targeted optimizations:
  - Parallelized `AppDatabase.openDefault()` and `_loadGenreMap()` startup futures in `apps/mobile/lib/main.dart`.
  - Converted `HomeScreen` from an eager `ListView` + `for` loop to a lazy `CustomScrollView` + `SliverToBoxAdapter` + `SliverList.builder` in `apps/mobile/lib/features/home/presentation/home_screen.dart`.
  - Added `apps/mobile/test/performance_profile_test.dart` verifying lazy viewport materialization (`< 25` of 120 stations built initially) and smooth fling scrolling.
- Wrote `docs/release-android.md` documenting `applicationId` (`com.peksoft.radio`), `versionName`/`versionCode` mapping, Play App Signing (App Signing Key vs Upload Key), keystore setup, and `flutter build appbundle --release`.
- Built the Android release App Bundle: `apps/mobile/build/app/outputs/bundle/release/app-release.aab` (`59.7MB`).

---

## Phase 3 Summary — Ready for Review

**Branch:** `phase/3-wire-and-audio` → `main`  
**Milestones completed:** `3.1` Wire discovery · `3.2` Audio engine · `3.3` Resilience (J4) · `3.4` Listening features · `3.5` Tests & release prep

Phase 3 turns the Phase 1 UI + Phase 2 offline-first repositories/ViewModels into a working Android radio player:
- All discovery screens (`Welcome`, `Home`, `Explore`, `Search`, `Filters`, `CountryDetail`, `GenreDetail`, `StationDetail`) and `Library` / `Settings` are wired to Riverpod ViewModels with skeleton loading, empty, error, and offline states; mock data remains only in test fixtures.
- `AudioPlayerService` (`RadioAudioHandler` + `JustAudioPlayerService`) handles background playback, notification/lock-screen controls, audio focus ducking, headphone unplug pause, Bluetooth metadata, MP3/AAC/OGG/HLS streams, live ICY track updates, and cleartext HTTP streams via `network_security_config.xml`.
- J4 playback resilience (`urlResolved -> url` failover, 3 retries with back-off, `connectivity_plus` auto-reconnect, Radio Browser click reporting, local Drift report queue, and friendly unavailable suggestions).
- Listening features: sleep timer with fade-out, Data Saver bitrate variant selection, Library with free-tier `Entitlement` limits, Surprise me, and clipboard share link.
- End-to-end play flow test, cold-start/scroll profiling optimizations, `docs/release-android.md`, and verified release `.aab` (`59.7MB`).

---

## Milestone 4.1 — API scaffold (Phase 4: Backend, Auth & Sync)

### What I did
- Created `apps/api` production scaffold on Fastify 5 + TypeScript:
  - **Validated config** (`apps/api/src/config/env.ts`): Zod schema validating `PORT`, `HOST`, `NODE_ENV`, `LOG_LEVEL`, `CORS_ORIGINS`, `RATE_LIMIT_MAX`, `RATE_LIMIT_WINDOW_MS`, and `APP_VERSION` at startup.
  - **Structured logging without PII** (`apps/api/src/plugins/logger.ts`): Pino configuration redacting `authorization`, `cookie`, `x-api-key`, `password`, `token`, `idToken`, and `email` paths, with a custom `req` serializer omitting client IP addresses and raw headers.
  - **Central error handler & typed errors** (`apps/api/src/errors/app-error.ts`, `apps/api/src/plugins/error-handler.ts`): Consistent `{ error: { code, message, requestId, details? } }` envelope for `AppError`, `ZodError`, Fastify schema validation errors, rate-limit `429` errors, `404` unknown routes, and redacted `500` errors.
  - **Health endpoint** (`apps/api/src/routes/health.ts`): `GET /health` returning `status`, `service`, `version`, `uptimeSeconds`, and `timestamp`, exempted from rate limiting.
  - **OpenAPI 3.1 docs**: `@fastify/swagger` (`9.9.4`) at `/docs/json` + `@fastify/swagger-ui` (`6.1.4`) at `/docs`.
  - **CORS & Rate limiting**: `@fastify/cors` (`11.4.3`) parsed from `CORS_ORIGINS` + `@fastify/rate-limit` (`11.2.2`).
  - **Container & env template**: Multi-stage Node 22 Alpine `apps/api/Dockerfile` and updated `apps/api/.env.example`.
- Wrote 6 Vitest tests in `apps/api/src/server.test.ts` using Fastify's built-in `app.inject()`.

### How to run and verify
- `pnpm lint && pnpm typecheck && pnpm test && pnpm build`

---

## Milestone 4.2 — Radio Browser gateway (Phase 4: Backend, Auth & Sync)

### What I did
- Added shared Zod schemas, DTOs, and `createStationNormaliser` in `packages/shared/src/radio.ts` (exported via `packages/shared/src/index.ts`, with `./genre-map.json` exported in `packages/shared/package.json`), enforcing `packages/shared/genre-map.json`, deduplication, `isWorking`, `isHttps`, `isHttpsPlayable` (for web clients), and `usesFallbackLogo`.
- Added `CacheStore` interface (`apps/api/src/cache/cache-store.ts`) and `InMemoryLruCache` (`apps/api/src/cache/in-memory-lru-cache.ts`) with bounded LRU eviction and per-key TTL so Redis can drop in later without service changes.
- Added `RadioBrowserClient` (`apps/api/src/repositories/radio-browser-client.ts`) with 24-hour mirror discovery (`/json/servers`), random mirror selection, automatic failover to the next mirror on error, and `User-Agent: PekSoftRadioBrowser/<version>`.
- Added `CatalogService` (`apps/api/src/services/catalog-service.ts`) and versioned v1 routes in `apps/api/src/routes/v1/catalog.ts` (`/v1/catalog/countries`, `/v1/catalog/genres`, `/v1/catalog/languages`) and `apps/api/src/routes/v1/stations.ts` (`/v1/stations/trending`, `/v1/stations/search`, `/v1/stations/:id`) with `Cache-Control` headers and zero audio proxying.
- Added unit and injection tests using Phase 0 JSON fixtures in `packages/shared/src/radio.test.ts` and `apps/api/src/gateway.test.ts`.

### How to run and verify
- `pnpm lint && pnpm typecheck && pnpm test && pnpm build`

---

## Milestone 4.3 — Database (Prisma + PostgreSQL) (Phase 4: Backend, Auth & Sync)

### What I did
- Installed Prisma `7.10.1` (`prisma`, `@prisma/client`, `@prisma/adapter-pg`) and `pg` (`8.23.1`) in `apps/api`, and added `@prisma/engines` and `prisma` to `allowBuilds` in `pnpm-workspace.yaml`.
- Created `apps/api/prisma/schema.prisma` and `apps/api/prisma.config.ts` defining 9 PostgreSQL models:
  - `User` (`users`), `Favorite` (`favorites`), `Collection` (`collections`), `CollectionItem` (`collection_items`), `Recent` (`recents`), `SongHistory` (`song_history`), `Entitlement` (`entitlements`), `WebhookEvent` (`webhook_events`), and `StationReport` (`station_reports`).
- Generated the initial PostgreSQL SQL migration in `apps/api/prisma/migrations/0001_init/migration.sql` (`migration_lock.toml` locked to `postgresql`).
- Created `apps/api/src/db/prisma.ts` (`createPrismaClient` using `PrismaPg` + `pg.Pool`) and `apps/api/prisma/seed.ts` (idempotent seed for a demo listener, entitlement, favourite, and collection).
- Added `db:generate`, `db:migrate:deploy`, `db:seed` scripts to `apps/api/package.json` and `DATABASE_URL` to `apps/api/.env.example` and `apps/api/src/config/env.ts`.

### How to run and verify
- `pnpm lint && pnpm typecheck && pnpm test && pnpm build`
- Once `DATABASE_URL` is configured:
  - `pnpm --filter @peksoft/api db:migrate:deploy`
  - `pnpm --filter @peksoft/api db:seed`

---

## Milestone 4.4 — Authentication (Phase 4: Backend, Auth & Sync)

### What I did
- Installed `firebase-admin` (`14.5.1`) in `apps/api` and allowed `@firebase/util` and `protobufjs` postinstall scripts in `pnpm-workspace.yaml`.
- Created `AuthProvider` and `FirebaseAuthProvider` in `apps/api/src/auth/firebase-auth.ts` (`verifyIdToken(token, true)` with revocation checking + `deleteUser(uid)`).
- Created Fastify `preHandler` auth middleware `createRequireAuth` in `apps/api/src/plugins/auth-middleware.ts`, attaching `request.authUser`.
- Created `UserRepository` / `PrismaUserRepository` (`apps/api/src/repositories/user-repository.ts`) and `UserService` (`apps/api/src/services/user-service.ts`), computing server-side `FREE`/`PLUS` entitlement limits.
- Added `GET /v1/me` (upserts `User` + default `FREE` `Entitlement` on first call) and `DELETE /v1/me` (deletes PostgreSQL user data + Firebase Auth account) in `apps/api/src/routes/v1/me.ts`.
- Wired auth + user routes into `apps/api/src/server.ts`, added Firebase env vars to `apps/api/src/config/env.ts` and `apps/api/.env.example`, and wrote 3 tests in `apps/api/src/auth.test.ts` with mocked token verification.

### How to run and verify
- `pnpm lint && pnpm typecheck && pnpm test && pnpm build`

---

## Milestone 4.5 — Library sync API & StationReport (Phase 4: Backend, Auth & Sync)

### What I did
- Added shared Zod sync & report schemas in `packages/shared/src/sync.ts` (`favoriteInputSchema`, `collectionInputSchema`, `collectionItemInputSchema`, `recentInputSchema`, `songHistoryInputSchema`, `deltaSyncRequestSchema`, `stationReportInputSchema`).
- Implemented `LibraryRepository` / `PrismaLibraryRepository` (`apps/api/src/repositories/library-repository.ts`) and `ReportRepository` / `PrismaReportRepository` (`apps/api/src/repositories/report-repository.ts`).
- Implemented `LibraryService` (`apps/api/src/services/library-service.ts`) and `ReportService` (`apps/api/src/services/report-service.ts`) with:
  - Per-item `updatedAt` **last-write-wins (LWW)** conflict resolution and soft-delete tombstones (`isDeleted`).
  - Server-side **free-tier enforcement** from the user's `Entitlement` (`10` favourites, `2` collections, `10` song history entries; unlimited on `PLUS`), returning `403 TIER_LIMIT_REACHED` on direct CRUD and recording `rejected` items in delta-sync.
- Registered routes in `apps/api/src/routes/v1/library.ts` (favourites, collections, collection items, recents, song history, and `POST /v1/sync`) and `apps/api/src/routes/v1/reports.ts` (`POST /v1/reports` supporting guest or authenticated users).
- Added 3 comprehensive test suites in `apps/api/src/library-sync.test.ts` verifying LWW, free-tier vs Plus limits, delta-sync `since` filtering, and station reports.

### How to run and verify
- `pnpm lint && pnpm typecheck && pnpm test && pnpm build`


---

## Milestone 4.6 — Mobile authentication and sync (Phase 4: Backend, Auth & Sync)

### What I did
- Added `firebase_core` (`5.1.0`), `firebase_auth` (`7.0.1`), and `google_sign_in` (`7.2.0`) to `apps/mobile/pubspec.yaml` and safely initialized Firebase in `apps/mobile/lib/main.dart` (falling back to guest mode if `google-services.json` is not present yet).
- Created `AuthRepository` (`apps/mobile/lib/features/auth/domain/auth_repository.dart`) and `FirebaseAuthRepository` (`apps/mobile/lib/features/auth/data/firebase_auth_repository.dart`) supporting:
  - Email sign-up with verification email + status reload + resend
  - Email sign-in and password reset email
  - Google Sign-In (`google_sign_in` v7)
  - Shared-email account linking (`AuthAccountLinkRequired` -> `linkPendingCredentialWithPassword`)
  - Sign out and account deletion
- Built `ApiClient` (`apps/mobile/lib/core/network/api_client.dart`) wrapping `Dio` with an auth interceptor that attaches `Authorization: Bearer <idToken>` and silently force-refreshes + retries once on HTTP `401`.
- Added `SyncRepository` / `SyncRepositoryImpl` (`apps/mobile/lib/features/library/domain/sync_repository.dart`, `apps/mobile/lib/features/library/data/sync_repository_impl.dart`) for guest-to-account merge of favourites/recents via `POST /v1/sync` and flushing queued `PendingStationReports` via `POST /v1/reports` (with `markReportSynced` in `AppDatabase` + `DriftReportQueueRepository`).
- Updated `AuthViewModel` (`apps/mobile/lib/features/auth/presentation/view_models/auth_view_model.dart`) and wired `AuthLandingScreen`, `SignInScreen`, `SignUpScreen`, `VerifyEmailScreen`, `ForgotPasswordScreen`, `ProfileScreen`, and `DeleteAccountScreen`.
- Added `apps/mobile/test/auth_sync_test.dart`, `FakeAuthRepository`, and `FakeSyncRepository`.

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed lib test integration_test && flutter analyze && flutter test`


---

## Milestone 4.7 — Docs and staging (Phase 4: Backend, Auth & Sync)

### What I did
- Wrote `docs/api.md` documenting all system, Radio Browser gateway, account (`/v1/me`), library & delta-sync (`/v1/library/*`, `/v1/sync`), and station-report (`/v1/reports`) endpoints, auth headers, caching, rate limits, and environment variables.
- Compared Render, Railway, Fly.io, and Google Cloud Run for hosting `apps/api`; per user choice, configured **Render** + **Render Postgres** staging in `render.yaml` (`frankfurt` region, Docker Web Service, `preDeployCommand: npx --yes prisma@7.10.1 migrate deploy`, `/health` check) and updated `apps/api/Dockerfile` to include `prisma/` and `prisma.config.ts`.
- Recorded verified Phase 4 package versions and hosting choice in `docs/decisions.md` (`ADR-011`) and linked `docs/api.md` + `docs/release-android.md` in `docs/index.md`.

---

## Phase 4 Summary — Ready for Review

**Branch:** `phase/4-backend-auth` → `main`  
**Milestones completed:** `4.1` API scaffold · `4.2` Radio Browser gateway · `4.3` Database (Prisma + PostgreSQL) · `4.4` Authentication · `4.5` Library sync API · `4.6` Mobile authentication & sync · `4.7` Docs & staging

Phase 4 adds the Node.js/Fastify backend, PostgreSQL persistence, Firebase authentication, and mobile cloud sync:
- **Fastify 5 API (`apps/api`)**: Zod-validated config, PII-redacted Pino logging, central error envelope, `/health`, OpenAPI 3.1 (`/docs`), CORS, rate limiting, and multi-stage `Dockerfile`.
- **Radio Browser Gateway**: 24h mirror discovery + failover, shared `packages/shared/genre-map.json` normalisation, `isHttpsPlayable` web flag, `CacheStore` (`InMemoryLruCache`), and `Cache-Control` headers (zero audio proxying).
- **Database (`Prisma 7` + PostgreSQL)**: 9 models (`User`, `Favorite`, `Collection`, `CollectionItem`, `Recent`, `SongHistory`, `Entitlement`, `WebhookEvent`, `StationReport`), initial SQL migration (`0001_init`), and idempotent `seed.ts`.
- **Auth & Library Sync**: Firebase Admin token verification (`GET /v1/me`, `DELETE /v1/me`), LWW delta-sync (`POST /v1/sync`) with server-side `Entitlement` limit enforcement (`403 TIER_LIMIT_REACHED`), and `POST /v1/reports`.
- **Mobile Auth & Sync (`apps/mobile`)**: `FirebaseAuthRepository` (email sign-up + verification, sign-in, reset password, Google Sign-In, shared-email account linking, delete account), `ApiClient` (silent 401 token refresh + retry), `SyncRepositoryImpl` (guest-to-account merge + queued report flushing), wired auth/profile screens, and unit tests.
- **Docs & Staging**: `docs/api.md`, `render.yaml` (Render + Render Postgres staging blueprint), and `ADR-011`.


---

## Milestone 5.1 — Entitlements (Phase 5: Monetisation on Mobile)

### What I did
- Created the canonical Section 7 **Free vs Plus** feature-gate table in `packages/shared/feature-gates.json` (and synced to `apps/mobile/packages/shared/feature-gates.json`), plus typed Zod schemas and helpers in `packages/shared/src/entitlements.ts` (`FEATURE_GATE_TABLE`, `PLAN_FEATURE_GATES`, `getPlanFeatureGate`, `toPrismaEntitlementSource`, `fromPrismaEntitlementSource`).
- Implemented `EntitlementRepository` / `PrismaEntitlementRepository` (`apps/api/src/repositories/entitlement-repository.ts`) and `EntitlementService` (`apps/api/src/services/entitlement-service.ts`) with:
  - `getForIdentity`: returns the authenticated user's effective `EntitlementView` (`tier`, `status`, `source`, `adsEnabled`, `expiresAt`, `limits`, `features`) and `plans: PLAN_FEATURE_GATES`.
  - `grantPlus`: idempotent Plus grant recording the payment provider `source` (`'google_play'` or `'paystack'`), customer/subscription IDs, and `expiresAt` without regressing later expiry dates on duplicate webhook deliveries.
  - `revokePlus`: idempotent Plus revocation recording the provider `source` (`'google_play'` or `'paystack'`) and status (`'EXPIRED'` or `'CANCELLED'`) while protecting active subscriptions from a different provider.
- Registered `GET /v1/entitlements` in `apps/api/src/routes/v1/entitlements.ts` and wired `UserService` and `LibraryService` to the shared Section 7 limits (`30` favourites, `2` collections, `20` recents on Free / `200` on Plus, `10` song history entries).
- Replaced the mobile stub `EntitlementRepositoryImpl` (`apps/mobile/lib/features/subscription/data/entitlement_repository_impl.dart`) with a server-backed implementation (`GET /v1/entitlements`) that caches the latest verified entitlement in `AppDatabase` (`entitlement:current:v1`) for offline launches and supports a local 24-hour rewarded-ad convenience pass (`grantTemporaryRewardedPass`).
- Added `FeatureGate` and `PlanFeatureGates` (`apps/mobile/lib/features/subscription/domain/feature_gate.dart`) and wired `FeatureGate` across `LibraryRepositoryImpl` and all mobile ViewModels (`SubscriptionViewModel`, `LibraryViewModel`, `HomeViewModel`, `ExploreViewModel`, `SearchViewModel`, `PlayerViewModel`, `SettingsViewModel`) plus `featureGateProvider` in `apps/mobile/lib/core/di/providers.dart`.
- Added unit tests in `packages/shared/src/entitlements.test.ts`, `apps/api/src/entitlements.test.ts`, and `apps/mobile/test/entitlement_feature_gate_test.dart`.

### Why
- **Single source of truth for feature gating**: Having one table (`packages/shared/feature-gates.json`) shared by `apps/api` and `apps/mobile` prevents the backend and client UI from ever disagreeing on whether a feature is unlocked or what the Free/Plus caps are.
- **Server-side verification + idempotency**: Payment webhooks (Google Play Real-Time Developer Notifications and Paystack webhooks) are delivered *at-least-once* and can arrive out of order. Making `grantPlus` and `revokePlus` idempotent ensures duplicate deliveries never corrupt a user's entitlement or overwrite a newer expiry timestamp.

### How it works (plain English)
- **Entitlement vs Subscription**:
  - A **subscription** is a billing contract inside a payment provider (Google Play Billing on Android, Paystack on Web).
  - An **entitlement** is what your app actually cares about: *"Does this user currently have `PLUS` access, until when (`expiresAt`), and which provider (`google_play` or `paystack`) granted it?"*
- **Feature Gate flow**:
  1. `packages/shared/feature-gates.json` defines every row from Section 7 of `docs/ux-document.md` (`FREE` vs `PLUS`).
  2. On the backend, `EntitlementService.computeEntitlementView` checks whether `tier === 'PLUS'`, `status` is `'ACTIVE'` or `'GRACE'`, and `expiresAt > now`. If `expiresAt` has passed, the effective view automatically downgrades to `FREE` (`status: 'EXPIRED'`) without deleting any user library data.
  3. On mobile, `EntitlementRepositoryImpl` fetches `GET /v1/entitlements`, caches the result in SQLite (`AppDatabase`) so offline launches still know the user's status, and feeds `FeatureGate(entitlement)` into every ViewModel and `LibraryRepositoryImpl`.

### Files created or changed
- `packages/shared/feature-gates.json`
- `packages/shared/package.json`
- `packages/shared/src/entitlements.ts`
- `packages/shared/src/entitlements.test.ts`
- `packages/shared/src/index.ts`
- `apps/api/src/repositories/entitlement-repository.ts`
- `apps/api/src/services/entitlement-service.ts`
- `apps/api/src/services/user-service.ts`
- `apps/api/src/services/library-service.ts`
- `apps/api/src/routes/v1/entitlements.ts`
- `apps/api/src/server.ts`
- `apps/api/src/entitlements.test.ts`
- `apps/api/src/auth.test.ts`
- `apps/api/src/library-sync.test.ts`
- `apps/mobile/packages/shared/feature-gates.json`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/lib/core/database/app_database.dart`
- `apps/mobile/lib/core/di/providers.dart`
- `apps/mobile/lib/features/subscription/domain/entitlement.dart`
- `apps/mobile/lib/features/subscription/domain/entitlement.freezed.dart`
- `apps/mobile/lib/features/subscription/domain/entitlement_repository.dart`
- `apps/mobile/lib/features/subscription/domain/feature_gate.dart`
- `apps/mobile/lib/features/subscription/data/entitlement_repository_impl.dart`
- `apps/mobile/lib/features/library/data/library_repository_impl.dart`
- `apps/mobile/lib/features/subscription/presentation/view_models/subscription_view_model.dart`
- `apps/mobile/lib/features/library/presentation/view_models/library_view_model.dart`
- `apps/mobile/lib/features/home/presentation/view_models/home_view_model.dart`
- `apps/mobile/lib/features/explore/presentation/view_models/explore_view_model.dart`
- `apps/mobile/lib/features/search/presentation/view_models/search_view_model.dart`
- `apps/mobile/lib/features/player/presentation/view_models/player_view_model.dart`
- `apps/mobile/lib/features/profile/presentation/view_models/settings_view_model.dart`
- `apps/mobile/test/entitlement_feature_gate_test.dart`
- `apps/mobile/test/domain_models_test.dart`
- `apps/mobile/test/repositories_test.dart`
- `docs/api.md`
- `docs/build-log.md`

### How to run and verify
- TypeScript workspaces: `pnpm lint && pnpm typecheck && pnpm test && pnpm build`
- Mobile (`apps/mobile`): `dart format --output=none --set-exit-if-changed lib test integration_test && flutter analyze && flutter test`

### Concepts worth learning
- **Entitlement abstraction**: Decoupling *how someone paid* (`google_play` vs `paystack`) from *what features they get* (`FeatureGate`) lets one user sign in on Android or Web and enjoy the same Plus features without duplicating billing logic inside UI screens.
- **Idempotent state transitions**: In distributed billing systems, a webhook or client receipt verification can be sent 2–5 times. Checking whether the target state and expiry are already applied (`applied: false`) makes retries safe.
- **Graceful expiry (soft lock)**: When `expiresAt` passes, `computeEntitlementView` returns `tier: 'FREE'` and `status: 'EXPIRED'`, locking Plus-only additions while leaving all existing favourites, collections, and history intact in PostgreSQL and SQLite.

### Decisions and alternatives
- **Shared JSON table (`packages/shared/feature-gates.json`) verified by both Vitest and Flutter test**: Ensures TypeScript (`PLAN_FEATURE_GATES`) and Dart (`PlanFeatureGates`) never drift, while keeping zero runtime file-system overhead in web/mobile bundles.


---

## Milestone 5.2 — Ads (Phase 5: Monetisation on Mobile)

### What I did
- Added `google_mobile_ads: ^9.2.0` to `apps/mobile/pubspec.yaml` and configured `com.google.android.gms.ads.APPLICATION_ID` in `apps/mobile/android/app/src/main/AndroidManifest.xml` + `apps/mobile/android/app/build.gradle.kts` via `manifestPlaceholders["admobAppId"]` (`ADMOB_APP_ID` build property / environment variable, with Google's official test App ID fallback for local/debug builds).
- Created `AdConfig` (`apps/mobile/lib/core/ads/ad_config.dart`) which reads real AdMob unit IDs from `--dart-define` build variables and falls back to Google's official Android test ad unit IDs (`9214589741`, `2247696110`, `1033173712`, `5224354917`) **only** when `isDebugMode` is `true` (returning `null` in release builds if real IDs are not supplied).
- Built pure-Dart `AdPolicy` (`apps/mobile/lib/core/ads/ad_policy.dart`) enforcing all UX rules from Section 1 Principle 4 and Journey J7:
  - Nothing at all for Plus users (paid Plus or active 24h rewarded pass).
  - No ad before first sound (`hasReachedFirstSound` is recorded by `PlayerViewModel` when audio first reaches `PlaybackStatus.playing`).
  - Never on onboarding (`/splash`, `/welcome`), auth (`/auth/*`), paywall/billing (`/paywall`, `/subscription`), or player-control surfaces (`/player`, `isNearPlayerControls: true`).
  - At most 1 interstitial per 10 minutes (`interstitialCooldown = Duration(minutes: 10)`) and only on natural break triggers (`completedBrowseFlow`, `finishedCollectionEdit`, `exitedStationDetailAfterStop` — never on `appLaunch`, `firstPlay`, or `startingPlayback`).
  - Native ad cards every 8 station rows (`nativeAdInterval = 8`) in long lists (`>= 8` stations).
- Built `AdService` (`apps/mobile/lib/core/ads/ad_service.dart`) and `AdMobAdService` (`apps/mobile/lib/core/ads/admob_ad_service.dart`) running Google's **User Messaging Platform (UMP)** consent flow at launch (`runConsentFlowIfRequired` in `apps/mobile/lib/main.dart`), displaying policy-checked interstitials, and showing the optional rewarded ad (`showRewardedAdForPlusPass`) wired to `SubscriptionViewModel.watchRewardedAdForPlusPass()`.
- Added `FakeAdService` (`apps/mobile/test/helpers/fake_ad_service.dart`) and 5 thorough unit tests in `apps/mobile/test/ad_policy_test.dart`, and recorded `ADR-012` in `docs/decisions.md`.

### Why
- **Why debug builds must use test ad unit IDs**: Tapping or repeatedly loading real production AdMob ads on a developer's own phone or emulator triggers AdMob's automated invalid-traffic detection and can get a publisher account suspended before launch.
- **Why the 24-hour rewarded ad pass is client-side and expires on its own**:
  - Unlike a paid Google Play or Paystack subscription (which involves real money, recurring billing, receipts, and cross-device entitlement), watching a 15–30 second rewarded video is an ephemeral, zero-money convenience perk for price-sensitive listeners (Persona Tunde) that works even in **guest mode** without requiring sign-up.
  - Storing `rewardedPlusExpiresAt = now + 24h` in local SQLite (`AppDatabase`) means it unlocks convenience features (ad removal, custom sleep timer, advanced filters) immediately on that device and automatically expires as soon as `DateTime.now().isAfter(rewardedPlusExpiresAt)` — with zero server cron job needed and zero risk of permanently unlocking a paid account on the backend.

### How it works (plain English)
- **UMP Consent at Launch**: When the app starts, `AdMobAdService.runConsentFlowIfRequired()` asks Google's UMP SDK whether the user is in a region requiring GDPR/UK consent (EEA/UK). If required, UMP shows Google's certified consent dialog; only after `ConsentInformation.instance.canRequestAds()` returns `true` does the app initialize `MobileAds.instance`.
- **First-Sound Gate**: `AdPolicy._hasReachedFirstSound` starts `false`. Until `PlayerViewModel` transitions a stream to `PlaybackStatus.playing` and calls `adPolicy.recordFirstSound()`, every ad check (`canShowBanner`, `shouldInsertNativeAdAfterRow`, `canShowInterstitial`) returns `false`.
- **10-Minute Cooldown & Natural Breaks**: When a user finishes a browse flow or collection edit, `AdPolicy.canShowInterstitial` checks that the trigger is a natural break, the screen is not banned, the user is on Free tier, first sound has occurred, and at least 10 minutes have elapsed since `_lastInterstitialShownAt`.

### Files created or changed
- `apps/mobile/pubspec.yaml`
- `apps/mobile/android/app/build.gradle.kts`
- `apps/mobile/android/app/src/main/AndroidManifest.xml`
- `apps/mobile/lib/core/ads/ad_config.dart`
- `apps/mobile/lib/core/ads/ad_policy.dart`
- `apps/mobile/lib/core/ads/ad_service.dart`
- `apps/mobile/lib/core/ads/admob_ad_service.dart`
- `apps/mobile/lib/core/di/providers.dart`
- `apps/mobile/lib/features/player/presentation/view_models/player_view_model.dart`
- `apps/mobile/lib/features/subscription/presentation/view_models/subscription_view_model.dart`
- `apps/mobile/lib/main.dart`
- `apps/mobile/test/helpers/fake_ad_service.dart`
- `apps/mobile/test/helpers/mock_repository_overrides.dart`
- `apps/mobile/test/ad_policy_test.dart`
- `docs/decisions.md` (`ADR-012`)
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed lib test integration_test && flutter analyze && flutter test test/ad_policy_test.dart`

### Concepts worth learning
- **Ad Formats (Adaptive Banner, Native, Interstitial, Rewarded)**:
  - **Adaptive Banner**: A fixed-height strip anchored at the bottom of browse screens (never covering the mini-player).
  - **Native Ad**: Styled to match your own station list cards (`AdSlotPlaceholder` native variant) with a clear `AD` badge every 8 rows, avoiding jarring visual jumps.
  - **Interstitial**: Full-screen ad shown only between completed tasks with a strict 10-minute frequency cap so the app never feels spammy.
  - **Rewarded Ad**: Opt-in video ad where the user chooses to watch in exchange for a temporary reward (24 hours of Plus convenience features).
- **UMP (User Messaging Platform)**: Google's official IAB TCF v2.2 consent management SDK required by Google Play and AdMob for serving ads to EEA and UK users.

### Decisions and alternatives
- **Pure-Dart `AdPolicy` separated from `AdMobAdService`**: Keeps all business rules (first-sound gate, banned routes, 8-row cadence, 10-minute cooldown, Plus suppression) testable in milliseconds with an injectable clock (`DateTime Function() now`) without spinning up Android platform channels.


---

## Milestone 5.3 — Google Play Billing (Phase 5: Monetisation on Mobile)

### What I did
- Added shared billing constants and Zod schemas in `packages/shared/src/billing.ts` (`GOOGLE_PLAY_PRODUCT_IDS`: `plus_monthly`, `plus_annual`, `googlePlayVerifyPurchaseRequestSchema`, and `GOOGLE_PLAY_SUBSCRIPTION_NOTIFICATION_TYPES`).
- Implemented server-side Google Play Developer API verification in `apps/api`:
  - `HttpGooglePlayClient` (`apps/api/src/billing/google-play-client.ts`): signs RS256 JWT service-account assertions for `androidpublisher` OAuth2 tokens and queries `purchases.subscriptionsv2.get`.
  - `PrismaWebhookEventRepository` (`apps/api/src/repositories/webhook-event-repository.ts`): persists and deduplicates webhook deliveries in PostgreSQL (`webhook_events` unique `(provider, event_id)`).
  - `GooglePlayBillingService` (`apps/api/src/services/google-play-billing-service.ts`): handles `POST /v1/billing/google-play/verify` and `POST /v1/webhooks/google-play` (authenticity token verification via `timingSafeEqual`, `WebhookEvent` idempotency, and full RTDN lifecycle handling for purchase, renewal, cancellation, grace period, account hold, expiry, and refund/voided purchase).
  - Registered routes in `apps/api/src/routes/v1/billing.ts` and `apps/api/src/server.ts`, plus env vars in `apps/api/src/config/env.ts` and `apps/api/.env.example`.
  - Added recorded sample Pub/Sub & Subscriptions v2 payload tests in `apps/api/src/google-play-billing.test.ts` (all 21 API tests passing).
- Implemented mobile Google Play Billing in `apps/mobile`:
  - Added `in_app_purchase: ^3.3.1` to `apps/mobile/pubspec.yaml` and recorded `ADR-013` in `docs/decisions.md`.
  - Created `BillingService` (`apps/mobile/lib/features/subscription/domain/billing_service.dart`) and `GooglePlayBillingService` (`apps/mobile/lib/features/subscription/data/google_play_billing_service.dart`) supporting product loading (`plus_monthly`, `plus_annual`), purchase initiation (`buyNonConsumable`), server-side verification (`ApiClient.verifyGooglePlayPurchase`), purchase acknowledgement (`completePurchase`), and `restorePurchases()`.
  - Added `FakeBillingService` and `apps/mobile/test/google_play_billing_test.dart`.

### Why
- **Why server-side verification & acknowledgement matter**: Google Play automatically refunds any subscription that is not acknowledged within 3 days, and client-side purchase callbacks can be spoofed on rooted devices. Verifying the `purchaseToken` from our Node API using a Google Cloud service account before calling `completePurchase` ensures only genuine Play Store purchases unlock Plus.
- **Why Pub/Sub RTDN + `WebhookEvent` idempotency matter**: Purchases don't stay static—users cancel, cards fail (entering Google's Grace Period or Account Hold), renew monthly, or request refunds. Pub/Sub delivers Real-Time Developer Notifications *at-least-once*, so recording `messageId` in `WebhookEvent` guarantees duplicate pushes are safely ignored.

### How it works (plain English)
1. **Purchase flow**: Mobile loads `plus_monthly` and `plus_annual` from Play Store -> user completes Google Play sheet -> `GooglePlayBillingService` sends `purchaseToken` to `POST /v1/billing/google-play/verify` -> API verifies with Google Play Developer API -> API grants `PLUS` (`source: 'google_play'`) -> Mobile calls `completePurchase` to acknowledge and refreshes `EntitlementRepository`.
2. **Lifecycle webhooks**: Google Play pushes Pub/Sub messages to `POST /v1/webhooks/google-play?token=...` -> API verifies the token, checks `WebhookEvent` for `messageId`, queries `subscriptionsv2.get` for the authoritative state, and updates the user's `Entitlement` (`ACTIVE`, `GRACE`, `EXPIRED`, or `CANCELLED`).

### Files created or changed
- `packages/shared/src/billing.ts`, `packages/shared/src/index.ts`
- `apps/api/src/billing/google-play-client.ts`
- `apps/api/src/repositories/webhook-event-repository.ts`
- `apps/api/src/repositories/entitlement-repository.ts`
- `apps/api/src/services/google-play-billing-service.ts`
- `apps/api/src/routes/v1/billing.ts`
- `apps/api/src/config/env.ts`, `apps/api/.env.example`, `apps/api/src/server.ts`
- `apps/api/src/google-play-billing.test.ts`, `apps/api/src/entitlements.test.ts`
- `apps/mobile/pubspec.yaml`, `apps/mobile/lib/core/network/api_client.dart`, `apps/mobile/lib/core/di/providers.dart`
- `apps/mobile/lib/features/subscription/domain/billing_service.dart`
- `apps/mobile/lib/features/subscription/data/google_play_billing_service.dart`
- `apps/mobile/test/helpers/fake_billing_service.dart`, `apps/mobile/test/helpers/mock_repository_overrides.dart`, `apps/mobile/test/google_play_billing_test.dart`
- `docs/api.md`, `docs/decisions.md` (`ADR-013`), `docs/build-log.md`

### How to run and verify
- API (`apps/api`): `pnpm --filter @peksoft/shared build && pnpm --filter @peksoft/api lint && pnpm --filter @peksoft/api test -- --fileParallelism=false`
- Mobile (`apps/mobile`): `cd apps/mobile && dart format --output=none --set-exit-if-changed lib test integration_test && flutter analyze lib/features/subscription test/google_play_billing_test.dart && flutter test test/google_play_billing_test.dart`


---

## Milestone 5.4 — Paywall and lifecycle UI (Phase 5: Monetisation on Mobile)

### What I did
- Extended `SubscriptionViewModel` & `SubscriptionState` (`apps/mobile/lib/features/subscription/presentation/view_models/subscription_view_model.dart`) to load store-provided `StoreProduct` prices (`plus_monthly`, `plus_annual`), listen to `BillingService.purchaseUpdates`, handle `pending` / `verified` / `restored` / `canceled` / `error` states, expose `hasBillingProblem` (`EntitlementStatus.grace`) and `isExpired` (`EntitlementStatus.expired`), and build `manageSubscriptionUri` (`https://play.google.com/store/account/subscriptions?...`).
- Wired `PaywallScreen` (`apps/mobile/lib/features/subscription/presentation/paywall_screen.dart`) to `subscriptionViewModelProvider` with:
  - Store-provided local-currency pricing (`₦1,500 / mo`, `₦12,000 / yr`, etc.) and clear Google Play auto-renewal wording.
  - Purchase-pending banner, error banner, celebratory **PekSoft Plus Active** success screen, **Watch an ad: 24 hours of Plus** option, **Restore Purchases**, Terms/Privacy links, and visible Close button.
- Wired `SubscriptionManagementScreen` (`apps/mobile/lib/features/subscription/presentation/subscription_management_screen.dart`) with:
  - **Billing-problem grace banner** (`EntitlementStatus.grace`) with **Fix Payment** action.
  - **Graceful downgrade notice** (`EntitlementStatus.expired`) reassuring users that all saved favourites, collections, and song history remain safe while Plus extras lock until renewal.
  - **Manage Subscription** deep link backed by an Android `MethodChannel` (`com.peksoft.radio/links` in `MainActivity.kt`) opening Google Play's subscription management screen.
- Added widget and database tests in `apps/mobile/test/paywall_lifecycle_test.dart`.

### Why
- **Local-currency store prices**: Play Console localises prices into each listener's currency (`NGN`, `GBP`, `USD`, etc.). Reading `ProductDetails.price` directly from Google Play ensures the paywall always matches what the Google Play checkout sheet charges.
- **Graceful downgrade (soft lock)**: Deleting a user's 35 saved favourites when their subscription lapses would feel punitive. Keeping all data intact while locking new Plus-only additions encourages win-back renewals.

### Files created or changed
- `apps/mobile/lib/features/subscription/presentation/view_models/subscription_view_model.dart`
- `apps/mobile/lib/features/subscription/presentation/paywall_screen.dart`
- `apps/mobile/lib/features/subscription/presentation/subscription_management_screen.dart`
- `apps/mobile/android/app/src/main/kotlin/com/peksoft/peksoft_radio/MainActivity.kt`
- `apps/mobile/test/paywall_lifecycle_test.dart`
- `docs/build-log.md`

### How to run and verify
- `cd apps/mobile && dart format --output=none --set-exit-if-changed lib test integration_test && flutter analyze lib/features/subscription test/paywall_lifecycle_test.dart && flutter test test/paywall_lifecycle_test.dart test/account_money_screens_test.dart`


---

## Milestone 5.5 — Analytics (Phase 5: Monetisation on Mobile)

### What I did
- Defined the shared Section 11 event taxonomy in `packages/shared/src/analytics.ts` (`station_play`, `station_fail`, `favorite_add`, `paywall_view`, `purchase_success`, `first_audio_reached`, `ad_rewarded_completed`, `restore_purchases`) and `FORBIDDEN_ANALYTICS_PII_KEYS`.
- Added `firebase_analytics: ^13.1.0` and `firebase_crashlytics: ^6.1.0` to `apps/mobile/pubspec.yaml` and recorded `ADR-014` in `docs/decisions.md`.
- Implemented `AnalyticsService` (`apps/mobile/lib/core/analytics/analytics_service.dart`) and `FirebaseAnalyticsService` (`apps/mobile/lib/core/analytics/firebase_analytics_service.dart`) with:
  - Strict **consent gating** (`setConsentGranted`) wired from Google UMP at app launch in `apps/mobile/lib/main.dart`, disabling Firebase Analytics and Crashlytics collection until consent is granted/not required.
  - **PII scrubbing** (`sanitizeAnalyticsParams`) stripping email, name, displayName, uid, phone, token, password, and email-like strings before any event leaves the device.
  - Crashlytics `FlutterError.onError` and `PlatformDispatcher.instance.onError` hooks in `apps/mobile/lib/main.dart`.
- Wired Section 11 events into `PlayerViewModel` (`station_play`, `station_fail`), `LibraryViewModel` (`favorite_add`), and `SubscriptionViewModel` (`paywall_view`, `purchase_success`, `ad_rewarded_completed`).
- Added `FakeAnalyticsService` and unit tests in `apps/mobile/test/analytics_service_test.dart`.

---

## Phase 5 Summary — Ready for Review

**Branch:** `phase/5-monetisation` → `main`  
**Milestones completed:** `5.1` Entitlements · `5.2` Ads · `5.3` Google Play Billing · `5.4` Paywall & Lifecycle UI · `5.5` Analytics

Phase 5 delivers end-to-end mobile monetisation, server-verified billing, ad policy enforcement, and privacy-respecting telemetry:
- **Shared Feature Gates & Entitlements (`5.1`)**: Canonical Section 7 Free vs Plus table (`packages/shared/feature-gates.json`), `EntitlementService` + `GET /v1/entitlements` with idempotent `google_play` / `paystack` grant & revoke, and mobile `FeatureGate` + SQLite-cached `EntitlementRepositoryImpl`.
- **AdMob & UMP Consent (`5.2`)**: `google_mobile_ads` (`^9.2.0`), build-configured unit IDs with debug-only Google test IDs, launch UMP consent flow, pure-Dart `AdPolicy` (first-sound gate, banned routes, 10-minute natural-break interstitial cooldown, 8-row native card cadence, Plus suppression), and optional 24-hour rewarded ad pass.
- **Google Play Billing & RTDN Webhooks (`5.3`)**: `in_app_purchase` (`^3.3.1`) for `plus_monthly` and `plus_annual`, server-side verification via Google Play Developer API Subscriptions v2 (`POST /v1/billing/google-play/verify`), purchase acknowledgement (`completePurchase`), and idempotent Pub/Sub push webhook (`POST /v1/webhooks/google-play`) handling purchase, renewal, cancellation, grace period, account hold, expiry, and refund via `WebhookEvent`.
- **Paywall & Lifecycle UI (`5.4`)**: `PaywallScreen` wired to store-provided local-currency prices, purchase pending/success states, restore flow, and rewarded 24h pass; `SubscriptionManagementScreen` with billing-problem grace banner, Google Play `Manage Subscription` deep link, and graceful downgrade preserving user library data.
- **Analytics & Crashlytics (`5.5`)**: `AnalyticsService` / `FirebaseAnalyticsService` using the Section 11 taxonomy with PII scrubbing and UMP consent enforcement.


---

## Milestone 6.1 — Design system setup (Phase 6: Web App)

### What I did
- Created branch `phase/6-web` from `main`.
- Initialised `shadcn/ui` in `apps/web` (`components.json`, `src/lib/utils.ts`) and added all 20 base components (`button`, `card`, `badge`, `avatar`, `input`, `tabs`, `toggle-group`, `dialog`, `sheet`, `drawer`, `popover`, `dropdown-menu`, `tooltip`, `skeleton`, `sonner`, `slider`, `scroll-area`, `separator`, `switch`, plus `toggle`).
- Mapped `packages/design-tokens` (`tokens.css`) onto `shadcn/ui` CSS variables in `apps/web/src/app/globals.css` (dark by default, light supported, `--radius: 0.875rem`), loaded `Space Grotesk` and `Inter` via `next/font/google` in `apps/web/src/app/layout.tsx`, and added the `signal` button variant plus `live` and `quality` badge variants.
- Installed `motion` (`14.14.0`), `lucide-react` (`1.73.0`), and `react-use-measure` (`2.1.7`), verified the Motion Primitives catalog via `npx motion-primitives@latest list`, and added all 13 requested Motion Primitives (`text-effect`, `animated-group`, `in-view`, `infinite-slider`, `magnetic`, `border-trail`, `spotlight`, `tilt`, `animated-background`, `sliding-number`, `morphing-dialog`, `scroll-progress`, `text-shimmer`).
- Created `apps/web/src/lib/motion.ts` (durations, easings, springs, stagger tokens) and wrapped the app in `<MotionConfig reducedMotion="user">` in `apps/web/src/components/providers.tsx`.
- Built the dev-only `/dev/components` gallery (`apps/web/src/app/dev/components/page.tsx`, `components-gallery.tsx`) showcasing every restyled component and motion preset in both Dark and Light themes.

### Why
- **Why `shadcn/ui` components are code we own**: Unlike a traditional `node_modules` component library, `shadcn/ui` copies the actual TSX source into `apps/web/src/components/ui/`. We can add product-specific variants (`signal`, `live`, `quality`) or accessibility tweaks directly without fighting library overrides.
- **Why we restyle through CSS tokens instead of editing each component**: Every component references semantic CSS variables (`--background`, `--card`, `--primary`, `--border`, `--radius`) mapped to `tokens.css`. Changing a brand colour or switching between Dark and Light themes updates all 20+ components in one place with zero per-file edits.

### How to run and verify
- `pnpm --filter @peksoft/web lint && pnpm --filter @peksoft/web typecheck && pnpm --filter @peksoft/web test && pnpm --filter @peksoft/web build`
- Dev gallery: `pnpm --filter @peksoft/web dev` and open `http://localhost:3000/dev/components`


---

## Milestone 6.2 — Web UI with mock data (Phase 6: Web App)

### What I did
- Created deterministic mock data in `apps/web/src/lib/mock-data.ts` (`MOCK_COUNTRIES`, `MOCK_GENRES`, `MOCK_STATIONS`, `MOCK_COLLECTIONS`) and `MockSessionProvider` (`apps/web/src/components/mock-session-provider.tsx`) so clicking Play/Favourite on any station updates the persistent `PlayerBar`, `NowPlayingSheet`, and `Library`.
- Built product compositions in `apps/web/src/components/radio/`:
  - `StationArtwork` (station logo with deterministic initials + gradient fallback)
  - `StationRow` (artwork, `ON AIR` live badge, `"Best in the mobile app"` badge for HTTP-only streams, country flag, up to 2 genres, quality badge, heart, and play/pause `signal` button)
  - `StationCard` and `CountryCard`
  - `FilterBar` (`Working now` ON by default, `HTTPS playable`, genre pills, Popular/Trending/A–Z sort)
  - `PlanToggle` (Monthly vs Annual with `"Save 33%"` badge)
  - `PlayerBar` + `NowPlayingSheet` (persistent bottom player bar opening the full player `Sheet` with volume slider, sleep timer, share, and report actions)
  - `AppShell` (desktop left sidebar collapsing to a mobile bottom nav, sticky top search bar, Dark/Light theme toggle, and persistent `PlayerBar`)
- Built all 10 routes with mock data: `/` (marketing landing), `/home`, `/explore`, `/country/[code]`, `/genre/[slug]`, `/station/[slug]`, `/library`, `/pricing`, `/account`, and `/auth`.

### How to run and verify
- `pnpm --filter @peksoft/web lint && pnpm --filter @peksoft/web typecheck && pnpm --filter @peksoft/web test && pnpm --filter @peksoft/web build`


---

## Milestone 6.3 — Motion pass (Phase 6: Web App)

### What I did
- Created `apps/web/src/app/template.tsx` for subtle `120ms` transform+opacity route transitions.
- Created `apps/web/src/components/radio/lazy-effects.tsx` using `next/dynamic(..., { ssr: false })` to lazy-load `InfiniteSlider`, `Tilt`, `Spotlight`, and `BorderTrail` without blocking SSR or LCP.
- Applied Motion Primitives across `/`, `/home`, `/explore`, and `/pricing`:
  - `TextEffect` on the landing hero headline, `Magnetic` + `BorderTrail` on the primary CTA, `InfiniteSlider` flag/station marquee inside a fixed `h-11` slot (zero CLS).
  - `Tilt` + `Spotlight` on genre/collection/hero cards.
  - `AnimatedBackground` on `PlanToggle` and `FilterBar` sort pills.
  - `SlidingNumber` on landing station count and Pricing `₦12,000` / `₦1,500` toggle.
  - `InView` + `AnimatedGroup` staggered reveals and `ScrollProgress` on long pages.
- Documented motion rules and observed `next build` bundle measurements (`1,589 KB` total split client chunks) in `docs/motion-report.md`.

### How to run and verify
- `pnpm --filter @peksoft/web lint && pnpm --filter @peksoft/web typecheck && pnpm --filter @peksoft/web test && pnpm --filter @peksoft/web build`


---

## Phase 7 — Hardening and Launch

### Milestone 7.1 — Accessibility and Performance (2026-11-19)

#### What I did
- Audited all key Flutter mobile screens (`HomeScreen`, `ExploreScreen`, `WorldRadioMapTab`, `NowPlayingScreen`, `SplashScreen`, `WelcomeScreen`, `ProfileScreen`, `StationLogo`, `GenreChip`) for TalkBack semantics, 48dp touch targets, WCAG AA contrast (dark & light), and 2.0x text scaling.
- Fixed every critical/high accessibility issue found: added Play/Pause and Details semantics on map station cards, raised map pins and zoom/refresh controls to 48x48dp, added selection semantics and visible checkmarks on onboarding genre cards, replaced the tiny email-verify `GestureDetector` with a 48dp `TextButton`, made the light-mode splash logo high-contrast, darkened light-mode status tokens (`success`, `warning`, `info`) to >= 4.5:1, switched `GenreChip` selected text to `colors.accentText`, scoped `_PlaybackStatusBanner` `liveRegion` to status text only, and made shelf/grid heights scale cleanly up to 2.0x text scaling.
- Configured Flutter's bounded LRU `ImageCache` (250 images / 64 MB) in `main.dart` and added DPR-aware `cacheWidth`/`cacheHeight` decoding in `StationLogo`.
- Audited Next.js web accessibility and production bundle/caching: added a keyboard-accessible `Skip to main content` link and `#main-content` landmark in `AppShell`, enabled `compress: true`, `poweredByHeader: false`, `images.formats: ['image/avif', 'image/webp']`, `experimental.optimizePackageImports: ['lucide-react', 'motion']`, and 1-year `immutable` `Cache-Control` headers for `/images/*` in `next.config.ts`.
- Recorded all Before and After measurements in `docs/performance-accessibility-audit.md` and added an automated 2.0x text-scale widget test in `apps/mobile/test/polish_accessibility_test.dart`.

#### Why
- Hardening accessibility (TalkBack, keyboard bypass, 48dp targets, WCAG AA contrast, 2.0x font scaling) ensures the app is usable by everyone and avoids Play Store accessibility warnings.
- Bounding decoded image memory (`ImageCache` + `cacheWidth`/`cacheHeight`) and enabling AVIF/WebP + immutable image caching keeps scrolling smooth on low-RAM Android devices and improves web Lighthouse/LCP scores.

#### How it works (plain English)
- On mobile, every interactive icon/pin now exposes a 48x48dp tap area and clear TalkBack label, while `StationLogo` decodes images at the exact pixel size needed for the screen rather than full raw resolution.
- On web, keyboard users can press Tab once to jump straight past the sidebar/header to the main content, and browsers cache static genre/brand images locally for a full year.

#### Files created or changed
- `docs/performance-accessibility-audit.md` (new)
- `docs/build-log.md` (updated)
- `apps/mobile/lib/main.dart`
- `apps/mobile/lib/core/theme/design_tokens.dart`
- `apps/mobile/lib/core/widgets/genre_chip.dart`
- `apps/mobile/lib/core/widgets/peksoft_signal_loader.dart`
- `apps/mobile/lib/core/widgets/station_logo.dart`
- `apps/mobile/lib/features/explore/presentation/world_radio_map_tab.dart`
- `apps/mobile/lib/features/home/presentation/home_screen.dart`
- `apps/mobile/lib/features/onboarding/presentation/welcome_screen.dart`
- `apps/mobile/lib/features/player/presentation/now_playing_screen.dart`
- `apps/mobile/lib/features/profile/presentation/profile_screen.dart`
- `apps/mobile/test/polish_accessibility_test.dart`
- `apps/mobile/test/goldens/*.png`
- `apps/web/next.config.ts`
- `apps/web/src/components/radio/app-shell.tsx`

#### How to run and verify
- Mobile: `cd apps/mobile && flutter analyze && flutter test`
- Web: `pnpm --filter @peksoft/web lint && pnpm --filter @peksoft/web test && pnpm --filter @peksoft/web build`

#### Concepts worth learning
- **`cacheWidth` / `cacheHeight` in Flutter**: Telling Flutter's image decoder the exact pixel size (`logicalSize * devicePixelRatio`) avoids decoding a 1200x1200 JPEG into a 5.7 MB uncompressed RGBA bitmap just to render a 56dp thumbnail.
- **`Semantics(excludeSemantics: true)`**: When you wrap a card in a custom accessible label, `excludeSemantics: true` prevents TalkBack from reading both your summary label and every child `Text` node twice.
- **Immutable `Cache-Control` headers**: `public, max-age=31536000, immutable` lets browsers and CDNs reuse static assets without revalidation round-trips.

#### Decisions and alternatives
- Kept `flutter_map` + OpenStreetMap tiles (zero API keys) and enlarged marker hit targets to 48x48dp rather than switching to a paid map SDK.
- Used Next.js built-in `optimizePackageImports` and `Cache-Control` headers rather than adding extra bundler plugins, keeping the build pipeline simple and fast.


### Milestone 7.2 — Security Review (2026-11-19)

#### What I did
- Walked through all 10 categories of the **OWASP API Security Top 10 (2023)** against `apps/api` and documented the full assessment, fixes, and operational guidance in `docs/security-review.md`.
- Hardened `apps/api/src/server.ts`: added baseline HTTP security headers (`X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Permissions-Policy`, `X-Permitted-Cross-Domain-Policies: none`, and `Strict-Transport-Security` in production), bounded JSON payload size (`bodyLimit: 256 KiB`), disabled Swagger UI (`/docs`) by default when `NODE_ENV === 'production'`, and blocked wildcard `CORS_ORIGINS=*` in production when credentials are enabled.
- Tightened `POST /v1/reports` rate limiting to `15 req/min` (`apps/api/src/routes/v1/reports.ts`), expanded PII/secret redaction in `apps/api/src/plugins/logger.ts` (`x-paystack-signature`, `x-goog-pubsub-token`, `purchaseToken`, `secretKey`, `privateKey`), and enforced exact `packageName` matching in `GooglePlayBillingService.verifyPurchase`.
- Ran `pnpm audit --prod`, `flutter pub outdated --no-dev-dependencies`, and a repository secrets scan; verified Paystack HMAC-SHA512 and Google Play Pub/Sub constant-time webhook signature verification and Firebase revocation checks.
- Added automated security-header and production CORS tests in `apps/api/src/server.test.ts`.

#### Why
- Hardening HTTP headers, payload limits, public endpoint rate limits, package-name binding, and production CORS/Swagger defaults closes the most common OWASP API misconfigurations before public launch.

#### How it works (plain English)
- Every API response now includes security headers that tell browsers not to MIME-sniff, embed the API in iframes, or leak referrers.
- In production, the API refuses to start with wildcard CORS (`*`) alongside cookies/auth headers, hides `/docs`, caps request bodies at 256 KiB, and strictly rejects Google Play purchase tokens submitted for any package other than `com.peksoft.radio`.

#### Files created or changed
- `docs/security-review.md` (new)
- `docs/build-log.md` (updated)
- `apps/api/src/server.ts`
- `apps/api/src/plugins/logger.ts`
- `apps/api/src/routes/v1/reports.ts`
- `apps/api/src/services/google-play-billing-service.ts`
- `apps/api/src/server.test.ts`

#### How to run and verify
- `pnpm --filter @peksoft/api lint && pnpm --filter @peksoft/api test`
- `pnpm audit --prod`
- `cd apps/mobile && flutter pub outdated --no-dev-dependencies`

#### Concepts worth learning
- **Constant-time comparison (`crypto.timingSafeEqual`)**: Comparing HMAC signatures or webhook tokens with `===` leaks how many leading bytes matched via microsecond timing differences; `timingSafeEqual` takes constant time regardless of where a mismatch occurs.
- **CORS wildcard + `credentials: true` (OWASP API8)**: Reflecting arbitrary `Origin` headers while allowing credentials lets any malicious site make authenticated cross-origin requests from a logged-in user's browser.
- **`checkRevoked: true` in Firebase Admin**: Ensures that if a user signs out everywhere or has their account disabled, their still-unexpired JWT is rejected immediately.

#### Decisions and alternatives
- Added baseline security headers directly via a zero-dependency Fastify `onSend` hook rather than introducing `@fastify/helmet`, avoiding an unapproved new dependency while enforcing the exact headers needed for a JSON API.
- Documented the 3 transitive `apps/web` advisories (`@grpc/grpc-js` from Firebase Firestore and `minimatch` from `shadcn`) in `docs/security-review.md` with clear remediation steps rather than mutating lockfiles without approval.


### Milestone 7.3 — Observability (2026-11-19)

#### What I did
- Verified mobile **Firebase Crashlytics** wiring in `apps/mobile/lib/main.dart` and `apps/mobile/lib/core/analytics/firebase_analytics_service.dart` (consent-gated, PII-stripped).
- Added **Sentry** error reporting on the API (`apps/api/src/plugins/sentry.ts`, wired into `apps/api/src/plugins/error-handler.ts` and `apps/api/src/server.ts`) and Web (`apps/web/src/lib/sentry.ts` + `apps/web/src/app/global-error.tsx`), stripping query strings and personal data before dispatch and acting as a safe no-op when `SENTRY_DSN` / `NEXT_PUBLIC_SENTRY_DSN` is unset.
- Added a readiness probe `GET /health/ready` (`apps/api/src/routes/health.ts`) reporting process status, memory RSS, uptime, and database probe status for uptime monitors (UptimeRobot / BetterStack / Cloud Run).
- Built the Section 11 **Observability & KPI Dashboard** page at `/status` (`apps/web/src/app/status/page.tsx`) showing live `/health/ready` checks alongside all 8 Section 11 KPI targets.
- Documented the complete observability runbook in `docs/observability.md` and added unit tests for `/health/ready` and PII-free Sentry reporting in `apps/api/src/server.test.ts`.

#### Why
- Production apps need fast detection of crashes, unhandled 500s, and downtime without leaking listener PII (emails, tokens, IPs), plus a single place to track the product KPIs defined in Section 11.

#### How it works (plain English)
- When an unhandled 500 happens on the API or a React crash hits the web app, our Sentry reporter strips query strings/PII and posts a structured JSON error report directly to your Sentry DSN.
- External uptime monitors ping `/health/ready` every 60 seconds; if the database probe fails, it returns `503 Service Unavailable` so alerts fire immediately.

#### Files created or changed
- `docs/observability.md` (new)
- `docs/build-log.md` (updated)
- `apps/api/src/plugins/sentry.ts` (new)
- `apps/api/src/config/env.ts`, `apps/api/.env.example`
- `apps/api/src/plugins/error-handler.ts`, `apps/api/src/routes/health.ts`, `apps/api/src/server.ts`, `apps/api/src/server.test.ts`
- `apps/web/src/lib/sentry.ts` (new), `apps/web/src/app/global-error.tsx` (new), `apps/web/src/app/status/page.tsx` (new), `apps/web/.env.example`

#### How to run and verify
- API: `pnpm --filter @peksoft/api lint && pnpm --filter @peksoft/api test`
- Web: `pnpm --filter @peksoft/web lint && pnpm --filter @peksoft/web test`
- Visit `/status` on the web app to view live readiness & Section 11 KPIs.

#### Concepts worth learning
- **Liveness (`/health`) vs. Readiness (`/health/ready`)**: Liveness tells an orchestrator "is the process alive?"; readiness tells load balancers and uptime monitors "can this instance safely serve traffic (e.g., is the database reachable)?".
- **Zero-dependency Sentry Store API**: Sentry's HTTP Store endpoint accepts standard JSON error payloads signed with `X-Sentry-Auth`, letting you add PII-free crash reporting without heavy SDK bundle overhead.

#### Decisions and alternatives
- Implemented lightweight, zero-dependency Sentry Store API reporters for API and Web (consistent with `AGENTS.md` rule 4 not to add unapproved dependencies), while keeping the interface compatible with dropping in `@sentry/node` / `@sentry/nextjs` later if distributed tracing is desired.


### Milestone 7.4 — Legal and Store Assets (2026-11-19)

#### What I did
- Created lawyer-review legal templates and public compliance pages on the web app:
  - `/privacy` (`apps/web/src/app/privacy/page.tsx`) — Privacy Policy template covering guest-first local storage, Firebase Auth, Google Play Billing & Paystack, consent-gated AdMob/AdSense & Crashlytics/Sentry, and Radio Browser attribution.
  - `/terms` (`apps/web/src/app/terms/page.tsx`) — Terms of Service template covering third-party radio stream disclaimer, Plus subscription terms, and acceptable use.
  - `/delete-account` (`apps/web/src/app/delete-account/page.tsx`) — Public account & data deletion page required by Google Play Data Safety policy.
- Linked `/privacy`, `/terms`, `/delete-account`, and `/status` in the global web footer (`apps/web/src/components/radio/app-shell.tsx`), alongside the existing cookie/ad consent banner (`ad-consent-provider.tsx`).
- Wrote `docs/store-assets.md` with draft answers for the **Google Play Data Safety form**, **IARC content-rating questionnaire**, **Google Play store listing copy** (title, 78-char short description, full description, category, tags), and a 6-screen **screenshot plan**.
- Created a crisp `1024×500` brand **Feature Graphic** (`docs/store-assets/feature-graphic-1024x500.svg`) using the exact PekSoft logo geometry and flat Material 3 brand palette (`#0B0E17`, `#131826`, `#8A2BE2`, `#FFB020`, `#10B981`).

#### Why
- Google Play rejects app submissions that lack a live Privacy Policy URL, a public web Account Deletion URL (for apps offering account creation), accurate Data Safety declarations, and a `1024×500` feature graphic.

#### How it works (plain English)
- Anyone — including Google Play reviewers — can open `/privacy`, `/terms`, and `/delete-account` directly from the web footer without signing in.
- The feature graphic SVG is exact `1024×500` and ready to export directly to PNG for Play Console upload.

#### Files created or changed
- `apps/web/src/app/privacy/page.tsx` (new)
- `apps/web/src/app/terms/page.tsx` (new)
- `apps/web/src/app/delete-account/page.tsx` (new)
- `apps/web/src/components/radio/app-shell.tsx` (updated footer links)
- `docs/store-assets.md` (new)
- `docs/store-assets/feature-graphic-1024x500.svg` (new)
- `docs/build-log.md` (updated)

#### How to run and verify
- `pnpm --filter @peksoft/web lint && pnpm --filter @peksoft/web test`
- Visit `/privacy`, `/terms`, and `/delete-account` in the web app.

#### Concepts worth learning
- **Google Play Account Deletion Policy**: Any app that lets users create an account must provide BOTH an in-app deletion path AND a public web URL where users can request deletion even after uninstalling the app.
- **IARC Rating for Live Radio**: Even when your app has no violent or adult UI, streaming unmoderated third-party live broadcasts typically places the app in Teen / PEGI 12.

#### Decisions and alternatives
- Authored the `1024×500` feature graphic as an exact vector SVG (`docs/store-assets/feature-graphic-1024x500.svg`) using the exact PekSoft logo paths and tokens so there is zero typography distortion or unwanted glow/glassmorphism when exporting to PNG for Play Console.
