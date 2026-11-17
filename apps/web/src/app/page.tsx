import Link from 'next/link';
import { ArrowRight, Globe2, Radio, ShieldCheck, Sparkles } from 'lucide-react';
import { AppShell } from '@/components/radio/app-shell';
import { CountryCard } from '@/components/radio/country-card';
import { StationCard } from '@/components/radio/station-card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { MOCK_COUNTRIES, MOCK_GENRES, MOCK_STATIONS } from '@/lib/mock-data';

export default function LandingPage() {
  return (
    <AppShell>
      <div className="space-y-12">
        {/* Hero Banner with Atmospheric Picture-Style Backdrop */}
        <section className="relative overflow-hidden rounded-3xl border border-border bg-gradient-to-br from-[#18243E] via-[#101A2E] to-[#0A0F1C] p-6 sm:p-10">
          <div
            aria-hidden="true"
            className="pointer-events-none absolute -top-24 -right-24 size-72 rounded-full bg-[var(--color-accent)]/15 blur-3xl"
          />
          <div className="relative z-10 max-w-2xl space-y-5">
            <Badge variant="live" className="gap-1.5">
              <Radio className="size-3.5" /> Live Global Radio · Zero Setup
            </Badge>
            <h1 className="font-heading text-3xl font-bold tracking-tight text-white sm:text-5xl">
              Every radio station in the world, one tap away.
            </h1>
            <p className="text-base text-slate-300 sm:text-lg">
              Open PekSoft Radio and hear something you love within 10 seconds.
              Discover verified working stations by country, language, and genre
              with one synced library across Android and Web.
            </p>
            <div className="flex flex-wrap items-center gap-3 pt-2">
              <Link href="/home">
                <Button variant="signal" size="lg">
                  Start Listening Free <ArrowRight className="size-4" />
                </Button>
              </Link>
              <Link href="/explore">
                <Button variant="outline" size="lg">
                  Explore 30,000+ Stations
                </Button>
              </Link>
            </div>
          </div>
        </section>

        {/* Trending Now */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="font-heading text-2xl font-bold">Trending Live</h2>
              <p className="text-sm text-muted-foreground">
                Verified working streams playing right now.
              </p>
            </div>
            <Link href="/explore">
              <Button variant="ghost" size="sm">
                View all <ArrowRight className="size-4" />
              </Button>
            </Link>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {MOCK_STATIONS.slice(0, 4).map((station) => (
              <StationCard key={station.id} station={station} />
            ))}
          </div>
        </section>

        {/* Popular Countries */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-heading text-2xl font-bold">
              Browse by Country
            </h2>
            <Link href="/explore">
              <Button variant="ghost" size="sm">
                All countries <Globe2 className="size-4" />
              </Button>
            </Link>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {MOCK_COUNTRIES.slice(0, 4).map((country) => (
              <CountryCard key={country.code} country={country} />
            ))}
          </div>
        </section>

        {/* Genres & Plus Highlight */}
        <section className="grid gap-6 lg:grid-cols-3">
          <div className="space-y-4 lg:col-span-2">
            <h2 className="font-heading text-2xl font-bold">
              Canonical Genres
            </h2>
            <div className="grid gap-3 sm:grid-cols-2">
              {MOCK_GENRES.slice(0, 4).map((genre) => (
                <Link
                  key={genre.id}
                  href={`/genre/${genre.slug}`}
                  className={`block rounded-2xl border border-border bg-gradient-to-br ${genre.gradient} p-5 transition-transform hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring`}
                >
                  <h3 className="font-heading text-lg font-bold text-white">
                    {genre.name}
                  </h3>
                  <p className="mt-1 text-xs text-slate-200">{genre.tagline}</p>
                  <p className="mt-3 text-xs font-medium text-[var(--color-accent)]">
                    {genre.stationCount} stations →
                  </p>
                </Link>
              ))}
            </div>
          </div>

          <div className="flex flex-col justify-between rounded-2xl border border-[var(--color-accent)]/40 bg-card p-6">
            <div className="space-y-3">
              <Badge variant="default" className="gap-1">
                <Sparkles className="size-3" /> PekSoft Plus
              </Badge>
              <h3 className="font-heading text-xl font-bold">
                Ad-free, unlimited library &amp; power tools
              </h3>
              <p className="text-sm text-muted-foreground">
                Keep unlimited favourites and custom collections synced across
                your Android phone and browser.
              </p>
              <ul className="space-y-1.5 text-sm text-muted-foreground">
                <li className="flex items-center gap-2">
                  <ShieldCheck className="size-4 text-[var(--color-success)]" />
                  Zero ads everywhere
                </li>
                <li className="flex items-center gap-2">
                  <ShieldCheck className="size-4 text-[var(--color-success)]" />
                  Custom sleep timer &amp; fade-out
                </li>
                <li className="flex items-center gap-2">
                  <ShieldCheck className="size-4 text-[var(--color-success)]" />
                  Bitrate &amp; codec advanced filters
                </li>
              </ul>
            </div>
            <Link href="/pricing" className="mt-6 block">
              <Button variant="signal" className="w-full">
                See Plus Plans
              </Button>
            </Link>
          </div>
        </section>
      </div>
    </AppShell>
  );
}
