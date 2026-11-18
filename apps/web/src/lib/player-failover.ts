export type PlaybackStatus =
  | 'idle'
  | 'connecting'
  | 'playing'
  | 'paused'
  | 'reconnecting'
  | 'unavailable';

export const DEFAULT_RETRY_DELAYS_MS = [1000, 3000, 7000] as const;

export interface StreamCandidateStation {
  streamUrl: string;
  fallbackStreamUrl?: string | null;
  isHls?: boolean;
}

export function isHlsStream(url: string, isHlsFlag = false): boolean {
  if (isHlsFlag) return true;
  try {
    const parsed = new URL(url);
    return parsed.pathname.toLowerCase().endsWith('.m3u8');
  } catch {
    return url.toLowerCase().includes('.m3u8');
  }
}

export function getCandidateStreamUrls(
  station: StreamCandidateStation,
): string[] {
  const primary = station.streamUrl.trim();
  const fallback = station.fallbackStreamUrl?.trim();
  const urls: string[] = [];
  if (primary.length > 0) {
    urls.push(primary);
  }
  if (fallback && fallback.length > 0 && fallback !== primary) {
    urls.push(fallback);
  }
  return urls;
}

export interface FailoverOptions {
  station: StreamCandidateStation;
  attemptPlayUrl: (url: string) => Promise<boolean>;
  isCancelled: () => boolean;
  onStatusChange: (status: PlaybackStatus, attempt?: number) => void;
  retryDelaysMs?: readonly number[];
  skipInitial?: boolean;
  sleep?: (ms: number) => Promise<void>;
}

const defaultSleep = (ms: number) =>
  new Promise<void>((resolve) => setTimeout(resolve, ms));

/**
 * Mirrors mobile's PlayerViewModel failover & exponential backoff:
 * 1. Try primary streamUrl, then fallbackStreamUrl (if distinct).
 * 2. On failure (or mid-stream drop with skipInitial=true), enter 'reconnecting'
 *    and retry primary -> fallback across each backoff delay.
 * 3. If all attempts fail, return false so caller marks status 'unavailable'.
 */
export async function runWithFailoverAndRetries({
  station,
  attemptPlayUrl,
  isCancelled,
  onStatusChange,
  retryDelaysMs = DEFAULT_RETRY_DELAYS_MS,
  skipInitial = false,
  sleep = defaultSleep,
}: FailoverOptions): Promise<boolean> {
  const candidates = getCandidateStreamUrls(station);
  if (candidates.length === 0) {
    onStatusChange('unavailable');
    return false;
  }

  const tryCandidates = async (): Promise<boolean> => {
    for (const url of candidates) {
      if (isCancelled()) return false;
      const ok = await attemptPlayUrl(url);
      if (isCancelled()) return false;
      if (ok) return true;
    }
    return false;
  };

  if (!skipInitial) {
    onStatusChange('connecting');
    if (await tryCandidates()) {
      if (!isCancelled()) {
        onStatusChange('playing');
      }
      return true;
    }
  }

  for (let i = 0; i < retryDelaysMs.length; i++) {
    if (isCancelled()) return false;
    onStatusChange('reconnecting', i + 1);
    const delay = retryDelaysMs[i] ?? 0;
    if (delay > 0) {
      await sleep(delay);
    }
    if (isCancelled()) return false;

    if (await tryCandidates()) {
      if (!isCancelled()) {
        onStatusChange('playing');
      }
      return true;
    }
  }

  if (!isCancelled()) {
    onStatusChange('unavailable');
  }
  return false;
}
