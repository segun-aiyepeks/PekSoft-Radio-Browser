import { APP_NAME } from '@peksoft/shared';

export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-8 text-center">
      <h1 className="text-3xl font-bold">{APP_NAME}</h1>
      <p className="mt-2 text-sm opacity-75">
        Phase 0 foundation scaffold — no product features yet.
      </p>
    </main>
  );
}
