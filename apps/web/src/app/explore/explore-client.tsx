'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import type { LanguageDto } from '@peksoft/shared';
import { AnimatedGroup } from '@/components/motion-primitives/animated-group';
import { ScrollProgress } from '@/components/motion-primitives/scroll-progress';
import { AdSlot } from '@/components/ads/ad-slot';
import { AppShell } from '@/components/radio/app-shell';
import { CountryCard } from '@/components/radio/country-card';
import {
  FilterBar,
  type StationFilterState,
} from '@/components/radio/filter-bar';
import { StationRow } from '@/components/radio/station-row';
import { Input } from '@/components/ui/input';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { FADE_UP_VARIANTS } from '@/lib/motion';
import type { WebCountry, WebGenre, WebStation } from '@/lib/mock-data';

export function ExploreClient({
  initialStations,
  countries,
  genres,
  languages,
}: {
  initialStations: WebStation[];
  countries: WebCountry[];
  genres: WebGenre[];
  languages: LanguageDto[];
}) {
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState<StationFilterState>({
    workingOnly: true,
    httpsOnly: false,
    sort: 'popular',
    genre: null,
  });

  const filteredStations = useMemo(() => {
    const q = query.trim().toLowerCase();
    const list = initialStations.filter((s) => {
      if (filter.workingOnly && !s.isWorking) return false;
      if (filter.httpsOnly && !s.isHttpsPlayable) return false;
      if (filter.genre && !s.genres.includes(filter.genre)) return false;
      if (q) {
        const hay = `${s.name} ${s.countryName} ${s.language} ${s.genres.join(' ')}`.toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });
    return [...list].sort((a, b) => {
      if (filter.sort === 'name') return a.name.localeCompare(b.name);
      if (filter.sort === 'trending') return b.clickCount - a.clickCount;
      return b.votes - a.votes;
    });
  }, [initialStations, query, filter]);

  return (
    <AppShell>
      <ScrollProgress className="fixed top-0 z-50 h-0.5 bg-[var(--color-accent)]" />
      <div className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="font-heading text-3xl font-bold tracking-tight">
              Explore
            </h1>
            <p className="text-sm text-muted-foreground">
              Discover stations by country, genre, language, or stream health.
            </p>
          </div>
          <Input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Filter stations..."
            aria-label="Filter stations"
            className="max-w-xs"
          />
        </div>

        <Tabs defaultValue="stations">
          <TabsList>
            <TabsTrigger value="stations">Stations</TabsTrigger>
            <TabsTrigger value="countries">Countries</TabsTrigger>
            <TabsTrigger value="genres">Genres</TabsTrigger>
            <TabsTrigger value="languages">Languages</TabsTrigger>
          </TabsList>

          <TabsContent value="stations" className="mt-4 space-y-4">
            <FilterBar value={filter} onChange={setFilter} />
            {filteredStations.length === 0 ? (
              <p className="rounded-xl border border-border bg-card p-6 text-center text-sm text-muted-foreground">
                No stations match those filters.
              </p>
            ) : (
              <AnimatedGroup variants={FADE_UP_VARIANTS} className="space-y-2.5">
                {filteredStations.map((station) => (
                  <StationRow key={station.id} station={station} />
                ))}
              </AnimatedGroup>
            )}
            <AdSlot variant="card" />
          </TabsContent>

          <TabsContent value="countries" className="mt-4">
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              {countries.map((country) => (
                <CountryCard key={country.code} country={country} />
              ))}
            </div>
          </TabsContent>

          <TabsContent value="genres" className="mt-4">
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {genres.map((genre) => (
                <Link
                  key={genre.id}
                  href={`/genre/${genre.slug}`}
                  className={`block rounded-2xl border border-border bg-gradient-to-br ${genre.gradient} p-5 transition-transform hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring`}
                >
                  <h3 className="font-heading text-lg font-bold text-white">
                    {genre.name}
                  </h3>
                  <p className="mt-1 text-xs text-slate-200">{genre.tagline}</p>
                  <p className="mt-3 text-xs font-medium text-[var(--color-accent)]">
                    {genre.stationCount} stations
                  </p>
                </Link>
              ))}
            </div>
          </TabsContent>

          <TabsContent value="languages" className="mt-4">
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              {languages.slice(0, 24).map((lang) => (
                <div
                  key={lang.name}
                  className="rounded-xl border border-border bg-card p-4"
                >
                  <p className="font-heading font-semibold">{lang.name}</p>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {lang.stationCount} stations
                  </p>
                </div>
              ))}
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </AppShell>
  );
}
