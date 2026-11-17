'use client';

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
} from 'react';
import { toast } from 'sonner';
import { PlayerProvider, usePlayer } from '@/components/player/player-provider';
import { MOCK_STATIONS, type WebStation } from '@/lib/mock-data';

interface MockSessionContextValue {
  currentStation: WebStation | null;
  isPlaying: boolean;
  volume: number;
  favouriteIds: string[];
  recentIds: string[];
  isPlus: boolean;
  dataSaver: boolean;
  workingNowDefault: boolean;
  playStation: (station: WebStation) => void;
  togglePlayPause: () => void;
  setVolume: (vol: number) => void;
  toggleFavourite: (station: WebStation) => void;
  setDataSaver: (enabled: boolean) => void;
  setWorkingNowDefault: (enabled: boolean) => void;
  playSurpriseMe: () => void;
}

const MockSessionContext = createContext<MockSessionContextValue | null>(null);

function MockSessionInner({
  children,
  favouriteIds,
  recentIds,
  dataSaver,
  workingNowDefault,
  toggleFavourite,
  setDataSaver,
  setWorkingNowDefault,
}: {
  children: React.ReactNode;
  favouriteIds: string[];
  recentIds: string[];
  dataSaver: boolean;
  workingNowDefault: boolean;
  toggleFavourite: (station: WebStation) => void;
  setDataSaver: (enabled: boolean) => void;
  setWorkingNowDefault: (enabled: boolean) => void;
}) {
  const {
    currentStation,
    isPlaying,
    volume,
    playStation,
    togglePlayPause,
    setVolume,
  } = usePlayer();

  const playSurpriseMe = useCallback(() => {
    const working = MOCK_STATIONS.filter(
      (s) => s.isWorking && s.isHttpsPlayable,
    );
    const pool = working.length > 0 ? working : MOCK_STATIONS;
    const pick = pool[Math.floor(Math.random() * pool.length)];
    if (pick) {
      playStation(pick);
    }
  }, [playStation]);

  const value = useMemo<MockSessionContextValue>(
    () => ({
      currentStation,
      isPlaying,
      volume,
      favouriteIds,
      recentIds,
      isPlus: false,
      dataSaver,
      workingNowDefault,
      playStation,
      togglePlayPause,
      setVolume,
      toggleFavourite,
      setDataSaver,
      setWorkingNowDefault,
      playSurpriseMe,
    }),
    [
      currentStation,
      isPlaying,
      volume,
      favouriteIds,
      recentIds,
      dataSaver,
      workingNowDefault,
      playStation,
      togglePlayPause,
      setVolume,
      toggleFavourite,
      setDataSaver,
      setWorkingNowDefault,
      playSurpriseMe,
    ],
  );

  return (
    <MockSessionContext.Provider value={value}>
      {children}
    </MockSessionContext.Provider>
  );
}

export function MockSessionProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const [favouriteIds, setFavouriteIds] = useState<string[]>([
    'st-cool-fm',
    'st-fip-paris',
  ]);
  const [recentIds, setRecentIds] = useState<string[]>([
    'st-cool-fm',
    'st-bbc-world',
  ]);
  const [dataSaver, setDataSaver] = useState(false);
  const [workingNowDefault, setWorkingNowDefault] = useState(true);

  const recordRecent = useCallback((station: WebStation) => {
    setRecentIds((prev) => [
      station.id,
      ...prev.filter((id) => id !== station.id),
    ]);
  }, []);

  const toggleFavourite = useCallback((station: WebStation) => {
    setFavouriteIds((prev) => {
      const exists = prev.includes(station.id);
      if (exists) {
        toast('Removed from Favourites');
        return prev.filter((id) => id !== station.id);
      }
      toast.success(`Saved ${station.name} to Favourites`);
      return [station.id, ...prev];
    });
  }, []);

  return (
    <PlayerProvider
      initialStation={MOCK_STATIONS[0] ?? null}
      onStationPlay={recordRecent}
    >
      <MockSessionInner
        favouriteIds={favouriteIds}
        recentIds={recentIds}
        dataSaver={dataSaver}
        workingNowDefault={workingNowDefault}
        toggleFavourite={toggleFavourite}
        setDataSaver={setDataSaver}
        setWorkingNowDefault={setWorkingNowDefault}
      >
        {children}
      </MockSessionInner>
    </PlayerProvider>
  );
}

export function useMockSession(): MockSessionContextValue {
  const ctx = useContext(MockSessionContext);
  if (!ctx) {
    throw new Error('useMockSession must be used inside MockSessionProvider');
  }
  return ctx;
}
