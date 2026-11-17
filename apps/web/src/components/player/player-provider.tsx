'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import type Hls from 'hls.js';
import { APP_NAME } from '@peksoft/shared';
import { toast } from 'sonner';
import { probeStreamCors } from '@/lib/audio-cors';
import type { WebStation } from '@/lib/mock-data';
import {
  isHlsStream,
  runWithFailoverAndRetries,
  type PlaybackStatus,
} from '@/lib/player-failover';

export interface PlayerContextValue {
  currentStation: WebStation | null;
  status: PlaybackStatus;
  isPlaying: boolean;
  isBuffering: boolean;
  error: string | null;
  volume: number;
  isMuted: boolean;
  corsAnalyserActive: boolean;
  analyserLevels: readonly number[];
  playStation: (station: WebStation) => void;
  togglePlayPause: () => void;
  retry: () => void;
  stop: () => void;
  setVolume: (vol: number) => void;
  toggleMute: () => void;
}

const PlayerContext = createContext<PlayerContextValue | null>(null);

const IDLE_LEVELS = [0.2, 0.35, 0.25, 0.3] as const;

export function PlayerProvider({
  children,
  initialStation = null,
  onStationPlay,
}: {
  children: React.ReactNode;
  initialStation?: WebStation | null;
  onStationPlay?: (station: WebStation) => void;
}) {
  const [currentStation, setCurrentStation] = useState<WebStation | null>(
    initialStation,
  );
  const [status, setStatus] = useState<PlaybackStatus>('idle');
  const [error, setError] = useState<string | null>(null);
  const [volume, setVolumeState] = useState<number>(80);
  const [isMuted, setIsMuted] = useState<boolean>(false);
  const [corsAnalyserActive, setCorsAnalyserActive] = useState<boolean>(false);
  const [analyserLevels, setAnalyserLevels] =
    useState<readonly number[]>(IDLE_LEVELS);

  // Separate plain audio element (never touched by Web Audio API) from the
  // CORS-only audio element so non-CORS streams are never silenced.
  const plainAudioRef = useRef<HTMLAudioElement | null>(null);
  const corsAudioRef = useRef<HTMLAudioElement | null>(null);
  const activeAudioRef = useRef<HTMLAudioElement | null>(null);
  const hlsRef = useRef<Hls | null>(null);

  const audioCtxRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const corsSourceBoundRef = useRef<boolean>(false);
  const rafRef = useRef<number | null>(null);

  const playRequestIdRef = useRef<number>(0);
  const statusRef = useRef<PlaybackStatus>('idle');
  const currentStationRef = useRef<WebStation | null>(initialStation);
  const isRecoveringRef = useRef<boolean>(false);
  const volumeRef = useRef<number>(80);
  const isMutedRef = useRef<boolean>(false);

  statusRef.current = status;
  currentStationRef.current = currentStation;
  volumeRef.current = volume;
  isMutedRef.current = isMuted;

  const ensurePlainAudio = useCallback((): HTMLAudioElement | null => {
    if (typeof window === 'undefined') return null;
    if (!plainAudioRef.current) {
      const audio = document.createElement('audio');
      audio.preload = 'none';
      audio.setAttribute('playsinline', '');
      plainAudioRef.current = audio;
    }
    return plainAudioRef.current;
  }, []);

  const ensureCorsAudio = useCallback((): HTMLAudioElement | null => {
    if (typeof window === 'undefined') return null;
    if (!corsAudioRef.current) {
      const audio = document.createElement('audio');
      audio.preload = 'none';
      audio.crossOrigin = 'anonymous';
      audio.setAttribute('playsinline', '');
      corsAudioRef.current = audio;
    }
    return corsAudioRef.current;
  }, []);

  const stopAnalyserLoop = useCallback(() => {
    if (rafRef.current !== null) {
      cancelAnimationFrame(rafRef.current);
      rafRef.current = null;
    }
    setCorsAnalyserActive(false);
    setAnalyserLevels(IDLE_LEVELS);
  }, []);

  const startAnalyserLoop = useCallback((corsAudio: HTMLAudioElement) => {
    if (typeof window === 'undefined') return;
    const AudioContextCtor =
      window.AudioContext ||
      (window as unknown as { webkitAudioContext?: typeof AudioContext })
        .webkitAudioContext;
    if (!AudioContextCtor) return;

    try {
      if (!audioCtxRef.current) {
        audioCtxRef.current = new AudioContextCtor();
      }
      const ctx = audioCtxRef.current;
      if (ctx.state === 'suspended') {
        void ctx.resume();
      }
      if (!analyserRef.current) {
        const analyser = ctx.createAnalyser();
        analyser.fftSize = 32;
        analyser.smoothingTimeConstant = 0.75;
        analyserRef.current = analyser;
      }
      if (!corsSourceBoundRef.current) {
        const source = ctx.createMediaElementSource(corsAudio);
        source.connect(analyserRef.current);
        analyserRef.current.connect(ctx.destination);
        corsSourceBoundRef.current = true;
      }

      const analyser = analyserRef.current;
      const data = new Uint8Array(analyser.frequencyBinCount);
      setCorsAnalyserActive(true);

      const tick = () => {
        if (statusRef.current !== 'playing') {
          setAnalyserLevels(IDLE_LEVELS);
          rafRef.current = null;
          return;
        }
        analyser.getByteFrequencyData(data);
        const bars = [
          Math.max(0.18, (data[1] ?? 0) / 255),
          Math.max(0.18, (data[3] ?? 0) / 255),
          Math.max(0.18, (data[5] ?? 0) / 255),
          Math.max(0.18, (data[7] ?? 0) / 255),
        ];
        setAnalyserLevels(bars);
        rafRef.current = requestAnimationFrame(tick);
      };
      if (rafRef.current !== null) {
        cancelAnimationFrame(rafRef.current);
      }
      rafRef.current = requestAnimationFrame(tick);
    } catch {
      setCorsAnalyserActive(false);
    }
  }, []);

  const teardownActiveStream = useCallback(() => {
    stopAnalyserLoop();
    if (hlsRef.current) {
      hlsRef.current.destroy();
      hlsRef.current = null;
    }
    for (const el of [plainAudioRef.current, corsAudioRef.current]) {
      if (el) {
        el.pause();
        el.removeAttribute('src');
        el.load();
      }
    }
    activeAudioRef.current = null;
  }, [stopAnalyserLoop]);

  const attemptPlayUrl = useCallback(
    async (
      station: WebStation,
      url: string,
      requestId: number,
    ): Promise<boolean> => {
      if (requestId !== playRequestIdRef.current) return false;

      const isHls = isHlsStream(url, station.isHls);
      // Probe CORS only for non-HLS streams; only connect Web Audio API if allowed.
      const allowCorsAnalyser = !isHls && (await probeStreamCors(url));
      if (requestId !== playRequestIdRef.current) return false;

      teardownActiveStream();

      const audio = allowCorsAnalyser ? ensureCorsAudio() : ensurePlainAudio();
      if (!audio) return false;

      activeAudioRef.current = audio;
      audio.volume = isMutedRef.current ? 0 : volumeRef.current / 100;

      const canPlayNativeHls =
        isHls && audio.canPlayType('application/vnd.apple.mpegurl') !== '';

      if (isHls && !canPlayNativeHls) {
        try {
          const { default: HlsLib } = await import('hls.js');
          if (requestId !== playRequestIdRef.current) return false;
          if (!HlsLib.isSupported()) {
            return false;
          }

          return await new Promise<boolean>((resolve) => {
            const hls = new HlsLib({
              enableWorker: true,
              lowLatencyMode: true,
            });
            hlsRef.current = hls;

            let settled = false;
            const finish = (ok: boolean) => {
              if (settled) return;
              settled = true;
              window.clearTimeout(timer);
              resolve(ok);
            };

            const timer = window.setTimeout(() => {
              hls.destroy();
              if (hlsRef.current === hls) hlsRef.current = null;
              finish(false);
            }, 10000);

            hls.on(HlsLib.Events.MANIFEST_PARSED, async () => {
              if (requestId !== playRequestIdRef.current) {
                finish(false);
                return;
              }
              try {
                await audio.play();
                finish(true);
              } catch {
                finish(false);
              }
            });

            hls.on(HlsLib.Events.ERROR, (_event, data) => {
              if (data.fatal) {
                hls.destroy();
                if (hlsRef.current === hls) hlsRef.current = null;
                finish(false);
              }
            });

            hls.loadSource(url);
            hls.attachMedia(audio);
          });
        } catch {
          return false;
        }
      }

      return await new Promise<boolean>((resolve) => {
        let settled = false;
        const cleanup = () => {
          audio.removeEventListener('canplay', onCanPlay);
          audio.removeEventListener('error', onError);
          window.clearTimeout(timer);
        };
        const finish = (ok: boolean) => {
          if (settled) return;
          settled = true;
          cleanup();
          resolve(ok);
        };

        const onCanPlay = async () => {
          if (requestId !== playRequestIdRef.current) {
            finish(false);
            return;
          }
          try {
            await audio.play();
            if (allowCorsAnalyser) {
              startAnalyserLoop(audio);
            }
            finish(true);
          } catch {
            finish(false);
          }
        };

        const onError = () => finish(false);

        const timer = window.setTimeout(() => finish(false), 10000);
        audio.addEventListener('canplay', onCanPlay, { once: true });
        audio.addEventListener('error', onError, { once: true });
        audio.src = url;
        audio.load();
      });
    },
    [ensureCorsAudio, ensurePlainAudio, startAnalyserLoop, teardownActiveStream],
  );

  const startPlaybackWithFailover = useCallback(
    async (station: WebStation, skipInitial = false) => {
      const requestId = ++playRequestIdRef.current;
      isRecoveringRef.current = true;
      setError(null);

      try {
        const ok = await runWithFailoverAndRetries({
          station,
          skipInitial,
          attemptPlayUrl: (url) => attemptPlayUrl(station, url, requestId),
          isCancelled: () => requestId !== playRequestIdRef.current,
          onStatusChange: (nextStatus) => {
            if (requestId !== playRequestIdRef.current) return;
            setStatus(nextStatus);
            if (nextStatus === 'unavailable') {
              setError(
                `Could not connect to ${station.name}. Tap Retry or choose another station.`,
              );
            }
          },
        });
        if (!ok && requestId === playRequestIdRef.current) {
          teardownActiveStream();
        }
      } finally {
        if (requestId === playRequestIdRef.current) {
          isRecoveringRef.current = false;
        }
      }
    },
    [attemptPlayUrl, teardownActiveStream],
  );

  const playStation = useCallback(
    (station: WebStation) => {
      setCurrentStation(station);
      onStationPlay?.(station);

      if (!station.isHttpsPlayable) {
        playRequestIdRef.current += 1;
        teardownActiveStream();
        setStatus('unavailable');
        setError('HTTP-only stream — best in the mobile app.');
        toast.info(`${station.name} is HTTP-only — best in the mobile app.`);
        return;
      }

      void startPlaybackWithFailover(station, false);
    },
    [onStationPlay, startPlaybackWithFailover, teardownActiveStream],
  );

  const togglePlayPause = useCallback(() => {
    const station = currentStationRef.current;
    if (!station) return;

    if (!station.isHttpsPlayable) {
      toast.info(`${station.name} is HTTP-only — best in the mobile app.`);
      return;
    }

    const currentStatus = statusRef.current;
    const audio = activeAudioRef.current;

    if (
      currentStatus === 'playing' ||
      currentStatus === 'connecting' ||
      currentStatus === 'reconnecting'
    ) {
      playRequestIdRef.current += 1;
      isRecoveringRef.current = false;
      audio?.pause();
      stopAnalyserLoop();
      setStatus('paused');
      return;
    }

    if (currentStatus === 'paused' && audio && audio.src) {
      void audio
        .play()
        .then(() => {
          setStatus('playing');
          if (audio === corsAudioRef.current) {
            startAnalyserLoop(audio);
          }
        })
        .catch(() => {
          void startPlaybackWithFailover(station, false);
        });
      return;
    }

    void startPlaybackWithFailover(station, false);
  }, [startAnalyserLoop, startPlaybackWithFailover, stopAnalyserLoop]);

  const retry = useCallback(() => {
    const station = currentStationRef.current;
    if (!station) return;
    playStation(station);
  }, [playStation]);

  const stop = useCallback(() => {
    playRequestIdRef.current += 1;
    isRecoveringRef.current = false;
    teardownActiveStream();
    setStatus('idle');
    setError(null);
  }, [teardownActiveStream]);

  const setVolume = useCallback((vol: number) => {
    const clamped = Math.max(0, Math.min(100, Math.round(vol)));
    setVolumeState(clamped);
    if (clamped > 0 && isMutedRef.current) {
      setIsMuted(false);
    }
    if (activeAudioRef.current) {
      activeAudioRef.current.volume = clamped / 100;
    }
  }, []);

  const toggleMute = useCallback(() => {
    setIsMuted((prev) => {
      const next = !prev;
      if (activeAudioRef.current) {
        activeAudioRef.current.volume = next ? 0 : volumeRef.current / 100;
      }
      return next;
    });
  }, []);

  // Mid-stream drop recovery
  useEffect(() => {
    const handleStreamError = () => {
      const station = currentStationRef.current;
      if (
        !station ||
        !station.isHttpsPlayable ||
        statusRef.current !== 'playing' ||
        isRecoveringRef.current
      ) {
        return;
      }
      void startPlaybackWithFailover(station, true);
    };

    const plain = ensurePlainAudio();
    const cors = ensureCorsAudio();
    plain?.addEventListener('error', handleStreamError);
    cors?.addEventListener('error', handleStreamError);
    return () => {
      plain?.removeEventListener('error', handleStreamError);
      cors?.removeEventListener('error', handleStreamError);
    };
  }, [ensureCorsAudio, ensurePlainAudio, startPlaybackWithFailover]);

  // Tab title showing the current station
  useEffect(() => {
    if (typeof document === 'undefined') return;
    if (currentStation && status === 'playing') {
      document.title = `▶ ${currentStation.name} — ${APP_NAME}`;
    } else if (
      currentStation &&
      (status === 'connecting' || status === 'reconnecting')
    ) {
      document.title = `⏳ ${currentStation.name} — ${APP_NAME}`;
    } else {
      document.title = APP_NAME;
    }
  }, [currentStation, status]);

  // Media Session API integration
  useEffect(() => {
    if (typeof navigator === 'undefined' || !('mediaSession' in navigator)) {
      return;
    }
    const ms = navigator.mediaSession;
    if (currentStation) {
      ms.metadata = new MediaMetadata({
        title: currentStation.name,
        artist:
          currentStation.currentTrack ??
          `${currentStation.countryName} · ${currentStation.language}`,
        album: APP_NAME,
        artwork: currentStation.faviconUrl
          ? [
              {
                src: currentStation.faviconUrl,
                sizes: '512x512',
                type: 'image/png',
              },
            ]
          : [],
      });
    } else {
      ms.metadata = null;
    }

    ms.playbackState =
      status === 'playing'
        ? 'playing'
        : status === 'paused'
          ? 'paused'
          : 'none';

    ms.setActionHandler('play', () => {
      if (statusRef.current !== 'playing') {
        togglePlayPause();
      }
    });
    ms.setActionHandler('pause', () => {
      if (statusRef.current === 'playing') {
        togglePlayPause();
      }
    });
    ms.setActionHandler('stop', () => stop());

    return () => {
      ms.setActionHandler('play', null);
      ms.setActionHandler('pause', null);
      ms.setActionHandler('stop', null);
    };
  }, [currentStation, status, stop, togglePlayPause]);

  // Global keyboard shortcuts: k / Space (outside interactive controls), m (mute), Shift+ArrowUp/Down (volume)
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.ctrlKey || event.metaKey || event.altKey) return;
      const target = event.target as HTMLElement | null;
      if (target) {
        const tag = target.tagName;
        if (
          tag === 'INPUT' ||
          tag === 'TEXTAREA' ||
          tag === 'SELECT' ||
          target.isContentEditable
        ) {
          return;
        }
      }

      if (event.key === 'k' || event.key === 'K') {
        event.preventDefault();
        togglePlayPause();
        return;
      }

      if (event.code === 'Space') {
        const isInteractive =
          target &&
          (target.tagName === 'BUTTON' ||
            target.tagName === 'A' ||
            target.getAttribute('role') === 'button' ||
            target.getAttribute('role') === 'slider');
        if (!isInteractive) {
          event.preventDefault();
          togglePlayPause();
        }
        return;
      }

      if (event.key === 'm' || event.key === 'M') {
        event.preventDefault();
        toggleMute();
        return;
      }

      if (event.shiftKey && event.key === 'ArrowUp') {
        event.preventDefault();
        setVolume(volumeRef.current + 10);
        return;
      }

      if (event.shiftKey && event.key === 'ArrowDown') {
        event.preventDefault();
        setVolume(volumeRef.current - 10);
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [setVolume, toggleMute, togglePlayPause]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      playRequestIdRef.current += 1;
      teardownActiveStream();
      void audioCtxRef.current?.close();
      audioCtxRef.current = null;
    };
  }, [teardownActiveStream]);

  const isPlaying = status === 'playing';
  const isBuffering = status === 'connecting' || status === 'reconnecting';

  const value = useMemo<PlayerContextValue>(
    () => ({
      currentStation,
      status,
      isPlaying,
      isBuffering,
      error,
      volume,
      isMuted,
      corsAnalyserActive,
      analyserLevels,
      playStation,
      togglePlayPause,
      retry,
      stop,
      setVolume,
      toggleMute,
    }),
    [
      currentStation,
      status,
      isPlaying,
      isBuffering,
      error,
      volume,
      isMuted,
      corsAnalyserActive,
      analyserLevels,
      playStation,
      togglePlayPause,
      retry,
      stop,
      setVolume,
      toggleMute,
    ],
  );

  return (
    <PlayerContext.Provider value={value}>{children}</PlayerContext.Provider>
  );
}

export function usePlayer(): PlayerContextValue {
  const ctx = useContext(PlayerContext);
  if (!ctx) {
    throw new Error('usePlayer must be used inside PlayerProvider');
  }
  return ctx;
}
