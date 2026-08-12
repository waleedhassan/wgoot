import 'package:timezone/timezone.dart' as tz;

import '../core/utils/arabic_text.dart';
import '../data/hijri_date.dart';
import '../data/models/city.dart';
import '../data/models/prayer_slot.dart';
import '../data/prayer_engine.dart';
import 'notification_service.dart';

class ScheduleRequest {
  const ScheduleRequest({
    required this.city,
    required this.config,
    required this.enabled,
    required this.mutedPrayers,
    required this.adhanSoundEnabled,
    required this.preAlertMinutes,
    required this.hijriOffset,
    required this.use24HourClock,
  });

  final City city;
  final PrayerCalculationConfig config;
  final bool enabled;
  final Set<PrayerSlot> mutedPrayers;
  final bool adhanSoundEnabled;
  final int preAlertMinutes;
  final int hijriOffset;
  final bool use24HourClock;
}

class PrayerScheduler {
  PrayerScheduler(this._notifications);

  static const int horizonInDays = 10;
  static const int _maxNotifications = 120;

  final NotificationService _notifications;

  Future<int> reschedule(ScheduleRequest request) async {
    await _notifications.cancelAll();
    if (!request.enabled || !_notifications.isSupported) {
      return 0;
    }

    final tz.Location location = PrayerEngine.locationFor(request.city);
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    int id = 1000;
    int scheduled = 0;

    for (int dayOffset = 0; dayOffset < horizonInDays; dayOffset++) {
      final DayTimes day = PrayerEngine.compute(
        request.city,
        request.config,
        now.add(Duration(days: dayOffset)),
      );
      final HijriDate hijri = HijriDate.fromGregorian(
        day.day,
        offsetDays: request.hijriOffset,
      );

      for (final PrayerSlot slot in kFardSlots) {
        if (request.mutedPrayers.contains(slot)) {
          continue;
        }
        final tz.TZDateTime time = day.timeOf(slot);
        if (!time.isAfter(now)) {
          continue;
        }
        if (scheduled >= _maxNotifications) {
          return scheduled;
        }

        final String clock = formatClock(
          time,
          use24Hour: request.use24HourClock,
        );

        if (request.preAlertMinutes > 0) {
          final tz.TZDateTime reminderAt = time.subtract(
            Duration(minutes: request.preAlertMinutes),
          );
          if (reminderAt.isAfter(now)) {
            final bool ok = await _notifications.schedule(
              id: id++,
              title: 'اقترب وقت ${slot.title}',
              body:
                  'بقيت ${toArabicNumerals(request.preAlertMinutes)} دقيقة على '
                  'أذان ${slot.title} — $clock في ${request.city.name}',
              when: reminderAt,
              withSound: true,
              isReminder: true,
            );
            if (ok) {
              scheduled++;
            }
          }
        }

        final bool ok = await _notifications.schedule(
          id: id++,
          title: slot.announcement,
          body:
              '$clock — ${request.city.name}\n'
              '${hijri.formatted}',
          when: time,
          withSound: request.adhanSoundEnabled,
          isReminder: false,
        );
        if (ok) {
          scheduled++;
        }
      }
    }

    return scheduled;
  }

  Future<void> cancelAll() => _notifications.cancelAll();
}
