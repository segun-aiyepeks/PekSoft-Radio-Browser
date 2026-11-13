import fs from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const sharp = require('sharp');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '../../..');

const squareSvgPath = path.join(repoRoot, 'brand/app-icon-square.svg');
const roundedSvgPath = path.join(repoRoot, 'brand/logo-mark.svg');

const squareSvg = fs.readFileSync(squareSvgPath);
const roundedSvg = fs.readFileSync(roundedSvgPath);

function buildIco(pngBuffers) {
  const count = pngBuffers.length;
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0); // reserved
  header.writeUInt16LE(1, 2); // type 1 = ICO
  header.writeUInt16LE(count, 4);

  const dirEntries = [];
  let offset = 6 + count * 16;

  for (const { size, data } of pngBuffers) {
    const entry = Buffer.alloc(16);
    entry.writeUInt8(size >= 256 ? 0 : size, 0);
    entry.writeUInt8(size >= 256 ? 0 : size, 1);
    entry.writeUInt8(0, 2); // color palette
    entry.writeUInt8(0, 3); // reserved
    entry.writeUInt16LE(1, 4); // color planes
    entry.writeUInt16LE(32, 6); // bits per pixel
    entry.writeUInt32LE(data.length, 8);
    entry.writeUInt32LE(offset, 12);
    dirEntries.push(entry);
    offset += data.length;
  }

  return Buffer.concat([header, ...dirEntries, ...pngBuffers.map((p) => p.data)]);
}

async function main() {
  // 1. 1024px PNG from square icon (Play Store / master asset)
  const png1024Out = path.join(repoRoot, 'brand/app-icon-1024.png');
  await sharp(squareSvg, { density: 384 })
    .resize(1024, 1024)
    .png()
    .toFile(png1024Out);

  // 2. Android launcher icons (from square SVG so Android launcher mask shapes it cleanly)
  const androidMipmaps = [
    { dir: 'mipmap-mdpi', size: 48 },
    { dir: 'mipmap-hdpi', size: 72 },
    { dir: 'mipmap-xhdpi', size: 96 },
    { dir: 'mipmap-xxhdpi', size: 144 },
    { dir: 'mipmap-xxxhdpi', size: 192 },
  ];

  for (const { dir, size } of androidMipmaps) {
    const out = path.join(
      repoRoot,
      'apps/mobile/android/app/src/main/res',
      dir,
      'ic_launcher.png'
    );
    fs.mkdirSync(path.dirname(out), { recursive: true });
    await sharp(squareSvg, { density: 384 }).resize(size, size).png().toFile(out);
  }

  // 3. Web favicons & app icons
  const webAppDir = path.join(repoRoot, 'apps/web/src/app');
  const webPublicIconsDir = path.join(repoRoot, 'apps/web/public/icons');
  fs.mkdirSync(webPublicIconsDir, { recursive: true });

  await sharp(roundedSvg, { density: 384 })
    .resize(512, 512)
    .png()
    .toFile(path.join(webAppDir, 'icon.png'));

  await sharp(squareSvg, { density: 384 })
    .resize(180, 180)
    .png()
    .toFile(path.join(webAppDir, 'apple-icon.png'));

  await sharp(squareSvg, { density: 384 })
    .resize(192, 192)
    .png()
    .toFile(path.join(webPublicIconsDir, 'icon-192.png'));

  await sharp(squareSvg, { density: 384 })
    .resize(512, 512)
    .png()
    .toFile(path.join(webPublicIconsDir, 'icon-512.png'));

  const png16 = await sharp(roundedSvg, { density: 384 }).resize(16, 16).png().toBuffer();
  const png32 = await sharp(roundedSvg, { density: 384 }).resize(32, 32).png().toBuffer();
  const png48 = await sharp(roundedSvg, { density: 384 }).resize(48, 48).png().toBuffer();

  fs.writeFileSync(path.join(webPublicIconsDir, 'favicon-16x16.png'), png16);
  fs.writeFileSync(path.join(webPublicIconsDir, 'favicon-32x32.png'), png32);
  fs.writeFileSync(
    path.join(webAppDir, 'favicon.ico'),
    buildIco([
      { size: 16, data: png16 },
      { size: 32, data: png32 },
      { size: 48, data: png48 },
    ])
  );

  console.log('Generated brand/app-icon-1024.png, Android mipmaps, and web favicons.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
