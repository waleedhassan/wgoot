import 'package:adhan/adhan.dart';
import 'package:timezone/timezone.dart' as tz;

import 'models/city.dart';
import 'models/prayer_slot.dart';

class PrayerCalculationConfig {
  const PrayerCalculationConfig({
    required this.method,
    required this.madhab,
    required this.highLatitudeRule,
    required this.adjustments,
  });

  final CalculationMethod method;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;
  final Map<PrayerSlot, int> adjustments;

  int adjustmentFor(PrayerSlot slot) => adjustments[slot] ?? 0;
}

class DayTimes {
  const DayTimes({
    required this.city,
    required this.day,
    required this.times,
  });

  final City city;
  final tz.TZDateTime day;
  final Map<PrayerSlot, tz.TZDateTime> times;

  tz.TZDateTime timeOf(PrayerSlot slot) => times[slot]!;
}

class UpcomingPrayer {
  const UpcomingPrayer({
    required this.slot,
    required this.time,
    required this.isTomorrow,
  });

  final PrayerSlot slot;
  final tz.TZDateTime time;
  final bool isTomorrow;

  Duration remainingFrom(tz.TZDateTime now) => time.difference(now);
}

abstract final class PrayerEngine {
  static tz.Location locationFor(City city) {
    try {
      return tz.getLocation(city.timeZone);
    } on tz.LocationNotFoundException {
      return tz.local;
    }
  }

  static tz.TZDateTime nowIn(City city) =>
      tz.TZDateTime.now(locationFor(city));

  static tz.TZDateTime startOfDay(tz.TZDateTime moment) => tz.TZDateTime(
    moment.location,
    moment.year,
    moment.month,
    moment.day,
  );

  static DayTimes compute(
    City city,
    PrayerCalculationConfig config,
    tz.TZDateTime day,
  ) {
    final tz.Location location = locationFor(city);
    final CalculationParameters parameters = config.method.getParameters()
      ..madhab = config.madhab
      ..highLatitudeRule = config.highLatitudeRule;

    final PrayerTimes computed = PrayerTimes.utc(
      city.coordinates,
      DateComponents(day.year, day.month, day.day),
      parameters,
    );

    final Map<PrayerSlot, DateTime> raw = <PrayerSlot, DateTime>{
      PrayerSlot.fajr: computed.fajr,
      PrayerSlot.sunrise: computed.sunrise,
      PrayerSlot.dhuhr: computed.dhuhr,
      PrayerSlot.asr: computed.asr,
      PrayerSlot.maghrib: computed.maghrib,
      PrayerSlot.isha: computed.isha,
    };

    final Map<PrayerSlot, tz.TZDateTime> times =
        <PrayerSlot, tz.TZDateTime>{};
    raw.forEach((PrayerSlot slot, DateTime value) {
      times[slot] = tz.TZDateTime.from(
        value.add(Duration(minutes: config.adjustmentFor(slot))),
        location,
      );
    });

    return DayTimes(
      city: city,
      day: tz.TZDateTime(location, day.year, day.month, day.day),
      times: times,
    );
  }

  static DayTimes today(City city, PrayerCalculationConfig config) {
    return compute(city, config, tz.TZDateTime.now(locationFor(city)));
  }

  static UpcomingPrayer? nextPrayer(
    City city,
    PrayerCalculationConfig config, {
    tz.TZDateTime? from,
    bool includeSunrise = false,
  }) {
    final tz.Location location = locationFor(city);
    final tz.TZDateTime now = from ?? tz.TZDateTime.now(location);
    final List<PrayerSlot> slots = includeSunrise
        ? PrayerSlot.values
        : kFardSlots;

    for (int offset = 0; offset <= 1; offset++) {
      final DayTimes day = compute(
        city,
        config,
        now.add(Duration(days: offset)),
      );
      for (final PrayerSlot slot in slots) {
        final tz.TZDateTime time = day.timeOf(slot);
        if (time.isAfter(now)) {
          return UpcomingPrayer(
            slot: slot,
            time: time,
            isTomorrow: offset > 0 || time.day != now.day,
          );
        }
      }
    }
    return null;
  }

  static PrayerSlot? currentPrayer(
    City city,
    PrayerCalculationConfig config, {
    tz.TZDateTime? from,
  }) {
    final tz.Location location = locationFor(city);
    final tz.TZDateTime now = from ?? tz.TZDateTime.now(location);
    PrayerSlot? current;
    for (int offset = 0; offset >= -1; offset--) {
      final DayTimes day = compute(
        city,
        config,
        now.add(Duration(days: offset)),
      );
      for (final PrayerSlot slot in PrayerSlot.values) {
        if (!day.timeOf(slot).isAfter(now)) {
          current = slot;
        }
      }
      if (current != null) {
        return current;
      }
    }
    return null;
  }

  static List<DayTimes> month(
    City city,
    PrayerCalculationConfig config,
    tz.TZDateTime anyDayInMonth,
  ) {
    final tz.Location location = locationFor(city);
    final int daysInMonth = DateTime(
      anyDayInMonth.year,
      anyDayInMonth.month + 1,
      0,
    ).day;
    return List<DayTimes>.generate(daysInMonth, (int index) {
      return compute(
        city,
        config,
        tz.TZDateTime(
          location,
          anyDayInMonth.year,
          anyDayInMonth.month,
          index + 1,
        ),
      );
    }, growable: false);
  }
}
