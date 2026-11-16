import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import {
  createStationNormaliser,
  type GenreMapConfig,
  type StationNormaliser,
} from '@peksoft/shared';

const require = createRequire(import.meta.url);

export function loadSharedGenreMap(): GenreMapConfig {
  const genreMapPath = require.resolve('@peksoft/shared/genre-map.json');
  return JSON.parse(readFileSync(genreMapPath, 'utf8')) as GenreMapConfig;
}

export const defaultStationNormaliser: StationNormaliser =
  createStationNormaliser(loadSharedGenreMap());
