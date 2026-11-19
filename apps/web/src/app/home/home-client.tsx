'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import {
  Activity,
  Flag,
  Heart,
  Pause,
  Play,
  Radio,
  Shuffle,
  Sparkles,
} from 'lucide-react';
import { toast } from 'sonner';
import { AdSlot } from '@/components/ads/ad-slot';
import { useMockSession } from '@/components/mock-session-provider';
import { AnimatedGroup } from '@/components/motion-primitives/animated-group';
import { InView } from '@/components/motion-primitives/in-view';
import { ScrollProgress } from '@/components/motion-primitives/scroll-progress';
import { usePlayer } from '@/components/player/player-provider';
import { AppShell } from '@/components/radio/app-shell';
import { AudioVisualizer } from '@/components/radio/audio-visualizer';
import { CountryFlag } from '@/components/radio/country-flag';
import { StationArtwork } from '@/components/radio/station-artwork';
import { StationCard } from '@/components/radio/station-card';
import { StationRow } from '@/components/radio/station-row';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { FADE_UP_VARIANTS, TRANSITION_NORMAL } from '@/lib/motion';
import {
  MOCK_COLLECTIONS,
  type WebGenre,
  type WebStation,
} from '@/lib/mock-data';
import { cn } from '@/lib/utils';

export function HomeClient({
  trendingStations,
  nigeriaStations,
  genres,
}: {
  trendingStations: WebStation[];
  nigeriaStations: WebStation[];
  genres: WebGenre[];
}) {
  const { recentIds, favouriteIds, playSurpriseMe, toggleFavourite } =
    useMockSession();
  const {
    currentStation,
    isPlaying,
    playStation,
    seedDefaultStation,
    togglePlayPause,
  } = usePlayer();

  const spotlight =
    trendingStations.find((s) => s.isHttpsPlayable) ?? trendingStations[0];

  useEffect(() => {
    if (spotlight) {
      seedDefaultStation(spotlight);
    }
  }, [spotlight, seedDefaultStation]);
  const activeInspectorStation = currentStation ?? spotlight;
  const isSpotlightPlaying =
    Boolean(spotlight) && isPlaying && currentStation?.id === spotlight?.id;

  const continueStations = trendingStations.filter((s) =>
    recentIds.includes(s.id),
  );

  return (
    <AppShell>
      <ScrollProgress className="fixed top-0 z-50 h-0.5 bg-[var(--color-accent-violet)]" />
      <div className="space-y-8">
        {/* Welcome & Stream Status */}
        <section className="flex flex-col justify-between gap-4 lg:flex-row lg:items-end">
          <div className="space-y-1">
            <h1 className="font-heading text-3xl font-bold tracking-tight">
              Discover Live Radio
            </h1>
            <p className="text-sm text-muted-foreground">
              Verified working stations · Working now filter ON
            </p>
          </div>

          <div className="flex items-center gap-3 rounded-xl border border-border bg-card px-4 py-3">
            <div className="flex size-9 items-center justify-center rounded-lg bg-muted text-foreground">
              <Radio className="size-4" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-heading text-sm font-bold">
                  38,420 Streams
                </span>
                <Badge variant="live">99.4%</Badge>
              </div>
              <p className="text-xs text-muted-foreground">
                Radio Browser mirror synchronized
              </p>
            </div>
          </div>
        </section>

        {/* Quick Action Hub Chips */}
        <section
          aria-label="Quick genre and hub shortcuts"
          className="flex flex-wrap items-center gap-2"
        >
          <Button variant="signal" size="sm" onClick={playSurpriseMe}>
            <Shuffle className="size-3.5" /> Surprise Me
          </Button>
          <Link href="/country/ng">
            <Badge
              variant="secondary"
              className="gap-1.5 px-3 py-1.5 text-xs hover:bg-muted"
            >
              <CountryFlag code="NG" name="Nigeria" size="xs" /> Nigeria Hub
            </Badge>
          </Link>
          {genres.map((genre) => (
            <Link key={genre.id} href={`/genre/${genre.slug}`}>
              <Badge
                variant="secondary"
                className="px-3 py-1.5 text-xs hover:bg-muted"
              >
                {genre.name}
              </Badge>
            </Link>
          ))}
        </section>

        {/* Two-Column Dashboard */}
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-12">
          {/* Center Stage (8 cols) */}
          <div className="space-y-8 lg:col-span-8">
            {/* Spotlight Station Card */}
            {spotlight && (
              <Card className="border-border bg-card">
                <CardContent className="space-y-5 p-6">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge variant="live">99.8% Healthy Stream</Badge>
                      <Badge variant="quality">
                        {spotlight.codec} · {spotlight.bitrateKbps || 128} kbps
                      </Badge>
                    </div>
                    <span className="text-xs text-muted-foreground">
                      {spotlight.clickCount.toLocaleString()} listeners
                    </span>
                  </div>

                  <div className="flex flex-col gap-5 sm:flex-row sm:items-center">
                    <StationArtwork
                      name={spotlight.name}
                      faviconUrl={spotlight.faviconUrl}
                      genres={spotlight.genres}
                      size="xl"
                    />
                    <div className="min-w-0 flex-1 space-y-1.5">
                      <p className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                        <span>Spotlight ·</span>
                        <CountryFlag
                          code={spotlight.countryCode}
                          name={spotlight.countryName}
                          emojiFallback={spotlight.countryFlag}
                          size="xs"
                        />
                        <span>{spotlight.countryName}</span>
                      </p>
                      <h2 className="truncate font-heading text-2xl font-bold text-foreground">
                        {spotlight.name}
                      </h2>
                      <p className="truncate text-sm text-muted-foreground">
                        {spotlight.currentTrack ??
                          `${spotlight.language} · Live Broadcast`}
                      </p>
                      <AudioVisualizer
                        isPlaying={isSpotlightPlaying}
                        className="pt-1"
                      />
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center gap-3">
                    <Button
                      variant="signal"
                      size="lg"
                      onClick={() =>
                        currentStation?.id === spotlight.id
                          ? togglePlayPause()
                          : playStation(spotlight)
                      }
                    >
                      {isSpotlightPlaying ? (
                        <>
                          <Pause className="size-4" /> Pause Broadcast
                        </>
                      ) : (
                        <>
                          <Play className="size-4" /> Play Now (
                          {spotlight.bitrateKbps || 128}k)
                        </>
                      )}
                    </Button>

                    <Button
                      variant="outline"
                      size="icon"
                      className="size-10"
                      aria-label="Favourite spotlight station"
                      onClick={() => toggleFavourite(spotlight)}
                    >
                      <Heart
                        className={cn(
                          'size-4',
                          favouriteIds.includes(spotlight.id) &&
                            'fill-red-500 text-red-500',
                        )}
                      />
                    </Button>

                    <Link href={`/station/${spotlight.slug}`}>
                      <Button variant="outline">Station Details</Button>
                    </Link>
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Recently Tuned */}
            {continueStations.length > 0 && (
              <section className="space-y-3">
                <h2 className="font-heading text-xl font-bold">
                  Recently Tuned
                </h2>
                <AnimatedGroup
                  variants={FADE_UP_VARIANTS}
                  className="grid gap-4 sm:grid-cols-2"
                >
                  {continueStations.map((station) => (
                    <StationCard key={station.id} station={station} />
                  ))}
                </AnimatedGroup>
              </section>
            )}

            {/* Curated Collections */}
            <section className="space-y-3">
              <div className="flex items-center gap-2">
                <Sparkles className="size-4 text-muted-foreground" />
                <h2 className="font-heading text-xl font-bold">
                  Curated Collections
                </h2>
              </div>
              <div className="grid gap-4 md:grid-cols-3">
                {MOCK_COLLECTIONS.map((col, idx) => {
                  const colImages = [
                    '/images/genres/afrobeats.jpg',
                    '/images/genres/jazz.jpg',
                    '/images/genres/news.jpg',
                  ];
                  const colImg = col.imageUrl ?? colImages[idx % colImages.length]!;
                  return (
                    <Link
                      key={col.id}
                      href="/explore"
                      className="group relative flex min-h-44 flex-col justify-end overflow-hidden rounded-xl border border-border p-5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    >
                      <img
                        src={colImg}
                        alt=""
                        aria-hidden="true"
                        className="absolute inset-0 size-full object-cover transition-transform duration-300 group-hover:scale-105"
                      />
                      <div
                        aria-hidden="true"
                        className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/45 to-black/20"
                      />
                      <div className="relative z-10 space-y-1.5">
                        <Badge
                          variant="secondary"
                          className="border-white/20 bg-black/50 text-white"
                        >
                          {col.stationIds.length} stations
                        </Badge>
                        <h3 className="font-heading text-base font-bold text-white">
                          {col.title}
                        </h3>
                        <p className="text-xs text-slate-200">{col.subtitle}</p>
                      </div>
                    </Link>
                  );
                })}
              </div>
            </section>

            {/* Radio from Nigeria */}
            <section className="space-y-3">
              <div className="flex items-center justify-between">
                <h2 className="flex items-center gap-2 font-heading text-xl font-bold">
                  <CountryFlag code="NG" name="Nigeria" size="sm" />
                  Radio from Nigeria
                </h2>
                <Link href="/country/ng">
                  <Button variant="ghost" size="sm">
                    See all
                  </Button>
                </Link>
              </div>
              <InView
                once
                variants={{
                  hidden: { opacity: 0, y: 10 },
                  visible: { opacity: 1, y: 0 },
                }}
                transition={TRANSITION_NORMAL}
              >
                <div className="space-y-2.5">
                  {nigeriaStations.map((station) => (
                    <StationRow key={station.id} station={station} />
                  ))}
                </div>
              </InView>
            </section>

            {/* Trending Now */}
            <section className="space-y-3">
              <h2 className="font-heading text-xl font-bold">Trending Now</h2>
              <div className="space-y-2.5">
                {trendingStations.slice(0, 6).map((station) => (
                  <StationRow key={station.id} station={station} />
                ))}
              </div>
            </section>

            <AdSlot variant="banner" />
          </div>

          {/* Right Stream Inspector Rail (4 cols) */}
          <aside
            aria-label="Stream Inspector"
            className="space-y-5 lg:col-span-4"
          >
            {activeInspectorStation && (
              <Card className="border-border bg-card">
                <CardContent className="space-y-4 p-5">
                  <div className="flex items-center justify-between">
                    <span className="flex items-center gap-2 text-xs font-semibold text-muted-foreground uppercase">
                      <Activity className="size-3.5 text-[#10B981]" />
                      Stream Inspector
                    </span>
                    <Badge variant="quality">TELEMETRY</Badge>
                  </div>

                  <div>
                    <p className="font-heading text-lg font-bold">
                      {activeInspectorStation.name}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {activeInspectorStation.countryFlag}{' '}
                      {activeInspectorStation.countryName} ·{' '}
                      {activeInspectorStation.language}
                    </p>
                  </div>

                  <dl className="space-y-2.5 rounded-lg border border-border bg-muted/30 p-3.5 text-xs">
                    <div className="flex items-center justify-between">
                      <dt className="text-muted-foreground">
                        Codec &amp; Bitrate
                      </dt>
                      <dd className="font-medium text-foreground">
                        {activeInspectorStation.codec} ·{' '}
                        {activeInspectorStation.bitrateKbps || 128} kbps
                      </dd>
                    </div>
                    <div className="flex items-center justify-between">
                      <dt className="text-muted-foreground">
                        Browser Playback
                      </dt>
                      <dd className="font-medium text-[#10B981]">
                        {activeInspectorStation.isHttpsPlayable
                          ? 'Direct HTTPS Verified'
                          : 'HTTP (Mobile App)'}
                      </dd>
                    </div>
                    <div className="flex items-center justify-between">
                      <dt className="text-muted-foreground">Community Votes</dt>
                      <dd className="font-medium text-foreground">
                        {activeInspectorStation.votes.toLocaleString()}
                      </dd>
                    </div>
                  </dl>

                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="w-full justify-start text-xs text-muted-foreground"
                    onClick={() => toast.info('Station health report submitted')}
                  >
                    <Flag className="size-3.5" /> Report Broken Stream
                  </Button>
                </CardContent>
              </Card>
            )}

            <Card className="border-border bg-card">
              <CardContent className="space-y-3 p-5">
                <p className="text-xs font-semibold text-muted-foreground uppercase">
                  PekSoft Plus
                </p>
                <h3 className="font-heading text-base font-bold text-foreground">
                  Ad-Free Listening &amp; Unlimited Library
                </h3>
                <p className="text-xs text-muted-foreground">
                  Save unlimited stations, unlock advanced bitrate/HTTPS
                  filters, and sync across Android &amp; Web.
                </p>
                <Link href="/pricing" className="block pt-1">
                  <Button variant="signal" className="w-full">
                    Explore Plus · ₦1,200/mo
                  </Button>
                </Link>
              </CardContent>
            </Card>
          </aside>
        </div>
      </div>
    </AppShell>
  );
}
