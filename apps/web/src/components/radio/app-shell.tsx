'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  Compass,
  Crown,
  Home,
  Library,
  Moon,
  Radio,
  Search,
  Sun,
  User,
} from 'lucide-react';
import { PlayerBar } from '@/components/radio/player-bar';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';

const NAV_ITEMS = [
  { href: '/home', label: 'Home', icon: Home },
  { href: '/explore', label: 'Explore', icon: Compass },
  { href: '/library', label: 'Library', icon: Library },
  { href: '/pricing', label: 'Upgrade', icon: Crown },
  { href: '/account', label: 'Account', icon: User },
] as const;

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [searchQuery, setSearchQuery] = useState('');
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');

  useEffect(() => {
    const root = document.documentElement;
    root.setAttribute('data-theme', theme);
    root.classList.remove('dark', 'light');
    root.classList.add(theme);
  }, [theme]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = searchQuery.trim();
    router.push(
      trimmed ? `/explore?q=${encodeURIComponent(trimmed)}` : '/explore',
    );
  };

  return (
    <div className="min-h-screen bg-background text-foreground">
      {/* Desktop Left Sidebar */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-60 flex-col border-r border-border bg-sidebar p-4 md:flex">
        <Link
          href="/"
          className="flex items-center gap-2.5 rounded-xl px-2 py-2 font-heading text-base font-bold text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <span className="flex size-9 items-center justify-center rounded-xl bg-[var(--color-accent)] text-[var(--color-on-accent)]">
            <Radio className="size-5" />
          </span>
          <span>PekSoft Radio</span>
        </Link>

        <nav aria-label="Main navigation" className="mt-6 flex-1 space-y-1">
          {NAV_ITEMS.map((item) => {
            const Icon = item.icon;
            const active =
              pathname === item.href || pathname.startsWith(`${item.href}/`);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
                  active
                    ? 'bg-sidebar-accent text-foreground'
                    : 'text-muted-foreground hover:bg-sidebar-accent/50 hover:text-foreground',
                )}
              >
                <Icon
                  className={cn(
                    'size-4',
                    active && 'text-[var(--color-accent)]',
                  )}
                />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        <div className="rounded-xl border border-border bg-card p-3 text-xs text-muted-foreground">
          <p className="font-semibold text-foreground">PekSoft Plus</p>
          <p className="mt-1">Ad-free listening &amp; unlimited collections.</p>
          <Link href="/pricing" className="mt-2 inline-block">
            <Button size="sm" variant="signal" className="w-full">
              Upgrade
            </Button>
          </Link>
        </div>
      </aside>

      {/* Main Column */}
      <div className="flex min-h-screen flex-col md:pl-60">
        <header className="sticky top-0 z-20 border-b border-border bg-background/90 backdrop-blur">
          <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-3 px-4 sm:px-6">
            <form onSubmit={handleSearch} className="relative flex-1 max-w-md">
              <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search stations, countries, or genres..."
                aria-label="Search radio stations"
                className="pl-9"
              />
            </form>

            <div className="flex items-center gap-2">
              <Button
                type="button"
                variant="ghost"
                size="icon"
                aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
                onClick={() =>
                  setTheme((prev) => (prev === 'dark' ? 'light' : 'dark'))
                }
              >
                {theme === 'dark' ? (
                  <Sun className="size-4" />
                ) : (
                  <Moon className="size-4" />
                )}
              </Button>
              <Link href="/auth">
                <Button variant="outline" size="sm">
                  Sign in
                </Button>
              </Link>
            </div>
          </div>
        </header>

        <main className="mx-auto w-full max-w-6xl flex-1 px-4 pt-6 pb-40 sm:px-6 md:pb-24">
          {children}
        </main>
      </div>

      {/* Persistent Player Bar */}
      <PlayerBar />

      {/* Mobile Bottom Nav */}
      <nav
        aria-label="Mobile navigation"
        className="fixed inset-x-0 bottom-0 z-40 flex h-16 items-center justify-around border-t border-border bg-card/95 backdrop-blur md:hidden"
      >
        {NAV_ITEMS.map((item) => {
          const Icon = item.icon;
          const active =
            pathname === item.href || pathname.startsWith(`${item.href}/`);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex min-w-12 flex-col items-center justify-center gap-1 rounded-lg px-2 py-1 text-[11px] font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
                active ? 'text-[var(--color-accent)]' : 'text-muted-foreground',
              )}
            >
              <Icon className="size-5" />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
