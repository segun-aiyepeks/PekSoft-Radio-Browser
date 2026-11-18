/**
 * Probes whether a stream URL allows cross-origin reads (`Access-Control-Allow-Origin`).
 *
 * Web Audio API's `createMediaElementSource()` silences playback if the audio
 * element loads a cross-origin stream without CORS headers. We NEVER attach
 * `crossOrigin="anonymous"` or `AudioContext` unless this probe succeeds.
 */
export async function probeStreamCors(
  url: string,
  signal?: AbortSignal,
): Promise<boolean> {
  if (typeof window === 'undefined' || typeof fetch === 'undefined') {
    return false;
  }

  const controller = new AbortController();
  const timeoutId = window.setTimeout(() => controller.abort(), 2000);

  const onAbort = () => controller.abort();
  signal?.addEventListener('abort', onAbort, { once: true });

  try {
    const response = await fetch(url, {
      method: 'HEAD',
      mode: 'cors',
      credentials: 'omit',
      signal: controller.signal,
    });
    return response.ok;
  } catch {
    return false;
  } finally {
    window.clearTimeout(timeoutId);
    signal?.removeEventListener('abort', onAbort);
  }
}
