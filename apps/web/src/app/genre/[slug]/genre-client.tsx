'use client';

import { useMemo, useState } from 'react';
import { AppShell } from '@/components/radio/app-shell';
import {
  FilterBar,
  type StationFilterState,
} from '@/components/radio/filter-bar';
import { StationRow } from '@/components/radio/station-row';
import type { WebGenre, WebStation } from '@/lib/mock-data';

export function GenreClient({
  genre,
  initialStations,
}: {
  genre: WebGenre;
  initialStations: WebStation[];
}) {
  const [filter, setFilter] = useState<StationFilterState>({
    workingOnly: true,
    httpsOnly: false,
    sort: 'popular',
    genre: null,
  });

  const stations = useMemo(() => {
    const filtered = initialStations.filter((s) => {
      if (filter.workingOnly && !s.isWorking) return false;
      if (filter.httpsOnly && !s.isHttpsPlayable) return false;
      return true;
    });
    return [...filtered].sort((a, b) => {
      if (filter.sort === 'name') return a.name.localeCompare(b.name);
      if (filter.sort === 'trending') return b.clickCount - a.clickCount;
      return b.votes - a.votes;
    });
  }, [initialStations, filter]);

  return (
    <AppShell>
      <div className="space-y-6">
        <header
          className={`rounded-2xl border border-border bg-gradient-to-br ${genre.gradient} p-6`}
        >
          <h1 className="font-heading text-3xl font-bold text-white">
            {genre.name}
          </h1>
          <p className="mt-1 text-sm text-slate-200">{genre.tagline}</p>
        </header>

        <FilterBar value={filter} onChange={setFilter} genres={[genre.id]} />

        <div className="space-y-2.5">
          {stations.length === 0 ? (
            <p className="rounded-xl border border-border bg-card p-6 text-center text-sm text-muted-foreground">
              No stations match those filters.
            </p>
          ) : (
            stations.map((station) => (
              <StationRow key={station.id} station={station} />
            ))
          )}
        </div>
      </div>
    </AppShell>
  );
}
