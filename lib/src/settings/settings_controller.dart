import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../data/cities.dart';
import '../data/models/city.dart';
import '../data/models/prayer_slot.dart';
import '../data/prayer_engine.dart';
import '../homescreen/home_widget_sync.dart';
import '../notifications/notification_service.dart';
import '../notifications/prayer_scheduler.dart';
import 'settings_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(
    this._service,
    this._notifications,
    this._scheduler, [
    HomeWidgetSync? homeWidget,
  ]) : _homeWidget = homeWidget ?? HomeWidgetSync();

  static const int maxAdjustment = 60;
  static const List<int> preAlertChoices = <int>[0, 5, 10, 15, 20, 30];

  final SettingsService _service;
  final NotificationService _notifications;
  final PrayerScheduler _scheduler;
  final HomeWidgetSync _homeWidget;

  ThemeMode _themeMode = ThemeMode.system;
  City _city = kDefaultCity;
  CalculationMethod? _method;
  Madhab _madhab = Madhab.shafi;
  HighLatitudeRule _highLatitudeRule = HighLatitudeRule.middle_of_the_night;
  Map<PrayerSlot, int> _adjustments = <PrayerSlot, int>{};
  Set<PrayerSlot> _mutedPrayers = <PrayerSlot>{};
  bool _notificationsEnabled = true;
  bool _adhanSoundEnabled = true;
  int _preAlertMinutes = 0;
  int _hijriOffset = 0;
  bool _use24HourClock = false;
  bool _hasChosenCity = false;
  int _scheduledCount = 0;
  Timer? _rescheduleDebounce;

  ThemeMode get themeMode => _themeMode;
  City get city => _city;
  CalculationMethod get method => _method ?? suggestedMethodFor(_city);
  bool get usesAutomaticMethod => _method == null;
  Madhab get madhab => _madhab;
  HighLatitudeRule get highLatitudeRule => _highLatitudeRule;
  Set<PrayerSlot> get mutedPrayers => Set<PrayerSlot>.unmodifiable(_mutedPrayers);
  bool get notificationsEnabled => _notificationsEnabled;
  bool get adhanSoundEnabled => _adhanSoundEnabled;
  int get preAlertMinutes => _preAlertMinutes;
  int get hijriOffset => _hijriOffset;
  bool get use24HourClock => _use24HourClock;
  bool get hasChosenCity => _hasChosenCity;
  int get scheduledCount => _scheduledCount;
  bool get notificationsSupported => _notifications.isSupported;

  int adjustmentFor(PrayerSlot slot) => _adjustments[slot] ?? 0;

  bool hasAnyAdjustment() =>
      _adjustments.values.any((int minutes) => minutes != 0);

  bool isMuted(PrayerSlot slot) => _mutedPrayers.contains(slot);

  PrayerCalculationConfig get calculationConfig => PrayerCalculationConfig(
    method: method,
    madhab: _madhab,
    highLatitudeRule: _highLatitudeRule,
    adjustments: _adjustments,
  );

  Future<void> load() async {
    final SettingsSnapshot snapshot = await _service.load();
    _themeMode = snapshot.themeMode;
    _hasChosenCity = snapshot.city != null;
    _city = snapshot.city ?? kDefaultCity;
    _method = snapshot.method;
    _madhab = snapshot.madhab;
    _highLatitudeRule = snapshot.highLatitudeRule;
    _adjustments = Map<PrayerSlot, int>.of(snapshot.adjustments);
    _mutedPrayers = Set<PrayerSlot>.of(snapshot.mutedPrayers);
    _notificationsEnabled = snapshot.notificationsEnabled;
    _adhanSoundEnabled = snapshot.adhanSoundEnabled;
    _preAlertMinutes = snapshot.preAlertMinutes;
    _hijriOffset = snapshot.hijriOffset;
    _use24HourClock = snapshot.use24HourClock;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await _service.saveThemeMode(mode);
  }

  Future<void> toggleBrightness(Brightness current) => setThemeMode(
    current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
  );

  Future<void> setCity(City city) async {
    if (city == _city && _hasChosenCity) {
      return;
    }
    _city = city;
    _hasChosenCity = true;
    notifyListeners();
    await _service.saveCity(city);
    _requestReschedule();
  }

  Future<void> setMethod(CalculationMethod? method) async {
    if (method == _method) {
      return;
    }
    _method = method;
    notifyListeners();
    await _service.saveMethod(method);
    _requestReschedule();
  }

  Future<void> setMadhab(Madhab madhab) async {
    if (madhab == _madhab) {
      return;
    }
    _madhab = madhab;
    notifyListeners();
    await _service.saveMadhab(madhab);
    _requestReschedule();
  }

  Future<void> setHighLatitudeRule(HighLatitudeRule rule) async {
    if (rule == _highLatitudeRule) {
      return;
    }
    _highLatitudeRule = rule;
    notifyListeners();
    await _service.saveHighLatitudeRule(rule);
    _requestReschedule();
  }

  Future<void> setAdjustment(PrayerSlot slot, int minutes) async {
    final int clamped = minutes.clamp(-maxAdjustment, maxAdjustment);
    if (adjustmentFor(slot) == clamped) {
      return;
    }
    final Map<PrayerSlot, int> updated = Map<PrayerSlot, int>.of(_adjustments);
    if (clamped == 0) {
      updated.remove(slot);
    } else {
      updated[slot] = clamped;
    }
    _adjustments = updated;
    notifyListeners();
    await _service.saveAdjustments(updated);
    _requestReschedule();
  }

  Future<void> clearAdjustments() async {
    if (_adjustments.isEmpty) {
      return;
    }
    _adjustments = <PrayerSlot, int>{};
    notifyListeners();
    await _service.saveAdjustments(_adjustments);
    _requestReschedule();
  }

  Future<void> setMuted(PrayerSlot slot, bool muted) async {
    final Set<PrayerSlot> updated = Set<PrayerSlot>.of(_mutedPrayers);
    if (muted) {
      updated.add(slot);
    } else {
      updated.remove(slot);
    }
    if (updated.length == _mutedPrayers.length) {
      return;
    }
    _mutedPrayers = updated;
    notifyListeners();
    await _service.saveMutedPrayers(updated);
    _requestReschedule();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (value == _notificationsEnabled) {
      return;
    }
    _notificationsEnabled = value;
    notifyListeners();
    await _service.saveNotificationsEnabled(value);
    if (value) {
      await _notifications.requestPermissions();
    }
    _requestReschedule();
  }

  Future<void> setAdhanSoundEnabled(bool value) async {
    if (value == _adhanSoundEnabled) {
      return;
    }
    _adhanSoundEnabled = value;
    notifyListeners();
    await _service.saveAdhanSoundEnabled(value);
    _requestReschedule();
  }

  Future<void> setPreAlertMinutes(int minutes) async {
    if (minutes == _preAlertMinutes) {
      return;
    }
    _preAlertMinutes = minutes;
    notifyListeners();
    await _service.savePreAlertMinutes(minutes);
    _requestReschedule();
  }

  Future<void> setHijriOffset(int offset) async {
    final int clamped = offset.clamp(-3, 3);
    if (clamped == _hijriOffset) {
      return;
    }
    _hijriOffset = clamped;
    notifyListeners();
    await _service.saveHijriOffset(clamped);
    _requestReschedule();
  }

  Future<void> setUse24HourClock(bool value) async {
    if (value == _use24HourClock) {
      return;
    }
    _use24HourClock = value;
    notifyListeners();
    await _service.saveUse24HourClock(value);
    _requestReschedule();
  }

  Future<void> requestNotificationPermissions() =>
      _notifications.requestPermissions();

  bool get homeScreenWidgetSupported => _homeWidget.isSupported;

  Future<bool> canPinHomeScreenWidget() => _homeWidget.canPinToHomeScreen();

  Future<void> pinHomeScreenWidget() async {
    await refreshHomeScreenWidget();
    await _homeWidget.requestPinToHomeScreen();
  }

  Future<void> refreshHomeScreenWidget() {
    return _homeWidget.push(
      HomeWidgetRequest(
        city: _city,
        config: calculationConfig,
        hijriOffset: _hijriOffset,
        use24HourClock: _use24HourClock,
      ),
    );
  }

  Future<void> refreshSchedule() async {
    _scheduledCount = await _scheduler.reschedule(
      ScheduleRequest(
        city: _city,
        config: calculationConfig,
        enabled: _notificationsEnabled,
        mutedPrayers: _mutedPrayers,
        adhanSoundEnabled: _adhanSoundEnabled,
        preAlertMinutes: _preAlertMinutes,
        hijriOffset: _hijriOffset,
        use24HourClock: _use24HourClock,
      ),
    );
    await refreshHomeScreenWidget();
    notifyListeners();
  }

  void _requestReschedule() {
    _rescheduleDebounce?.cancel();
    _rescheduleDebounce = Timer(
      const Duration(milliseconds: 700),
      refreshSchedule,
    );
  }

  @override
  void dispose() {
    _rescheduleDebounce?.cancel();
    super.dispose();
  }
}
