'use client';

import Link from 'next/link';
import { useMockSession } from '@/components/mock-session-provider';
import { AppShell } from '@/components/radio/app-shell';
import { StationRow } from '@/components/radio/station-row';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { MOCK_COLLECTIONS, MOCK_STATIONS } from '@/lib/mock-data';

export default function LibraryPage() {
  const { favouriteIds, recentIds } = useMockSession();
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
              {favourites.length} of 30 free favourites used · Syncs when signed
              in
            </p>
          </div>
          <Link href="/pricing">
            <Button variant="outline">Upgrade for Unlimited</Button>
          </Link>
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
            {recents.map((s) => (
              <StationRow key={s.id} station={s} />
            ))}
          </TabsContent>

          <TabsContent value="collections" className="mt-4 grid gap-4 md:grid-cols-3">
            {MOCK_COLLECTIONS.map((col) => (
              <Card key={col.id}>
                <CardHeader>
                  <CardTitle className="text-base">{col.title}</CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                  <p className="text-xs text-muted-foreground">
                    {col.subtitle}
                  </p>
                  <Badge variant="secondary">
                    {col.stationIds.length} stations
                  </Badge>
                </CardContent>
              </Card>
            ))}
          </TabsContent>

          <TabsContent value="history" className="mt-4 space-y-2">
            {[
              { track: 'Burna Boy — City Boys', station: 'Cool FM 96.9 Lagos' },
              { track: 'Khruangbin — Time (You and I)', station: 'FIP Paris' },
              { track: 'Ryo Fukui — Scenery', station: 'Tokyo Jazz Club FM' },
            ].map((item) => (
              <div
                key={item.track}
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
