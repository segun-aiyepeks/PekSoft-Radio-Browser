'use client';

import { useEffect, useRef } from 'react';
import { usePathname } from 'next/navigation';
import { useAdConsent } from '@/components/ads/ad-consent-provider';
import { useMockSession } from '@/components/mock-session-provider';
import { shouldRenderWebAds } from '@/lib/ad-policy';
import { cn } from '@/lib/utils';

declare global {
  interface Window {
    adsbygoogle?: Array<Record<string, unknown>>;
  }
}

export function AdSlot({
  slotId,
  variant = 'banner',
  className,
}: {
  slotId?: string;
  variant?: 'banner' | 'card';
  className?: string;
}) {
  const pathname = usePathname();
  const { isPlus } = useMockSession();
  const { consentStatus, adsenseClientId } = useAdConsent();
  const pushedRef = useRef(false);

  const visible = shouldRenderWebAds({
    isPlus,
    consentStatus,
    pathname,
  });

  useEffect(() => {
    if (!visible || !adsenseClientId || !slotId || pushedRef.current) return;
    try {
      (window.adsbygoogle = window.adsbygoogle || []).push({});
      pushedRef.current = true;
    } catch {
      // Ignore AdSense push errors in dev/blocked environments
    }
  }, [adsenseClientId, slotId, visible]);

  if (!visible) return null;

  // Reserved fixed dimensions prevent Cumulative Layout Shift (CLS = 0) and
  // the slot is intentionally never animated.
  const reservedHeightClass =
    variant === 'card' ? 'min-h-[250px]' : 'min-h-[90px]';

  return (
    <aside
      aria-label="Sponsored advertisement"
      className={cn(
        'flex w-full items-center justify-center overflow-hidden rounded-xl border border-border/60 bg-card/60 px-3 py-2 text-center',
        reservedHeightClass,
        className,
      )}
    >
      {adsenseClientId && slotId ? (
        <ins
          className="adsbygoogle block w-full"
          style={{
            display: 'block',
            minHeight: variant === 'card' ? '230px' : '72px',
          }}
          data-ad-client={adsenseClientId}
          data-ad-slot={slotId}
          data-ad-format="auto"
          data-full-width-responsive="true"
        />
      ) : (
        <div className="space-y-1">
          <p className="text-[10px] font-medium tracking-wider text-muted-foreground uppercase">
            Sponsored · Free tier
          </p>
          <p className="text-xs text-muted-foreground">
            AdSense slot reserved ({variant === 'card' ? '300×250' : '728×90'})
          </p>
        </div>
      )}
    </aside>
  );
}
