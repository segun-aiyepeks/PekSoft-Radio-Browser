# System Architecture — PekSoft Radio Browser

## Overview
PekSoft Radio Browser uses a **client–gateway–directory** architecture:
- **Audio streams** flow directly from third-party radio broadcasters to the user's device (mobile or browser) — our backend **never** proxies, records, or rebroadcasts audio.
- **Metadata & discovery** are cached and normalised by `apps/api` (for web and shared collections) and queried respectfully from Radio Browser mirrors.
- **Play click attribution** is sent directly from clients to Radio Browser so per-IP 24h counting remains accurate.
- **Auth, library sync, and entitlements** are unified through Firebase Authentication and our Node.js/Fastify API backed by PostgreSQL.

## System Diagram

```mermaid
flowchart TB
    subgraph Clients["User Devices"]
        Mobile["Flutter Android App<br/>(apps/mobile · com.peksoft.radio)"]
        Web["Next.js Web App<br/>(apps/web · App Router + PWA)"]
    end

    subgraph Backend["PekSoft Backend"]
        API["Node.js + Fastify API<br/>(apps/api)"]
        DB[("PostgreSQL<br/>Users · Libraries · Entitlements · Curated")]
    end

    subgraph AuthObs["Identity & Telemetry"]
        Firebase["Firebase<br/>Auth (Email/Google) · Analytics · Crashlytics"]
    end

    subgraph Radio["Radio Ecosystem"]
        RB["Radio Browser Mirrors<br/>(all.api.radio-browser.info / de1)"]
        Streams["Third-Party Radio Streams<br/>(HTTPS / HTTP / HLS)"]
    end

    subgraph Monetisation["Payments & Ads"]
        PlayBilling["Google Play Billing<br/>& RTDN Webhooks"]
        Paystack["Paystack<br/>Hosted Checkout & Webhooks"]
        AdMob["Google AdMob + UMP<br/>(Mobile Ads)"]
        AdSense["Google AdSense<br/>(Web Ads)"]
    end

    %% Client -> Backend & Auth
    Mobile <-->|"REST + Firebase ID Token<br/>Sync · Entitlements · Curated"| API
    Web <-->|"SSR & REST + Firebase ID Token<br/>Catalog · SEO Pages · Sync"| API
    API <-->|"Read / Write"| DB
    API -->|"Verify ID Tokens"| Firebase

    Mobile <-->|"Email / Google Sign-In<br/>Analytics & Crashlytics"| Firebase
    Web <-->|"Email / Google Sign-In"| Firebase

    %% Radio Browser & Audio
    API <-->|"Mirror Discovery · Cached Catalog<br/>Search · Normalisation"| RB
    Mobile <-->|"Direct Discovery (Cached) &<br/>Click Reporting (/json/url)"| RB
    Web -->|"Direct Click Reporting<br/>(/json/url)"| RB
    Streams -->|"Direct Audio Stream<br/>(HTTP / HTTPS / HLS)"| Mobile
    Streams -->|"Direct Audio Stream<br/>(HTTPS / HLS only)"| Web

    %% Payments & Webhooks
    Mobile <-->|"In-App Subscriptions"| PlayBilling
    PlayBilling -->|"RTDN Server Verification"| API
    Web -->|"Hosted Checkout"| Paystack
    Paystack -->|"Payment Webhooks"| API

    %% Ads
    Mobile <-->|"Banner / Native / Interstitial / Rewarded"| AdMob
    Web <-->|"Reserved Ad Slots"| AdSense
```

## Key Architectural Boundaries
1. **No audio proxying**: `apps/mobile` plays HTTP, HTTPS, and HLS streams directly via `just_audio` (with Android cleartext config for HTTP streams). `apps/web` plays HTTPS/HLS streams directly and marks HTTP-only stations as *"Best in the mobile app"*.
2. **Server-side entitlement truth**: Neither `apps/mobile` nor `apps/web` unlocks Plus features locally without verified state from `apps/api` (backed by Play RTDN and Paystack webhooks in PostgreSQL).
3. **Shared contracts & tokens**: `packages/shared` holds Zod schemas and Radio Browser fixtures; `packages/design-tokens` drives both Flutter `ThemeData` and Next.js Tailwind CSS variables.
