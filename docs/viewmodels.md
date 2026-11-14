# Mobile ViewModels (Phase 2 — MVVM + Riverpod)

Every Phase 1 screen is backed by a dedicated Riverpod `Notifier` or `AsyncNotifier` with an immutable `@immutable` state class and explicit event methods. In Phase 2, no Phase 1 UI was modified or wired up; Phase 3 will connect these providers to the screens.

Shared dependency injection providers live in `apps/mobile/lib/core/di/providers.dart`.

---

## Screen-to-ViewModel Mapping

| Screen / Sheet | Route | ViewModel & Provider | State Class |
| :--- | :--- | :--- | :--- |
| **Splash** | `/splash` | `SplashViewModel` (`splashViewModelProvider`) | `SplashState` |
| **Welcome** | `/welcome` | `WelcomeViewModel` (`welcomeViewModelProvider`) | `WelcomeState` |
| **Home** | `/home` | `HomeViewModel` (`homeViewModelProvider`) | `HomeState` |
| **Explore** | `/explore` | `ExploreViewModel` (`exploreViewModelProvider`) | `ExploreState` |
| **Country Detail** | `/country/:code` | `CountryDetailViewModel` (`countryDetailViewModelProvider(code)`) | `CountryDetailState` |
| **Genre Detail** | `/genre/:id` | `GenreDetailViewModel` (`genreDetailViewModelProvider(id)`) | `GenreDetailState` |
| **Search & Filters Sheet** | `/search` | `SearchViewModel` (`searchViewModelProvider`) | `SearchState` |
| **Station Detail** | `/station/:id` | `StationDetailViewModel` (`stationDetailViewModelProvider(id)`) | `StationDetailState` |
| **Mini-Player, Now Playing, Sleep Timer, Report Sheet** | `/player` + shell slot | `PlayerViewModel` (`playerViewModelProvider`) | `PlayerState` |
| **Library** | `/library` | `LibraryViewModel` (`libraryViewModelProvider`) | `LibraryState` |
| **Auth Landing, Sign In, Sign Up, Verify Email, Forgot & Reset Password** | `/auth/*` | `AuthViewModel` (`authViewModelProvider`) | `AuthState` |
| **Paywall & Subscription Management** | `/paywall`, `/subscription` | `SubscriptionViewModel` (`subscriptionViewModelProvider`) | `SubscriptionState` |
| **Profile, Settings, Delete Account, About & Legal, Offline Banner** | `/profile`, `/settings`, `/delete-account`, `/about` | `SettingsViewModel` (`settingsViewModelProvider`) | `SettingsState` |

---

## Detailed State Fields & Events

### 1. `SplashViewModel` (`AsyncNotifier<SplashState>`)
- **Maps to:** `SplashScreen` (`/splash`) — reads persisted `UserSettings` on launch and determines whether to route to `/home` or `/welcome`.
- **State (`SplashState`):** `isInitialized`, `hasHomeCountry`, `destinationRoute`
- **Events:** `initialize()`

### 2. `WelcomeViewModel` (`Notifier<WelcomeState>`)
- **Maps to:** `WelcomeScreen` (`/welcome`) — manages country picker selection, optional genre taste chips, saving onboarding choices, or skipping.
- **State (`WelcomeState`):** `selectedCountryCode`, `selectedGenreIds`, `isSubmitting`, `completed`, `error`
- **Events:** `selectCountry(countryCode)`, `toggleGenre(genreId)`, `completeOnboarding()`, `skip()`

### 3. `HomeViewModel` (`AsyncNotifier<HomeState>`)
- **Maps to:** `HomeScreen` (`/home`) — loads canonical genre chips, curated collections, active entitlement (for `AdSlotPlaceholder` visibility), and working stations.
- **State (`HomeState`):** `genres`, `curatedCollections`, `stations`, `selectedGenreId`, `entitlement`, `error`
- **Events:** `refresh()`, `selectGenre(genreId)`

### 4. `ExploreViewModel` (`AsyncNotifier<ExploreState>`)
- **Maps to:** `ExploreScreen` (`/explore`) — drives the `Countries`, `Genres`, `Languages`, and `Map` tabs.
- **State (`ExploreState`):** `activeTabIndex`, `countries`, `genres`, `languages`, `error`
- **Events:** `selectTab(index)`, `refresh()`

### 5. `CountryDetailViewModel` (`AsyncNotifier<CountryDetailState>` family)
- **Maps to:** `CountryDetailScreen` (`/country/:code`) — loads normalised stations for a country with sort and working-now filter controls.
- **State (`CountryDetailState`):** `countryCode`, `stations`, `sort`, `workingNowOnly`, `error`
- **Events:** `setSort(sort)`, `toggleWorkingNow()`, `refresh()`

### 6. `GenreDetailViewModel` (`AsyncNotifier<GenreDetailState>` family)
- **Maps to:** `GenreDetailScreen` (`/genre/:id`) — loads stations matching a canonical genre with sort and working-now filter controls.
- **State (`GenreDetailState`):** `genreId`, `stations`, `sort`, `workingNowOnly`, `error`
- **Events:** `setSort(sort)`, `toggleWorkingNow()`, `refresh()`

### 7. `SearchViewModel` (`Notifier<SearchState>`)
- **Maps to:** `SearchScreen` (`/search`) and `FiltersBottomSheet` — manages query input, recent queries, active `StationFilter` (`workingNowOnly: true` by default), sort order, and results.
- **State (`SearchState`):** `query`, `filter`, `sort`, `results`, `isLoading`, `hasSearched`, `recentQueries`, `error`
- **Events:** `setQuery(query)`, `submitSearch()`, `applyFilter(filter)`, `setSort(sort)`, `resetFilters()`, `clearQuery()`

### 8. `StationDetailViewModel` (`AsyncNotifier<StationDetailState>` family)
- **Maps to:** `StationDetailScreen` (`/station/:id`) — loads station metadata, similar stations, favourite toggle state, and report submission.
- **State (`StationDetailState`):** `station`, `similarStations`, `isFavourite`, `isReportSubmitting`, `reportSubmitted`, `error`
- **Events:** `toggleFavourite()`, `submitReport(reason)`, `refresh()`

### 9. `PlayerViewModel` (`Notifier<PlayerState>`)
- **Maps to:** `MiniPlayerSlot`, `NowPlayingScreen` (`/player`), `SleepTimerSheet`, and `ReportStationSheet` — manages active station, playback status (`idle`, `buffering`, `playing`, `paused`, `reconnecting`, `unavailable`), ICY track title logging to song history, Radio Browser click reporting, sleep timer, and similar stations.
- **State (`PlayerState`):** `playback` (`PlaybackState`), `isFavourite`, `similarStations`, `reportSubmitted`, `error`
- **Events:** `playStation(station)`, `togglePlayPause()`, `stop()`, `setPlaybackStatus(status, errorMessage)`, `updateTrackTitle(title)`, `toggleFavourite()`, `setSleepTimer(duration)`, `cancelSleepTimer()`, `reportCurrentStation(reason)`

### 10. `LibraryViewModel` (`AsyncNotifier<LibraryState>`)
- **Maps to:** `LibraryScreen` (`/library`) — drives `Favourites`, `Recents`, `Collections`, and `Song History` tabs, plus free-tier limit prompts (`limitReachedFailure`).
- **State (`LibraryState`):** `activeTabIndex`, `favourites`, `recents`, `collections`, `songHistory`, `entitlement`, `limitReachedFailure`, `error`
- **Events:** `selectTab(index)`, `toggleFavourite(station)`, `createCollection(title, subtitle)`, `deleteCollection(collectionId)`, `clearSongHistory()`, `clearLimitPrompt()`, `refresh()`

### 11. `AuthViewModel` (`Notifier<AuthState>`)
- **Maps to:** `AuthLandingScreen`, `SignInScreen`, `SignUpScreen`, `VerifyEmailScreen`, `ForgotPasswordScreen`, `ResetPasswordScreen` (`/auth/*`) — validates forms and manages auth session state (Firebase Auth wired in Phase 4).
- **State (`AuthState`):** `isAuthenticated`, `userEmail`, `displayName`, `isLoading`, `verificationEmailSent`, `resetEmailSent`, `passwordResetCompleted`, `error`
- **Events:** `signInWithEmail(email, password)`, `signUpWithEmail(email, password, displayName)`, `signInWithGoogle()`, `resendVerificationEmail()`, `sendPasswordReset(email)`, `confirmPasswordReset(code, newPassword)`, `signOut()`, `clearError()`

### 12. `SubscriptionViewModel` (`AsyncNotifier<SubscriptionState>`)
- **Maps to:** `PaywallScreen` (`/paywall`) and `SubscriptionManagementScreen` (`/subscription`) — manages Monthly/Annual billing toggle, current `Entitlement`, and restore purchases.
- **State (`SubscriptionState`):** `entitlement`, `billingPeriod`, `isProcessing`, `statusMessage`, `error`
- **Events:** `selectBillingPeriod(period)`, `restorePurchases()`, `refresh()`

### 13. `SettingsViewModel` (`AsyncNotifier<SettingsState>`)
- **Maps to:** `ProfileScreen` (`/profile`), `SettingsScreen` (`/settings`), `DeleteAccountScreen` (`/delete-account`), `AboutLegalScreen` (`/about`), and `OfflineBanner` — manages persisted `UserSettings`, offline simulation toggle, and account deletion flow.
- **State (`SettingsState`):** `settings` (`UserSettings`), `isOfflineSimulated`, `isDeletingAccount`, `accountDeleted`, `error`
- **Events:** `toggleDataSaver(enabled)`, `setDefaultSleepMinutes(minutes)`, `setTheme(theme)`, `setLanguage(languageCode)`, `toggleNotifyCollections(enabled)`, `toggleWorkingNowDefault(enabled)`, `toggleOfflineSimulated()`, `requestDeleteAccount()`, `refresh()`
