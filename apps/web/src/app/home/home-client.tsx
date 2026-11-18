'use client';

import Link from 'next/link';
import { Shuffle, Sparkles } from 'lucide-react';
import { AnimatedGroup } from '@/components/motion-primitives/animated-group';
import { InView } from '@/components/motion-primitives/in-view';
import { ScrollProgress } from '@/components/motion-primitives/scroll-progress';
import { useMockSession } from '@/components/mock-session-provider';
import { AdSlot } from '@/components/ads/ad-slot';
import { AppShell } from '@/components/radio/app-shell';
import { LazySpotlight, LazyTilt } from '@/components/radio/lazy-effects';
import { StationCard } from '@/components/radio/station-card';
import { StationRow } from '@/components/radio/station-row';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { FADE_UP_VARIANTS, TRANSITION_NORMAL } from '@/lib/motion';
import {
  MOCK_COLLECTIONS,
  type WebGenre,
  type WebStation,
} from '@/lib/mock-data';

export function HomeClient({
  trendingStations,
  nigeriaStations,
  genres,
}: {
  trendingStations: WebStation[];
  nigeriaStations: WebStation[];
  genres: WebGenre[];
}) {
  const { recentIds, playSurpriseMe } = useMockSession();
  const continueStations = trendingStations.filter((s) =>
    recentIds.includes(s.id),
  );

  return (
    <AppShell>
      <ScrollProgress className="fixed top-0 z-50 h-0.5 bg-[var(--color-accent)]" />
      <div className="space-y-10">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="font-heading text-3xl font-bold tracking-tight">
              Home
            </h1>
            <p className="text-sm text-muted-foreground">
              Radio from Nigeria 🇳🇬 · Working now filter ON
            </p>
          </div>
          <Button variant="signal" onClick={playSurpriseMe}>
            <Shuffle className="size-4" /> Surprise me
          </Button>
        </div>

        {/* Genre Chips */}
        <section aria-label="Genre shortcuts" className="flex flex-wrap gap-2">
          {genres.map((genre) => (
            <Link
              key={genre.id}
              href={`/genre/${genre.slug}`}
              className="rounded-full focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            >
              <Badge
                variant="secondary"
                className="px-3.5 py-1.5 text-xs hover:bg-primary hover:text-primary-foreground"
              >
                {genre.name}
              </Badge>
            </Link>
          ))}
        </section>

        {/* Continue Listening */}
        {continueStations.length > 0 && (
          <section className="space-y-3">
            <h2 className="font-heading text-xl font-bold">
              Continue Listening
            </h2>
            <AnimatedGroup
              variants={FADE_UP_VARIANTS}
              className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4"
            >
              {continueStations.map((station) => (
                <StationCard key={station.id} station={station} />
              ))}
            </AnimatedGroup>
          </section>
        )}

        {/* Curated Collections (Signature Tilt + Spotlight) */}
        <section className="space-y-3">
          <div className="flex items-center gap-2">
            <Sparkles className="size-4 text-[var(--color-accent)]" />
            <h2 className="font-heading text-xl font-bold">
              Curated Collections
            </h2>
          </div>
          <div className="grid gap-4 md:grid-cols-3">
            {MOCK_COLLECTIONS.map((col) => (
              <LazyTilt key={col.id} rotationFactor={5}>
                <Link
                  href="/explore"
                  className={`relative block overflow-hidden rounded-2xl border border-border bg-gradient-to-br ${col.gradient} p-5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring`}
                >
                  <LazySpotlight className="from-white/15 to-transparent" />
                  <Badge
                    variant="outline"
                    className="relative z-10 mb-3 border-white/20 text-white"
                  >
                    {col.stationIds.length} stations
                  </Badge>
                  <h3 className="relative z-10 font-heading text-lg font-bold text-white">
                    {col.title}
                  </h3>
                  <p className="relative z-10 mt-1 text-xs text-slate-200">
                    {col.subtitle}
                  </p>
                </Link>
              </LazyTilt>
            ))}
          </div>
        </section>

        {/* Radio from Nigeria */}
        <section className="space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="font-heading text-xl font-bold">
              🇳🇬 Radio from Nigeria
            </h2>
            <Link href="/country/ng">
              <Button variant="ghost" size="sm">
                See all
              </Button>
            </Link>
          </div>
          <InView
            once
            variants={{
              hidden: { opacity: 0, y: 10 },
              visible: { opacity: 1, y: 0 },
            }}
            transition={TRANSITION_NORMAL}
          >
            <div className="space-y-2.5">
              {nigeriaStations.map((station) => (
                <StationRow key={station.id} station={station} />
              ))}
            </div>
          </InView>
        </section>

        {/* Trending Now */}
        <section className="space-y-3">
          <h2 className="font-heading text-xl font-bold">Trending Now</h2>
          <div className="space-y-2.5">
            {trendingStations.slice(0, 6).map((station) => (
              <StationRow key={station.id} station={station} />
            ))}
          </div>
        </section>

        <AdSlot variant="banner" />
      </div>
    </AppShell>
  );
}
