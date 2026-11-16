/**
 * Cache abstraction so an in-memory LRU cache can be swapped for Redis
 * without changing service or route code.
 */
export interface CacheStore {
  get<T>(key: string): Promise<T | null>;
  set<T>(key: string, value: T, ttlMs: number): Promise<void>;
  delete(key: string): Promise<void>;
  clear(): Promise<void>;
}
