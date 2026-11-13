# AGENTS.md — PekSoft Radio Browser

## Project
PekSoft Radio Browser streams radio stations worldwide using the community Radio Browser API (radio-browser.info). Apps: Flutter mobile (Android first), Next.js web and a Node.js API, in one monorepo. Revenue: ads (AdMob on mobile, AdSense on web) and Plus subscriptions (Google Play Billing on Android, Paystack on web). Auth: Firebase Authentication (email + Google). The product source of truth is docs/ux-document.md. If code and that document disagree, stop and ask.

## About the developer (teach as you build)
Segun is a Flutter/Dart and UI/UX developer with foundational Node.js, React and web skills. He is newer to backend architecture, payments, ads and release engineering, so explain those areas in more depth.

## How you must work (non-negotiable)
1. Plan first: write a short plan before coding each milestone.
2. Explain everything: after each milestone, add an entry to docs/build-log.md and give the same summary in chat using: What I did / Why / How it works (plain English) / Files created or changed / How to run and verify / Concepts worth learning / Decisions and alternatives.
3. Stop at every milestone: finish, commit, summarise, then wait for me to say continue. Never start the next milestone or phase on your own.
4. Ask before: adding dependencies not named in the phase prompt, deleting or renaming files, changing the architecture, creating cloud resources or anything that costs money, running destructive commands.
5. Verify, do not assume: check current stable versions and official docs before using any package, API or platform setting. Record the versions you chose and why in docs/decisions.md.
6. Never invent data, endpoints or field names. Check the live Radio Browser API and use real saved responses as test fixtures.

## Git protocol
- One branch per phase: phase/<n>-<short-name>, created from main. Never commit directly to main.
- Small commits after each logical step. Conventional Commits (feat:, fix:, refactor:, test:, docs:, chore:, ci:), imperative subject of at most 72 characters, body explains why.
- Push the branch after every milestone. Never force-push.
- At the end of a phase, open a pull request (or give me the compare link) containing the build-log summary. I will merge it.
- Never commit secrets: service-account keys, .env files, keystores, API secrets. Keep a .env.example. Ask me before committing google-services.json or GoogleService-Info.plist.

## Mobile architecture (Flutter): strict MVVM + Riverpod
- Feature-first folders: lib/features/<feature>/{presentation, domain, data}. Shared code in lib/core.
- View (widgets): render state and forward user events. No business logic, no direct repository, network or database access, and no BuildContext inside ViewModels.
- ViewModel: one Riverpod Notifier or AsyncNotifier per screen exposing one immutable state class (freezed). It talks only to repositories and use cases through providers.
- Repository: abstract interface in domain, implementation in data. Combines remote and local sources. Returns domain models, never DTOs.
- DTOs (JSON) are separate from domain models. Map at the repository boundary.
- Errors are modelled with sealed classes or a Result type, never swallowed. User-facing messages come from the ViewModel.
- Dependency direction: presentation -> domain <- data.
- Tests: unit tests for every ViewModel and repository using fakes; widget tests for key screens; no test may hit the live network.
- Quality gate before every commit: dart format, flutter analyze (zero issues), flutter test.

## Web and API conventions
- TypeScript strict everywhere. Validate all input with Zod. Shared types and schemas live in packages/shared.
- API is layered: routes -> services -> repositories. Config comes from env and is validated at startup. Structured logs without personal data. Rate limiting and CORS configured.
- Web: Next.js App Router, Server Components by default, client components only where needed. Public SEO pages are server-rendered with metadata and a sitemap.
- Quality gate before every commit: pnpm lint, typecheck and test must pass.

## Radio Browser etiquette
- Discover mirrors, pick one at random and retry the next on failure. Never hard-code a single server.
- Send the header User-Agent: PekSoftRadioBrowser/<version>.
- Report a click for every play. Cache lists (countries, tags, languages) for hours. Never hammer the servers.
- Show 'Station data by Radio Browser' in About.

## Product rules (from the UX document)
- Guest-first: sound before sign-up. The Working now filter is ON by default.
- Never show an ad before first sound, over playback controls, or on auth and paywall screens.
- Never unlock paid features on the client alone: entitlements are verified server-side.
- Android subscriptions use Google Play Billing only.
- Accessibility: 48dp touch targets, semantic labels, WCAG AA contrast, respect reduced motion and text scaling.
- Brand: packages/design-tokens is the single source for colour, type and spacing. Never hard-code colours.