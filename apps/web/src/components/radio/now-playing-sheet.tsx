'use client';

import {
  Flag,
  Heart,
  Loader2,
  Pause,
  Play,
  RotateCcw,
  Share2,
  Smartphone,
  Timer,
  Volume2,
  VolumeX,
} from 'lucide-react';
import { toast } from 'sonner';
import { useMockSession } from '@/components/mock-session-provider';
import { usePlayer } from '@/components/player/player-provider';
import { AudioVisualizer } from '@/components/radio/audio-visualizer';
import { CountryFlag } from '@/components/radio/country-flag';
import { StationArtwork } from '@/components/radio/station-artwork';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from '@/components/ui/sheet';
import { Slider } from '@/components/ui/slider';
import { cn } from '@/lib/utils';

export function NowPlayingSheet({ trigger }: { trigger: React.ReactNode }) {
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

  const statusLabel =
    status === 'playing'
      ? 'LIVE'
      : status === 'connecting'
        ? 'CONNECTING'
        : status === 'reconnecting'
          ? 'RECONNECTING'
          : status === 'unavailable'
            ? 'UNAVAILABLE'
            : 'PAUSED';

  return (
    <Sheet>
      <SheetTrigger render={trigger as React.ReactElement} />
      <SheetContent className="flex flex-col justify-between sm:max-w-md">
        <div>
          <SheetHeader>
            <SheetTitle>Now Playing</SheetTitle>
            <SheetDescription className="flex items-center gap-1.5">
              <CountryFlag
                code={currentStation.countryCode}
                name={currentStation.countryName}
                emojiFallback={currentStation.countryFlag}
                size="xs"
              />
              <span>
                {currentStation.countryName} · {currentStation.language}
              </span>
            </SheetDescription>
          </SheetHeader>

          <div className="mt-6 flex flex-col items-center text-center">
            <StationArtwork
              name={currentStation.name}
              faviconUrl={currentStation.faviconUrl}
              genres={currentStation.genres}
              size="xl"
            />
            <h3 className="mt-4 font-heading text-xl font-bold">
              {currentStation.name}
            </h3>
            <p className="mt-1 text-sm text-muted-foreground">
              {error ?? currentStation.currentTrack ?? 'Live radio broadcast'}
            </p>

            <div className="mt-3 flex flex-wrap items-center justify-center gap-2">
              <Badge variant={isPlaying ? 'live' : 'outline'}>
                {statusLabel}
              </Badge>
              <Badge variant="quality">
                {currentStation.codec} · {currentStation.bitrateKbps} kbps
              </Badge>
              {!currentStation.isHttpsPlayable && (
                <Badge variant="outline" className="gap-1">
                  <Smartphone className="size-3" /> Best in the mobile app
                </Badge>
              )}
              <AudioVisualizer
                isPlaying={isPlaying}
                corsAnalyserActive={corsAnalyserActive}
                levels={analyserLevels}
              />
            </div>

            <div className="mt-8 flex items-center gap-4">
              <Button
                type="button"
                variant="outline"
                size="icon"
                className="size-12 rounded-full"
                aria-label="Toggle favourite"
                onClick={() => toggleFavourite(currentStation)}
              >
                <Heart
                  className={cn(
                    'size-5',
                    isFav && 'fill-red-500 text-red-500',
                  )}
                />
              </Button>

              {status === 'unavailable' && currentStation.isHttpsPlayable ? (
                <Button
                  type="button"
                  variant="signal"
                  size="icon"
                  className="size-14 rounded-full"
                  aria-label="Retry stream"
                  onClick={retry}
                >
                  <RotateCcw className="size-6" />
                </Button>
              ) : (
                <Button
                  type="button"
                  variant="signal"
                  size="icon"
                  className="size-14 rounded-full"
                  aria-label={
                    isBuffering
                      ? 'Cancel connecting'
                      : isPlaying
                        ? 'Pause stream'
                        : 'Play stream'
                  }
                  onClick={togglePlayPause}
                >
                  {isBuffering ? (
                    <Loader2 className="size-6 animate-spin" />
                  ) : isPlaying ? (
                    <Pause className="size-6" />
                  ) : (
                    <Play className="size-6 translate-x-[1px]" />
                  )}
                </Button>
              )}

              <Button
                type="button"
                variant="outline"
                size="icon"
                className="size-12 rounded-full"
                aria-label="Share station"
                onClick={() =>
                  toast.success(
                    `Share link copied: /station/${currentStation.slug}`,
                  )
                }
              >
                <Share2 className="size-5" />
              </Button>
            </div>

            <div className="mt-8 flex w-full items-center gap-3 px-2">
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
                aria-label="Player volume"
              />
              <span className="w-9 text-right font-mono text-xs text-muted-foreground">
                {isMuted ? 0 : volume}%
              </span>
            </div>
          </div>
        </div>

        <div className="mt-6 flex items-center justify-between border-t border-border pt-4">
          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={() => toast.info('Sleep timer set for 30 minutes')}
          >
            <Timer className="size-4" /> Sleep Timer
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={() => toast.info('Station report submitted')}
          >
            <Flag className="size-4" /> Report Broken
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  );
}
