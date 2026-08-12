import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Name of a raw resource under `android/app/src/main/res/raw` used as the
/// adhan call. Leave `null` to fall back to the system notification sound.
const String? kAdhanRawResource = null;

RawResourceAndroidNotificationSound? _adhanSound() {
  final String? resource = kAdhanRawResource;
  return resource == null
      ? null
      : RawResourceAndroidNotificationSound(resource);
}

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String adhanChannelId = 'wgoot.adhan.v1';
  static const String silentChannelId = 'wgoot.adhan.silent.v1';
  static const String reminderChannelId = 'wgoot.reminder.v1';

  final FlutterLocalNotificationsPlugin _plugin;

  bool _ready = false;
  bool _supported = false;

  bool get isSupported => _supported;

  Future<void> initialize() async {
    if (_ready) {
      return;
    }
    _ready = true;
    _supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    tzdata.initializeTimeZones();

    if (!_supported) {
      return;
    }

    await _syncDeviceTimeZone();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    await _createAndroidChannels();
  }

  Future<void> _syncDeviceTimeZone() async {
    try {
      final String name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Falls back to the UTC default bundled with the timezone package.
      // Prayer times never rely on it: every city carries its own zone.
    }
  }

  Future<void> _createAndroidChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        adhanChannelId,
        'الأذان',
        description: 'تنبيه صوتي عند دخول وقت الصلاة',
        importance: Importance.max,
        playSound: true,
        sound: _adhanSound(),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
      ),
    );

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        silentChannelId,
        'تنبيه صامت',
        description: 'تنبيه بدخول وقت الصلاة بدون صوت',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ),
    );

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        reminderChannelId,
        'تذكير قبل الأذان',
        description: 'تذكير قبل دخول وقت الصلاة بعدة دقائق',
        importance: Importance.high,
        playSound: true,
      ),
    );
  }

  Future<bool> requestPermissions() async {
    if (!_supported) {
      return false;
    }
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final bool granted = await android.requestNotificationsPermission() ?? false;
      final bool canScheduleExact =
          await android.canScheduleExactNotifications() ?? true;
      if (!canScheduleExact) {
        await android.requestExactAlarmsPermission();
      }
      return granted;
    }

    final IOSFlutterLocalNotificationsPlugin? ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }

    final MacOSFlutterLocalNotificationsPlugin? macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    return await macos?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_supported) {
      return false;
    }
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  Future<void> cancelAll() async {
    if (!_supported) {
      return;
    }
    await _plugin.cancelAll();
  }

  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required bool withSound,
    required bool isReminder,
  }) async {
    if (!_supported) {
      return false;
    }
    final String channelId = isReminder
        ? reminderChannelId
        : (withSound ? adhanChannelId : silentChannelId);
    final String channelName = isReminder
        ? 'تذكير قبل الأذان'
        : (withSound ? 'الأذان' : 'تنبيه صامت');

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: isReminder ? Importance.high : Importance.max,
            priority: isReminder ? Priority.high : Priority.max,
            playSound: withSound || isReminder,
            sound: !isReminder && withSound ? _adhanSound() : null,
            audioAttributesUsage: isReminder
                ? AudioAttributesUsage.notification
                : AudioAttributesUsage.alarm,
            category: isReminder
                ? AndroidNotificationCategory.reminder
                : AndroidNotificationCategory.alarm,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: DarwinNotificationDetails(
            presentSound: withSound || isReminder,
            interruptionLevel: isReminder
                ? InterruptionLevel.active
                : InterruptionLevel.timeSensitive,
          ),
          macOS: DarwinNotificationDetails(
            presentSound: withSound || isReminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return true;
    } on Exception {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          NotificationDetails(
            android: AndroidNotificationDetails(channelId, channelName),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        return true;
      } on Exception {
        return false;
      }
    }
  }

  Future<int> pendingCount() async {
    if (!_supported) {
      return 0;
    }
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    return pending.length;
  }
}
