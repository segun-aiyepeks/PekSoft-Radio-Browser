'use client';

import Link from 'next/link';
import { Heart, Pause, Play, Smartphone } from 'lucide-react';
import { useMockSession } from '@/components/mock-session-provider';
import { CountryFlag } from '@/components/radio/country-flag';
import { StationArtwork } from '@/components/radio/station-artwork';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import type { WebStation } from '@/lib/mock-data';
import { cn } from '@/lib/utils';

export function StationRow({ station }: { station: WebStation }) {
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

  return (
    <div
      className={cn(
        'group flex items-center gap-3 rounded-xl border border-border bg-card p-3 transition-colors hover:bg-muted/40',
        isCurrent && 'border-[var(--color-accent-violet)]',
      )}
    >
      <Link
        href={`/station/${station.slug}`}
        className="flex min-w-0 flex-1 items-center gap-3 rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
      >
        <StationArtwork
          name={station.name}
          faviconUrl={station.faviconUrl}
          genres={station.genres}
        />

        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <span className="truncate font-heading text-sm font-bold text-foreground sm:text-base">
              {station.name}
            </span>
            {isActivePlaying && (
              <Badge variant="live">
                <span className="size-1.5 rounded-full bg-[#10B981]" />
                ON AIR
              </Badge>
            )}
            {!station.isHttpsPlayable && (
              <Badge variant="outline" className="gap-1 text-[11px]">
                <Smartphone className="size-3" /> Best in the mobile app
              </Badge>
            )}
          </div>

          <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1.5">
              <CountryFlag
                code={station.countryCode}
                name={station.countryName}
                emojiFallback={station.countryFlag}
                size="xs"
              />
              {station.countryName}
            </span>
            {station.genres.slice(0, 2).map((genre) => (
              <Badge key={genre} variant="secondary" className="text-[11px]">
                {genre}
              </Badge>
            ))}
            <Badge variant="quality" className="text-[11px]">
              {station.codec}
              {station.bitrateKbps > 0 ? ` · ${station.bitrateKbps}k` : ''}
            </Badge>
          </div>
        </div>
      </Link>

      <div className="flex shrink-0 items-center gap-1.5">
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="size-10"
          aria-label={
            isFav
              ? `Remove ${station.name} from favourites`
              : `Save ${station.name} to favourites`
          }
          onClick={() => toggleFavourite(station)}
        >
          <Heart
            className={cn(
              'size-4',
              isFav
                ? 'fill-red-500 text-red-500'
                : 'text-muted-foreground',
            )}
          />
        </Button>

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
    </div>
  );
}
