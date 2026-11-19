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
      className="fixed inset-x-0 bottom-16 z-30 border-t border-border bg-card md:bottom-0 md:left-64"
    >
      <div className="mx-auto flex h-20 max-w-7xl items-center justify-between gap-4 px-4 sm:px-6">
        <NowPlayingSheet
          trigger={
            <button
              type="button"
              className="flex min-w-0 flex-1 items-center gap-3 rounded-lg text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring md:max-w-xs"
            >
              <StationArtwork
                name={currentStation.name}
                faviconUrl={currentStation.faviconUrl}
                genres={currentStation.genres}
                size="sm"
              />
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="truncate font-heading text-sm font-bold text-foreground">
                    {currentStation.name}
                  </span>
                  <Badge variant="quality" className="hidden sm:inline-flex">
                    {currentStation.codec}
                  </Badge>
                </div>
                <p className="truncate text-xs text-muted-foreground">
                  {error ??
                    currentStation.currentTrack ??
                    `${currentStation.countryFlag} ${currentStation.countryName}`}
                </p>
              </div>
            </button>
          }
        />

        <div className="flex flex-col items-center gap-1.5">
          <div className="flex items-center gap-3">
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="size-9"
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
                    ? 'fill-red-500 text-red-500'
                    : 'text-muted-foreground',
                )}
              />
            </Button>

            {status === 'unavailable' && currentStation.isHttpsPlayable ? (
              <Button
                type="button"
                variant="outline"
                size="icon"
                className="size-10 rounded-full"
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
                className="size-10 rounded-full"
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
                  <Loader2 className="size-4 animate-spin" />
                ) : isPlaying ? (
                  <Pause className="size-4" />
                ) : (
                  <Play className="size-4 translate-x-[1px]" />
                )}
              </Button>
            )}

            <AudioVisualizer
              isPlaying={isPlaying}
              corsAnalyserActive={corsAnalyserActive}
              levels={analyserLevels}
              className="hidden sm:flex"
            />
          </div>

          <div className="hidden items-center gap-2 sm:flex">
            <span className="flex items-center gap-1 text-[10px] font-medium tracking-wider text-muted-foreground uppercase">
              <span
                className={cn(
                  'size-1.5 rounded-full',
                  isPlaying ? 'bg-[#10B981]' : 'bg-muted-foreground',
                )}
              />
              {status === 'reconnecting'
                ? 'RECONNECTING'
                : isPlaying
                  ? 'LIVE STREAM'
                  : 'READY'}
            </span>
            <div className="h-1 w-40 overflow-hidden rounded-full bg-muted">
              <div
                className={cn(
                  'h-full rounded-full bg-[var(--color-accent-violet)] transition-all duration-300',
                  isPlaying ? 'w-full' : 'w-1/3 opacity-40',
                )}
              />
            </div>
          </div>
        </div>

        <div className="flex shrink-0 items-center gap-2">
          {!currentStation.isHttpsPlayable && (
            <Badge variant="outline" className="hidden gap-1 lg:inline-flex">
              <Smartphone className="size-3" /> Best in the mobile app
            </Badge>
          )}

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

          <NowPlayingSheet
            trigger={
              <Button
                type="button"
                variant="ghost"
                size="icon"
                className="size-9"
                aria-label="Expand now playing"
              >
                <Maximize2 className="size-4 text-muted-foreground" />
              </Button>
            }
          />
        </div>
      </div>
    </aside>
  );
}
