'use client';

import { useState } from 'react';
import Link from 'next/link';
import { toast } from 'sonner';
import { AppShell } from '@/components/radio/app-shell';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Separator } from '@/components/ui/separator';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

export default function AuthPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = (mode: string) => (e: React.FormEvent) => {
    e.preventDefault();
    toast.info(`${mode} will connect to Firebase Web SDK in Milestone 6.6`);
  };

  return (
    <AppShell>
      <div className="mx-auto max-w-md py-6">
        <Card>
          <CardHeader>
            <CardTitle className="font-heading text-2xl">
              Welcome to PekSoft Radio
            </CardTitle>
            <CardDescription>
              Sync your favourites, collections, and Plus subscription across
              devices.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-5">
            <Button
              type="button"
              variant="outline"
              className="w-full"
              onClick={() =>
                toast.info('Google sign-in connects in Milestone 6.6')
              }
            >
              Continue with Google
            </Button>

            <div className="flex items-center gap-3 text-xs text-muted-foreground">
              <Separator className="flex-1" />
              <span>OR</span>
              <Separator className="flex-1" />
            </div>

            <Tabs defaultValue="signin">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="signin">Sign In</TabsTrigger>
                <TabsTrigger value="signup">Sign Up</TabsTrigger>
                <TabsTrigger value="reset">Reset</TabsTrigger>
              </TabsList>

              <TabsContent value="signin" className="mt-4">
                <form onSubmit={handleSubmit('Sign In')} className="space-y-3">
                  <Input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    aria-label="Email address"
                  />
                  <Input
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Password"
                    aria-label="Password"
                  />
                  <Button type="submit" variant="signal" className="w-full">
                    Sign In with Email
                  </Button>
                </form>
              </TabsContent>

              <TabsContent value="signup" className="mt-4">
                <form onSubmit={handleSubmit('Sign Up')} className="space-y-3">
                  <Input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    aria-label="Email address"
                  />
                  <Input
                    type="password"
                    required
                    minLength={6}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Create a password (min 6 chars)"
                    aria-label="New password"
                  />
                  <Button type="submit" variant="signal" className="w-full">
                    Create Account
                  </Button>
                </form>
              </TabsContent>

              <TabsContent value="reset" className="mt-4">
                <form
                  onSubmit={handleSubmit('Password reset')}
                  className="space-y-3"
                >
                  <Input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    aria-label="Reset email address"
                  />
                  <Button type="submit" variant="outline" className="w-full">
                    Send Reset Link
                  </Button>
                </form>
              </TabsContent>
            </Tabs>

            <div className="text-center text-xs text-muted-foreground">
              <Link href="/home" className="underline-offset-4 hover:underline">
                Continue as Guest
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  );
}
