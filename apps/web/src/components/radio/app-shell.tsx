'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  Compass,
  Crown,
  Flag,
  Globe,
  Home,
  Library,
  Lock,
  Moon,
  Radio,
  Search,
  Shuffle,
  Sun,
  User,
} from 'lucide-react';
import { useAuth } from '@/components/auth/auth-provider';
import { useMockSession } from '@/components/mock-session-provider';
import { PlayerBar } from '@/components/radio/player-bar';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';

const NAV_ITEMS = [
  { href: '/home', label: 'Home', icon: Home },
  { href: '/explore', label: 'Explore', icon: Compass },
  { href: '/genre/afrobeats', label: 'Genres', icon: Radio },
  { href: '/country/ng', label: 'Countries', icon: Flag },
  { href: '/library', label: 'Library & Favourites', icon: Library },
  { href: '/pricing', label: 'Plus Plans', icon: Crown },
] as const;

const MOBILE_NAV_ITEMS = [
  { href: '/home', label: 'Home', icon: Home },
  { href: '/explore', label: 'Explore', icon: Compass },
  { href: '/library', label: 'Library', icon: Library },
  { href: '/pricing', label: 'Plus', icon: Crown },
  { href: '/account', label: 'Account', icon: User },
] as const;

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const searchInputRef = useRef<HTMLInputElement | null>(null);
  const { user } = useAuth();
  const { isPlus, playSurpriseMe } = useMockSession();
  const [searchQuery, setSearchQuery] = useState('');
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');

  useEffect(() => {
    const root = document.documentElement;
    root.setAttribute('data-theme', theme);
    root.classList.remove('dark', 'light');
    root.classList.add(theme);
  }, [theme]);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        searchInputRef.current?.focus();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = searchQuery.trim();
    router.push(
      trimmed ? `/explore?q=${encodeURIComponent(trimmed)}` : '/explore',
    );
  };

  return (
    <div className="min-h-screen overflow-x-hidden bg-background text-foreground">
      {/* Desktop Left Sidebar */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 flex-col justify-between border-r border-border bg-card p-4 md:flex">
        <div className="space-y-4">
          <Link
            href="/"
            className="flex items-center gap-2.5 rounded-lg px-1.5 py-1.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <img
              src="/images/peksoft-logo.png"
              alt="PekSoft Radio Browser logo"
              className="size-9 shrink-0 rounded-lg border border-border object-cover"
            />
            <div className="flex flex-col">
              <span className="font-heading text-base font-bold tracking-tight text-foreground">
                PekSoft
              </span>
              <span className="text-[11px] font-medium text-muted-foreground">
                Radio Browser
              </span>
            </div>
          </Link>

          <button
            type="button"
            onClick={() => searchInputRef.current?.focus()}
            className="flex w-full items-center gap-2 rounded-lg border border-border bg-background px-3 py-2 text-xs text-muted-foreground transition-colors hover:bg-muted/50 hover:text-foreground"
          >
            <Search className="size-3.5" />
            <span className="flex-1 text-left">Quick Find...</span>
            <kbd className="rounded border border-border bg-muted px-1.5 py-0.5 text-[10px] font-medium">
              ⌘K
            </kbd>
          </button>

          <nav aria-label="Main navigation" className="space-y-1">
            {NAV_ITEMS.map((item) => {
              const Icon = item.icon;
              const active =
                pathname === item.href || pathname.startsWith(`${item.href}/`);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
                    active
                      ? 'bg-[var(--color-accent-violet)] text-white'
                      : 'text-muted-foreground hover:bg-muted/60 hover:text-foreground',
                  )}
                >
                  <Icon className="size-4" />
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </nav>
        </div>

        <div className="space-y-3">
          {!isPlus && (
            <div className="rounded-lg border border-border bg-muted/40 p-3.5">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-foreground">
                  PekSoft Plus
                </span>
                <span className="rounded bg-muted px-1.5 py-0.5 text-[10px] font-medium text-muted-foreground">
                  Ad-Free
                </span>
              </div>
              <p className="mt-1.5 text-xs text-muted-foreground">
                Zero ads, unlimited favourites &amp; power filters.
              </p>
              <Link href="/pricing" className="mt-3 block">
                <Button size="sm" variant="signal" className="w-full">
                  Upgrade to Plus
                </Button>
              </Link>
            </div>
          )}

          <Link
            href="/account"
            className="flex items-center justify-between rounded-lg px-2 py-1.5 text-xs text-muted-foreground transition-colors hover:bg-muted/60 hover:text-foreground"
          >
            <span className="flex items-center gap-2">
              <User className="size-4" />
              <span className="truncate">
                {user?.displayName || user?.email || 'Account & Settings'}
              </span>
            </span>
          </Link>
        </div>
      </aside>

      {/* Main Column */}
      <div className="flex min-h-screen flex-col md:pl-64">
        <header className="sticky top-0 z-20 border-b border-border bg-background">
          <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-3 px-4 sm:px-6">
            <div className="flex flex-1 items-center gap-2.5">
              <form
                onSubmit={handleSearch}
                className="relative flex-1 max-w-md"
              >
                <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  ref={searchInputRef}
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search 40,000+ live stations, city, genre..."
                  aria-label="Search radio stations"
                  className="pl-9"
                />
              </form>

              <Link
                href="/explore"
                className="hidden items-center gap-1.5 rounded-md border border-border bg-card px-2.5 py-1.5 text-xs font-medium text-muted-foreground hover:text-foreground lg:inline-flex"
              >
                <span className="size-2 rounded-full bg-[#10B981]" />
                Working Now
              </Link>

              <Link
                href="/explore"
                className="hidden items-center gap-1 rounded-md border border-border bg-card px-2.5 py-1.5 text-xs font-medium text-muted-foreground hover:text-foreground xl:inline-flex"
              >
                <Lock className="size-3 text-[#10B981]" />
                HTTPS
              </Link>
            </div>

            <div className="flex items-center gap-2">
              <Link href="/explore" className="hidden sm:inline-flex">
                <Button variant="outline" size="sm">
                  <Globe className="size-3.5" />
                  Global
                </Button>
              </Link>

              <Button
                type="button"
                variant="outline"
                size="sm"
                className="hidden sm:inline-flex"
                onClick={playSurpriseMe}
              >
                <Shuffle className="size-3.5" />
                Surprise Me
              </Button>

              <Button
                type="button"
                variant="ghost"
                size="icon"
                className="size-9"
                aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
                onClick={() => setTheme((t) => (t === 'dark' ? 'light' : 'dark'))}
              >
                {theme === 'dark' ? (
                  <Sun className="size-4" />
                ) : (
                  <Moon className="size-4" />
                )}
              </Button>

              <Link href={user ? '/account' : '/auth'}>
                <Button size="sm" variant="signal">
                  {user ? 'Account' : 'Sign In'}
                </Button>
              </Link>
            </div>
          </div>
        </header>

        <main className="mx-auto flex w-full max-w-7xl min-w-0 flex-1 flex-col px-3 pt-5 pb-40 sm:px-6 sm:pt-6 md:pb-28">
          <div className="min-w-0 flex-1">{children}</div>
          <footer className="mt-12 border-t border-border pt-6 text-center text-xs text-muted-foreground">
            © {new Date().getFullYear()} developed by aiyepeks
          </footer>
        </main>
      </div>

      {/* Mobile Bottom Navigation */}
      <nav
        aria-label="Mobile navigation"
        className="fixed inset-x-0 bottom-0 z-30 flex h-16 items-center justify-around border-t border-border bg-card pb-[env(safe-area-inset-bottom)] md:hidden"
      >
        {MOBILE_NAV_ITEMS.map((item) => {
          const Icon = item.icon;
          const active =
            pathname === item.href || pathname.startsWith(`${item.href}/`);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex flex-col items-center justify-center gap-0.5 px-3 py-1 text-[11px] font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
                active
                  ? 'text-[var(--color-accent-violet)]'
                  : 'text-muted-foreground',
              )}
            >
              <Icon className="size-5" />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>

      <PlayerBar />
    </div>
  );
}
