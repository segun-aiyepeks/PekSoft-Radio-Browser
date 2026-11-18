import { describe, expect, it, vi } from 'vitest';
import { probeStreamCors } from './audio-cors';
import {
  getCandidateStreamUrls,
  isHlsStream,
  runWithFailoverAndRetries,
  type PlaybackStatus,
} from './player-failover';

describe('isHlsStream', () => {
  it('detects .m3u8 URLs with or without query strings and respects flag', () => {
    expect(isHlsStream('https://cdn.example.com/live/stream.m3u8')).toBe(true);
    expect(
      isHlsStream('https://cdn.example.com/live/playlist.M3U8?token=abc'),
    ).toBe(true);
    expect(isHlsStream('https://cdn.example.com/live.mp3', false)).toBe(false);
    expect(isHlsStream('https://cdn.example.com/live', true)).toBe(true);
  });
});

describe('getCandidateStreamUrls', () => {
  it('returns primary and distinct fallback, deduplicating identical URLs', () => {
    expect(
      getCandidateStreamUrls({
        streamUrl: ' https://a.test/1.mp3 ',
        fallbackStreamUrl: 'https://b.test/2.mp3',
      }),
    ).toEqual(['https://a.test/1.mp3', 'https://b.test/2.mp3']);

    expect(
      getCandidateStreamUrls({
        streamUrl: 'https://a.test/1.mp3',
        fallbackStreamUrl: 'https://a.test/1.mp3',
      }),
    ).toEqual(['https://a.test/1.mp3']);
  });
});

describe('runWithFailoverAndRetries', () => {
  it('plays primary without retries when it succeeds', async () => {
    const statuses: PlaybackStatus[] = [];
    const attemptPlayUrl = vi.fn(async () => true);

    const ok = await runWithFailoverAndRetries({
      station: {
        streamUrl: 'https://primary.test/stream.mp3',
        fallbackStreamUrl: 'https://fallback.test/stream.mp3',
      },
      attemptPlayUrl,
      isCancelled: () => false,
      onStatusChange: (s) => statuses.push(s),
      retryDelaysMs: [10, 20],
      sleep: async () => {},
    });

    expect(ok).toBe(true);
    expect(attemptPlayUrl).toHaveBeenCalledTimes(1);
    expect(attemptPlayUrl).toHaveBeenCalledWith(
      'https://primary.test/stream.mp3',
    );
    expect(statuses).toEqual(['connecting', 'playing']);
  });

  it('fails over immediately to fallbackStreamUrl when primary fails', async () => {
    const statuses: PlaybackStatus[] = [];
    const attemptPlayUrl = vi.fn(
      async (url: string) => url === 'https://fallback.test/stream.mp3',
    );

    const ok = await runWithFailoverAndRetries({
      station: {
        streamUrl: 'https://primary.test/stream.mp3',
        fallbackStreamUrl: 'https://fallback.test/stream.mp3',
      },
      attemptPlayUrl,
      isCancelled: () => false,
      onStatusChange: (s) => statuses.push(s),
      retryDelaysMs: [10, 20],
      sleep: async () => {},
    });

    expect(ok).toBe(true);
    expect(attemptPlayUrl.mock.calls.map((c) => c[0])).toEqual([
      'https://primary.test/stream.mp3',
      'https://fallback.test/stream.mp3',
    ]);
    expect(statuses).toEqual(['connecting', 'playing']);
  });

  it('retries with backoff when both fail and recovers on retry', async () => {
    const statuses: PlaybackStatus[] = [];
    let calls = 0;
    const attemptPlayUrl = vi.fn(async () => {
      calls += 1;
      return calls >= 3;
    });
    const sleep = vi.fn(async () => {});

    const ok = await runWithFailoverAndRetries({
      station: {
        streamUrl: 'https://primary.test/stream.mp3',
        fallbackStreamUrl: 'https://fallback.test/stream.mp3',
      },
      attemptPlayUrl,
      isCancelled: () => false,
      onStatusChange: (s) => statuses.push(s),
      retryDelaysMs: [1000, 3000],
      sleep,
    });

    expect(ok).toBe(true);
    expect(sleep).toHaveBeenCalledWith(1000);
    expect(statuses).toEqual(['connecting', 'reconnecting', 'playing']);
  });

  it('marks unavailable after exhausting all retries', async () => {
    const statuses: PlaybackStatus[] = [];
    const ok = await runWithFailoverAndRetries({
      station: { streamUrl: 'https://primary.test/stream.mp3' },
      attemptPlayUrl: async () => false,
      isCancelled: () => false,
      onStatusChange: (s) => statuses.push(s),
      retryDelaysMs: [10, 20],
      sleep: async () => {},
    });

    expect(ok).toBe(false);
    expect(statuses).toEqual([
      'connecting',
      'reconnecting',
      'reconnecting',
      'unavailable',
    ]);
  });

  it('supports skipInitial for mid-stream recovery and respects cancellation', async () => {
    const statuses: PlaybackStatus[] = [];
    let cancelled = false;
    const attemptPlayUrl = vi.fn(async () => {
      cancelled = true;
      return false;
    });

    const ok = await runWithFailoverAndRetries({
      station: { streamUrl: 'https://primary.test/stream.mp3' },
      attemptPlayUrl,
      isCancelled: () => cancelled,
      onStatusChange: (s) => statuses.push(s),
      retryDelaysMs: [10, 20],
      skipInitial: true,
      sleep: async () => {},
    });

    expect(ok).toBe(false);
    expect(statuses).toEqual(['reconnecting']);
  });
});

describe('probeStreamCors', () => {
  it('returns false when fetch throws or is non-ok, and true when ok', async () => {
    const originalWindow = globalThis.window;
    const originalFetch = globalThis.fetch;
    (globalThis as unknown as { window: typeof globalThis }).window =
      globalThis;

    globalThis.fetch = vi.fn(async () => {
      throw new TypeError('CORS blocked');
    }) as unknown as typeof fetch;
    expect(await probeStreamCors('https://no-cors.test/live.mp3')).toBe(false);

    globalThis.fetch = vi.fn(async () => ({
      ok: true,
    })) as unknown as typeof fetch;
    expect(await probeStreamCors('https://cors.test/live.mp3')).toBe(true);

    globalThis.fetch = originalFetch;
    if (originalWindow === undefined) {
      delete (globalThis as unknown as { window?: typeof globalThis }).window;
    }
  });
});
