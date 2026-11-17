'use client';

import Link from 'next/link';
import { Shuffle, Sparkles } from 'lucide-react';
import { useMockSession } from '@/components/mock-session-provider';
import { AppShell } from '@/components/radio/app-shell';
import { StationCard } from '@/components/radio/station-card';
import { StationRow } from '@/components/radio/station-row';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  MOCK_COLLECTIONS,
  MOCK_GENRES,
  MOCK_STATIONS,
} from '@/lib/mock-data';

export default function HomePage() {
  const { recentIds, playSurpriseMe } = useMockSession();
  const continueStations = MOCK_STATIONS.filter((s) =>
    recentIds.includes(s.id),
  );
  const nigeriaStations = MOCK_STATIONS.filter((s) => s.countryCode === 'NG');

  return (
    <AppShell>
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
          {MOCK_GENRES.map((genre) => (
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
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {continueStations.map((station) => (
                <StationCard key={station.id} station={station} />
              ))}
            </div>
          </section>
        )}

        {/* Curated Collections with Picture-Style Backgrounds */}
        <section className="space-y-3">
          <div className="flex items-center gap-2">
            <Sparkles className="size-4 text-[var(--color-accent)]" />
            <h2 className="font-heading text-xl font-bold">
              Curated Collections
            </h2>
          </div>
          <div className="grid gap-4 md:grid-cols-3">
            {MOCK_COLLECTIONS.map((col) => (
              <Link
                key={col.id}
                href="/explore"
                className={`block rounded-2xl border border-border bg-gradient-to-br ${col.gradient} p-5 transition-transform hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring`}
              >
                <Badge variant="outline" className="mb-3 border-white/20 text-white">
                  {col.stationIds.length} stations
                </Badge>
                <h3 className="font-heading text-lg font-bold text-white">
                  {col.title}
                </h3>
                <p className="mt-1 text-xs text-slate-200">{col.subtitle}</p>
              </Link>
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
          <div className="space-y-2.5">
            {nigeriaStations.map((station) => (
              <StationRow key={station.id} station={station} />
            ))}
          </div>
        </section>

        {/* Trending Now */}
        <section className="space-y-3">
          <h2 className="font-heading text-xl font-bold">Trending Now</h2>
          <div className="space-y-2.5">
            {MOCK_STATIONS.slice(0, 6).map((station) => (
              <StationRow key={station.id} station={station} />
            ))}
          </div>
        </section>
      </div>
    </AppShell>
  );
}
