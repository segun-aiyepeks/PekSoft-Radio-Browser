'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import type { LanguageDto } from '@peksoft/shared';
import { Loader2 } from 'lucide-react';
import { AdSlot } from '@/components/ads/ad-slot';
import { AnimatedGroup } from '@/components/motion-primitives/animated-group';
import { ScrollProgress } from '@/components/motion-primitives/scroll-progress';
import { AppShell } from '@/components/radio/app-shell';
import { CountryCard } from '@/components/radio/country-card';
import {
  FilterBar,
  type StationFilterState,
} from '@/components/radio/filter-bar';
import { StationRow } from '@/components/radio/station-row';
import { Input } from '@/components/ui/input';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { searchStations } from '@/lib/api-client';
import type { WebCountry, WebGenre, WebStation } from '@/lib/mock-data';
import { FADE_UP_VARIANTS } from '@/lib/motion';

export function ExploreClient({
  initialQuery = '',
  initialStations,
  countries,
  genres,
  languages,
}: {
  initialQuery?: string;
  initialStations: WebStation[];
  countries: WebCountry[];
  genres: WebGenre[];
  languages: LanguageDto[];
}) {
  const [query, setQuery] = useState(initialQuery);
  const [stations, setStations] = useState<WebStation[]>(initialStations);
  const [searching, setSearching] = useState(false);
  const [filter, setFilter] = useState<StationFilterState>({
    workingOnly: true,
    httpsOnly: false,
    sort: 'popular',
    genre: null,
  });
  const isFirstRender = useRef(true);

  useEffect(() => {
    setQuery(initialQuery);
  }, [initialQuery]);

  // Live API search when query or server-side filters change
  useEffect(() => {
    if (isFirstRender.current) {
      isFirstRender.current = false;
      return;
    }

    let cancelled = false;
    const timer = window.setTimeout(() => {
      setSearching(true);
      void searchStations({
        q: query.trim() || undefined,
        genre: filter.genre ?? undefined,
        workingOnly: filter.workingOnly,
        httpsOnly: filter.httpsOnly ? true : undefined,
        sort: filter.sort === 'trending' ? 'popular' : 'votes',
        limit: 40,
      })
        .then((res) => {
          if (!cancelled) {
            setStations(res);
          }
        })
        .finally(() => {
          if (!cancelled) {
            setSearching(false);
          }
        });
    }, 300);

    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [query, filter.genre, filter.workingOnly, filter.httpsOnly, filter.sort]);

  const displayedStations = useMemo(() => {
    if (filter.sort === 'name') {
      return [...stations].sort((a, b) => a.name.localeCompare(b.name));
    }
    return stations;
  }, [stations, filter.sort]);

  return (
    <AppShell>
      <ScrollProgress className="fixed top-0 z-50 h-0.5 bg-[var(--color-accent-violet)]" />
      <div className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="font-heading text-3xl font-bold tracking-tight">
              Explore
            </h1>
            <p className="text-sm text-muted-foreground">
              Discover live stations by country, genre, language, or stream
              health.
            </p>
          </div>
          <div className="relative w-full max-w-xs">
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search stations..."
              aria-label="Filter stations"
            />
            {searching && (
              <Loader2 className="absolute top-1/2 right-3 size-4 -translate-y-1/2 animate-spin text-muted-foreground" />
            )}
          </div>
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
            {displayedStations.length === 0 ? (
              <p className="rounded-xl border border-border bg-card p-6 text-center text-sm text-muted-foreground">
                No stations match those filters.
              </p>
            ) : (
              <AnimatedGroup variants={FADE_UP_VARIANTS} className="space-y-2.5">
                {displayedStations.map((station) => (
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
                  className="group overflow-hidden rounded-xl border border-border bg-card transition-colors hover:bg-muted/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                >
                  <img
                    src={genre.imageUrl}
                    alt={genre.name}
                    className="h-32 w-full border-b border-border object-cover"
                  />
                  <div className="p-4">
                    <h3 className="font-heading text-base font-bold text-foreground">
                      {genre.name}
                    </h3>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {genre.tagline}
                    </p>
                    <p className="mt-2 text-xs font-medium text-foreground">
                      {genre.stationCount} stations
                    </p>
                  </div>
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
