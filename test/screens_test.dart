import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wgoot/src/app.dart';
import 'package:wgoot/src/core/theme/app_theme.dart';
import 'package:wgoot/src/data/cities.dart';
import 'package:wgoot/src/data/models/prayer_slot.dart';
import 'package:wgoot/src/features/about/about_screen.dart';
import 'package:wgoot/src/features/adjust/adjustments_screen.dart';
import 'package:wgoot/src/features/city/city_picker_screen.dart';
import 'package:wgoot/src/features/monthly/monthly_screen.dart';
import 'package:wgoot/src/features/settings/settings_screen.dart';
import 'package:wgoot/src/notifications/notification_service.dart';
import 'package:wgoot/src/notifications/prayer_scheduler.dart';
import 'package:wgoot/src/settings/settings_controller.dart';
import 'package:wgoot/src/settings/settings_service.dart';

Future<SettingsController> _buildController({bool withCity = true}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final NotificationService notifications = NotificationService();
  await notifications.initialize();
  final SettingsController controller = SettingsController(
    SettingsService(),
    notifications,
    PrayerScheduler(notifications),
  );
  await controller.load();
  if (withCity) {
    await controller.setCity(kDefaultCity);
  }
  return controller;
}

/// Unmounts the tree so screen timers are cancelled, then drains the
/// controller's reschedule debounce before the test framework checks for
/// pending timers.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

Widget _host(SettingsController controller, Widget child) {
  return ChangeNotifierProvider<SettingsController>.value(
    value: controller,
    child: MaterialApp(
      locale: const Locale('ar'),
      theme: AppTheme.light(),
      home: Directionality(textDirection: TextDirection.rtl, child: child),
    ),
  );
}

const MethodChannel _notificationChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);
const MethodChannel _timezoneChannel = MethodChannel('flutter_timezone');

final List<MethodCall> scheduledCalls = <MethodCall>[];

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    scheduledCalls.clear();
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _notificationChannel,
      (MethodCall call) async {
        scheduledCalls.add(call);
        switch (call.method) {
          case 'initialize':
          case 'requestNotificationsPermission':
          case 'canScheduleExactNotifications':
          case 'areNotificationsEnabled':
            return true;
          case 'pendingNotificationRequests':
            return <Object?>[];
          default:
            return null;
        }
      },
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _timezoneChannel,
      (MethodCall call) async =>
          call.method == 'getLocalTimezone' ? 'Asia/Riyadh' : null,
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(_notificationChannel, null)
      ..setMockMethodCallHandler(_timezoneChannel, null);
  });

  testWidgets('welcome screen shows until a city is chosen', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = await _buildController(
      withCity: false,
    );
    await tester.pumpWidget(WgootApp(settingsController: controller));
    await tester.pump();

    expect(find.text('اختر مدينتك لنحسب لك المواقيت'), findsOneWidget);
    expect(find.text('المتابعة بمكة المكرمة'), findsOneWidget);

    await tester.tap(find.text('المتابعة بمكة المكرمة'));
    await tester.pump();
    await tester.pump();

    expect(controller.hasChosenCity, isTrue);
    expect(find.text('الصلاة القادمة'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('home screen lists all six times for the chosen city', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = await _buildController();
    await tester.pumpWidget(WgootApp(settingsController: controller));
    await tester.pump();

    expect(find.text('وَقُوتُ الصَّلاة'), findsOneWidget);
    expect(find.textContaining('مكة المكرمة'), findsWidgets);
    for (final String title in <String>[
      'الفجر',
      'الشروق',
      'الظهر',
      'العصر',
      'المغرب',
      'العشاء',
    ]) {
      expect(find.text(title), findsWidgets, reason: title);
    }
    expect(find.textContaining('هـ'), findsWidgets);
    await _settle(tester);
  });

  testWidgets('city picker filters and selects a city', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = await _buildController();
    await tester.pumpWidget(_host(controller, const CityPickerScreen()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'اسطنبول');
    await tester.pump();

    expect(find.text('إسطنبول'), findsOneWidget);
    expect(find.text('الرياض'), findsNothing);

    await tester.tap(find.text('إسطنبول'));
    await tester.pump();

    expect(controller.city.id, 'tr-istanbul');
    await _settle(tester);
  });

  testWidgets('settings screen exposes calculation and alert options', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = await _buildController();
    await tester.pumpWidget(_host(controller, const SettingsScreen()));
    await tester.pump();

    expect(find.text('طريقة الحساب'), findsOneWidget);
    expect(find.text('مذهب حساب العصر'), findsOneWidget);
    expect(find.text('تنبيه عند دخول الوقت'), findsOneWidget);
    expect(find.text('تعديل المواقيت يدوياً'), findsOneWidget);

    await tester.tap(find.text('مذهب حساب العصر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الحنفي'));
    await tester.pumpAndSettle();

    expect(controller.madhab.name, 'hanafi');
    await _settle(tester);
  });

  testWidgets('adjustments screen writes a per-prayer offset', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = await _buildController();
    await tester.pumpWidget(_host(controller, const AdjustmentsScreen()));
    await tester.pump();

    expect(find.byType(Slider), findsWidgets);
    expect(find.text('الفجر'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded).first);
    await tester.pump();

    expect(controller.adjustmentFor(PrayerSlot.fajr), 1);
    expect(controller.hasAnyAdjustment(), isTrue);
    await _settle(tester);
  });

  testWidgets('monthly screen renders a full month of rows', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = await _buildController();
    await tester.pumpWidget(_host(controller, const MonthlyScreen()));
    await tester.pump();

    expect(find.text('جدول الشهر'), findsOneWidget);
    expect(find.text('اليوم'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('about screen explains the name from the Muwatta', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = await _buildController();
    await tester.pumpWidget(_host(controller, const AboutScreen()));
    await tester.pump();

    expect(find.textContaining('الموطأ'), findsOneWidget);
    expect(find.textContaining('مالك بن أنس'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('opening the home screen schedules adhan notifications', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = await _buildController();
    await tester.pumpWidget(WgootApp(settingsController: controller));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(controller.scheduledCount, greaterThan(0));
    expect(
      scheduledCalls.where((MethodCall c) => c.method == 'zonedSchedule').length,
      greaterThanOrEqualTo(controller.scheduledCount),
    );
    expect(
      scheduledCalls.any((MethodCall c) => c.method == 'cancelAll'),
      isTrue,
    );
    await _settle(tester);
  });

  testWidgets('muting a prayer removes it from the schedule', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = await _buildController();
    await tester.pumpWidget(WgootApp(settingsController: controller));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final int all = controller.scheduledCount;

    await controller.setMuted(PrayerSlot.fajr, true);
    await tester.pump(const Duration(seconds: 2));

    expect(controller.scheduledCount, lessThan(all));
    await _settle(tester);
  });

  testWidgets('disabling notifications cancels everything', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = await _buildController();
    await tester.pumpWidget(WgootApp(settingsController: controller));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(controller.scheduledCount, greaterThan(0));

    await controller.setNotificationsEnabled(false);
    await tester.pump(const Duration(seconds: 2));

    expect(controller.scheduledCount, 0);
    await _settle(tester);
  });
}
