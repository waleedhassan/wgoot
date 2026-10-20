import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:geomag/geomag.dart';

import 'models/city.dart';

/// The Kaaba, as used by the adhan package for the bearing.
final Coordinates kKaaba = Qibla.MAKKAH;

const double _earthRadiusKm = 6371.0088;

/// Within this many kilometres of the Kaaba a bearing stops being meaningful,
/// so the screen tells the user to face the Kaaba directly instead.
const double kInsideHaramKm = 1;

/// The Qibla for one city, relative to true (geographic) north.
class QiblaInfo {
  const QiblaInfo({
    required this.bearing,
    required this.distanceKm,
    required this.declination,
  });

  factory QiblaInfo.forCity(City city, {DateTime? at}) {
    return QiblaInfo(
      bearing: qiblaBearing(city),
      distanceKm: distanceToKaabaKm(city.latitude, city.longitude),
      declination: magneticDeclination(
        city.latitude,
        city.longitude,
        at ?? DateTime.now(),
      ),
    );
  }

  /// Degrees clockwise from true north.
  final double bearing;

  /// Great-circle distance to the Kaaba.
  final double distanceKm;

  /// Degrees magnetic north lies east of true north at the city.
  final double declination;

  bool get isAtKaaba => distanceKm < kInsideHaramKm;
}

/// Degrees clockwise from true north along the great circle to the Kaaba.
double qiblaBearing(City city) => Qibla(city.coordinates).direction;

/// Haversine distance from [latitude], [longitude] to the Kaaba.
double distanceToKaabaKm(double latitude, double longitude) {
  final double lat1 = _radians(latitude);
  final double lat2 = _radians(kKaaba.latitude);
  final double dLat = lat2 - lat1;
  final double dLon = _radians(kKaaba.longitude - longitude);
  final double a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
}

/// Declination from the World Magnetic Model bundled with geomag (WMM-2025),
/// so magnetic compass readings can be turned into true headings offline.
double magneticDeclination(double latitude, double longitude, DateTime at) {
  return GeoMag().calculate(latitude, longitude, 0, at).dec;
}

/// Normalises any angle to [0, 360).
double normalizeDegrees(double degrees) {
  final double value = degrees % 360;
  return value < 0 ? value + 360 : value;
}

/// Signed shortest turn from [from] to [to], in (-180, 180].
double angleBetween(double from, double to) {
  final double diff = normalizeDegrees(to - from);
  return diff > 180 ? diff - 360 : diff;
}

const List<String> _compassPoints = <String>[
  'الشمال',
  'الشمال الشرقي',
  'الشرق',
  'الجنوب الشرقي',
  'الجنوب',
  'الجنوب الغربي',
  'الغرب',
  'الشمال الغربي',
];

/// Nearest of the eight compass points, in Arabic.
String compassPointName(double degrees) {
  final int index = ((normalizeDegrees(degrees) + 22.5) ~/ 45) % 8;
  return _compassPoints[index];
}

double _radians(double degrees) => degrees * math.pi / 180;
