'use client';

import { useEffect, useState } from 'react';
import { usePathname, useSearchParams } from 'next/navigation';
import { PekSoftSignalLoader } from '@/components/radio/peksoft-signal-loader';

export function RouteLoadingProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [navigating, setNavigating] = useState(false);

  const routeKey = `${pathname}?${searchParams.toString()}`;

  // Clear loading overlay whenever the route finishes changing
  useEffect(() => {
    setNavigating(false);
  }, [routeKey]);

  // Show centered PekSoft signal loader immediately when clicking internal links
  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if (e.defaultPrevented || e.button !== 0) return;
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;

      const anchor = (e.target as HTMLElement | null)?.closest('a');
      if (!anchor) return;
      if (anchor.target && anchor.target !== '_self') return;
      if (anchor.hasAttribute('download')) return;

      const href = anchor.getAttribute('href');
      if (!href || href.startsWith('#') || href.startsWith('mailto:') || href.startsWith('tel:')) {
        return;
      }

      try {
        const nextUrl = new URL(anchor.href, window.location.href);
        if (nextUrl.origin !== window.location.origin) return;
        const currentFull = `${window.location.pathname}${window.location.search}`;
        const nextFull = `${nextUrl.pathname}${nextUrl.search}`;
        if (currentFull === nextFull) return;
        setNavigating(true);
      } catch {
        // Ignore invalid URLs
      }
    };

    document.addEventListener('click', onClick, true);
    return () => document.removeEventListener('click', onClick, true);
  }, []);

  // Safety fallback in case a navigation is aborted
  useEffect(() => {
    if (!navigating) return;
    const timer = window.setTimeout(() => setNavigating(false), 10000);
    return () => window.clearTimeout(timer);
  }, [navigating]);

  return (
    <>
      {children}
      {navigating && (
        <div
          aria-hidden="false"
          className="fixed inset-0 z-50 flex items-center justify-center bg-background/80"
        >
          <PekSoftSignalLoader label="Searching for signal…" />
        </div>
      )}
    </>
  );
}
