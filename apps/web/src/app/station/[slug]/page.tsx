'use client';

import { use } from 'react';
import Link from 'next/link';
import {
  ExternalLink,
  Heart,
  Pause,
  Play,
  Share2,
  Smartphone,
} from 'lucide-react';
import { toast } from 'sonner';
import { useMockSession } from '@/components/mock-session-provider';
import { AppShell } from '@/components/radio/app-shell';
import { StationArtwork } from '@/components/radio/station-artwork';
import { StationRow } from '@/components/radio/station-row';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { getStationBySlug, MOCK_STATIONS } from '@/lib/mock-data';
import { cn } from '@/lib/utils';

export default function StationDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = use(params);
  const station = getStationBySlug(slug) ?? MOCK_STATIONS[0]!;
  const {
    currentStation,
    isPlaying,
    favouriteIds,
    playStation,
    togglePlayPause,
    toggleFavourite,
  } = useMockSession();

  const isCurrent = currentStation?.id === station.id;
  const isActivePlaying = isCurrent && isPlaying;
  const isFav = favouriteIds.includes(station.id);
  const similar = MOCK_STATIONS.filter((s) => s.id !== station.id).slice(0, 3);

  return (
    <AppShell>
      <div className="space-y-8">
        <section className="flex flex-col gap-6 rounded-3xl border border-border bg-card p-6 sm:flex-row sm:items-center">
          <StationArtwork
            name={station.name}
            faviconUrl={station.faviconUrl}
            size="xl"
          />

          <div className="flex-1 space-y-3">
            <div className="flex flex-wrap items-center gap-2">
              <Badge variant={station.isWorking ? 'live' : 'destructive'}>
                {station.isWorking ? 'WORKING NOW' : 'UNAVAILABLE'}
              </Badge>
              <Badge variant="quality">
                {station.codec}
                {station.bitrateKbps > 0 ? ` · ${station.bitrateKbps} kbps` : ''}
              </Badge>
              {!station.isHttpsPlayable && (
                <Badge variant="outline" className="gap-1">
                  <Smartphone className="size-3" /> Best in the mobile app
                </Badge>
              )}
            </div>

            <h1 className="font-heading text-3xl font-bold">{station.name}</h1>
            <p className="text-sm text-muted-foreground">
              <Link
                href={`/country/${station.countryCode.toLowerCase()}`}
                className="underline-offset-4 hover:underline"
              >
                {station.countryFlag} {station.countryName}
              </Link>{' '}
              · {station.language}
            </p>

            <div className="flex flex-wrap items-center gap-3 pt-2">
              <Button
                variant="signal"
                size="lg"
                onClick={() =>
                  isCurrent ? togglePlayPause() : playStation(station)
                }
              >
                {isActivePlaying ? (
                  <>
                    <Pause className="size-4" /> Pause Live
                  </>
                ) : (
                  <>
                    <Play className="size-4" /> Play Live
                  </>
                )}
              </Button>

              <Button
                variant="outline"
                size="lg"
                onClick={() => toggleFavourite(station)}
              >
                <Heart
                  className={cn(
                    'size-4',
                    isFav &&
                      'fill-[var(--color-accent)] text-[var(--color-accent)]',
                  )}
                />
                {isFav ? 'Saved' : 'Save'}
              </Button>

              <Button
                variant="ghost"
                size="lg"
                onClick={() => toast.success('Station link copied')}
              >
                <Share2 className="size-4" /> Share
              </Button>

              {station.homepage && (
                <a
                  href={station.homepage}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground"
                >
                  Website <ExternalLink className="size-3" />
                </a>
              )}
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <h2 className="font-heading text-xl font-bold">Similar Stations</h2>
          <div className="space-y-2.5">
            {similar.map((s) => (
              <StationRow key={s.id} station={s} />
            ))}
          </div>
        </section>
      </div>
    </AppShell>
  );
}
