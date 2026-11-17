'use client';

import {
  Heart,
  Loader2,
  Maximize2,
  Pause,
  Play,
  RotateCcw,
  Smartphone,
  Volume2,
  VolumeX,
} from 'lucide-react';
import { useMockSession } from '@/components/mock-session-provider';
import { usePlayer } from '@/components/player/player-provider';
import { AudioVisualizer } from '@/components/radio/audio-visualizer';
import { NowPlayingSheet } from '@/components/radio/now-playing-sheet';
import { StationArtwork } from '@/components/radio/station-artwork';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Slider } from '@/components/ui/slider';
import { cn } from '@/lib/utils';

export function PlayerBar() {
  const { favouriteIds, toggleFavourite } = useMockSession();
  const {
    currentStation,
    status,
    isPlaying,
    isBuffering,
    error,
    volume,
    isMuted,
    corsAnalyserActive,
    analyserLevels,
    togglePlayPause,
    retry,
    setVolume,
    toggleMute,
  } = usePlayer();

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
                  {status === 'reconnecting' && (
                    <Badge variant="outline" className="text-[11px]">
                      Reconnecting…
                    </Badge>
                  )}
                  {!currentStation.isHttpsPlayable && (
                    <Badge variant="outline" className="hidden gap-1 sm:inline-flex">
                      <Smartphone className="size-3" /> Best in the mobile app
                    </Badge>
                  )}
                </div>
                <p className="truncate text-xs text-muted-foreground">
                  {error ??
                    currentStation.currentTrack ??
                    `${currentStation.countryFlag} ${currentStation.countryName}`}
                </p>
              </div>
              <AudioVisualizer
                isPlaying={isPlaying}
                corsAnalyserActive={corsAnalyserActive}
                levels={analyserLevels}
                className="hidden sm:flex"
              />
              <Maximize2 className="hidden size-4 shrink-0 text-muted-foreground sm:block" />
            </button>
          }
        />

        <div className="flex shrink-0 items-center gap-2">
          <div className="hidden w-32 items-center gap-1.5 lg:flex">
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="size-8 shrink-0"
              aria-label={isMuted ? 'Unmute audio' : 'Mute audio'}
              onClick={toggleMute}
            >
              {isMuted || volume === 0 ? (
                <VolumeX className="size-4 text-muted-foreground" />
              ) : (
                <Volume2 className="size-4 text-muted-foreground" />
              )}
            </Button>
            <Slider
              value={[isMuted ? 0 : volume]}
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
              isFav
                ? 'Remove current station from favourites'
                : 'Favourite current station'
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

          {status === 'unavailable' && currentStation.isHttpsPlayable ? (
            <Button
              type="button"
              variant="outline"
              size="icon"
              className="size-11 rounded-full"
              aria-label="Retry stream"
              onClick={retry}
            >
              <RotateCcw className="size-4" />
            </Button>
          ) : (
            <Button
              type="button"
              variant="signal"
              size="icon"
              className="size-11 rounded-full"
              aria-label={
                isBuffering
                  ? 'Cancel connecting'
                  : isPlaying
                    ? 'Pause radio'
                    : 'Play radio'
              }
              onClick={togglePlayPause}
            >
              {isBuffering ? (
                <Loader2 className="size-5 animate-spin" />
              ) : isPlaying ? (
                <Pause className="size-5" />
              ) : (
                <Play className="size-5 translate-x-[1px]" />
              )}
            </Button>
          )}
        </div>
      </div>
    </aside>
  );
}
