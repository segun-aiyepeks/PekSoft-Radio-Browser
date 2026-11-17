'use client';

import { use, useMemo, useState } from 'react';
import { AppShell } from '@/components/radio/app-shell';
import {
  FilterBar,
  type StationFilterState,
} from '@/components/radio/filter-bar';
import { StationRow } from '@/components/radio/station-row';
import { Badge } from '@/components/ui/badge';
import { getCountryByCode, MOCK_STATIONS } from '@/lib/mock-data';

export default function CountryDetailPage({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = use(params);
  const country = getCountryByCode(code) ?? {
    code: code.toUpperCase(),
    name: code.toUpperCase(),
    flag: '🌍',
    stationCount: 0,
    workingCount: 0,
  };

  const [filter, setFilter] = useState<StationFilterState>({
    workingOnly: true,
    httpsOnly: false,
    sort: 'popular',
    genre: null,
  });

  const stations = useMemo(() => {
    return MOCK_STATIONS.filter((s) => {
      if (s.countryCode.toLowerCase() !== country.code.toLowerCase()) {
        return false;
      }
      if (filter.workingOnly && !s.isWorking) return false;
      if (filter.httpsOnly && !s.isHttpsPlayable) return false;
      if (filter.genre && !s.genres.includes(filter.genre)) return false;
      return true;
    });
  }, [country.code, filter]);

  return (
    <AppShell>
      <div className="space-y-6">
        <header className="flex flex-wrap items-center gap-4 rounded-2xl border border-border bg-card p-6">
          <span className="flex size-16 items-center justify-center rounded-2xl bg-muted text-4xl">
            {country.flag}
          </span>
          <div>
            <h1 className="font-heading text-3xl font-bold">{country.name}</h1>
            <div className="mt-1 flex items-center gap-2 text-sm text-muted-foreground">
              <span>{country.stationCount} total stations</span>
              <Badge variant="live">{country.workingCount} working now</Badge>
            </div>
          </div>
        </header>

        <FilterBar value={filter} onChange={setFilter} />

        <div className="space-y-2.5">
          {stations.length === 0 ? (
            <p className="rounded-xl border border-border bg-card p-6 text-center text-sm text-muted-foreground">
              No mock stations for {country.name} match those filters yet.
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
