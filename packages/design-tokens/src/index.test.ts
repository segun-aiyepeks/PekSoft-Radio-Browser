import { describe, expect, it } from 'vitest';
import { DESIGN_TOKENS_VERSION } from './index.js';

describe('@peksoft/design-tokens', () => {
  it('exports a version string', () => {
    expect(DESIGN_TOKENS_VERSION).toBe('0.1.0');
  });
});
