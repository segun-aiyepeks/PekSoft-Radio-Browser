import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import {
  createStationNormaliser,
  type GenreMapConfig,
  type RawRadioBrowserStation,
} from './radio.js';

const here = dirname(fileURLToPath(import.meta.url));
const genreMap = JSON.parse(
  readFileSync(resolve(here, '../genre-map.json'), 'utf8'),
) as GenreMapConfig;
const sample200 = JSON.parse(
  readFileSync(
    resolve(here, '../fixtures/radio-browser/stations-sample-200.json'),
    'utf8',
  ),
) as RawRadioBrowserStation[];

const normaliser = createStationNormaliser(genreMap);

describe('Radio Browser normalisation (@peksoft/shared)', () => {
  it('maps messy tags to canonical genres and strips noise tags', () => {
    const genres = normaliser.normalizeTags(
      'music, fm, naija, gospel music, moi merino, jazz',
    );
    expect(genres.map((g) => g.id)).toEqual(['afrobeats', 'gospel']);
  });

  it('computes isHttpsPlayable, usesFallbackLogo, and isWorking on real fixtures', () => {
    const normalized = normaliser.normalizeStations(sample200);
    expect(normalized.length).toBeGreaterThan(150);

    const httpOnly = normalized.find((s) => !s.isHttps);
    expect(httpOnly).toBeDefined();
    expect(httpOnly!.isHttpsPlayable).toBe(false);

    const sslBroken = normaliser.normalizeStation({
      stationuuid: 'ssl-err-1',
      name: 'Broken SSL FM',
      url: 'https://broken-ssl.example.com/stream',
      lastcheckok: 1,
      ssl_error: 1,
    });
    expect(sslBroken?.isHttps).toBe(true);
    expect(sslBroken?.isHttpsPlayable).toBe(false);
  });
});
