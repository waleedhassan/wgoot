import 'package:flutter/foundation.dart';

import '../cities.dart';
import '../models/city.dart';

/// The web build does not bundle SQLite, so it searches the curated cities.
abstract final class CityDatabase {
  static int get cityCount => kFeaturedCities.length;

  @visibleForTesting
  static void useFile(String path) {}

  static Future<List<City>> search(String query) async =>
      searchFeaturedCities(query);
}
