export type AdConsentStatus = 'unknown' | 'granted' | 'denied';

export const AD_BLOCKED_PATH_PREFIXES = [
  '/auth',
  '/pricing',
  '/checkout',
] as const;

export function isAdBlockedRoute(pathname: string | null | undefined): boolean {
  if (!pathname) return false;
  const normalized = pathname.toLowerCase();
  return AD_BLOCKED_PATH_PREFIXES.some(
    (prefix) =>
      normalized === prefix || normalized.startsWith(`${prefix}/`),
  );
}

export function shouldRenderWebAds(params: {
  isPlus: boolean;
  consentStatus: AdConsentStatus;
  pathname: string | null | undefined;
}): boolean {
  if (params.isPlus) return false;
  if (params.consentStatus !== 'granted') return false;
  if (isAdBlockedRoute(params.pathname)) return false;
  return true;
}
