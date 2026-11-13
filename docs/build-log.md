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
