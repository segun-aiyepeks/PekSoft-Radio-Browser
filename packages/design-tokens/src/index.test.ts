import { describe, expect, it } from 'vitest';
import { DESIGN_TOKENS_VERSION, tokens } from './index.js';

describe('@peksoft/design-tokens', () => {
  it('exports version and dark/light themes', () => {
    expect(DESIGN_TOKENS_VERSION).toBe('1.0.0');
    expect(tokens.colors.dark.background).toBe('#0A0F1C');
    expect(tokens.colors.light.background).toBe('#F6F4EE');
    expect(tokens.typography.fontFamily).toBe('Space Grotesk');
  });
});
