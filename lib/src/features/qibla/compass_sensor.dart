import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// How far the platform trusts its own heading. Mirrors Android's
/// `SENSOR_STATUS_*` levels; iOS maps `headingAccuracy` onto the same scale.
enum CompassAccuracy { unreliable, low, medium, high }

class CompassReading {
  const CompassReading({required this.magneticHeading, required this.accuracy});

  /// Degrees clockwise from magnetic north that the top of the screen faces.
  final double magneticHeading;
  final CompassAccuracy accuracy;
}

/// Magnetic heading from the native side (MainActivity.kt / AppDelegate.swift).
///
/// Both platforms report magnetic rather than true north so no location
/// permission is needed; the Qibla screen applies the declination itself.
class CompassSensor {
  const CompassSensor();

  static const MethodChannel _methods = MethodChannel(
    'apps.waleed.sunnah.wgoot/compass',
  );
  static const EventChannel _events = EventChannel(
    'apps.waleed.sunnah.wgoot/compass/heading',
  );

  /// False on devices without a compass and on platforms with no native
  /// handler (web, desktop, tests). Listening to [readings] there would only
  /// report a missing-plugin error, so callers must check this first.
  Future<bool> isAvailable() async {
    if (kIsWeb) {
      return false;
    }
    try {
      return await _methods.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Stream<CompassReading> readings() {
    return _events.receiveBroadcastStream().map(_parse);
  }

  static CompassReading _parse(Object? event) {
    final List<Object?> values = event! as List<Object?>;
    final int level = (values[1]! as num).toInt().clamp(0, 3);
    return CompassReading(
      magneticHeading: (values[0]! as num).toDouble(),
      accuracy: CompassAccuracy.values[level],
    );
  }
}
