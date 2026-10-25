import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../core/utils/arabic_text.dart';
import '../cities.dart';
import '../city_db_info.g.dart';
import '../models/city.dart';

/// Searches the bundled SQLite catalogue of world cities built by
/// tool/build_city_db.py.
abstract final class CityDatabase {
  static const String _asset = 'assets/db/cities.db';
  static const int maxResults = 200;

  // Featured cities first, then names that start with the query, then by size.
  static const String _searchSql = '''
    SELECT c.id, c.name, r.name, c.country_code, k.name_ar,
           c.latitude, c.longitude, z.name
    FROM cities c
    JOIN regions r ON r.id = c.region_id
    JOIN countries k ON k.code = c.country_code
    JOIN time_zones z ON z.id = c.time_zone_id
    WHERE c.search LIKE ?1
       OR c.country_code IN (SELECT code FROM countries WHERE search LIKE ?1)
    ORDER BY c.featured DESC, c.search LIKE ?2 DESC, c.population DESC
    LIMIT ?3
  ''';

  static Future<String>? _path;

  static int get cityCount => kCityDbCount;

  @visibleForTesting
  static void useFile(String path) => _path = Future<String>.value(path);

  /// Cities matching [query] by city or country name, in Arabic or Latin
  /// script. Falls back to the curated cities if the database is unavailable.
  static Future<List<City>> search(String query) async {
    final String needle = normalizeForSearch(query);
    if (needle.isEmpty) {
      return kFeaturedCities;
    }
    final Future<String> pending = _path ??= _install();
    try {
      final String path = await pending;
      return await Isolate.run(() => _query(path, needle));
    } on Object catch (error) {
      debugPrint('City database unavailable: $error');
      if (identical(_path, pending)) {
        _path = null;
      }
      return searchFeaturedCities(query);
    }
  }

  static List<City> _query(String path, String needle) {
    final Database db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final ResultSet rows = db.select(_searchSql, <Object>[
        '%$needle%',
        '% $needle%',
        maxResults,
      ]);
      return <City>[
        for (final Row row in rows)
          City(
            id: row.columnAt(0) as String,
            name: row.columnAt(1) as String,
            region: row.columnAt(2) as String,
            countryCode: row.columnAt(3) as String,
            country: row.columnAt(4) as String,
            latitude: (row.columnAt(5) as num).toDouble(),
            longitude: (row.columnAt(6) as num).toDouble(),
            timeZone: row.columnAt(7) as String,
          ),
      ];
    } finally {
      db.close();
    }
  }

  /// SQLite needs a real file, so the asset is copied out once per version.
  static Future<String> _install() async {
    final Directory dir = await getApplicationSupportDirectory();
    final File file = File('${dir.path}/cities-v$kCityDbVersion.db');
    if (await file.exists()) {
      return file.path;
    }
    final ByteData data = await rootBundle.load(_asset);
    final File partial = File('${file.path}.part');
    await partial.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    await partial.rename(file.path);
    final RegExp older = RegExp(r'cities-v\d+\.db$');
    await for (final FileSystemEntity entry in dir.list()) {
      if (entry is File &&
          entry.path != file.path &&
          older.hasMatch(entry.path)) {
        await entry.delete();
      }
    }
    return file.path;
  }
}
