'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import Script from 'next/script';
import { useAuth } from '@/components/auth/auth-provider';
import { Button } from '@/components/ui/button';
import type { AdConsentStatus } from '@/lib/ad-policy';

const CONSENT_STORAGE_KEY = 'peksoft_ad_consent_v1';

interface AdConsentContextValue {
  consentStatus: AdConsentStatus;
  grantConsent: () => void;
  denyConsent: () => void;
  resetConsent: () => void;
  adsenseClientId: string | null;
}

const AdConsentContext = createContext<AdConsentContextValue | null>(null);

export function AdConsentProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const { isPlus } = useAuth();
  const [consentStatus, setConsentStatus] =
    useState<AdConsentStatus>('unknown');
  const [hydrated, setHydrated] = useState(false);

  const adsenseClientId =
    process.env.NEXT_PUBLIC_ADSENSE_CLIENT_ID?.trim() || null;

  useEffect(() => {
    try {
      const saved = window.localStorage.getItem(CONSENT_STORAGE_KEY);
      if (saved === 'granted' || saved === 'denied') {
        setConsentStatus(saved);
      }
    } catch {
      // Ignore storage access errors
    } finally {
      setHydrated(true);
    }
  }, []);

  const grantConsent = useCallback(() => {
    setConsentStatus('granted');
    try {
      window.localStorage.setItem(CONSENT_STORAGE_KEY, 'granted');
    } catch {
      // Ignore
    }
  }, []);

  const denyConsent = useCallback(() => {
    setConsentStatus('denied');
    try {
      window.localStorage.setItem(CONSENT_STORAGE_KEY, 'denied');
    } catch {
      // Ignore
    }
  }, []);

  const resetConsent = useCallback(() => {
    setConsentStatus('unknown');
    try {
      window.localStorage.removeItem(CONSENT_STORAGE_KEY);
    } catch {
      // Ignore
    }
  }, []);

  const value = useMemo<AdConsentContextValue>(
    () => ({
      consentStatus,
      grantConsent,
      denyConsent,
      resetConsent,
      adsenseClientId,
    }),
    [consentStatus, grantConsent, denyConsent, resetConsent, adsenseClientId],
  );

  const shouldLoadAdSense =
    !isPlus && consentStatus === 'granted' && Boolean(adsenseClientId);

  return (
    <AdConsentContext.Provider value={value}>
      {shouldLoadAdSense && adsenseClientId && (
        <Script
          id="google-adsense-script"
          async
          strategy="afterInteractive"
          src={`https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${encodeURIComponent(adsenseClientId)}`}
          crossOrigin="anonymous"
        />
      )}
      {children}
      {hydrated && !isPlus && consentStatus === 'unknown' && (
        <div
          role="dialog"
          aria-label="Privacy and ad preferences"
          className="fixed right-4 bottom-36 z-40 max-w-sm rounded-2xl border border-border bg-card p-4 shadow-xl md:bottom-22"
        >
          <p className="font-heading text-sm font-semibold text-foreground">
            Keep PekSoft Radio free
          </p>
          <p className="mt-1 text-xs text-muted-foreground">
            Allow AdSense cookies to support free radio streaming, or choose
            essential cookies only. Plus members never see ads.
          </p>
          <div className="mt-3 flex items-center justify-end gap-2">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={denyConsent}
            >
              Essential only
            </Button>
            <Button
              type="button"
              variant="signal"
              size="sm"
              onClick={grantConsent}
            >
              Accept ads
            </Button>
          </div>
        </div>
      )}
    </AdConsentContext.Provider>
  );
}

export function useAdConsent(): AdConsentContextValue {
  const ctx = useContext(AdConsentContext);
  if (!ctx) {
    throw new Error('useAdConsent must be used inside AdConsentProvider');
  }
  return ctx;
}
