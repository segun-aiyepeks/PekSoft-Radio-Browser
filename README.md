# PekSoft Radio Browser

Every radio station in the world, one tap away — powered by the community [Radio Browser API](https://www.radio-browser.info/).

## Repository Layout

This is a monorepo combining TypeScript workspaces (`pnpm` + Turborepo) and the Flutter mobile app:

- `apps/mobile` — Flutter Android app (`com.peksoft.radio`, outside `pnpm`)
- `apps/web` — Next.js web app (App Router, TypeScript, Tailwind CSS)
- `apps/api` — Node.js backend API (Fastify, TypeScript, Zod)
- `packages/shared` — Shared TypeScript types, Zod schemas, and API fixtures
- `packages/design-tokens` — Single source of truth for colours, typography, spacing, and radii
- `brand/` — Logo marks, palette, and app icon sources
- `docs/` — Architecture, ADRs, API spike notes, and build log

## Prerequisites

- **Node.js**: `>= 22.0.0` (tested on Node `24.x`)
- **pnpm**: `>= 10.0.0` (`npm install -g pnpm`)
- **Flutter SDK**: `3.44+` (Dart `3.12+`) and Android SDK for `apps/mobile`

## Getting Started

Install TypeScript workspace dependencies from the repository root:

```bash
pnpm install
```

### Run Web (`apps/web`)

```bash
pnpm --filter @peksoft/web dev
```

### Run API (`apps/api`)

```bash
cp apps/api/.env.example apps/api/.env
pnpm --filter @peksoft/api dev
```

### Run Mobile (`apps/mobile`)

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Quality Checks

```bash
# TypeScript workspaces (build, lint, typecheck, test)
pnpm build
pnpm lint
pnpm typecheck
pnpm test

# Flutter mobile
cd apps/mobile
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
