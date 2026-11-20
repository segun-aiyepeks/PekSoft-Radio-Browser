import type { Metadata } from 'next';
import Link from 'next/link';
import { AppShell } from '@/components/radio/app-shell';

export const metadata: Metadata = {
  title: 'Terms of Service — PekSoft Radio Browser',
  description:
    'Terms of Service template for PekSoft Radio Browser (web and mobile).',
};

export default function TermsOfServicePage() {
  return (
    <AppShell>
      <article className="mx-auto max-w-3xl space-y-6">
        <header className="space-y-2 border-b border-border pb-4">
          <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            Legal Template — Pending Lawyer Review
          </p>
          <h1 className="text-3xl font-bold tracking-tight">Terms of Service</h1>
          <p className="text-sm text-muted-foreground">
            Effective Date: November 19, 2026 · PekSoft Radio Browser
            (developed by aiyepeks)
          </p>
        </header>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">1. Acceptance of Terms</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            By accessing or using PekSoft Radio Browser on Android, iOS, or the
            web, you agree to these Terms of Service and our{' '}
            <Link
              href="/privacy"
              className="font-medium text-foreground underline underline-offset-4"
            >
              Privacy Policy
            </Link>
            .
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">2. Third-Party Radio Streams</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            PekSoft Radio Browser is a directory and audio player powered by
            community-maintained metadata from Radio Browser
            (radio-browser.info). We do not host, control, or own the audio
            broadcasts. Stream availability, audio quality, and broadcast
            content are the sole responsibility of each respective radio
            station.
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">3. PekSoft Plus Subscriptions</h2>
          <ul className="list-disc space-y-1.5 pl-5 text-sm text-muted-foreground">
            <li>
              Android subscriptions are billed and managed through Google Play
              Billing. You may cancel anytime in Google Play Store settings.
            </li>
            <li>
              Web subscriptions are billed and managed through Paystack. You may
              cancel anytime from your Account or Pricing page; access continues
              through the end of the current billing period.
            </li>
            <li>
              Downgrading from Plus to Free never deletes your saved favourites
              or collections; Plus-only extras pause until you resubscribe.
            </li>
          </ul>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">4. Acceptable Use</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            You agree not to abuse our APIs, bypass rate limits, scrape station
            endpoints at automated scale, or attempt to circumvent entitlement
            or billing verification.
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">5. Disclaimer &amp; Limitation of Liability</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            The service is provided &ldquo;as is&rdquo; without warranties of
            uninterrupted availability. To the maximum extent permitted by law,
            PekSoft Radio Browser is not liable for indirect or consequential
            damages arising from third-party stream outages or broadcast
            content.
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">6. Contact</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Questions about these terms? Email{' '}
            <a
              href="mailto:support@peksoft.radio"
              className="font-medium text-foreground underline underline-offset-4"
            >
              support@peksoft.radio
            </a>
            .
          </p>
        </section>
      </article>
    </AppShell>
  );
}
