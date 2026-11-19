import { PekSoftSignalLoader } from '@/components/radio/peksoft-signal-loader';

export default function Loading() {
  return (
    <div className="flex min-h-[70vh] w-full items-center justify-center">
      <PekSoftSignalLoader label="Loading stations…" />
    </div>
  );
}
