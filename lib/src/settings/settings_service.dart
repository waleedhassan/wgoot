import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/city.dart';
import '../data/models/prayer_slot.dart';

class SettingsSnapshot {
  const SettingsSnapshot({
    required this.themeMode,
    required this.city,
    required this.method,
    required this.madhab,
    required this.highLatitudeRule,
    required this.adjustments,
    required this.mutedPrayers,
    required this.notificationsEnabled,
    required this.adhanSoundEnabled,
    required this.preAlertMinutes,
    required this.hijriOffset,
    required this.use24HourClock,
  });

  final ThemeMode themeMode;
  final City? city;
  final CalculationMethod? method;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;
  final Map<PrayerSlot, int> adjustments;
  final Set<PrayerSlot> mutedPrayers;
  final bool notificationsEnabled;
  final bool adhanSoundEnabled;
  final int preAlertMinutes;
  final int hijriOffset;
  final bool use24HourClock;
}

class SettingsService {
  static const String _themeModeKey = 'settings.themeMode';
  static const String _cityKey = 'settings.city';
  static const String _methodKey = 'settings.method';
  static const String _madhabKey = 'settings.madhab';
  static const String _highLatitudeKey = 'settings.highLatitudeRule';
  static const String _adjustmentsKey = 'settings.adjustments';
  static const String _mutedKey = 'settings.mutedPrayers';
  static const String _notificationsKey = 'settings.notificationsEnabled';
  static const String _adhanSoundKey = 'settings.adhanSoundEnabled';
  static const String _preAlertKey = 'settings.preAlertMinutes';
  static const String _hijriOffsetKey = 'settings.hijriOffset';
  static const String _clockKey = 'settings.use24HourClock';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<SettingsSnapshot> load() async {
    final SharedPreferences prefs = await _prefs;
    return SettingsSnapshot(
      themeMode: ThemeMode.values.firstWhere(
        (ThemeMode mode) => mode.name == prefs.getString(_themeModeKey),
        orElse: () => ThemeMode.system,
      ),
      city: _decodeCity(prefs.getString(_cityKey)),
      method: _decodeEnum(
        prefs.getString(_methodKey),
        CalculationMethod.values,
      ),
      madhab:
          _decodeEnum(prefs.getString(_madhabKey), Madhab.values) ??
          Madhab.shafi,
      highLatitudeRule:
          _decodeEnum(
            prefs.getString(_highLatitudeKey),
            HighLatitudeRule.values,
          ) ??
          HighLatitudeRule.middle_of_the_night,
      adjustments: _decodeAdjustments(prefs.getString(_adjustmentsKey)),
      mutedPrayers: _decodeMuted(prefs.getStringList(_mutedKey)),
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      adhanSoundEnabled: prefs.getBool(_adhanSoundKey) ?? true,
      preAlertMinutes: prefs.getInt(_preAlertKey) ?? 0,
      hijriOffset: prefs.getInt(_hijriOffsetKey) ?? 0,
      use24HourClock: prefs.getBool(_clockKey) ?? false,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async =>
      (await _prefs).setString(_themeModeKey, mode.name);

  Future<void> saveCity(City city) async =>
      (await _prefs).setString(_cityKey, jsonEncode(city.toJson()));

  Future<void> saveMethod(CalculationMethod? method) async {
    final SharedPreferences prefs = await _prefs;
    if (method == null) {
      await prefs.remove(_methodKey);
      return;
    }
    await prefs.setString(_methodKey, method.name);
  }

  Future<void> saveMadhab(Madhab madhab) async =>
      (await _prefs).setString(_madhabKey, madhab.name);

  Future<void> saveHighLatitudeRule(HighLatitudeRule rule) async =>
      (await _prefs).setString(_highLatitudeKey, rule.name);

  Future<void> saveAdjustments(Map<PrayerSlot, int> adjustments) async {
    final Map<String, int> encoded = adjustments.map(
      (PrayerSlot slot, int minutes) => MapEntry<String, int>(slot.key, minutes),
    );
    await (await _prefs).setString(_adjustmentsKey, jsonEncode(encoded));
  }

  Future<void> saveMutedPrayers(Set<PrayerSlot> muted) async {
    await (await _prefs).setStringList(
      _mutedKey,
      muted.map((PrayerSlot slot) => slot.key).toList(),
    );
  }

  Future<void> saveNotificationsEnabled(bool value) async =>
      (await _prefs).setBool(_notificationsKey, value);

  Future<void> saveAdhanSoundEnabled(bool value) async =>
      (await _prefs).setBool(_adhanSoundKey, value);

  Future<void> savePreAlertMinutes(int value) async =>
      (await _prefs).setInt(_preAlertKey, value);

  Future<void> saveHijriOffset(int value) async =>
      (await _prefs).setInt(_hijriOffsetKey, value);

  Future<void> saveUse24HourClock(bool value) async =>
      (await _prefs).setBool(_clockKey, value);

  City? _decodeCity(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return City.fromJson(decoded);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  T? _decodeEnum<T extends Enum>(String? raw, List<T> values) {
    if (raw == null) {
      return null;
    }
    for (final T value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  Map<PrayerSlot, int> _decodeAdjustments(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <PrayerSlot, int>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return <PrayerSlot, int>{};
      }
      final Map<PrayerSlot, int> result = <PrayerSlot, int>{};
      decoded.forEach((String key, Object? value) {
        final PrayerSlot? slot = prayerSlotByKey(key);
        if (slot != null && value is num) {
          result[slot] = value.toInt();
        }
      });
      return result;
    } on FormatException {
      return <PrayerSlot, int>{};
    }
  }

  Set<PrayerSlot> _decodeMuted(List<String>? raw) {
    if (raw == null) {
      return <PrayerSlot>{};
    }
    return raw
        .map(prayerSlotByKey)
        .whereType<PrayerSlot>()
        .toSet();
  }
}
