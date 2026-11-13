import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const pkgRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(pkgRoot, '../..');

const tokensPath = path.join(pkgRoot, 'tokens.json');
const tokens = JSON.parse(fs.readFileSync(tokensPath, 'utf8'));

function toDartColor(hex) {
  const clean = hex.replace('#', '').toUpperCase();
  return `Color(0xFF${clean})`;
}

function toDartKey(key) {
  // Convert keys like "2xl" -> "s2xl" or keep valid identifiers
  if (/^\d/.test(key)) return `s${key}`;
  return key;
}

function toKebab(str) {
  return str
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .replace(/([a-zA-Z])(\d)/g, '$1-$2')
    .toLowerCase();
}

function toFontWeightDart(weight) {
  const map = {
    400: 'FontWeight.w400',
    500: 'FontWeight.w500',
    600: 'FontWeight.w600',
    700: 'FontWeight.w700',
  };
  return map[weight] ?? 'FontWeight.w400';
}

function generateDart(t) {
  const darkLines = Object.entries(t.colors.dark)
    .map(([k, v]) => `  static const Color ${k} = ${toDartColor(v)};`)
    .join('\n');

  const lightLines = Object.entries(t.colors.light)
    .map(([k, v]) => `  static const Color ${k} = ${toDartColor(v)};`)
    .join('\n');

  const typeLines = Object.entries(t.typography.scale)
    .map(
      ([k, v]) =>
        `  static const TextStyle ${k} = TextStyle(\n` +
        `    fontFamily: fontFamily,\n` +
        `    fontSize: ${v.fontSize},\n` +
        `    height: ${(v.lineHeight / v.fontSize).toFixed(3)},\n` +
        `    fontWeight: ${toFontWeightDart(v.fontWeight)},\n` +
        `    letterSpacing: ${v.letterSpacing},\n` +
        `  );`
    )
    .join('\n\n');

  const spacingLines = Object.entries(t.spacing)
    .map(([k, v]) => `  static const double ${toDartKey(k)} = ${v.toFixed(1)};`)
    .join('\n');

  const radiiLines = Object.entries(t.radii)
    .map(([k, v]) => `  static const double ${k} = ${v.toFixed(1)};`)
    .join('\n');

  const elevationLines = Object.entries(t.elevation)
    .map(
      ([k, v]) =>
        `  static const List<BoxShadow> ${k} = [\n` +
        `    BoxShadow(\n` +
        `      color: Color.fromRGBO(0, 0, 0, ${v.opacity}),\n` +
        `      offset: Offset(0, ${v.offsetY}),\n` +
        `      blurRadius: ${v.blur},\n` +
        `      spreadRadius: ${v.spread},\n` +
        `    ),\n` +
        `  ];`
    )
    .join('\n\n');

  const durationLines = Object.entries(t.motion.durationsMs)
    .map(([k, v]) => `  static const Duration ${k} = Duration(milliseconds: ${v});`)
    .join('\n');

  return `// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: packages/design-tokens/tokens.json

import 'package:flutter/material.dart';

abstract final class AppDarkColors {
${darkLines}
}

abstract final class AppLightColors {
${lightLines}
}

abstract final class AppTypography {
  static const String fontFamily = '${t.typography.fontFamily}';

${typeLines}
}

abstract final class AppSpacing {
${spacingLines}
}

abstract final class AppRadii {
${radiiLines}
}

abstract final class AppElevation {
${elevationLines}
}

abstract final class AppDurations {
${durationLines}
}
`;
}

function generateCss(t) {
  const darkVars = Object.entries(t.colors.dark)
    .map(([k, v]) => `  --color-${toKebab(k)}: ${v};`)
    .join('\n');

  const lightVars = Object.entries(t.colors.light)
    .map(([k, v]) => `  --color-${toKebab(k)}: ${v};`)
    .join('\n');

  const spacingVars = Object.entries(t.spacing)
    .map(([k, v]) => `  --spacing-${toKebab(k)}: ${v}px;`)
    .join('\n');

  const radiiVars = Object.entries(t.radii)
    .map(([k, v]) => `  --radius-${toKebab(k)}: ${v === 9999 ? '9999px' : `${v}px`};`)
    .join('\n');

  const durationVars = Object.entries(t.motion.durationsMs)
    .map(([k, v]) => `  --duration-${toKebab(k)}: ${v}ms;`)
    .join('\n');

  const typeVars = Object.entries(t.typography.scale)
    .map(
      ([k, v]) =>
        `  --text-${toKebab(k)}: ${v.fontSize}px;\n` +
        `  --text-${toKebab(k)}--line-height: ${v.lineHeight}px;\n` +
        `  --text-${toKebab(k)}--letter-spacing: ${v.letterSpacing}px;\n` +
        `  --text-${toKebab(k)}--font-weight: ${v.fontWeight};`
    )
    .join('\n');

  const themeColorMappings = Object.keys(t.colors.dark)
    .map((k) => `  --color-${toKebab(k)}: var(--color-${toKebab(k)});`)
    .join('\n');

  return `/* GENERATED FILE - DO NOT MODIFY BY HAND.
 * Source: packages/design-tokens/tokens.json
 */

:root,
[data-theme='dark'] {
${darkVars}
${spacingVars}
${radiiVars}
${durationVars}
}

[data-theme='light'] {
${lightVars}
}

@theme inline {
  --font-sans: '${t.typography.fontFamily}', ui-sans-serif, system-ui, sans-serif;
${themeColorMappings}
${typeVars}
}
`;
}

function generateTs(t) {
  return `// GENERATED FILE - DO NOT MODIFY BY HAND.
// Source: packages/design-tokens/tokens.json

export const tokens = ${JSON.stringify(t, null, 2)} as const;

export type DesignTokens = typeof tokens;
`;
}

const dartOut = path.join(repoRoot, 'apps/mobile/lib/core/theme/design_tokens.dart');
const webCssOut = path.join(repoRoot, 'apps/web/src/app/tokens.css');
const pkgCssOut = path.join(pkgRoot, 'dist/tokens.css');
const tsOut = path.join(pkgRoot, 'src/generated.ts');

for (const file of [dartOut, webCssOut, pkgCssOut, tsOut]) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
}

fs.writeFileSync(dartOut, generateDart(tokens), 'utf8');
const css = generateCss(tokens);
fs.writeFileSync(webCssOut, css, 'utf8');
fs.writeFileSync(pkgCssOut, css, 'utf8');
fs.writeFileSync(tsOut, generateTs(tokens), 'utf8');

console.log('Generated design tokens:');
console.log(' -', path.relative(repoRoot, dartOut));
console.log(' -', path.relative(repoRoot, webCssOut));
console.log(' -', path.relative(repoRoot, pkgCssOut));
console.log(' -', path.relative(repoRoot, tsOut));
