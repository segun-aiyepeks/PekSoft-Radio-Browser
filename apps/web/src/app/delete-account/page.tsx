import type { Metadata } from 'next';
import Link from 'next/link';
import { AppShell } from '@/components/radio/app-shell';
import { Button } from '@/components/ui/button';

export const metadata: Metadata = {
  title: 'Delete Account — PekSoft Radio Browser',
  description:
    'Public account and data deletion instructions for PekSoft Radio Browser (Google Play Data Safety compliant).',
};

export default function DeleteAccountPage() {
  return (
    <AppShell>
      <article className="mx-auto max-w-3xl space-y-6">
        <header className="space-y-2 border-b border-border pb-4">
          <h1 className="text-3xl font-bold tracking-tight">
            Delete Your Account &amp; Data
          </h1>
          <p className="text-sm text-muted-foreground">
            PekSoft Radio Browser gives you full control over your account and
            synced library data.
          </p>
        </header>

        <section className="rounded-xl border border-border bg-card p-5 space-y-3">
          <h2 className="text-lg font-semibold">Option 1: Delete Immediately in the App or Web</h2>
          <ol className="list-decimal space-y-1.5 pl-5 text-sm text-muted-foreground">
            <li>
              <strong>Android Mobile App:</strong> Open{' '}
              <code>Profile &rarr; Delete Account</code>, confirm your request,
              and your account + cloud library are deleted immediately.
            </li>
            <li>
              <strong>Web App:</strong> Sign in and open your{' '}
              <Link
                href="/account"
                className="font-medium text-foreground underline underline-offset-4"
              >
                Account settings
              </Link>{' '}
              to permanently delete your account.
            </li>
          </ol>
          <div className="pt-2">
            <Link href="/account">
              <Button variant="outline">Go to Account Settings</Button>
            </Link>
          </div>
        </section>

        <section className="rounded-xl border border-border bg-card p-5 space-y-3">
          <h2 className="text-lg font-semibold">Option 2: Request Deletion by Email</h2>
          <p className="text-sm leading-relaxed text-muted-foreground">
            If you no longer have access to the app, send an email from the
            address registered to your account to{' '}
            <a
              href="mailto:privacy@peksoft.radio?subject=Account%20Deletion%20Request"
              className="font-medium text-foreground underline underline-offset-4"
            >
              privacy@peksoft.radio
            </a>{' '}
            with the subject <strong>Account Deletion Request</strong>. We
            verify ownership and complete deletion within 7 business days.
          </p>
        </section>

        <section className="space-y-2">
          <h2 className="text-lg font-semibold">What Data Is Deleted</h2>
          <ul className="list-disc space-y-1.5 pl-5 text-sm text-muted-foreground">
            <li>Firebase Authentication account (email, display name, UID).</li>
            <li>Synced favourites, custom collections, recent stations, and song history in PostgreSQL.</li>
            <li>Active device sync tokens.</li>
          </ul>
          <p className="pt-2 text-xs text-muted-foreground">
            <strong>Retention note:</strong> Billing transaction records held by
            Google Play or Paystack may be retained by those payment processors
            as required by financial and tax regulations. Cancel any active
            Google Play subscription in Google Play Store settings to stop
            future renewals.
          </p>
        </section>
      </article>
    </AppShell>
  );
}
