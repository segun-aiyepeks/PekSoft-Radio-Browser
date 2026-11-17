'use client';

import { Heart, Maximize2, Pause, Play, Volume2 } from 'lucide-react';
import { useMockSession } from '@/components/mock-session-provider';
import { NowPlayingSheet } from '@/components/radio/now-playing-sheet';
import { StationArtwork } from '@/components/radio/station-artwork';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Slider } from '@/components/ui/slider';
import { cn } from '@/lib/utils';

export function PlayerBar() {
  const {
    currentStation,
    isPlaying,
    volume,
    favouriteIds,
    togglePlayPause,
    setVolume,
    toggleFavourite,
  } = useMockSession();

  if (!currentStation) return null;
  const isFav = favouriteIds.includes(currentStation.id);

  return (
    <aside
      aria-label="Persistent radio player"
      className="fixed inset-x-0 bottom-16 z-30 border-t border-border bg-card/95 backdrop-blur md:bottom-0 md:left-60"
    >
      <div className="mx-auto flex h-18 max-w-6xl items-center justify-between gap-3 px-4">
        <NowPlayingSheet
          trigger={
            <button
              type="button"
              className="flex min-w-0 flex-1 items-center gap-3 rounded-lg text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            >
              <StationArtwork
                name={currentStation.name}
                faviconUrl={currentStation.faviconUrl}
                size="sm"
              />
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="truncate font-heading text-sm font-semibold text-foreground">
                    {currentStation.name}
                  </span>
                  {isPlaying && <Badge variant="live">LIVE</Badge>}
                </div>
                <p className="truncate text-xs text-muted-foreground">
                  {currentStation.currentTrack ??
                    `${currentStation.countryFlag} ${currentStation.countryName}`}
                </p>
              </div>
              <Maximize2 className="hidden size-4 shrink-0 text-muted-foreground sm:block" />
            </button>
          }
        />

        <div className="flex shrink-0 items-center gap-2">
          <div className="hidden w-28 items-center gap-2 lg:flex">
            <Volume2 className="size-4 text-muted-foreground" />
            <Slider
              value={[volume]}
              onValueChange={(val) =>
                setVolume(Array.isArray(val) ? (val[0] ?? 80) : val)
              }
              max={100}
              step={1}
              aria-label="Volume"
            />
          </div>

          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="size-10"
            aria-label={
              isFav ? 'Remove current station from favourites' : 'Favourite current station'
            }
            onClick={() => toggleFavourite(currentStation)}
          >
            <Heart
              className={cn(
                'size-4',
                isFav
                  ? 'fill-[var(--color-accent)] text-[var(--color-accent)]'
                  : 'text-muted-foreground',
              )}
            />
          </Button>

          <Button
            type="button"
            variant="signal"
            size="icon"
            className="size-11 rounded-full"
            aria-label={isPlaying ? 'Pause radio' : 'Play radio'}
            onClick={togglePlayPause}
          >
            {isPlaying ? (
              <Pause className="size-5" />
            ) : (
              <Play className="size-5 translate-x-[1px]" />
            )}
          </Button>
        </div>
      </div>
    </aside>
  );
}
