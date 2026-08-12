import 'package:flutter/material.dart';

enum PrayerSlot {
  fajr('fajr', 'الفجر', 'حان الآن وقت صلاة الفجر', Icons.nightlight_round),
  sunrise('sunrise', 'الشروق', 'شروق الشمس', Icons.wb_twilight_rounded),
  dhuhr('dhuhr', 'الظهر', 'حان الآن وقت صلاة الظهر', Icons.light_mode_rounded),
  asr('asr', 'العصر', 'حان الآن وقت صلاة العصر', Icons.wb_sunny_outlined),
  maghrib(
    'maghrib',
    'المغرب',
    'حان الآن وقت صلاة المغرب',
    Icons.wb_twilight_rounded,
  ),
  isha('isha', 'العشاء', 'حان الآن وقت صلاة العشاء', Icons.dark_mode_rounded);

  const PrayerSlot(this.key, this.title, this.announcement, this.icon);

  final String key;
  final String title;
  final String announcement;
  final IconData icon;

  bool get isFard => this != PrayerSlot.sunrise;
}

const List<PrayerSlot> kFardSlots = <PrayerSlot>[
  PrayerSlot.fajr,
  PrayerSlot.dhuhr,
  PrayerSlot.asr,
  PrayerSlot.maghrib,
  PrayerSlot.isha,
];

PrayerSlot? prayerSlotByKey(String key) {
  for (final PrayerSlot slot in PrayerSlot.values) {
    if (slot.key == key) {
      return slot;
    }
  }
  return null;
}
