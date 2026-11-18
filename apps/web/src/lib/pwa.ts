const AUDIO_EXT_RE =
  /\.(mp3|aac|aacp|ogg|opus|flac|wav|m3u8|m3u|pls|ts)(\?|$)/i;

export function isCacheableShellRequest(params: {
  method: string;
  url: string;
  appOrigin: string;
  destination?: string;
  hasRangeHeader?: boolean;
}): boolean {
  if (params.method.toUpperCase() !== 'GET') return false;
  if (params.destination === 'audio' || params.destination === 'video') {
    return false;
  }
  if (params.hasRangeHeader) return false;

  let parsed: URL;
  try {
    parsed = new URL(params.url);
  } catch {
    return false;
  }

  if (parsed.origin !== params.appOrigin) return false;
  if (AUDIO_EXT_RE.test(parsed.pathname)) return false;

  return parsed.pathname.startsWith('/_next/static/');
}

export function shouldShowGetAppBanner(params: {
  engaged: boolean;
  dismissed: boolean;
  isStandalone: boolean;
}): boolean {
  if (params.dismissed || params.isStandalone) return false;
  return params.engaged;
}
