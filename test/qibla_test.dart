import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wgoot/src/core/theme/app_theme.dart';
import 'package:wgoot/src/core/utils/arabic_text.dart';
import 'package:wgoot/src/data/cities.dart';
import 'package:wgoot/src/data/models/city.dart';
import 'package:wgoot/src/data/qibla.dart';
import 'package:wgoot/src/features/qibla/qibla_screen.dart';
import 'package:wgoot/src/notifications/notification_service.dart';
import 'package:wgoot/src/notifications/prayer_scheduler.dart';
import 'package:wgoot/src/settings/settings_controller.dart';
import 'package:wgoot/src/settings/settings_service.dart';

City _city(String id) => kCities.firstWhere((City c) => c.id == id);

const MethodChannel _compassMethods = MethodChannel(
  'apps.waleed.sunnah.wgoot/compass',
);
const EventChannel _compassEvents = EventChannel(
  'apps.waleed.sunnah.wgoot/compass/heading',
);

void main() {
  // Reference values from NOAA's WMM-2025 (via pygeomag) and the standard
  // great-circle formulas.
  group('qibla math', () {
    final DateTime mid2026 = DateTime.utc(2026, 7, 2);

    test('bearing, distance and declination for known cities', () {
      final Map<String, List<double>> expected = <String, List<double>>{
        'eg-cairo': <double>[136.14, 1287.2, 4.76],
        'gb-london': <double>[118.99, 4793.8, 1.16],
        'id-jakarta': <double>[295.15, 7920.1, 0.64],
      };
      expected.forEach((String id, List<double> values) {
        final QiblaInfo info = QiblaInfo.forCity(_city(id), at: mid2026);
        expect(info.bearing, closeTo(values[0], 0.05), reason: id);
        expect(info.distanceKm, closeTo(values[1], 1), reason: id);
        expect(info.declination, closeTo(values[2], 0.1), reason: id);
        expect(info.isAtKaaba, isFalse, reason: id);
      });
    });

    test('Makkah itself has no meaningful bearing', () {
      expect(QiblaInfo.forCity(_city('sa-makkah')).isAtKaaba, isTrue);
    });

    test('angles wrap through north', () {
      expect(normalizeDegrees(-10), 350);
      expect(normalizeDegrees(725), 5);
      expect(angleBetween(350, 10), 20);
      expect(angleBetween(10, 350), -20);
      expect(angleBetween(0, 180), 180);
    });

    test('compass point names', () {
      expect(compassPointName(0), 'الشمال');
      expect(compassPointName(136), 'الجنوب الشرقي');
      expect(compassPointName(295), 'الشمال الغربي');
      expect(compassPointName(359), 'الشمال');
    });

    test('formatting', () {
      expect(formatDegrees(136.14), '١٣٦°');
      expect(formatDegrees(359.7), '٠°');
      expect(formatDegrees(4.76, fractionDigits: 1), '٤٫٨°');
      expect(formatDistanceKm(1287.2), '١٬٢٨٧');
      expect(formatDistanceKm(912), '٩١٢');
    });
  });

  group('qibla screen', () {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();

    Future<SettingsController> controllerFor(City city) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'settings.city': jsonEncode(city.toJson()),
      });
      final NotificationService notifications = NotificationService();
      final SettingsController controller = SettingsController(
        SettingsService(),
        notifications,
        PrayerScheduler(notifications),
      );
      await controller.load();
      return controller;
    }

    Widget host(SettingsController controller) {
      return ChangeNotifierProvider<SettingsController>.value(
        value: controller,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: QiblaScreen(),
          ),
        ),
      );
    }

    tearDown(() {
      binding.defaultBinaryMessenger
        ..setMockMethodCallHandler(_compassMethods, null)
        ..setMockStreamHandler(_compassEvents, null);
    });

    testWidgets('falls back to the bearing when there is no compass', (
      WidgetTester tester,
    ) async {
      final SettingsController controller = await controllerFor(
        _city('eg-cairo'),
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _compassMethods,
        (MethodCall call) async => false,
      );
      await tester.pumpWidget(host(controller));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('لا تتوفر بوصلة'), findsOneWidget);
      expect(find.text('١٣٦° الجنوب الشرقي'), findsOneWidget);
      expect(find.textContaining('١٬٢٨٧ كم'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('guides the user until they face the Qibla', (
      WidgetTester tester,
    ) async {
      final City cairo = _city('eg-cairo');
      final SettingsController controller = await controllerFor(cairo);
      final double declination = QiblaInfo.forCity(cairo).declination;
      late MockStreamHandlerEventSink sink;
      binding.defaultBinaryMessenger
        ..setMockMethodCallHandler(
          _compassMethods,
          (MethodCall call) async => call.method == 'isAvailable',
        )
        ..setMockStreamHandler(
          _compassEvents,
          MockStreamHandler.inline(
            onListen: (Object? _, MockStreamHandlerEventSink events) {
              sink = events;
            },
          ),
        );

      await tester.pumpWidget(host(controller));
      await tester.pump();
      await tester.pump();

      // Facing true north: the Qibla is ~136° clockwise, so turn right.
      sink.success(<Object>[-declination, 3]);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('استدر يميناً ١٣٦°'), findsOneWidget);
      expect(find.textContaining('معايرة'), findsNothing);

      // A first reading snaps; later ones are smoothed, so feed a few.
      for (int i = 0; i < 30; i++) {
        sink.success(<Object>[136.14 - declination, 1]);
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('أنت متّجه إلى القبلة'), findsOneWidget);
      expect(find.textContaining('معايرة'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
