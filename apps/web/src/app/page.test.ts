import { describe, expect, it } from 'vitest';
import { APP_NAME } from '@peksoft/shared';

describe('@peksoft/web', () => {
  it('resolves shared app name', () => {
    expect(APP_NAME).toBe('PekSoft Radio Browser');
  });
});
