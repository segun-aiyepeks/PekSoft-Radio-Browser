import type { Metadata } from 'next';
import Link from 'next/link';
import { AppShell } from '@/components/radio/app-shell';

export const metadata: Metadata = {
  title: 'Privacy Policy — PekSoft Radio Browser',
  description:
    'Privacy Policy template for PekSoft Radio Browser (web and mobile).',
};

export default function PrivacyPolicyPage() {
  return (
    <AppShell>
      <article className="mx-auto max-w-3xl space-y-6">
        <header className="space-y-2 border-b border-border pb-4">
          <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            Legal Template — Pending Lawyer Review
          </p>
          <h1 className="text-3xl font-bold tracking-tight">Privacy Policy</h1>
          <p className="text-sm text-muted-foreground">
            Effective Date: November 19, 2026 · PekSoft Radio Browser
            (developed by aiyepeks)
          </p>
        </header>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">1. Overview &amp; Guest-First Design</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            PekSoft Radio Browser lets you browse and listen to live global
            radio stations without creating an account. When you use the app as
            a guest, your favourites, recent stations, and listening preferences
            are stored locally on your device.
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">2. Information We Collect</h2>
          <ul className="list-disc space-y-1.5 pl-5 text-sm text-muted-foreground">
            <li>
              <strong>Account data (optional):</strong> If you sign in with
              Firebase Authentication (email/password or Google Sign-In), we
              store your Firebase UID, email address, and display name to sync
              your library across devices.
            </li>
            <li>
              <strong>Library &amp; preferences:</strong> Saved favourites,
              collections, recent station IDs, song history entries, and home
              country selection.
            </li>
            <li>
              <strong>Subscriptions &amp; billing:</strong> Processed by Google
              Play Billing (Android) or Paystack (Web). We store subscription
              status, plan tier, expiry timestamp, and provider tokens — we
              never store full payment card numbers.
            </li>
            <li>
              <strong>Diagnostics &amp; analytics (consent-gated):</strong> With
              your consent, we collect anonymized crash reports (Firebase
              Crashlytics on mobile, Sentry on web/API) and aggregate playback
              metrics (station play/fail counts). Personal data such as email
              addresses, auth tokens, and client IP addresses are stripped or
              redacted from logs.
            </li>
          </ul>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">3. Cookies, Ads &amp; Consent</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Free-tier users may see non-intrusive ads powered by Google AdMob
            (Android) or Google AdSense (Web). You can accept or decline
            personalized advertising and analytics cookies using our consent
            banner at any time. PekSoft Plus subscribers receive an ad-free
            experience.
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">4. Third-Party Radio Streams</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            Station directory metadata is provided by the community Radio
            Browser directory (radio-browser.info). Audio streams are delivered
            directly from each broadcaster&apos;s servers; broadcasters may log
            standard connection metadata (such as your IP address) when you
            stream their audio.
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">5. Data Deletion &amp; Your Rights</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            You can permanently delete your account and all synced library data
            at any time from the mobile app (Profile &rarr; Delete Account),
            from your Web Account settings, or by following the instructions on
            our{' '}
            <Link
              href="/delete-account"
              className="font-medium text-foreground underline underline-offset-4"
            >
              Account Deletion page
            </Link>
            .
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">6. Contact</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            For privacy inquiries or data requests, contact:{' '}
            <a
              href="mailto:privacy@peksoft.radio"
              className="font-medium text-foreground underline underline-offset-4"
            >
              privacy@peksoft.radio
            </a>
            .
          </p>
        </section>
      </article>
    </AppShell>
  );
}
