import 'package:adhan/adhan.dart';

class City {
  const City({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
  });

  final String id;
  final String name;
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;
  final String timeZone;

  Coordinates get coordinates => Coordinates(latitude, longitude);

  String get flag {
    if (countryCode.length != 2) {
      return '🏳️';
    }
    final int base = 0x1F1E6 - 0x41;
    return String.fromCharCodes(<int>[
      base + countryCode.codeUnitAt(0),
      base + countryCode.codeUnitAt(1),
    ]);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'country': country,
    'countryCode': countryCode,
    'latitude': latitude,
    'longitude': longitude,
    'timeZone': timeZone,
  };

  static City? fromJson(Map<String, Object?> json) {
    final Object? id = json['id'];
    final Object? name = json['name'];
    final Object? latitude = json['latitude'];
    final Object? longitude = json['longitude'];
    final Object? timeZone = json['timeZone'];
    if (id is! String ||
        name is! String ||
        latitude is! num ||
        longitude is! num ||
        timeZone is! String) {
      return null;
    }
    return City(
      id: id,
      name: name,
      country: json['country'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      timeZone: timeZone,
    );
  }

  @override
  bool operator ==(Object other) => other is City && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
