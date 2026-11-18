# Web Motion & Performance Report (`apps/web`)

## 1. Motion Architecture & Rules Enforced
- **Transform & opacity only**: All `template.tsx`, `AnimatedGroup`, `InView`, and `AnimatedBackground` transitions animate `transform` and `opacity` only—no `width`, `height`, `top`, or `left` layout animations.
- **Reduced motion**: Root `AppProviders` wraps the entire app in `<MotionConfig reducedMotion="user">`, automatically disabling transform animations when `prefers-reduced-motion: reduce` is enabled in the OS/browser.
- **Zero layout shift (CLS = 0)**:
  - The flag/station marquee (`LazyInfiniteSlider`) sits inside a fixed-height `h-11` container.
  - `PlayerBar` (`h-18`) and mobile bottom nav (`h-16`) occupy fixed slots with matching `pb-40 md:pb-24` main padding.
  - `LazySpotlight` and `LazyBorderTrail` are `position: absolute` overlays inside already-sized cards/buttons.
- **LCP & Audio Controls Protection**:
  - Hero `<h1>` (`TextEffect`) starts immediately (`delay={0}`) and audio play/pause buttons in `PlayerBar` / `StationRow` have zero entrance delay.
- **Lazy-loaded heavy effects (`apps/web/src/components/radio/lazy-effects.tsx`)**:
  - `InfiniteSlider`, `Tilt`, `Spotlight`, and `BorderTrail` are loaded asynchronously via `next/dynamic(..., { ssr: false })` so they never block SSR HTML or initial hydration.

## 2. Build & Bundle Measurements (`next build`)
- **Framework**: Next.js `16.4.6` (Turbopack)
- **Milestone 6.3 Total Client JS Chunks (`apps/web/.next/static/chunks/*.js`)**: `1,589 KB` across split lazy chunks (including `motion` + `react-use-measure` + `shadcn/ui` Base UI primitives, with heavy pointer/measure effects deferred to dynamic chunks).
- **Lighthouse / Core Web Vitals**:
  - Full Lighthouse CLI audit against live SSR routes is scheduled in **Milestone 6.9** after real data, SEO metadata, and PWA manifest/service worker are wired.

## 3. Signature Motion Per Page
| Route | Signature Moment | Subtle Supporting Motion |
| --- | --- | --- |
| `/` (Landing) | `TextEffect` hero headline + `Magnetic`/`BorderTrail` CTA + `LazyInfiniteSlider` marquee | `InView` + `AnimatedGroup` trending cards, `SlidingNumber` station count, `ScrollProgress` |
| `/home` | `LazyTilt` + `LazySpotlight` curated collection cards | `AnimatedGroup` continue-listening grid, `ScrollProgress` |
| `/explore` | `AnimatedBackground` active sort pill in `FilterBar` | `AnimatedGroup` station rows, `ScrollProgress` |
| `/pricing` | `SlidingNumber` price transition (`12,000` ↔ `1,500`) + `AnimatedBackground` `PlanToggle` | `LazyBorderTrail` + `LazySpotlight` on Plus card |
| Global | `app/template.tsx` route transition (`opacity` + `translateY(6px)`, `120ms`) | `NowPlayingSheet` (`shadcn Sheet` slide-over) |
