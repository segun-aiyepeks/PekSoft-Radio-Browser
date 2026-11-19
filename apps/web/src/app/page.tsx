import Link from 'next/link';
import {
  Activity,
  ArrowRight,
  Check,
  Play,
  Radio,
  ShieldCheck,
  Smartphone,
  Zap,
} from 'lucide-react';
import { AnimatedGroup } from '@/components/motion-primitives/animated-group';
import { InView } from '@/components/motion-primitives/in-view';
import { ScrollProgress } from '@/components/motion-primitives/scroll-progress';
import { SlidingNumber } from '@/components/motion-primitives/sliding-number';
import { TextEffect } from '@/components/motion-primitives/text-effect';
import { CountryCard } from '@/components/radio/country-card';
import { CountryFlag } from '@/components/radio/country-flag';
import { LandingLiveCard } from '@/components/radio/landing-live-card';
import { LazyInfiniteSlider } from '@/components/radio/lazy-effects';
import { StationCard } from '@/components/radio/station-card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import {
  fetchCountries,
  fetchGenres,
  fetchTrendingStations,
} from '@/lib/api-client';
import { MOCK_STATIONS } from '@/lib/mock-data';
import { FADE_UP_VARIANTS, TRANSITION_NORMAL } from '@/lib/motion';
import { buildMetadata } from '@/lib/seo';

export const revalidate = 300;

export const metadata = buildMetadata({
  title: 'Every radio station in the world, one tap away',
  description:
    'Open PekSoft Radio and hear something you love within 10 seconds. Discover verified working stations by country, language, and genre.',
  path: '/',
});

export default async function LandingPage() {
  const [stations, countries, genres] = await Promise.all([
    fetchTrendingStations({ limit: 8 }),
    fetchCountries(),
    fetchGenres(),
  ]);

  const totalOnline =
    countries.reduce((sum, c) => sum + c.stationCount, 0) || 40000;
  const featuredStation = stations[0] ?? MOCK_STATIONS[0]!;

  return (
    <div className="min-h-screen bg-background text-foreground">
      <ScrollProgress className="fixed top-0 z-50 h-0.5 bg-[var(--color-accent-violet)]" />

      {/* Public Header */}
      <header className="sticky top-0 z-40 border-b border-border bg-background">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-4 px-4 sm:px-6">
          <div className="flex items-center gap-8">
            <Link href="/" className="flex items-center gap-2.5">
              <img
                src="/images/peksoft-logo.png"
                alt="PekSoft Radio Browser logo"
                className="size-9 shrink-0 rounded-lg border border-border object-cover"
              />
              <span className="font-heading text-base font-bold tracking-tight text-foreground">
                PekSoft Radio
              </span>
            </Link>

            <nav className="hidden items-center gap-6 text-sm text-muted-foreground lg:flex">
              <a href="#features" className="hover:text-foreground">
                Features
              </a>
              <a href="#directory" className="hover:text-foreground">
                Global Directory
              </a>
              <Link href="/explore" className="hover:text-foreground">
                Discover
              </Link>
              <Link href="/pricing" className="hover:text-foreground">
                Pricing
              </Link>
            </nav>
          </div>

          <div className="flex items-center gap-2.5">
            <Link href="/home" className="hidden sm:inline-flex">
              <Button variant="outline">Open Web Player</Button>
            </Link>
            <Link href="/home">
              <Button variant="signal">Get Started Free</Button>
            </Link>
          </div>
        </div>
      </header>

      <main>
        <div className="mx-auto max-w-7xl space-y-16 px-4 pt-12 pb-20 sm:px-6">
          {/* Split Hero */}
          <section className="grid items-center gap-10 lg:grid-cols-12">
            <div className="space-y-6 lg:col-span-7">
              <Badge variant="outline" className="gap-2 px-3 py-1 text-xs">
                <span className="size-2 rounded-full bg-[#10B981]" />
                Community-Driven · 40,000+ Live Streams · Zero Setup
              </Badge>

              <div className="space-y-2">
                <TextEffect
                  as="h1"
                  per="word"
                  preset="fade-in-blur"
                  speedReveal={1.4}
                  className="font-heading text-4xl font-bold tracking-tight text-foreground sm:text-5xl"
                >
                  Every radio station in the world. One tap away.
                </TextEffect>
              </div>

              <p className="max-w-xl text-base text-muted-foreground sm:text-lg">
                Experience borderless audio broadcasting from 195+ countries.
                From Lagos Afrobeats to Tokyo jazz lounges, listen instantly in
                studio bitrates with real-time stream health monitoring.
              </p>

              <div className="flex flex-wrap items-center gap-3">
                <Link href="/home">
                  <Button variant="signal" size="lg" className="h-11 px-6">
                    <Play className="size-4" /> Listen in Web Player — Free
                  </Button>
                </Link>
                <Link href="/explore">
                  <Button variant="outline" size="lg" className="h-11 px-5">
                    <Smartphone className="size-4" /> Explore Directory
                  </Button>
                </Link>
              </div>

              {/* 4-Metric Strip */}
              <div className="grid grid-cols-2 gap-4 rounded-xl border border-border bg-card p-4 sm:grid-cols-4">
                <div>
                  <p className="font-heading text-xl font-bold text-foreground">
                    <SlidingNumber value={totalOnline} />+
                  </p>
                  <p className="text-[11px] font-medium text-muted-foreground uppercase">
                    Stations Online
                  </p>
                </div>
                <div>
                  <p className="font-heading text-xl font-bold text-[#10B981]">
                    99.4%
                  </p>
                  <p className="text-[11px] font-medium text-muted-foreground uppercase">
                    Working Streams
                  </p>
                </div>
                <div>
                  <p className="font-heading text-xl font-bold text-foreground">
                    195
                  </p>
                  <p className="text-[11px] font-medium text-muted-foreground uppercase">
                    Countries
                  </p>
                </div>
                <div>
                  <p className="font-heading text-xl font-bold text-foreground">
                    ₦0
                  </p>
                  <p className="text-[11px] font-medium text-muted-foreground uppercase">
                    Required to Start
                  </p>
                </div>
              </div>
            </div>

            <div className="lg:col-span-5">
              <LandingLiveCard station={featuredStation} />
            </div>
          </section>

          {/* Live Broadcast Ticker (zero CLS h-11) */}
          <section
            aria-label="Live broadcast ticker"
            className="h-11 overflow-hidden"
          >
            <LazyInfiniteSlider gap={16} speed={35} speedOnHover={14}>
              {stations.map((s) => (
                <Link
                  key={s.id}
                  href={`/station/${s.slug}`}
                  className="inline-flex h-10 items-center gap-2 rounded-lg border border-border bg-card px-3.5 text-xs font-medium whitespace-nowrap text-foreground hover:bg-muted/50"
                >
                  <CountryFlag
                    code={s.countryCode}
                    name={s.countryName}
                    emojiFallback={s.countryFlag}
                    size="xs"
                  />
                  <span>{s.name}</span>
                  <span className="text-muted-foreground">{s.codec}</span>
                </Link>
              ))}
            </LazyInfiniteSlider>
          </section>

          {/* Core Value Engine */}
          <section id="features" className="space-y-6">
            <div>
              <h2 className="font-heading text-2xl font-bold text-foreground">
                Sound First, Setup Never.
              </h2>
              <p className="mt-1 text-sm text-muted-foreground">
                Engineered for sonic explorers who demand immediacy over
                onboarding friction.
              </p>
            </div>

            <div className="grid gap-5 md:grid-cols-3">
              {[
                {
                  num: '01 · Zero Friction',
                  title: 'Instant Sound, Zero Friction',
                  desc: 'No mandatory registration walls or sponsored audio clips gating your first tap. Failover routing connects you in milliseconds.',
                  icon: Zap,
                },
                {
                  num: '02 · Stream Integrity',
                  title: 'Honest Stream Health',
                  desc: 'Powered by Radio Browser with active heartbeat checks. Dead links are automatically deprioritized so Working Now actually works.',
                  icon: ShieldCheck,
                },
                {
                  num: '03 · High Fidelity',
                  title: 'Direct Browser & HLS Audio',
                  desc: 'Direct-to-stream HTML5 and lazy HLS playback with Media Session controls and zero server audio proxying.',
                  icon: Activity,
                },
              ].map((item) => {
                const Icon = item.icon;
                return (
                  <Card key={item.num} className="border-border bg-card">
                    <CardHeader className="space-y-2">
                      <div className="inline-flex size-10 items-center justify-center rounded-lg border border-border bg-muted">
                        <Icon className="size-4 text-foreground" />
                      </div>
                      <p className="text-xs font-medium text-muted-foreground">
                        {item.num}
                      </p>
                      <CardTitle className="text-base">{item.title}</CardTitle>
                    </CardHeader>
                    <CardContent className="text-sm text-muted-foreground">
                      {item.desc}
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          </section>

          {/* Trending Live Stations */}
          <section className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="font-heading text-2xl font-bold text-foreground">
                  Trending Live
                </h2>
                <p className="text-sm text-muted-foreground">
                  Verified working streams playing right now.
                </p>
              </div>
              <Link href="/explore">
                <Button variant="ghost" size="sm">
                  View all <ArrowRight className="size-4" />
                </Button>
              </Link>
            </div>
            <InView
              once
              variants={{
                hidden: { opacity: 0, y: 12 },
                visible: { opacity: 1, y: 0 },
              }}
              transition={TRANSITION_NORMAL}
            >
              <AnimatedGroup
                variants={FADE_UP_VARIANTS}
                className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4"
              >
                {stations.slice(0, 4).map((station) => (
                  <StationCard key={station.id} station={station} />
                ))}
              </AnimatedGroup>
            </InView>
          </section>

          {/* Curated Frequencies (Countries + Genres) */}
          <section id="directory" className="space-y-6">
            <div className="flex flex-wrap items-end justify-between gap-4">
              <div>
                <h2 className="font-heading text-2xl font-bold text-foreground">
                  Browse by Country &amp; Genre
                </h2>
                <p className="text-sm text-muted-foreground">
                  Explore verified stations across countries and canonical genres.
                </p>
              </div>
              <Link
                href="/explore"
                className="text-xs font-medium text-foreground underline-offset-4 hover:underline"
              >
                Explore All Countries →
              </Link>
            </div>

            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {countries.slice(0, 6).map((country) => (
                <CountryCard key={country.code} country={country} />
              ))}
            </div>

            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {genres.map((genre) => (
                <Link
                  key={genre.id}
                  href={`/genre/${genre.slug}`}
                  className="group flex items-center gap-3.5 rounded-xl border border-border bg-card p-3 transition-colors hover:bg-muted/40"
                >
                  <img
                    src={genre.imageUrl}
                    alt={genre.name}
                    className="size-14 shrink-0 rounded-lg border border-border object-cover"
                  />
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-heading text-sm font-bold text-foreground">
                      {genre.name}
                    </p>
                    <p className="truncate text-xs text-muted-foreground">
                      {genre.stationCount} stations
                    </p>
                  </div>
                </Link>
              ))}
            </div>
          </section>

          {/* Pricing Comparison */}
          <section className="space-y-6">
            <div>
              <h2 className="font-heading text-2xl font-bold text-foreground">
                Never Lock Discovery. Pay Only for Power.
              </h2>
              <p className="mt-1 text-sm text-muted-foreground">
                Every radio station stays free forever. Plus removes ads and
                unlocks unlimited library tools.
              </p>
            </div>

            <div className="grid gap-6 md:grid-cols-2">
              <Card className="flex flex-col justify-between border-border bg-card p-6">
                <div className="space-y-4">
                  <p className="text-xs font-medium text-muted-foreground uppercase">
                    Standard Tier
                  </p>
                  <h3 className="font-heading text-xl font-bold text-foreground">
                    Free Forever
                  </h3>
                  <p className="font-heading text-3xl font-bold text-foreground">
                    ₦0{' '}
                    <span className="text-sm font-normal text-muted-foreground">
                      / forever
                    </span>
                  </p>
                  <ul className="space-y-2 text-sm text-muted-foreground">
                    {[
                      '40,000+ verified live streams worldwide',
                      'Real-time "Working Now" stream health filters',
                      'Store up to 30 custom favourites',
                      'Synced library across Android & Web',
                    ].map((b) => (
                      <li key={b} className="flex items-center gap-2">
                        <Check className="size-4 text-[#10B981]" />
                        <span>{b}</span>
                      </li>
                    ))}
                  </ul>
                </div>
                <Link href="/home" className="mt-6 block">
                  <Button variant="outline" size="lg" className="w-full">
                    Start Free Now
                  </Button>
                </Link>
              </Card>

              <Card className="flex flex-col justify-between border-[var(--color-accent-violet)] bg-card p-6">
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <p className="text-xs font-medium text-muted-foreground uppercase">
                      Pro Tier
                    </p>
                    <Badge variant="secondary">Save 33% Yearly</Badge>
                  </div>
                  <h3 className="font-heading text-xl font-bold text-foreground">
                    PekSoft Radio Plus
                  </h3>
                  <p className="font-heading text-3xl font-bold text-foreground">
                    ₦1,200{' '}
                    <span className="text-sm font-normal text-muted-foreground">
                      / month (or ₦12,000 / yr)
                    </span>
                  </p>
                  <ul className="space-y-2 text-sm text-muted-foreground">
                    {[
                      '100% ad-free experience (no banners or audio ads)',
                      'Unlimited station favourites & custom collections',
                      'Custom sleep timer with smooth fade-out',
                      'Bitrate, codec & HTTPS-only power filters',
                    ].map((b) => (
                      <li key={b} className="flex items-center gap-2">
                        <Check className="size-4 text-[#10B981]" />
                        <span>{b}</span>
                      </li>
                    ))}
                  </ul>
                </div>
                <Link href="/pricing" className="mt-6 block">
                  <Button variant="signal" size="lg" className="w-full">
                    Upgrade to Plus
                  </Button>
                </Link>
              </Card>
            </div>
          </section>
        </div>
      </main>

      <footer className="border-t border-border bg-card py-8 text-xs text-muted-foreground">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4 px-4 sm:px-6">
          <p>
            Station data by Radio Browser · Open-source global directory ·{' '}
            <span className="font-medium text-foreground">
              © {new Date().getFullYear()} developed by aiyepeks
            </span>
          </p>
          <div className="flex items-center gap-5">
            <Link href="/explore" className="hover:text-foreground">
              Explore
            </Link>
            <Link href="/pricing" className="hover:text-foreground">
              Pricing
            </Link>
            <Link href="/auth" className="hover:text-foreground">
              Sign In
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
