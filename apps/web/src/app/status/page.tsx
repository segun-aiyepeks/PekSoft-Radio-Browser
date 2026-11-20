import type { Metadata } from 'next';
import { AppShell } from '@/components/radio/app-shell';
import { Badge } from '@/components/ui/badge';

export const metadata: Metadata = {
  title: 'System Status & KPIs — PekSoft Radio Browser',
  description:
    'Live API health checks and Section 11 product KPIs for PekSoft Radio Browser.',
};

interface HealthPayload {
  status: string;
  version?: string;
  uptimeSeconds?: number;
  memoryRssMb?: number;
  checks?: { process?: string; database?: string };
}

async function fetchApiReadiness(): Promise<{
  reachable: boolean;
  payload?: HealthPayload;
}> {
  const baseUrl =
    process.env.NEXT_PUBLIC_API_URL?.replace(/\/+$/, '') ||
    'http://localhost:4000';
  try {
    const res = await fetch(`${baseUrl}/health/ready`, {
      cache: 'no-store',
      signal: AbortSignal.timeout(2500),
    });
    if (!res.ok) {
      return { reachable: false };
    }
    return {
      reachable: true,
      payload: (await res.json()) as HealthPayload,
    };
  } catch {
    return { reachable: false };
  }
}

const SECTION_11_KPIS = [
  {
    name: 'Time to First Sound (TTFS)',
    target: '< 2.5s (p75)',
    source: 'Firebase Analytics (`station_play`)',
    description: 'Elapsed time from tapping Play to first audio frame.',
  },
  {
    name: 'Stream Start Success Rate',
    target: '>= 95%',
    source: 'Firebase Analytics (`station_play` vs `station_fail`)',
    description: 'Percentage of play attempts that enter live playback.',
  },
  {
    name: 'Crash-Free Sessions',
    target: '>= 99.5%',
    source: 'Firebase Crashlytics (Mobile) · Sentry (Web/API)',
    description: 'Sessions completing without fatal crashes or unhandled 500s.',
  },
  {
    name: 'API Availability (Uptime)',
    target: '>= 99.9%',
    source: 'Uptime Monitor (`/health` & `/health/ready`)',
    description: '30-day rolling HTTP 200 availability of the API gateway.',
  },
  {
    name: 'D7 Listener Retention',
    target: '>= 25%',
    source: 'Firebase Analytics (Cohort)',
    description: 'Share of new listeners returning 7 days after first play.',
  },
  {
    name: 'Favourites per Active User',
    target: '>= 3.0',
    source: 'PostgreSQL (`favorites`) · `favorite_add`',
    description: 'Average saved stations per returning listener.',
  },
  {
    name: 'Free to Plus Conversion',
    target: '>= 2.0%',
    source: 'Google Play Billing · Paystack (`purchase_success`)',
    description: 'Active listeners upgrading to PekSoft Plus.',
  },
  {
    name: 'Broken Station Report Rate',
    target: '< 1.5%',
    source: 'PostgreSQL (`station_reports`)',
    description: 'Share of playback sessions generating a broken-stream report.',
  },
] as const;

export default async function StatusDashboardPage() {
  const readiness = await fetchApiReadiness();

  return (
    <AppShell>
      <div className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">
              Observability &amp; KPI Dashboard
            </h1>
            <p className="mt-1 text-sm text-muted-foreground">
              Live service health and Section 11 product health targets
              (zero personal data logged).
            </p>
          </div>
          <Badge
            variant="outline"
            className={
              readiness.reachable
                ? 'border-[#10B981] text-[#10B981]'
                : 'border-amber-500 text-amber-500'
            }
          >
            {readiness.reachable ? 'API Online' : 'API Unreachable (Local/Offline)'}
          </Badge>
        </div>

        <section
          aria-label="Service health checks"
          className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4"
        >
          <div className="rounded-xl border border-border bg-card p-4">
            <p className="text-xs font-medium text-muted-foreground">
              API Readiness
            </p>
            <p className="mt-1 text-lg font-bold">
              {readiness.payload?.status?.toUpperCase() ?? 'OFFLINE'}
            </p>
            <p className="mt-1 text-xs text-muted-foreground">
              Endpoint: <code>/health/ready</code>
            </p>
          </div>
          <div className="rounded-xl border border-border bg-card p-4">
            <p className="text-xs font-medium text-muted-foreground">
              API Version
            </p>
            <p className="mt-1 text-lg font-bold">
              {readiness.payload?.version ?? '—'}
            </p>
            <p className="mt-1 text-xs text-muted-foreground">
              Uptime:{' '}
              {readiness.payload?.uptimeSeconds !== undefined
                ? `${readiness.payload.uptimeSeconds}s`
                : '—'}
            </p>
          </div>
          <div className="rounded-xl border border-border bg-card p-4">
            <p className="text-xs font-medium text-muted-foreground">
              Database Probe
            </p>
            <p className="mt-1 text-lg font-bold">
              {readiness.payload?.checks?.database?.toUpperCase() ?? '—'}
            </p>
            <p className="mt-1 text-xs text-muted-foreground">
              PostgreSQL / Prisma connectivity
            </p>
          </div>
          <div className="rounded-xl border border-border bg-card p-4">
            <p className="text-xs font-medium text-muted-foreground">
              Telemetry Stack
            </p>
            <p className="mt-1 text-lg font-bold">Crashlytics + Sentry</p>
            <p className="mt-1 text-xs text-muted-foreground">
              PII redacted · Consent-gated
            </p>
          </div>
        </section>

        <section aria-label="Section 11 product KPIs" className="space-y-3">
          <h2 className="text-lg font-semibold">Section 11 Product KPIs</h2>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {SECTION_11_KPIS.map((kpi) => (
              <div
                key={kpi.name}
                className="flex flex-col justify-between rounded-xl border border-border bg-card p-4"
              >
                <div>
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="text-sm font-semibold">{kpi.name}</h3>
                    <span className="shrink-0 rounded-md border border-border bg-background px-2 py-0.5 text-xs font-semibold text-foreground">
                      {kpi.target}
                    </span>
                  </div>
                  <p className="mt-2 text-xs text-muted-foreground">
                    {kpi.description}
                  </p>
                </div>
                <p className="mt-3 border-t border-border pt-2 text-[11px] text-muted-foreground">
                  Source: {kpi.source}
                </p>
              </div>
            ))}
          </div>
        </section>
      </div>
    </AppShell>
  );
}
