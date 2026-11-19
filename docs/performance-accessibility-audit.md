# Milestone 7.1 — Accessibility & Performance Audit (Before & After)

Date: 2026-11-19  
Branch: `phase/7-launch`

---

## 1. Mobile Accessibility Audit (Flutter — TalkBack, Text Scale, Contrast, Touch Targets)

Audited `HomeScreen`, `ExploreScreen`, `WorldRadioMapTab`, `NowPlayingScreen`, `SplashScreen`, `WelcomeScreen`, `ProfileScreen`, `StationLogo`, `GenreChip`, and `AppTheme` against WCAG 2.1 AA, Material 3, and Android TalkBack guidelines.

| # | Area | Before | Fix Applied | After |
|---|---|---|---|---|
| 1 | Map Station Card Play/Pause (`world_radio_map_tab.dart`) | Unlabeled `FilledButton` with icon only (TalkBack read `"Button"`). | Wrapped in `Semantics(button: true, toggled: isPlaying, label: 'Play/Pause <station>', excludeSemantics: true)` + `Open details` semantics on card body. | Descriptive TalkBack announcement & state. |
| 2 | Map Pins & Zoom Controls (`world_radio_map_tab.dart`) | `Marker` was `24x24`/`34x34`; `_MapControlButton` was `40x40` (below 48dp). | Raised `Marker` hit box to `48x48` (`HitTestBehavior.opaque`, `selected` & playing state in `Semantics`) and `_MapControlButton` to `48x48` (`AppSpacing.touchTarget`). | 100% 48dp touch targets. |
| 3 | Onboarding Genre Cards (`welcome_screen.dart`) | No `selected` semantics; color-only border change; `childAspectRatio: 1.7` clipped at 2.0x scale. | Added `Semantics(button: true, selected: selected)`, visible checkmark badge when selected, `excludeFromSemantics: true` on decorative images, and text-scale-aware `mainAxisExtent`. | Accessible to TalkBack, colorblind users, and 2.0x text scale. |
| 4 | Profile Email Verify Link & Buttons (`profile_screen.dart`) | Bare `GestureDetector` (~14dp height, `colors.accent` 2.97:1 dark contrast); rigid `SizedBox(height: 48)` buttons. | Replaced with `TextButton` (`48x48` minimumSize, `colors.accentText` > 6.5:1 contrast) and `ConstrainedBox(minHeight: 48)` on action buttons. | Passes 48dp, WCAG AA, and 2.0x text scale. |
| 5 | Splash Logo in Light Mode (`peksoft_signal_loader.dart`) | Hardcoded `#F4F6FB` `'P'` mark on `#F6F7FB` light background (1.01:1 invisible). | Made `_PekSoftSignalPainter` theme-aware (`colors.textPrimary` stem + `#D97706` signal in light mode when `showBackground: false`). | High-contrast logo in both light and dark themes. |
| 6 | Light-Mode Status Banner & Dark-Mode `GenreChip` (`design_tokens.dart`, `genre_chip.dart`) | Light `success` (3.77:1), `warning` (3.19:1), `info` (4.10:1) and dark selected `GenreChip` (~3.0:1) failed 4.5:1. | Tuned light semantic tokens (`#047857`, `#B45309`, `#0369A1`) and switched `GenreChip` selected text to `colors.accentText`. | All pass WCAG AA >= 4.5:1. |
| 7 | `NowPlayingScreen` Status Banner Live Region (`now_playing_screen.dart`) | `Semantics(liveRegion: true)` wrapped interactive `Retry` / `Report broken` buttons; rigid `SizedBox(height: 48)` buttons. | Scoped `liveRegion: true` to status text row only; switched buttons to `ConstrainedBox(minHeight: 48)`. | Clean TalkBack announcements without focus theft. |
| 8 | 2.0x Text Scaling & Duplicate Announcements (`home_screen.dart`, `station_logo.dart`) | Fixed `SizedBox(height: 204)` on horizontal station shelves; duplicate TalkBack focus on `StationLogo` inside cards. | Scaled shelf height with `MediaQuery.textScalerOf(context)`; added `excludeSemantics: true` on station cards and `excludeFromSemantics` option on `StationLogo`. | Zero overflow across all 8 key screens at 2.0x text scale. |

---

## 2. Mobile Performance Measurements (Before vs. After)

| Metric | Before | After | Notes |
|---|---|---|---|
| **Cold start & shell boot** (`performance_profile_test.dart`) | Pass (< 15s budget) | Pass (< 15s budget) | Verified in automated cold-start profile test. |
| **Lazy list scrolling (120 stations)** | Pass (< 25 viewport items materialized; smooth fling) | Pass (< 25 viewport items materialized; smooth fling) | Horizontal `ListView.separated` + `SliverList.builder` materialize only visible cards. |
| **Image caching & decode memory** (`main.dart`, `station_logo.dart`) | Unbounded default `ImageCache`; full-resolution image decode for 48px–124px thumbnails | Bounded `ImageCache` (`maximumSize = 250`, `maximumSizeBytes = 64 MB`) + `cacheWidth`/`cacheHeight` clamped to `48..512` px using `devicePixelRatio` | Prevents OOM spikes and reduces raster jank on fast scrolling. |
| **Automated a11y + 2.0x text-scale suite** (`polish_accessibility_test.dart`) | 2 tests (1.3x dark/light + landscape/tablet) | 3 tests (added 2.0x text scale across all 8 key screens) — **All passed** | Covers `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`, landscape, tablet, and 2.0x text scaling. |

---

## 3. Web Accessibility & Performance Audit (Before vs. After)

| Metric / Check | Before | After | Notes |
|---|---|---|---|
| **Keyboard navigation & skip link** (`app-shell.tsx`) | No skip-to-content link; `<main>` lacked `id`/`tabIndex`. | Added visually-hidden focusable `Skip to main content` link targeting `<main id="main-content" tabIndex={-1}>`. | Matches WCAG 2.1 Bypass Blocks (2.4.1) & axe landmark rules. |
| **Production build (`next build`)** | Compiled in 2.7 min (TypeScript 29.2s, 18 static pages in 9.1s) | Compiled in **55s** (TypeScript **7.1s**, 18 static pages in **5.8s**) | Added `experimental.optimizePackageImports: ['lucide-react', 'motion']`. |
| **Static JS chunks (`.next/static/chunks`)** | 42 files, **2,285.7 KB** total uncompressed (largest chunk `567.1 KB`) | 42 files, **2,286.1 KB** total uncompressed (largest chunk `567.1 KB`); gzip enabled via `compress: true` | `poweredByHeader: false` also removes unnecessary response header. |
| **Image caching & modern formats** (`next.config.ts`) | Default Next.js image config; no `Cache-Control` header for `/images/*` | `images.formats: ['image/avif', 'image/webp']`, `minimumCacheTTL: 86400`, and `Cache-Control: public, max-age=31536000, immutable` on `/images/:path*` | Eliminates repeat image fetches & improves Lighthouse Caching/LCP score. |
| **Web Lint & Unit Tests** | `tsc --noEmit` 0 errors; 23/23 Vitest tests passed | `tsc --noEmit` 0 errors; 23/23 Vitest tests passed | Zero regressions. |
