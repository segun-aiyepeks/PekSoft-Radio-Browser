import { notFound } from 'next/navigation';
import { DevComponentsGallery } from './components-gallery';

export const dynamic = 'force-dynamic';

export default function DevComponentsPage() {
  if (
    process.env.NODE_ENV === 'production' &&
    process.env.ALLOW_DEV_GALLERY !== 'true'
  ) {
    notFound();
  }

  return <DevComponentsGallery />;
}
