# Phase 1 Mobile UI Walkthrough

Every mobile screen in **PekSoft Radio Browser** (Phase 1: UI with mock data) is listed below with its `go_router` route, file path, and how to reach it interactively in the app.

---

## 1. Onboarding

| Screen | Route | How to reach | Source |
| :--- | :--- | :--- | :--- |
| **Splash** | `/splash` | **Profile** tab → **Replay Welcome & Splash** | `apps/mobile/lib/features/onboarding/presentation/splash_screen.dart` |
| **Welcome** | `/welcome` | From `/splash` → tap **Get Started** (includes country picker, optional taste chips, and visible **Skip**) | `apps/mobile/lib/features/onboarding/presentation/welcome_screen.dart` |

---

## 2. Main 4-Tab Shell (`StatefulShellRoute`)

The bottom navigation bar and persistent `MiniPlayerSlot` remain visible across all 4 tabs, with `OfflineBanner` appearing at the top when offline simulation is enabled.

| Screen | Route | How to reach | Source |
| :--- | :--- | :--- | :--- |
| **Home** | `/home` | App launch default / **Home** tab (search bar, genre chips, curated collections, ad slot, working stations) | `apps/mobile/lib/features/home/presentation/home_screen.dart` |
| **Explore** | `/explore` | **Explore** tab (`Countries`, `Genres`, `Languages`, `Map` placeholder tabs) | `apps/mobile/lib/features/explore/presentation/explore_screen.dart` |
| **Library** | `/library` | **Library** tab (`Favourites`, `Recents`, `Collections`, `Song History`, free-tier limit prompts) | `apps/mobile/lib/features/library/presentation/library_screen.dart` |
| **Profile** | `/profile` | **Profile** tab (guest/signed-in card, Pro card, Settings, Subscription, About & Legal, Offline toggle, Theme toggle) | `apps/mobile/lib/features/profile/presentation/profile_screen.dart` |

---

## 3. Discovery & Station Details

| Screen / Sheet | Route | How to reach | Source |
| :--- | :--- | :--- | :--- |
| **Search** | `/search` | **Home** search bar or top-right Search icon on **Home** / **Explore** (supports empty, typing, results, and no-results states) | `apps/mobile/lib/features/search/presentation/search_screen.dart` |
| **Filters Bottom Sheet** | Modal sheet | Top-right **Filters** icon on **Home** or **Search** (`Working now` ON by default, sort, genre, language, codec, bitrate) | `apps/mobile/lib/features/search/presentation/filters_bottom_sheet.dart` |
| **Country Detail** | `/country/:code` | **Explore → Countries** tab → tap any country (or **Map** hub chip) | `apps/mobile/lib/features/explore/presentation/country_detail_screen.dart` |
| **Genre Detail** | `/genre/:name` | **Explore → Genres** tab → tap any genre (or tap a genre chip on **Search** / **Station Detail**) | `apps/mobile/lib/features/explore/presentation/genre_detail_screen.dart` |
| **Station Detail** | `/station/:id` | Tap any `StationTile` across **Home**, **Search**, **Country**, **Genre**, **Library**, or **Now Playing → Details** | `apps/mobile/lib/features/station/presentation/station_detail_screen.dart` |

---

## 4. Player & Playback States

| Screen / Sheet | Route | How to reach | Source |
| :--- | :--- | :--- | :--- |
| **Mini-Player** | Persistent slot | Docked above the bottom navigation bar across all 4 tabs | `apps/mobile/lib/features/player/presentation/mini_player_slot.dart` |
| **Now Playing** | `/player` | Tap the persistent **Mini-Player** (includes artwork, track title, `QualityBadge`, play/pause, favourite, share, similar stations, and **Dev State Switcher** in debug mode for `idle`, `playing`, `paused`, `buffering`, `reconnecting`, `unavailable`) | `apps/mobile/lib/features/player/presentation/now_playing_screen.dart` |
| **Sleep Timer Sheet** | Modal sheet | **Now Playing** → tap the Moon (**Sleep Timer**) button | `apps/mobile/lib/features/player/presentation/sleep_timer_sheet.dart` |
| **Report Station Sheet** | Modal sheet | **Now Playing** → tap **Report** (or **Report broken** in unavailable state) | `apps/mobile/lib/features/player/presentation/report_station_sheet.dart` |

---

## 5. Account, Monetization & Legal

| Screen | Route | How to reach | Source |
| :--- | :--- | :--- | :--- |
| **Auth Landing** | `/auth` | **Profile** → **Sign In or Create Account** (Google, Email, Create Account, Guest skip) | `apps/mobile/lib/features/auth/presentation/auth_landing_screen.dart` |
| **Sign In** | `/auth/sign-in` | **Auth Landing** → **Sign in with Email** | `apps/mobile/lib/features/auth/presentation/sign_in_screen.dart` |
| **Sign Up** | `/auth/sign-up` | **Auth Landing** → **Create an account** | `apps/mobile/lib/features/auth/presentation/sign_up_screen.dart` |
| **Verify Email** | `/auth/verify-email` | **Sign Up** → submit valid form | `apps/mobile/lib/features/auth/presentation/verify_email_screen.dart` |
| **Forgot Password** | `/auth/forgot-password` | **Sign In** → **Forgot password?** | `apps/mobile/lib/features/auth/presentation/forgot_password_screen.dart` |
| **Reset Password** | `/auth/reset-password` | **Forgot Password** → submit valid email | `apps/mobile/lib/features/auth/presentation/reset_password_screen.dart` |
| **Paywall** | `/paywall` | **Library** → **Go Pro** prompt, or **Profile** → **Upgrade to PekSoft Pro** | `apps/mobile/lib/features/subscription/presentation/paywall_screen.dart` |
| **Subscription Management** | `/subscription` | **Profile** → **Subscription Management** (or **PekSoft Pro Active**) | `apps/mobile/lib/features/subscription/presentation/subscription_management_screen.dart` |
| **Settings** | `/settings` | **Profile** → **Settings** (Data Saver, Sleep-timer default, Theme, Language, Notifications) | `apps/mobile/lib/features/profile/presentation/settings_screen.dart` |
| **Delete Account** | `/delete-account` | **Profile → Settings** → **Delete Account** | `apps/mobile/lib/features/profile/presentation/delete_account_screen.dart` |
| **About & Legal** | `/about` | **Profile** → **About & Legal**, or **Paywall** → **Terms** / **Privacy** (includes *Station data by Radio Browser*) | `apps/mobile/lib/features/profile/presentation/about_legal_screen.dart` |

---

## 6. Developer-Only Tools (`kDebugMode`)

| Screen | Route | How to reach | Source |
| :--- | :--- | :--- | :--- |
| **Component Gallery** | `/gallery` | Top-right widgets icon on **Home**, or **Profile → Component Gallery (Dev)** | `apps/mobile/lib/features/dev_gallery/presentation/component_gallery_screen.dart` |
| **Offline Banner Preview** | Shell-wide | **Profile** → toggle **Simulate Offline Banner** | `apps/mobile/lib/core/widgets/offline_banner.dart` |
