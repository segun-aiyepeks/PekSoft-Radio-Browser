'use client';

import { useEffect, useState } from 'react';
import { Download, Smartphone, X } from 'lucide-react';
import { usePlayer } from '@/components/player/player-provider';
import { Button } from '@/components/ui/button';
import { shouldShowGetAppBanner } from '@/lib/pwa';

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

const DISMISS_KEY = 'peksoft_get_app_dismissed_v1';

export function PwaProvider({ children }: { children: React.ReactNode }) {
  const { isPlaying } = usePlayer();
  const [engaged, setEngaged] = useState(false);
  const [dismissed, setDismissed] = useState(true);
  const [isStandalone, setIsStandalone] = useState(false);
  const [deferredPrompt, setDeferredPrompt] =
    useState<BeforeInstallPromptEvent | null>(null);

  useEffect(() => {
    if (typeof window === 'undefined') return;

    if ('serviceWorker' in navigator && process.env.NODE_ENV === 'production') {
      void navigator.serviceWorker.register('/sw.js').catch(() => {});
    }

    const standalone =
      window.matchMedia('(display-mode: standalone)').matches ||
      (window.navigator as unknown as { standalone?: boolean }).standalone ===
        true;
    setIsStandalone(standalone);

    try {
      setDismissed(window.localStorage.getItem(DISMISS_KEY) === '1');
    } catch {
      setDismissed(false);
    }

    const onBeforeInstall = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
    };
    window.addEventListener('beforeinstallprompt', onBeforeInstall);

    // Engagement fallback: 20s active browsing
    const timer = window.setTimeout(() => setEngaged(true), 20000);

    return () => {
      window.removeEventListener('beforeinstallprompt', onBeforeInstall);
      window.clearTimeout(timer);
    };
  }, []);

  // Playing a live stream also counts as strong engagement
  useEffect(() => {
    if (isPlaying) {
      setEngaged(true);
    }
  }, [isPlaying]);

  const dismiss = () => {
    setDismissed(true);
    try {
      window.localStorage.setItem(DISMISS_KEY, '1');
    } catch {
      // Ignore
    }
  };

  const handleInstall = async () => {
    if (deferredPrompt) {
      await deferredPrompt.prompt();
      await deferredPrompt.userChoice;
      setDeferredPrompt(null);
      dismiss();
    } else {
      window.open(
        'https://play.google.com/store/apps',
        '_blank',
        'noopener,noreferrer',
      );
      dismiss();
    }
  };

  const showBanner = shouldShowGetAppBanner({
    engaged,
    dismissed,
    isStandalone,
  });

  return (
    <>
      {children}
      {showBanner && (
        <aside
          aria-label="Get the PekSoft Radio app"
          className="fixed bottom-36 left-4 z-40 flex max-w-sm items-center gap-3 rounded-2xl border border-border bg-card p-3.5 shadow-xl md:bottom-22 md:left-64"
        >
          <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-[var(--color-accent)]/15 text-[var(--color-accent)]">
            <Smartphone className="size-5" />
          </div>
          <div className="min-w-0 flex-1">
            <p className="font-heading text-sm font-semibold">
              Get the PekSoft Radio app
            </p>
            <p className="text-xs text-muted-foreground">
              {deferredPrompt
                ? 'Install as an app for one-tap listening.'
                : 'Play HTTP & background streams on Android.'}
            </p>
          </div>
          <Button
            type="button"
            variant="signal"
            size="sm"
            onClick={() => void handleInstall()}
          >
            <Download className="size-3.5" />
            {deferredPrompt ? 'Install' : 'Get App'}
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="size-7 shrink-0"
            aria-label="Dismiss app banner"
            onClick={dismiss}
          >
            <X className="size-3.5" />
          </Button>
        </aside>
      )}
    </>
  );
}
