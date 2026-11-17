import Link from 'next/link';
import { ArrowRight, Globe2, Radio, ShieldCheck, Sparkles } from 'lucide-react';
import { AnimatedGroup } from '@/components/motion-primitives/animated-group';
import { InView } from '@/components/motion-primitives/in-view';
import { Magnetic } from '@/components/motion-primitives/magnetic';
import { ScrollProgress } from '@/components/motion-primitives/scroll-progress';
import { SlidingNumber } from '@/components/motion-primitives/sliding-number';
import { TextEffect } from '@/components/motion-primitives/text-effect';
import { AppShell } from '@/components/radio/app-shell';
import { CountryCard } from '@/components/radio/country-card';
import {
  LazyBorderTrail,
  LazyInfiniteSlider,
  LazySpotlight,
  LazyTilt,
} from '@/components/radio/lazy-effects';
import { StationCard } from '@/components/radio/station-card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  fetchCountries,
  fetchGenres,
  fetchTrendingStations,
} from '@/lib/api-client';
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
    countries.reduce((sum, c) => sum + c.stationCount, 0) || 32400;

  return (
    <AppShell>
      <ScrollProgress className="fixed top-0 z-50 h-0.5 bg-[var(--color-accent)]" />
      <div className="space-y-12">
        {/* Hero Banner (Signature Motion: TextEffect + Magnetic CTA + Spotlight) */}
        <section className="relative overflow-hidden rounded-3xl border border-border bg-gradient-to-br from-[#18243E] via-[#101A2E] to-[#0A0F1C] p-6 sm:p-10">
          <LazySpotlight className="from-amber-400/20 via-amber-400/5 to-transparent" />
          <div className="relative z-10 max-w-2xl space-y-5">
            <div className="flex flex-wrap items-center gap-3">
              <Badge variant="live" className="gap-1.5">
                <Radio className="size-3.5" /> Live Global Radio · Zero Setup
              </Badge>
              <span className="inline-flex items-center gap-1.5 text-xs text-slate-300">
                <SlidingNumber value={totalOnline} />+ stations online
              </span>
            </div>

            <TextEffect
              as="h1"
              per="word"
              preset="fade-in-blur"
              speedReveal={1.4}
              className="font-heading text-3xl font-bold tracking-tight text-white sm:text-5xl"
            >
              Every radio station in the world, one tap away.
            </TextEffect>

            <p className="text-base text-slate-300 sm:text-lg">
              Open PekSoft Radio and hear something you love within 10 seconds.
              Discover verified working stations by country, language, and genre
              with one synced library across Android and Web.
            </p>

            <div className="flex flex-wrap items-center gap-3 pt-2">
              <Magnetic>
                <div className="relative inline-flex rounded-xl p-[1px]">
                  <LazyBorderTrail
                    className="bg-[var(--color-accent)]"
                    size={44}
                  />
                  <Link href="/home" className="relative z-10">
                    <Button variant="signal" size="lg">
                      Start Listening Free <ArrowRight className="size-4" />
                    </Button>
                  </Link>
                </div>
              </Magnetic>
              <Link href="/explore">
                <Button variant="outline" size="lg">
                  Explore 30,000+ Stations
                </Button>
              </Link>
            </div>
          </div>
        </section>

        {/* Flag & Station Marquee (fixed height h-11 -> zero layout shift) */}
        <section
          aria-label="Live broadcast ticker"
          className="h-11 overflow-hidden"
        >
          <LazyInfiniteSlider gap={16} speed={35} speedOnHover={14}>
            {stations.map((s) => (
              <Link
                key={s.id}
                href={`/station/${s.slug}`}
                className="inline-flex h-10 items-center gap-2 rounded-full border border-border bg-card px-4 text-xs font-medium whitespace-nowrap text-foreground hover:border-[var(--color-accent)]/50"
              >
                <span>{s.countryFlag}</span>
                <span>{s.name}</span>
                <span className="text-muted-foreground">{s.codec}</span>
              </Link>
            ))}
          </LazyInfiniteSlider>
        </section>

        {/* Trending Now */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="font-heading text-2xl font-bold">Trending Live</h2>
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

        {/* Popular Countries */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-heading text-2xl font-bold">
              Browse by Country
            </h2>
            <Link href="/explore">
              <Button variant="ghost" size="sm">
                All countries <Globe2 className="size-4" />
              </Button>
            </Link>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {countries.slice(0, 4).map((country) => (
              <CountryCard key={country.code} country={country} />
            ))}
          </div>
        </section>

        {/* Genres & Plus Highlight */}
        <section className="grid gap-6 lg:grid-cols-3">
          <div className="space-y-4 lg:col-span-2">
            <h2 className="font-heading text-2xl font-bold">
              Canonical Genres
            </h2>
            <div className="grid gap-3 sm:grid-cols-2">
              {genres.slice(0, 4).map((genre) => (
                <LazyTilt key={genre.id} rotationFactor={5}>
                  <Link
                    href={`/genre/${genre.slug}`}
                    className={`relative block overflow-hidden rounded-2xl border border-border bg-gradient-to-br ${genre.gradient} p-5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring`}
                  >
                    <LazySpotlight className="from-white/10 to-transparent" />
                    <h3 className="font-heading text-lg font-bold text-white">
                      {genre.name}
                    </h3>
                    <p className="mt-1 text-xs text-slate-200">
                      {genre.tagline}
                    </p>
                    <p className="mt-3 text-xs font-medium text-[var(--color-accent)]">
                      {genre.stationCount} stations →
                    </p>
                  </Link>
                </LazyTilt>
              ))}
            </div>
          </div>

          <div className="relative flex flex-col justify-between overflow-hidden rounded-2xl border border-[var(--color-accent)]/40 bg-card p-6">
            <LazySpotlight className="from-amber-400/15 to-transparent" />
            <div className="relative z-10 space-y-3">
              <Badge variant="default" className="gap-1">
                <Sparkles className="size-3" /> PekSoft Plus
              </Badge>
              <h3 className="font-heading text-xl font-bold">
                Ad-free, unlimited library &amp; power tools
              </h3>
              <p className="text-sm text-muted-foreground">
                Keep unlimited favourites and custom collections synced across
                your Android phone and browser.
              </p>
              <ul className="space-y-1.5 text-sm text-muted-foreground">
                <li className="flex items-center gap-2">
                  <ShieldCheck className="size-4 text-[var(--color-success)]" />
                  Zero ads everywhere
                </li>
                <li className="flex items-center gap-2">
                  <ShieldCheck className="size-4 text-[var(--color-success)]" />
                  Custom sleep timer &amp; fade-out
                </li>
                <li className="flex items-center gap-2">
                  <ShieldCheck className="size-4 text-[var(--color-success)]" />
                  Bitrate &amp; codec advanced filters
                </li>
              </ul>
            </div>
            <Link href="/pricing" className="relative z-10 mt-6 block">
              <Button variant="signal" className="w-full">
                See Plus Plans
              </Button>
            </Link>
          </div>
        </section>
      </div>
    </AppShell>
  );
}
