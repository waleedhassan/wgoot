import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/utils/arabic_text.dart';
import '../data/hijri_date.dart';
import '../data/models/city.dart';
import '../data/models/prayer_slot.dart';
import '../data/prayer_engine.dart';

class HomeWidgetRequest {
  const HomeWidgetRequest({
    required this.city,
    required this.config,
    required this.hijriOffset,
    required this.use24HourClock,
  });

  final City city;
  final PrayerCalculationConfig config;
  final int hijriOffset;
  final bool use24HourClock;
}

class HomeWidgetSync {
  static const String appGroupId = 'group.apps.waleed.sunnah.wgoot';
  static const String androidProvider =
      'apps.waleed.sunnah.wgoot.widget.PrayerWidgetProvider';
  static const String iOSWidgetKind = 'PrayerWidget';
  static const String payloadKey = 'wgoot_payload';
  static const int payloadVersion = 1;
  static const int horizonInDays = 4;

  bool _ready = false;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_ready || !isSupported) {
      return;
    }
    _ready = true;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {
      _ready = false;
    }
  }

  Future<bool> push(HomeWidgetRequest request) async {
    if (!isSupported) {
      return false;
    }
    await initialize();
    try {
      await HomeWidget.saveWidgetData<String>(
        payloadKey,
        jsonEncode(buildPayload(request)),
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidProvider,
        iOSName: iOSWidgetKind,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canPinToHomeScreen() async {
    if (!isSupported || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestPinToHomeScreen() async {
    if (!isSupported) {
      return;
    }
    try {
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: androidProvider,
      );
    } catch (_) {}
  }

  static Map<String, Object?> buildPayload(HomeWidgetRequest request) {
    final tz.Location location = PrayerEngine.locationFor(request.city);
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    final tz.TZDateTime today = PrayerEngine.startOfDay(now);

    final List<Map<String, Object?>> days = <Map<String, Object?>>[
      for (int offset = 0; offset < horizonInDays; offset++)
        _buildDay(request, _dayStart(today, offset), _dayStart(today, offset + 1)),
    ];

    return <String, Object?>{
      'version': payloadVersion,
      'city': request.city.name,
      'use24h': request.use24HourClock,
      'generatedAt': now.millisecondsSinceEpoch,
      'expiresAt': days.last['endAt'],
      'days': days,
    };
  }

  static tz.TZDateTime _dayStart(tz.TZDateTime today, int offset) {
    if (offset == 0) {
      return today;
    }
    return PrayerEngine.startOfDay(
      today.add(Duration(days: offset, hours: 12)),
    );
  }

  static Map<String, Object?> _buildDay(
    HomeWidgetRequest request,
    tz.TZDateTime start,
    tz.TZDateTime end,
  ) {
    final DayTimes day = PrayerEngine.compute(
      request.city,
      request.config,
      start,
    );
    final HijriDate hijri = HijriDate.fromGregorian(
      start,
      offsetDays: request.hijriOffset,
    );

    return <String, Object?>{
      'startAt': start.millisecondsSinceEpoch,
      'endAt': end.millisecondsSinceEpoch,
      'weekday': weekdayName(start),
      'gregorian': formatGregorian(start),
      'hijri': hijri.formatted,
      'slots': <Map<String, Object?>>[
        for (final PrayerSlot slot in PrayerSlot.values)
          <String, Object?>{
            'key': slot.key,
            'title': slot.title,
            'clock': formatClock(
              day.timeOf(slot),
              use24Hour: request.use24HourClock,
            ),
            'at': day.timeOf(slot).millisecondsSinceEpoch,
            'fard': slot.isFard,
          },
      ],
    };
  }
}
