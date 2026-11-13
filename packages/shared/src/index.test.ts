import { describe, expect, it } from 'vitest';
import { APP_NAME, appInfoSchema } from './index.js';

describe('@peksoft/shared', () => {
  it('validates app info', () => {
    const parsed = appInfoSchema.parse({ name: APP_NAME, version: '0.1.0' });
    expect(parsed.name).toBe('PekSoft Radio Browser');
  });
});
