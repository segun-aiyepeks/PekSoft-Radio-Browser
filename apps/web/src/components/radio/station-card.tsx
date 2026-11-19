'use client';

import Link from 'next/link';
import { Pause, Play, Smartphone } from 'lucide-react';
import { useMockSession } from '@/components/mock-session-provider';
import { CountryFlag } from '@/components/radio/country-flag';
import { StationArtwork } from '@/components/radio/station-artwork';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import type { WebStation } from '@/lib/mock-data';
import { cn } from '@/lib/utils';

export function StationCard({ station }: { station: WebStation }) {
  const { currentStation, isPlaying, playStation, togglePlayPause } =
    useMockSession();
  const isCurrent = currentStation?.id === station.id;
  const isActivePlaying = isCurrent && isPlaying;

  return (
    <Card
      className={cn(
        'group border-border bg-card transition-colors hover:bg-muted/40',
        isCurrent && 'border-[var(--color-accent-violet)]',
      )}
    >
      <CardContent className="flex flex-col gap-3 p-4">
        <div className="flex items-start justify-between gap-3">
          <Link
            href={`/station/${station.slug}`}
            className="rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <StationArtwork
              name={station.name}
              faviconUrl={station.faviconUrl}
              genres={station.genres}
              size="lg"
            />
          </Link>
          <Button
            type="button"
            variant={isActivePlaying ? 'signal' : 'secondary'}
            size="icon"
            className="size-10 rounded-full"
            aria-label={
              isActivePlaying
                ? `Pause ${station.name}`
                : `Play ${station.name}`
            }
            onClick={() =>
              isCurrent ? togglePlayPause() : playStation(station)
            }
          >
            {isActivePlaying ? (
              <Pause className="size-4" />
            ) : (
              <Play className="size-4 translate-x-[1px]" />
            )}
          </Button>
        </div>

        <Link
          href={`/station/${station.slug}`}
          className="space-y-1 rounded-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <h3 className="truncate font-heading text-base font-bold text-foreground">
            {station.name}
          </h3>
          <p className="flex items-center gap-1.5 truncate text-xs text-muted-foreground">
            <CountryFlag
              code={station.countryCode}
              name={station.countryName}
              emojiFallback={station.countryFlag}
              size="xs"
            />
            <span className="truncate">
              {station.countryName} · {station.language}
            </span>
          </p>
        </Link>

        <div className="flex flex-wrap items-center gap-1.5">
          {station.isWorking && <Badge variant="live">LIVE</Badge>}
          <Badge variant="quality">
            {station.codec}
            {station.bitrateKbps > 0 ? ` ${station.bitrateKbps}k` : ''}
          </Badge>
          {!station.isHttpsPlayable && (
            <Badge variant="outline" className="gap-1 text-[11px]">
              <Smartphone className="size-3" /> Best in the mobile app
            </Badge>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
