'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { Heart, Pause, Play, Share2 } from 'lucide-react';
import { toast } from 'sonner';
import { useMockSession } from '@/components/mock-session-provider';
import { usePlayer } from '@/components/player/player-provider';
import { AudioVisualizer } from '@/components/radio/audio-visualizer';
import { CountryFlag } from '@/components/radio/country-flag';
import { StationArtwork } from '@/components/radio/station-artwork';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import type { WebStation } from '@/lib/mock-data';
import { cn } from '@/lib/utils';

export function LandingLiveCard({ station }: { station: WebStation }) {
  const { favouriteIds, toggleFavourite } = useMockSession();
  const {
    currentStation,
    isPlaying,
    playStation,
    seedDefaultStation,
    togglePlayPause,
  } = usePlayer();

  useEffect(() => {
    seedDefaultStation(station);
  }, [seedDefaultStation, station]);

  const activeStation = currentStation ?? station;
  const isCurrentPlaying = isPlaying && currentStation?.id === activeStation.id;
  const isFav = favouriteIds.includes(activeStation.id);

  return (
    <Card className="border-border bg-card">
      <CardContent className="space-y-5 p-6">
        <div className="flex items-center justify-between gap-2">
          <Badge variant="live">
            <span className="size-1.5 rounded-full bg-[#10B981]" />
            Working Now (HTTP 200)
          </Badge>
          <Badge variant="quality">
            {activeStation.bitrateKbps > 0
              ? `${activeStation.bitrateKbps} KBPS`
              : 'HQ'}{' '}
            · {activeStation.codec}
          </Badge>
        </div>

        <div className="flex items-center gap-4">
          <StationArtwork
            name={activeStation.name}
            faviconUrl={activeStation.faviconUrl}
            genres={activeStation.genres}
            size="lg"
          />
          <div className="min-w-0 flex-1">
            <p className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
              <CountryFlag
                code={activeStation.countryCode}
                name={activeStation.countryName}
                emojiFallback={activeStation.countryFlag}
                size="xs"
              />
              {activeStation.countryName}
            </p>
            <Link
              href={`/station/${activeStation.slug}`}
              className="mt-0.5 block truncate font-heading text-lg font-bold text-foreground hover:underline"
            >
              {activeStation.name}
            </Link>
            <p className="mt-0.5 truncate text-xs text-muted-foreground">
              {activeStation.currentTrack ??
                `${activeStation.language} · Live Broadcast`}
            </p>
          </div>
        </div>

        <div className="rounded-lg border border-border bg-muted/40 p-3.5">
          <div className="mb-2 flex items-center justify-between text-[11px] font-medium text-muted-foreground">
            <span>Stream Signal</span>
            <span className="text-[#10B981]">
              {isCurrentPlaying ? 'Streaming Live' : 'Ready to Stream'}
            </span>
          </div>
          <div className="flex h-7 items-center justify-center gap-2">
            <AudioVisualizer isPlaying={isCurrentPlaying} className="h-6 gap-1.5" />
            <AudioVisualizer isPlaying={isCurrentPlaying} className="h-6 gap-1.5" />
          </div>
        </div>

        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <Button
              type="button"
              variant="outline"
              size="icon"
              className="size-9"
              aria-label="Favourite station"
              onClick={() => toggleFavourite(activeStation)}
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
              variant="outline"
              size="icon"
              className="size-9"
              aria-label="Share station"
              onClick={() => toast.success('Station link copied')}
            >
              <Share2 className="size-4 text-muted-foreground" />
            </Button>
          </div>

          <Button
            type="button"
            variant="signal"
            size="lg"
            onClick={() =>
              currentStation?.id === activeStation.id
                ? togglePlayPause()
                : playStation(activeStation)
            }
          >
            {isCurrentPlaying ? (
              <>
                <Pause className="size-4" /> Streaming Live
              </>
            ) : (
              <>
                <Play className="size-4" /> Listen Live Now
              </>
            )}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
