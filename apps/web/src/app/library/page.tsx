'use client';

import Link from 'next/link';
import { RefreshCw } from 'lucide-react';
import { useAuth } from '@/components/auth/auth-provider';
import { useMockSession } from '@/components/mock-session-provider';
import { AppShell } from '@/components/radio/app-shell';
import { StationRow } from '@/components/radio/station-row';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { MOCK_COLLECTIONS, MOCK_STATIONS } from '@/lib/mock-data';
import { cn } from '@/lib/utils';

export default function LibraryPage() {
  const { user } = useAuth();
  const {
    favouriteIds,
    recentIds,
    collections,
    songHistory,
    syncing,
    isPlus,
    syncNow,
  } = useMockSession();

  const favourites = MOCK_STATIONS.filter((s) => favouriteIds.includes(s.id));
  const recents = MOCK_STATIONS.filter((s) => recentIds.includes(s.id));

  return (
    <AppShell>
      <div className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="font-heading text-3xl font-bold tracking-tight">
              Library
            </h1>
            <p className="text-sm text-muted-foreground">
              {isPlus
                ? `${favourites.length} favourites · Unlimited Plus library`
                : `${favourites.length} of 30 free favourites used · ${
                    user ? 'Synced with your account' : 'Sign in to sync'
                  }`}
            </p>
          </div>
          <div className="flex items-center gap-2">
            {user ? (
              <Button
                type="button"
                variant="outline"
                disabled={syncing}
                onClick={() => void syncNow()}
              >
                <RefreshCw
                  className={cn('size-4', syncing && 'animate-spin')}
                />
                {syncing ? 'Syncing…' : 'Sync now'}
              </Button>
            ) : (
              <Link href="/auth">
                <Button variant="signal">Sign In to Sync</Button>
              </Link>
            )}
            {!isPlus && (
              <Link href="/pricing">
                <Button variant="outline">Upgrade for Unlimited</Button>
              </Link>
            )}
          </div>
        </div>

        <Tabs defaultValue="favourites">
          <TabsList>
            <TabsTrigger value="favourites">Favourites</TabsTrigger>
            <TabsTrigger value="recents">Recently Played</TabsTrigger>
            <TabsTrigger value="collections">Collections</TabsTrigger>
            <TabsTrigger value="history">Song History</TabsTrigger>
          </TabsList>

          <TabsContent value="favourites" className="mt-4 space-y-2.5">
            {favourites.length === 0 ? (
              <p className="rounded-xl border border-border bg-card p-6 text-center text-sm text-muted-foreground">
                Tap the heart on any station to save it here.
              </p>
            ) : (
              favourites.map((s) => <StationRow key={s.id} station={s} />)
            )}
          </TabsContent>

          <TabsContent value="recents" className="mt-4 space-y-2.5">
            {recents.length === 0 ? (
              <p className="rounded-xl border border-border bg-card p-6 text-center text-sm text-muted-foreground">
                Stations you play will appear here.
              </p>
            ) : (
              recents.map((s) => <StationRow key={s.id} station={s} />)
            )}
          </TabsContent>

          <TabsContent
            value="collections"
            className="mt-4 grid gap-4 md:grid-cols-3"
          >
            {(collections.length > 0
              ? collections.map((c) => ({
                  id: c.id,
                  title: c.name,
                  subtitle: c.description ?? 'Synced collection',
                  count: c.items.length,
                }))
              : MOCK_COLLECTIONS.map((c) => ({
                  id: c.id,
                  title: c.title,
                  subtitle: c.subtitle,
                  count: c.stationIds.length,
                }))
            ).map((col) => (
              <Card key={col.id}>
                <CardHeader>
                  <CardTitle className="text-base">{col.title}</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                  <p className="text-xs text-muted-foreground">
                    {col.subtitle}
                  </p>
                  <Badge variant="secondary">{col.count} stations</Badge>
                </CardContent>
              </Card>
            ))}
          </TabsContent>

          <TabsContent value="history" className="mt-4 space-y-2">
            {(songHistory.length > 0
              ? songHistory.map((h) => ({
                  id: h.id,
                  track: h.trackTitle,
                  station: h.stationName,
                }))
              : [
                  {
                    id: 'mock-1',
                    track: 'Burna Boy — City Boys',
                    station: 'Cool FM 96.9 Lagos',
                  },
                  {
                    id: 'mock-2',
                    track: 'Khruangbin — Time (You and I)',
                    station: 'FIP Paris',
                  },
                  {
                    id: 'mock-3',
                    track: 'Ryo Fukui — Scenery',
                    station: 'Tokyo Jazz Club FM',
                  },
                ]
            ).map((item) => (
              <div
                key={item.id}
                className="flex items-center justify-between rounded-xl border border-border bg-card px-4 py-3 text-sm"
              >
                <span className="font-medium">{item.track}</span>
                <span className="text-xs text-muted-foreground">
                  {item.station}
                </span>
              </div>
            ))}
          </TabsContent>
        </Tabs>
      </div>
    </AppShell>
  );
}
