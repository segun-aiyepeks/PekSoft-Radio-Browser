'use client';

import { useState } from 'react';
import Link from 'next/link';
import { FEATURE_FLAGS } from '@peksoft/shared';
import { toast } from 'sonner';
import { useAuth } from '@/components/auth/auth-provider';
import { useMockSession } from '@/components/mock-session-provider';
import { AppShell } from '@/components/radio/app-shell';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { cancelPaystackSubscription } from '@/lib/billing-api';

export default function AccountPage() {
  const { user, isPlus, entitlement, getIdToken, refreshEntitlement, signOut } =
    useAuth();
  const {
    dataSaver,
    workingNowDefault,
    setDataSaver,
    setWorkingNowDefault,
  } = useMockSession();

  const [cancelling, setCancelling] = useState(false);

  const displayName = user?.displayName || user?.email || 'Guest Listener';
  const initials = displayName.slice(0, 2).toUpperCase();

  const handleCancelSubscription = async () => {
    if (!user) return;
    setCancelling(true);
    try {
      const token = await getIdToken();
      if (!token) throw new Error('Not authenticated');
      await cancelPaystackSubscription(token);
      await refreshEntitlement();
      toast.success('Subscription cancelled.');
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : 'Unable to cancel subscription.',
      );
    } finally {
      setCancelling(false);
    }
  };

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
            <CardTitle>Subscription &amp; Billing</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-wrap items-center justify-between gap-4">
            <div className="space-y-1 text-sm">
              <p className="font-medium">
                Current plan: {isPlus ? 'PekSoft Plus' : 'Free'}
                {entitlement?.source ? ` (${entitlement.source})` : ''}
              </p>
              <p className="text-xs text-muted-foreground">
                {entitlement?.expiresAt
                  ? `Renews / expires: ${new Date(entitlement.expiresAt).toLocaleDateString()}`
                  : 'Every station stays free forever.'}
              </p>
              <p className="text-xs text-muted-foreground">
                Cross-platform Android unlock flag:{' '}
                {FEATURE_FLAGS.crossPlatformEntitlements ? 'ON' : 'OFF'}
              </p>
            </div>

            <div className="flex gap-2">
              {isPlus ? (
                <Button
                  type="button"
                  variant="destructive"
                  disabled={cancelling}
                  onClick={handleCancelSubscription}
                >
                  {cancelling ? 'Cancelling…' : 'Cancel Subscription'}
                </Button>
              ) : (
                <Link href="/checkout">
                  <Button variant="signal">Subscribe to Plus</Button>
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
