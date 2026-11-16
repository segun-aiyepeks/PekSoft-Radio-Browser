import type { CacheStore } from './cache-store.js';

interface CacheEntry<T> {
  value: T;
  expiresAt: number;
}

/**
 * Bounded in-memory LRU cache with per-entry TTL.
 * Uses JavaScript Map insertion order to promote hits and evict the oldest entry.
 */
export class InMemoryLruCache implements CacheStore {
  private readonly store = new Map<string, CacheEntry<unknown>>();
  private readonly maxEntries: number;
  private readonly now: () => number;

  constructor(options: { maxEntries?: number; now?: () => number } = {}) {
    this.maxEntries = options.maxEntries ?? 500;
    this.now = options.now ?? (() => Date.now());
  }

  get size(): number {
    return this.store.size;
  }

  async get<T>(key: string): Promise<T | null> {
    const entry = this.store.get(key);
    if (!entry) {
      return null;
    }
    if (this.now() >= entry.expiresAt) {
      this.store.delete(key);
      return null;
    }
    // Promote to most-recently-used position.
    this.store.delete(key);
    this.store.set(key, entry);
    return entry.value as T;
  }

  async set<T>(key: string, value: T, ttlMs: number): Promise<void> {
    if (ttlMs <= 0) {
      this.store.delete(key);
      return;
    }
    if (this.store.has(key)) {
      this.store.delete(key);
    } else if (this.store.size >= this.maxEntries) {
      const oldestKey = this.store.keys().next().value;
      if (oldestKey !== undefined) {
        this.store.delete(oldestKey);
      }
    }
    this.store.set(key, {
      value,
      expiresAt: this.now() + ttlMs,
    });
  }

  async delete(key: string): Promise<void> {
    this.store.delete(key);
  }

  async clear(): Promise<void> {
    this.store.clear();
  }
}
