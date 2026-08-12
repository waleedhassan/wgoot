import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';

import 'src/app.dart';
import 'src/notifications/notification_service.dart';
import 'src/notifications/prayer_scheduler.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  HijriCalendar.setLocal('ar');

  final NotificationService notifications = NotificationService();
  await notifications.initialize();

  final SettingsController settingsController = SettingsController(
    SettingsService(),
    notifications,
    PrayerScheduler(notifications),
  );
  await settingsController.load();

  if (settingsController.notificationsEnabled) {
    await notifications.requestPermissions();
  }

  runApp(WgootApp(settingsController: settingsController));
}
