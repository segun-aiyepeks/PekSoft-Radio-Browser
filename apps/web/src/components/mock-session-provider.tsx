'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import { toast } from 'sonner';
import { useAuth } from '@/components/auth/auth-provider';
import { PlayerProvider, usePlayer } from '@/components/player/player-provider';
import {
  deltaSyncLibrary,
  deleteLibraryFavorite,
  fetchLibraryCollections,
  fetchLibraryFavorites,
  fetchLibraryRecents,
  fetchLibrarySongHistory,
  upsertLibraryFavorite,
  upsertLibraryRecent,
  type LibraryCollectionRecord,
  type LibrarySongHistoryRecord,
} from '@/lib/library-api';
import { MOCK_STATIONS, type WebStation } from '@/lib/mock-data';

interface MockSessionContextValue {
  currentStation: WebStation | null;
  isPlaying: boolean;
  volume: number;
  favouriteIds: string[];
  recentIds: string[];
  collections: LibraryCollectionRecord[];
  songHistory: LibrarySongHistoryRecord[];
  syncing: boolean;
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
  syncNow: () => Promise<void>;
}

const MockSessionContext = createContext<MockSessionContextValue | null>(null);

function MockSessionInner({
  children,
  favouriteIds,
  recentIds,
  collections,
  songHistory,
  syncing,
  isPlus,
  dataSaver,
  workingNowDefault,
  toggleFavourite,
  setDataSaver,
  setWorkingNowDefault,
  syncNow,
}: {
  children: React.ReactNode;
  favouriteIds: string[];
  recentIds: string[];
  collections: LibraryCollectionRecord[];
  songHistory: LibrarySongHistoryRecord[];
  syncing: boolean;
  isPlus: boolean;
  dataSaver: boolean;
  workingNowDefault: boolean;
  toggleFavourite: (station: WebStation) => void;
  setDataSaver: (enabled: boolean) => void;
  setWorkingNowDefault: (enabled: boolean) => void;
  syncNow: () => Promise<void>;
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
      collections,
      songHistory,
      syncing,
      isPlus,
      dataSaver,
      workingNowDefault,
      playStation,
      togglePlayPause,
      setVolume,
      toggleFavourite,
      setDataSaver,
      setWorkingNowDefault,
      playSurpriseMe,
      syncNow,
    }),
    [
      currentStation,
      isPlaying,
      volume,
      favouriteIds,
      recentIds,
      collections,
      songHistory,
      syncing,
      isPlus,
      dataSaver,
      workingNowDefault,
      playStation,
      togglePlayPause,
      setVolume,
      toggleFavourite,
      setDataSaver,
      setWorkingNowDefault,
      playSurpriseMe,
      syncNow,
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
  const { user, isPlus, getIdToken } = useAuth();
  const [favouriteIds, setFavouriteIds] = useState<string[]>([
    'st-cool-fm',
    'st-fip-paris',
  ]);
  const [recentIds, setRecentIds] = useState<string[]>([
    'st-cool-fm',
    'st-bbc-world',
  ]);
  const [collections, setCollections] = useState<LibraryCollectionRecord[]>([]);
  const [songHistory, setSongHistory] = useState<LibrarySongHistoryRecord[]>([]);
  const [syncing, setSyncing] = useState(false);
  const [dataSaver, setDataSaver] = useState(false);
  const [workingNowDefault, setWorkingNowDefault] = useState(true);

  const syncNow = useCallback(async () => {
    if (!user) return;
    setSyncing(true);
    try {
      const token = await getIdToken();
      if (!token) return;
      await deltaSyncLibrary(token, {
        favorites: [],
        collections: [],
        recents: [],
        songHistory: [],
      });
      const [favs, recs, cols, hist] = await Promise.all([
        fetchLibraryFavorites(token),
        fetchLibraryRecents(token),
        fetchLibraryCollections(token),
        fetchLibrarySongHistory(token),
      ]);
      if (favs) setFavouriteIds(favs.map((f) => f.stationId));
      if (recs) setRecentIds(recs.map((r) => r.stationId));
      if (cols) setCollections(cols);
      if (hist) setSongHistory(hist);
    } finally {
      setSyncing(false);
    }
  }, [getIdToken, user]);

  useEffect(() => {
    if (user) {
      void syncNow();
    }
  }, [syncNow, user]);

  const recordRecent = useCallback(
    (station: WebStation) => {
      setRecentIds((prev) => [
        station.id,
        ...prev.filter((id) => id !== station.id),
      ]);
      if (user) {
        void getIdToken().then((token) => {
          if (!token) return;
          void upsertLibraryRecent(token, {
            stationId: station.id,
            stationName: station.name,
            streamUrl: station.streamUrl,
            countryCode: station.countryCode,
            playedAt: new Date().toISOString(),
          });
        });
      }
    },
    [getIdToken, user],
  );

  const toggleFavourite = useCallback(
    (station: WebStation) => {
      setFavouriteIds((prev) => {
        const exists = prev.includes(station.id);
        if (exists) {
          toast('Removed from Favourites');
          if (user) {
            void getIdToken().then((token) => {
              if (token) void deleteLibraryFavorite(token, station.id);
            });
          }
          return prev.filter((id) => id !== station.id);
        }
        toast.success(`Saved ${station.name} to Favourites`);
        if (user) {
          void getIdToken().then((token) => {
            if (!token) return;
            void upsertLibraryFavorite(token, {
              stationId: station.id,
              stationName: station.name,
              streamUrl: station.streamUrl,
              countryCode: station.countryCode,
              faviconUrl: station.faviconUrl,
              codec: station.codec,
              bitrateKbps: station.bitrateKbps,
              isDeleted: false,
            });
          });
        }
        return [station.id, ...prev];
      });
    },
    [getIdToken, user],
  );

  return (
    <PlayerProvider
      initialStation={MOCK_STATIONS[0] ?? null}
      onStationPlay={recordRecent}
    >
      <MockSessionInner
        favouriteIds={favouriteIds}
        recentIds={recentIds}
        collections={collections}
        songHistory={songHistory}
        syncing={syncing}
        isPlus={isPlus}
        dataSaver={dataSaver}
        workingNowDefault={workingNowDefault}
        toggleFavourite={toggleFavourite}
        setDataSaver={setDataSaver}
        setWorkingNowDefault={setWorkingNowDefault}
        syncNow={syncNow}
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
