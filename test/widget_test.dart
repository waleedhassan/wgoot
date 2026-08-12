import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:wgoot/src/core/utils/arabic_text.dart';
import 'package:wgoot/src/data/cities.dart';
import 'package:wgoot/src/data/hijri_date.dart';
import 'package:wgoot/src/data/models/city.dart';
import 'package:wgoot/src/data/models/prayer_slot.dart';
import 'package:wgoot/src/data/prayer_engine.dart';

const PrayerCalculationConfig _ummAlQura = PrayerCalculationConfig(
  method: CalculationMethod.umm_al_qura,
  madhab: Madhab.shafi,
  highLatitudeRule: HighLatitudeRule.middle_of_the_night,
  adjustments: <PrayerSlot, int>{},
);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('city data', () {
    test('ids are unique', () {
      final Set<String> ids = kCities.map((City city) => city.id).toSet();
      expect(ids.length, kCities.length);
    });

    test('coordinates are in range', () {
      for (final City city in kCities) {
        expect(city.latitude.abs() <= 90, isTrue, reason: city.id);
        expect(city.longitude.abs() <= 180, isTrue, reason: city.id);
      }
    });

    test('every time zone resolves', () {
      for (final City city in kCities) {
        expect(
          () => tz.getLocation(city.timeZone),
          returnsNormally,
          reason: '${city.id} → ${city.timeZone}',
        );
      }
    });

    test('search matches city and country names', () {
      expect(searchCities('مكه').map((City c) => c.id), contains('sa-makkah'));
      expect(searchCities('الاردن').isNotEmpty, isTrue);
      expect(searchCities('لا توجد مدينة بهذا الاسم'), isEmpty);
    });
  });

  group('prayer engine', () {
    test('Makkah times fall in expected windows', () {
      final tz.Location riyadh = tz.getLocation('Asia/Riyadh');
      final DayTimes day = PrayerEngine.compute(
        kDefaultCity,
        _ummAlQura,
        tz.TZDateTime(riyadh, 2026, 6, 15),
      );

      expect(day.timeOf(PrayerSlot.fajr).hour, inInclusiveRange(3, 5));
      expect(day.timeOf(PrayerSlot.dhuhr).hour, inInclusiveRange(11, 13));
      expect(day.timeOf(PrayerSlot.maghrib).hour, inInclusiveRange(18, 20));

      for (final PrayerSlot slot in PrayerSlot.values) {
        expect(day.timeOf(slot).day, 15, reason: slot.key);
      }
    });

    test('times are ordered through the day', () {
      for (final City city in <City>[
        kDefaultCity,
        cityById('id-jakarta')!,
        cityById('us-losangeles')!,
        cityById('gb-london')!,
      ]) {
        final DayTimes day = PrayerEngine.compute(
          city,
          _ummAlQura,
          tz.TZDateTime(PrayerEngine.locationFor(city), 2026, 3, 21),
        );
        DateTime previous = day.timeOf(PrayerSlot.fajr);
        for (final PrayerSlot slot in PrayerSlot.values.skip(1)) {
          expect(
            day.timeOf(slot).isAfter(previous),
            isTrue,
            reason: '${city.id} ${slot.key}',
          );
          previous = day.timeOf(slot);
        }
      }
    });

    test('manual adjustment shifts the resulting time', () {
      final tz.Location riyadh = tz.getLocation('Asia/Riyadh');
      final tz.TZDateTime day = tz.TZDateTime(riyadh, 2026, 6, 15);
      final DayTimes plain = PrayerEngine.compute(
        kDefaultCity,
        _ummAlQura,
        day,
      );
      final DayTimes shifted = PrayerEngine.compute(
        kDefaultCity,
        const PrayerCalculationConfig(
          method: CalculationMethod.umm_al_qura,
          madhab: Madhab.shafi,
          highLatitudeRule: HighLatitudeRule.middle_of_the_night,
          adjustments: <PrayerSlot, int>{PrayerSlot.fajr: -7},
        ),
        day,
      );

      expect(
        plain
            .timeOf(PrayerSlot.fajr)
            .difference(shifted.timeOf(PrayerSlot.fajr))
            .inMinutes,
        7,
      );
      expect(plain.timeOf(PrayerSlot.isha), shifted.timeOf(PrayerSlot.isha));
    });

    test('next prayer is always ahead of the given moment', () {
      final tz.Location riyadh = tz.getLocation('Asia/Riyadh');
      for (int hour = 0; hour < 24; hour++) {
        final tz.TZDateTime moment = tz.TZDateTime(
          riyadh,
          2026,
          6,
          15,
          hour,
          30,
        );
        final UpcomingPrayer? next = PrayerEngine.nextPrayer(
          kDefaultCity,
          _ummAlQura,
          from: moment,
        );
        expect(next, isNotNull, reason: 'hour $hour');
        expect(next!.time.isAfter(moment), isTrue, reason: 'hour $hour');
        expect(next.slot.isFard, isTrue);
      }
    });

    test('month table covers every day', () {
      final tz.Location riyadh = tz.getLocation('Asia/Riyadh');
      final List<DayTimes> days = PrayerEngine.month(
        kDefaultCity,
        _ummAlQura,
        tz.TZDateTime(riyadh, 2026, 2, 10),
      );
      expect(days.length, 28);
      expect(days.first.day.day, 1);
      expect(days.last.day.day, 28);
    });
  });

  group('hijri date', () {
    test('converts a known date', () {
      final HijriDate hijri = HijriDate.fromGregorian(DateTime(2026, 8, 12));
      expect(hijri.year, 1448);
      expect(hijri.month, inInclusiveRange(1, 12));
      expect(hijri.day, inInclusiveRange(1, 30));
    });

    test('offset shifts the day', () {
      final HijriDate plain = HijriDate.fromGregorian(DateTime(2026, 8, 12));
      final HijriDate shifted = HijriDate.fromGregorian(
        DateTime(2026, 8, 12),
        offsetDays: 1,
      );
      expect(shifted.day == plain.day + 1 || shifted.day == 1, isTrue);
    });
  });

  group('arabic formatting', () {
    test('converts digits', () {
      expect(toArabicNumerals(1448), '١٤٤٨');
      expect(toArabicNumerals('12:05'), '١٢:٠٥');
    });

    test('formats the clock in both systems', () {
      final DateTime evening = DateTime(2026, 6, 15, 17, 45);
      expect(formatClock(evening, use24Hour: true), '١٧:٤٥');
      expect(formatClock(evening, use24Hour: false), '٥:٤٥ م');
      expect(
        formatClock(DateTime(2026, 6, 15, 0, 5), use24Hour: false),
        '١٢:٠٥ ص',
      );
    });

    test('describes the remaining time', () {
      expect(describeRemaining(const Duration(minutes: 1)), 'دقيقة');
      expect(
        describeRemaining(const Duration(hours: 1, minutes: 30)),
        'ساعة و٣٠ دقيقة',
      );
      expect(describeRemaining(const Duration(seconds: 10)), 'أقل من دقيقة');
    });

    test('formats signed adjustments', () {
      expect(formatSignedMinutes(0), 'بدون تعديل');
      expect(formatSignedMinutes(5), '+٥ د');
      expect(formatSignedMinutes(-5), '−٥ د');
    });
  });
}
