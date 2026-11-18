const CACHE_NAME = 'peksoft-radio-shell-v1';
const AUDIO_EXT_RE = /\.(mp3|aac|aacp|ogg|opus|flac|wav|m3u8|m3u|pls|ts)(\?|$)/i;

function isAudioOrStreamRequest(request) {
  if (request.destination === 'audio' || request.destination === 'video') {
    return true;
  }
  if (request.headers && request.headers.has('range')) {
    return true;
  }
  const url = new URL(request.url);
  if (AUDIO_EXT_RE.test(url.pathname)) {
    return true;
  }
  return false;
}

self.addEventListener('install', (event) => {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  // Never intercept cross-origin requests (radio streams, CDN audio, AdSense, API)
  if (url.origin !== self.location.origin) return;

  // Never cache audio or range requests
  if (isAudioOrStreamRequest(request)) return;

  // Cache-first / stale-while-revalidate only for static Next.js build assets
  if (url.pathname.startsWith('/_next/static/')) {
    event.respondWith(
      caches.open(CACHE_NAME).then(async (cache) => {
        const cached = await cache.match(request);
        const networkPromise = fetch(request)
          .then((res) => {
            if (res.ok) cache.put(request, res.clone());
            return res;
          })
          .catch(() => cached);
        return cached || networkPromise;
      }),
    );
    return;
  }

  // Network-first for HTML/documents so ISR updates are always fresh
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request).catch(async () => {
        const cache = await caches.open(CACHE_NAME);
        return (await cache.match('/home')) || Response.error();
      }),
    );
  }
});
