'use client';

import Link from 'next/link';
import { useAuth } from '@/components/auth/auth-provider';
import { useMockSession } from '@/components/mock-session-provider';
import { AppShell } from '@/components/radio/app-shell';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';

export default function AccountPage() {
  const { user, isPlus, signOut } = useAuth();
  const {
    dataSaver,
    workingNowDefault,
    setDataSaver,
    setWorkingNowDefault,
  } = useMockSession();

  const displayName = user?.displayName || user?.email || 'Guest Listener';
  const initials = displayName.slice(0, 2).toUpperCase();

  return (
    <AppShell>
      <div className="space-y-6">
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          Account &amp; Settings
        </h1>

        <Card>
          <CardContent className="flex flex-wrap items-center justify-between gap-4 p-6">
            <div className="flex items-center gap-4">
              <Avatar className="size-14">
                <AvatarFallback>{initials}</AvatarFallback>
              </Avatar>
              <div>
                <div className="flex flex-wrap items-center gap-2">
                  <h2 className="font-heading text-lg font-semibold">
                    {displayName}
                  </h2>
                  <Badge variant={isPlus ? 'default' : 'outline'}>
                    {isPlus ? 'PekSoft Plus' : 'Free Plan'}
                  </Badge>
                  {user && (
                    <Badge variant={user.emailVerified ? 'live' : 'outline'}>
                      {user.emailVerified ? 'Verified' : 'Unverified'}
                    </Badge>
                  )}
                </div>
                <p className="text-sm text-muted-foreground">
                  {user
                    ? 'Your favourites and collections sync across Android and Web.'
                    : 'Sign in to sync favourites and collections across Android and Web.'}
                </p>
              </div>
            </div>

            <div className="flex gap-2">
              {user ? (
                <Button variant="outline" onClick={() => void signOut()}>
                  Sign Out
                </Button>
              ) : (
                <Link href="/auth">
                  <Button variant="signal">Sign In</Button>
                </Link>
              )}
              {!isPlus && (
                <Link href="/pricing">
                  <Button variant="outline">Upgrade</Button>
                </Link>
              )}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Playback &amp; Discovery Preferences</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium">Data Saver</p>
                <p className="text-xs text-muted-foreground">
                  Prefer lower-bitrate streams on mobile connections.
                </p>
              </div>
              <Switch
                checked={dataSaver}
                onCheckedChange={setDataSaver}
                aria-label="Data saver"
              />
            </div>

            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium">Working Now Filter</p>
                <p className="text-xs text-muted-foreground">
                  Hide stations whose last Radio Browser health check failed.
                </p>
              </div>
              <Switch
                checked={workingNowDefault}
                onCheckedChange={setWorkingNowDefault}
                aria-label="Working now default"
              />
            </div>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  );
}
