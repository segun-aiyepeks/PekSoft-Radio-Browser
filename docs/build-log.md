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
