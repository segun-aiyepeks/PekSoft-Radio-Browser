import dns from 'node:dns/promises';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '../../..');
const fixturesDir = path.join(repoRoot, 'packages/shared/fixtures/radio-browser');

const USER_AGENT = 'PekSoftRadioBrowser/0.1.0';
const HEADERS = {
  'User-Agent': USER_AGENT,
  Accept: 'application/json',
};

type JsonRecord = Record<string, unknown>;

async function fetchJsonWithTiming<T>(
  url: string,
  timeoutMs = 10_000
): Promise<{ data: T; latencyMs: number }> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  const start = performance.now();
  try {
    const res = await fetch(url, {
      headers: HEADERS,
      signal: controller.signal,
    });
    if (!res.ok) {
      throw new Error(`HTTP ${res.status} ${res.statusText} for ${url}`);
    }
    const data = (await res.json()) as T;
    const latencyMs = Math.round(performance.now() - start);
    return { data, latencyMs };
  } finally {
    clearTimeout(timer);
  }
}

async function discoverMirrors() {
  // 1a. DNS A record lookup + reverse PTR on all.api.radio-browser.info
  const dnsStart = performance.now();
  const ips = await dns.resolve4('all.api.radio-browser.info');
  const dnsLookupMs = Math.round(performance.now() - dnsStart);

  const dnsMirrors: Array<{ ip: string; host: string | null }> = [];
  for (const ip of ips) {
    try {
      const hosts = await dns.reverse(ip);
      dnsMirrors.push({ ip, host: hosts[0] ?? null });
    } catch {
      dnsMirrors.push({ ip, host: null });
    }
  }

  // 1b. DNS SRV lookup (_api._tcp.radio-browser.info)
  let srvRecords: Array<{ name: string; port: number; priority: number; weight: number }> = [];
  try {
    srvRecords = await dns.resolveSrv('_api._tcp.radio-browser.info');
  } catch {
    srvRecords = [];
  }

  // 1c. Server-list endpoint on all.api.radio-browser.info
  const serverListRes = await fetchJsonWithTiming<Array<{ ip: string; name: string }>>(
    'https://all.api.radio-browser.info/json/servers'
  );

  // Deduplicate HTTPS hostnames from server-list + DNS
  const hostSet = new Set<string>();
  for (const s of serverListRes.data) {
    if (s.name) hostSet.add(s.name);
  }
  for (const d of dnsMirrors) {
    if (d.host) hostSet.add(d.host);
  }
  for (const srv of srvRecords) {
    if (srv.name) hostSet.add(srv.name);
  }

  // Measure latency of each unique mirror via /json/stats
  const mirrorLatencies: Array<{
    host: string;
    ok: boolean;
    latencyMs: number | null;
    error?: string;
  }> = [];

  for (const host of hostSet) {
    try {
      const ping = await fetchJsonWithTiming<JsonRecord>(
        `https://${host}/json/stats`,
        6_000
      );
      mirrorLatencies.push({ host, ok: true, latencyMs: ping.latencyMs });
    } catch (err) {
      mirrorLatencies.push({
        host,
        ok: false,
        latencyMs: null,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }

  mirrorLatencies.sort((a, b) => {
    if (a.ok && !b.ok) return -1;
    if (!a.ok && b.ok) return 1;
    return (a.latencyMs ?? Infinity) - (b.latencyMs ?? Infinity);
  });

  return {
    dnsLookupMs,
    dnsMirrors,
    srvRecords,
    serverListLatencyMs: serverListRes.latencyMs,
    serverListRaw: serverListRes.data,
    mirrorLatencies,
  };
}

function inspectFieldTypes(records: JsonRecord[]) {
  const fieldMap = new Map<
    string,
    { types: Set<string>; emptyCount: number; sample: unknown }
  >();

  for (const rec of records) {
    for (const [key, val] of Object.entries(rec)) {
      let entry = fieldMap.get(key);
      if (!entry) {
        entry = { types: new Set(), emptyCount: 0, sample: val };
        fieldMap.set(key, entry);
      }
      const typeLabel = val === null ? 'null' : Array.isArray(val) ? 'array' : typeof val;
      entry.types.add(typeLabel);
      if (val === '' || val === null || val === undefined) {
        entry.emptyCount += 1;
      }
      if ((entry.sample === '' || entry.sample === null) && val !== '' && val !== null) {
        entry.sample = val;
      }
    }
  }

  return Array.from(fieldMap.entries()).map(([field, info]) => ({
    field,
    types: Array.from(info.types),
    emptyCount: info.emptyCount,
    sample: info.sample,
  }));
}

function analyseStations(stations: JsonRecord[]) {
  const total = stations.length;
  let resolvedHttps = 0;
  let resolvedHttp = 0;
  let resolvedOther = 0;
  let httpOnly = 0;
  let missingFavicon = 0;
  let hlsCount = 0;
  let lastCheckOkCount = 0;

  const codecCounts = new Map<string, number>();
  const bitrateBuckets = {
    zeroOrUnknown: 0,
    low_1_to_64: 0,
    medium_65_to_128: 0,
    high_129_to_192: 0,
    ultra_gt_192: 0,
  };
  const bitrates: number[] = [];

  const tagFrequency = new Map<string, number>();
  const tagLowerGroups = new Map<string, Set<string>>();

  for (const st of stations) {
    const url = String(st.url ?? '');
    const urlResolved = String(st.url_resolved ?? '');
    const favicon = String(st.favicon ?? '').trim();
    const hls = Number(st.hls ?? 0);
    const lastCheckOk = Number(st.lastcheckok ?? 0);
    const codec = String(st.codec ?? '').trim() || '(empty)';
    const bitrate = Number(st.bitrate ?? 0);
    const rawTags = String(st.tags ?? '');

    if (urlResolved.startsWith('https://')) {
      resolvedHttps += 1;
    } else if (urlResolved.startsWith('http://')) {
      resolvedHttp += 1;
    } else {
      resolvedOther += 1;
    }

    if (!urlResolved.startsWith('https://') && !url.startsWith('https://')) {
      httpOnly += 1;
    }

    if (!favicon) missingFavicon += 1;
    if (hls === 1) hlsCount += 1;
    if (lastCheckOk === 1) lastCheckOkCount += 1;

    codecCounts.set(codec, (codecCounts.get(codec) ?? 0) + 1);

    bitrates.push(bitrate);
    if (bitrate <= 0) bitrateBuckets.zeroOrUnknown += 1;
    else if (bitrate <= 64) bitrateBuckets.low_1_to_64 += 1;
    else if (bitrate <= 128) bitrateBuckets.medium_65_to_128 += 1;
    else if (bitrate <= 192) bitrateBuckets.high_129_to_192 += 1;
    else bitrateBuckets.ultra_gt_192 += 1;

    if (rawTags.trim()) {
      for (const rawTag of rawTags.split(',')) {
        const trimmed = rawTag.trim();
        if (!trimmed) continue;
        tagFrequency.set(trimmed, (tagFrequency.get(trimmed) ?? 0) + 1);
        const lower = trimmed.toLowerCase();
        const set = tagLowerGroups.get(lower) ?? new Set<string>();
        set.add(trimmed);
        tagLowerGroups.set(lower, set);
      }
    }
  }

  const caseCollisions = Array.from(tagLowerGroups.entries())
    .filter(([, variants]) => variants.size > 1)
    .map(([lower, variants]) => ({ lower, variants: Array.from(variants) }));

  const sortedBitrates = [...bitrates].filter((b) => b > 0).sort((a, b) => a - b);
  const medianBitrate =
    sortedBitrates.length > 0
      ? sortedBitrates[Math.floor(sortedBitrates.length / 2)]
      : 0;

  return {
    total,
    lastCheckOkCount,
    resolvedHttps,
    resolvedHttpsPct: Number(((resolvedHttps / total) * 100).toFixed(1)),
    resolvedHttp,
    resolvedOther,
    httpOnly,
    httpOnlyPct: Number(((httpOnly / total) * 100).toFixed(1)),
    missingFavicon,
    missingFaviconPct: Number(((missingFavicon / total) * 100).toFixed(1)),
    hlsCount,
    hlsPct: Number(((hlsCount / total) * 100).toFixed(1)),
    codecDistribution: Array.from(codecCounts.entries())
      .sort((a, b) => b[1] - a[1])
      .map(([codec, count]) => ({ codec, count })),
    bitrateBuckets,
    medianNonZeroBitrate: medianBitrate,
    caseCollisions,
    topStationTags: Array.from(tagFrequency.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 30),
  };
}

async function main() {
  fs.mkdirSync(fixturesDir, { recursive: true });

  console.log('1. Discovering Radio Browser mirrors...');
  const mirrors = await discoverMirrors();
  const healthyMirrors = mirrors.mirrorLatencies.filter((m) => m.ok);
  if (healthyMirrors.length === 0) {
    throw new Error('No healthy Radio Browser mirrors discovered.');
  }

  const primaryHost = healthyMirrors[0]!.host;
  console.log(`   Using fastest mirror: https://${primaryHost} (${healthyMirrors[0]!.latencyMs} ms)`);

  async function fetchFromMirrors<T>(endpointPath: string): Promise<T> {
    let lastError: unknown;
    for (const m of healthyMirrors) {
      try {
        const res = await fetchJsonWithTiming<T>(`https://${m.host}${endpointPath}`, 15_000);
        return res.data;
      } catch (err) {
        lastError = err;
      }
    }
    throw lastError;
  }

  console.log('2. Fetching countries, tags, and languages...');
  const countries = await fetchFromMirrors<JsonRecord[]>(
    '/json/countries?order=stationcount&reverse=true'
  );
  const tags = await fetchFromMirrors<JsonRecord[]>(
    '/json/tags?order=stationcount&reverse=true&limit=500'
  );
  const languages = await fetchFromMirrors<JsonRecord[]>(
    '/json/languages?order=stationcount&reverse=true&limit=200'
  );

  console.log('3. Fetching top stations by clickcount and working Nigerian stations...');
  const topClickStations = await fetchFromMirrors<JsonRecord[]>(
    '/json/stations/topclick/150'
  );
  const ngWorkingStations = await fetchFromMirrors<JsonRecord[]>(
    '/json/stations/search?countrycode=NG&lastcheckok=1&order=clickcount&reverse=true&limit=100'
  );

  // Combine & deduplicate to ~200 stations (prioritising working NG stations + top global)
  const combinedMap = new Map<string, JsonRecord>();
  for (const st of ngWorkingStations) {
    combinedMap.set(String(st.stationuuid), st);
  }
  for (const st of topClickStations) {
    if (combinedMap.size >= 200) break;
    const id = String(st.stationuuid);
    if (!combinedMap.has(id)) {
      combinedMap.set(id, st);
    }
  }
  const sample200 = Array.from(combinedMap.values()).slice(0, 200);

  console.log('4. Saving fixtures to packages/shared/fixtures/radio-browser/...');
  fs.writeFileSync(
    path.join(fixturesDir, 'servers.json'),
    JSON.stringify(mirrors.serverListRaw, null, 2)
  );
  fs.writeFileSync(
    path.join(fixturesDir, 'countries.json'),
    JSON.stringify(countries.slice(0, 150), null, 2)
  );
  fs.writeFileSync(
    path.join(fixturesDir, 'tags.json'),
    JSON.stringify(tags.slice(0, 250), null, 2)
  );
  fs.writeFileSync(
    path.join(fixturesDir, 'languages.json'),
    JSON.stringify(languages.slice(0, 100), null, 2)
  );
  fs.writeFileSync(
    path.join(fixturesDir, 'stations-topclick.json'),
    JSON.stringify(topClickStations.slice(0, 120), null, 2)
  );
  fs.writeFileSync(
    path.join(fixturesDir, 'stations-ng-working.json'),
    JSON.stringify(ngWorkingStations.slice(0, 100), null, 2)
  );
  fs.writeFileSync(
    path.join(fixturesDir, 'stations-sample-200.json'),
    JSON.stringify(sample200, null, 2)
  );

  console.log('5. Analysing live API responses...');
  const tagCaseExamples = new Map<string, Set<string>>();
  for (const t of tags) {
    const name = String(t.name ?? '').trim();
    if (!name) continue;
    const lower = name.toLowerCase();
    const set = tagCaseExamples.get(lower) ?? new Set<string>();
    set.add(name);
    tagCaseExamples.set(lower, set);
  }
  const tagEndpointCollisions = Array.from(tagCaseExamples.entries())
    .filter(([, s]) => s.size > 1)
    .map(([lower, s]) => ({ lower, variants: Array.from(s) }));

  const report = {
    timestamp: new Date().toISOString(),
    mirrors: {
      dnsLookupMs: mirrors.dnsLookupMs,
      dnsMirrors: mirrors.dnsMirrors,
      srvRecords: mirrors.srvRecords,
      serverListLatencyMs: mirrors.serverListLatencyMs,
      serverListCount: mirrors.serverListRaw.length,
      mirrorLatencies: mirrors.mirrorLatencies,
    },
    counts: {
      countriesTotal: countries.length,
      tagsFetched: tags.length,
      languagesFetched: languages.length,
      topClickFetched: topClickStations.length,
      ngWorkingFetched: ngWorkingStations.length,
      sample200Count: sample200.length,
    },
    schemas: {
      stationFields: inspectFieldTypes(sample200),
      countryFields: inspectFieldTypes(countries.slice(0, 50)),
      tagFields: inspectFieldTypes(tags.slice(0, 50)),
      languageFields: inspectFieldTypes(languages.slice(0, 50)),
    },
    stationAnalysisSample200: analyseStations(sample200),
    stationAnalysisTopClick: analyseStations(topClickStations),
    stationAnalysisNgWorking: analyseStations(ngWorkingStations),
    messyTagExamplesFromTagsEndpoint: {
      caseCollisions: tagEndpointCollisions.slice(0, 20),
      sampleTags: tags.slice(0, 60).map((t) => ({
        name: t.name,
        stationcount: t.stationcount,
      })),
    },
  };

  fs.writeFileSync(
    path.join(fixturesDir, 'spike-report.json'),
    JSON.stringify(report, null, 2)
  );

  console.log('\n=== SPIKE SUMMARY ===');
  console.log('Mirrors:', JSON.stringify(report.mirrors.mirrorLatencies, null, 2));
  console.log('Counts:', JSON.stringify(report.counts, null, 2));
  console.log('Sample-200 Analysis:', JSON.stringify(report.stationAnalysisSample200, null, 2));
  console.log('NG Working Analysis:', JSON.stringify(report.stationAnalysisNgWorking, null, 2));
  console.log('Top Click Analysis:', JSON.stringify(report.stationAnalysisTopClick, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
