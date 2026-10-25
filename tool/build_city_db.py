#!/usr/bin/env python3
"""Builds assets/db/cities.db, the SQLite city database bundled with the app.

Sources:
  * The curated cities in lib/src/data/cities.dart (kept as-is, marked
    `featured`, and always ranked first).
  * The "Countries States Cities Database" by dr5hn (ODbL v1.0):
    https://github.com/dr5hn/countries-states-cities-database

Usage:
  curl -LO https://github.com/dr5hn/countries-states-cities-database/releases/latest/download/json-cities.json.gz
  gunzip json-cities.json.gz
  curl -LO https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/json/countries.json
  curl -LO https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/json/states.json
  python3 tool/build_city_db.py json-cities.json countries.json states.json

Writes assets/db/cities.db and lib/src/data/city_db_info.g.dart.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sqlite3
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CURATED_DART = ROOT / 'lib/src/data/cities.dart'
DB_PATH = ROOT / 'assets/db/cities.db'
INFO_DART = ROOT / 'lib/src/data/city_db_info.g.dart'

# Bump when the schema or contents change so installed apps re-copy the asset.
DB_VERSION = 1

# --- Normalisation: must stay in sync with normalizeForSearch() in
# lib/src/core/utils/arabic_text.dart.

_DIACRITICS = re.compile('[ؐ-ًؚ-ٰٟۖ-ۭـ]')
_NON_SEARCHABLE = re.compile('[^ء-ي0-9a-zA-Z ]')
_WHITESPACE = re.compile(r'\s+')
_LETTER_MAP = {
    0x0622: 0x0627, 0x0623: 0x0627, 0x0625: 0x0627, 0x0671: 0x0627,
    0x0649: 0x064A, 0x0629: 0x0647, 0x0624: 0x0621, 0x0626: 0x0621,
}
# Latin letters that do not decompose under NFKD.
_LATIN_EXTRA = {
    'ß': 'ss', 'ø': 'o', 'Ø': 'o', 'ł': 'l', 'Ł': 'l', 'đ': 'd', 'Đ': 'd',
    'ı': 'i', 'æ': 'ae', 'Æ': 'ae', 'œ': 'oe', 'Œ': 'oe', 'þ': 'th',
    'ð': 'd', 'ħ': 'h',
}


def fold_latin(text: str) -> str:
    out = []
    for ch in text:
        if '؀' <= ch <= 'ۿ':
            out.append(ch)
        elif ch in _LATIN_EXTRA:
            out.append(_LATIN_EXTRA[ch])
        else:
            out.append(''.join(
                c for c in unicodedata.normalize('NFKD', ch)
                if not unicodedata.combining(c)))
    return ''.join(out)


def normalize(text: str) -> str:
    text = _DIACRITICS.sub('', fold_latin(text))
    buf = []
    for ch in text:
        cp = ord(ch)
        if cp in _LETTER_MAP:
            buf.append(chr(_LETTER_MAP[cp]))
        elif 0x0660 <= cp <= 0x0669:
            buf.append(chr(cp - 0x0660 + 0x30))
        elif 0x06F0 <= cp <= 0x06F9:
            buf.append(chr(cp - 0x06F0 + 0x30))
        else:
            buf.append(ch)
    text = _NON_SEARCHABLE.sub(' ', ''.join(buf))
    return _WHITESPACE.sub(' ', text).strip().lower()


def search_text(*names: str | None) -> str:
    """Space-padded, de-duplicated normalised names so `LIKE '% x%'` also
    works for word-prefix matches."""
    seen: list[str] = []
    for name in names:
        if name:
            n = normalize(name)
            if n and n not in seen:
                seen.append(n)
    return ' ' + ' | '.join(seen) + ' '


# --- Helpers

def km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 6371 * 2 * math.asin(math.sqrt(a))


def strip_article(name: str) -> str:
    for prefix in ('مدينه ', 'ال'):
        if name.startswith(prefix):
            name = name[len(prefix):]
    return name.replace(' ', '')


_CURATED_RE = re.compile(
    r"City\(id: '([^']+)', name: '([^']+)', country: '([^']+)', "
    r"countryCode: '([A-Z]{2})', latitude: (-?[\d.]+), longitude: (-?[\d.]+), "
    r"timeZone: '([^']+)'\)")


def load_curated() -> list[dict]:
    body = CURATED_DART.read_text(encoding='utf-8')
    body = body[body.index('const List<City> kFeaturedCities'):]
    body = body[:body.index('];')]
    rows = [
        dict(id=m[0], name=m[1], country=m[2], cc=m[3], lat=float(m[4]),
             lng=float(m[5]), tz=m[6])
        for m in _CURATED_RE.findall(body)
    ]
    if len(rows) != body.count('City('):
        raise SystemExit('could not parse every curated City(...) entry')
    return rows


# Wrong Arabic translations in the source, by city id.
_ARABIC_FIXES = {
    104990: 'درعا',  # Dar‘ā, Syria (source: «جديدة»)
    153359: 'دره بازاري',  # Derepazarı, Turkey (source: «طرابزون»)
}


def arabic(record: dict) -> str | None:
    if 'state_id' in record and record.get('id') in _ARABIC_FIXES:
        return _ARABIC_FIXES[record['id']]
    value = (record.get('translations') or {}).get('ar')
    return value.strip() if value and value.strip() else None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('cities')
    parser.add_argument('countries')
    parser.add_argument('states')
    args = parser.parse_args()

    cities = json.loads(Path(args.cities).read_text(encoding='utf-8'))
    countries = json.loads(Path(args.countries).read_text(encoding='utf-8'))
    states = json.loads(Path(args.states).read_text(encoding='utf-8'))
    curated = load_curated()

    country_ar: dict[str, str] = {}
    country_rows = []
    for c in countries:
        cc = c['iso2']
        name_ar = arabic(c) or c['name']
        country_ar[cc] = name_ar
        country_rows.append((cc, name_ar, c['name'],
                             search_text(name_ar, c['name'], c.get('native'))))
    # Curated Arabic country names win (e.g. «بريطانيا», «السعودية»).
    for row in curated:
        country_ar[row['cc']] = row['country']
    country_rows = [
        (cc, country_ar[cc], en, search_text(country_ar[cc]) + s)
        for cc, _, en, s in country_rows
    ]

    state_ar = {s['id']: arabic(s) or s['name'] for s in states}

    # Drop dataset entries that duplicate a curated city.
    by_country: dict[str, list[dict]] = {}
    for c in cities:
        by_country.setdefault(c['country_code'], []).append(c)
    replaced: set[int] = set()
    best_hit: dict[str, dict] = {}
    unmatched = []
    for row in curated:
        target = strip_article(normalize(row['name']))
        slug = row['id'].split('-', 1)[1].replace('-', '')
        hits = []
        for c in by_country.get(row['cc'], []):
            d = km(row['lat'], row['lng'], float(c['latitude']), float(c['longitude']))
            # Region-level entries can sit tens of km from the city centre.
            if d > 60:
                continue
            ar = strip_article(normalize(arabic(c) or ''))
            en = normalize(c['name']).replace(' ', '')
            if (ar and ar == target) or en == slug or (d < 15 and en.startswith(slug)):
                hits.append(c)
        replaced.update(c['id'] for c in hits)
        if hits:
            best_hit[row['id']] = max(hits, key=lambda c: c.get('population') or 0)
        else:
            unmatched.append(row['id'])

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()
    db = sqlite3.connect(DB_PATH)
    db.executescript(f'''
        PRAGMA page_size = 4096;
        PRAGMA user_version = {DB_VERSION};
        CREATE TABLE countries (
          code TEXT PRIMARY KEY,
          name_ar TEXT NOT NULL,
          name_en TEXT NOT NULL,
          search TEXT NOT NULL
        ) WITHOUT ROWID;
        CREATE TABLE regions (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL
        );
        CREATE TABLE time_zones (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL
        );
        CREATE TABLE cities (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          region_id INTEGER NOT NULL REFERENCES regions (id),
          country_code TEXT NOT NULL REFERENCES countries (code),
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          time_zone_id INTEGER NOT NULL REFERENCES time_zones (id),
          population INTEGER NOT NULL,
          featured INTEGER NOT NULL,
          search TEXT NOT NULL
        );
        CREATE INDEX cities_country ON cities (country_code, population DESC);
    ''')
    db.executemany('INSERT INTO countries VALUES (?, ?, ?, ?)', country_rows)

    regions: dict[str, int] = {'': 0}
    zones: dict[str, int] = {}

    def region_id(name: str) -> int:
        return regions.setdefault(name, len(regions))

    def zone_id(name: str) -> int:
        return zones.setdefault(name, len(zones))

    rows = []
    for row in curated:
        # Borrow the English name and population of the entry it replaces.
        hit = best_hit.get(row['id'], {})
        name_en = hit.get('name') or row['id'].split('-', 1)[1]
        rows.append((row['id'], row['name'], 0, row['cc'],
                     row['lat'], row['lng'], zone_id(row['tz']),
                     int(hit.get('population') or 0), 1,
                     search_text(row['name'], name_en, hit and arabic(hit))))
    seen: set[tuple] = set()
    skipped = 0
    for c in cities:
        if not c.get('timezone') or c['country_code'] not in country_ar:
            skipped += 1
            continue
        if c['id'] in replaced:
            continue
        name = arabic(c) or c['name']
        region = state_ar.get(c['state_id'], c.get('state_name') or '')
        if region == name:
            region = ''
        lat, lng = float(c['latitude']), float(c['longitude'])
        # The source repeats some places verbatim; keep the first.
        key = (name, c['country_code'], region, round(lat, 2), round(lng, 2))
        if key in seen:
            continue
        seen.add(key)
        rows.append((
            f"csc-{c['id']}",
            name,
            region_id(region),
            c['country_code'],
            round(lat, 5),
            round(lng, 5),
            zone_id(c['timezone']),
            int(c.get('population') or 0),
            0,
            search_text(arabic(c), c['name'], c.get('native')),
        ))
    db.executemany('INSERT INTO regions VALUES (?, ?)',
                   [(i, n) for n, i in regions.items()])
    db.executemany('INSERT INTO time_zones VALUES (?, ?)',
                   [(i, n) for n, i in zones.items()])
    db.executemany(
        'INSERT INTO cities VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', rows)
    db.commit()
    db.execute('VACUUM')
    db.close()

    count = len(rows)
    INFO_DART.write_text(
        '// GENERATED by tool/build_city_db.py. Do not edit by hand.\n\n'
        f'const int kCityDbVersion = {DB_VERSION};\n\n'
        f'const int kCityDbCount = {count};\n',
        encoding='utf-8')

    print(f'{count} cities ({len(curated)} curated, {len(replaced)} replaced by '
          f'curated, {len(cities) - count + len(curated) - len(replaced) - skipped} '
          f'repeats dropped, {skipped} skipped) → {DB_PATH.relative_to(ROOT)} '
          f'({DB_PATH.stat().st_size / 1e6:.1f} MB)')
    if unmatched:
        print('curated cities with no dataset match (kept anyway):',
              ', '.join(unmatched))


if __name__ == '__main__':
    main()
