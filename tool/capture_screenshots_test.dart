@Tags(<String>['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wgoot/src/core/theme/app_theme.dart';
import 'package:wgoot/src/data/cities.dart';
import 'package:wgoot/src/data/models/city.dart';
import 'package:wgoot/src/data/models/prayer_slot.dart';
import 'package:wgoot/src/features/about/about_screen.dart';
import 'package:wgoot/src/features/adjust/adjustments_screen.dart';
import 'package:wgoot/src/features/city/city_picker_screen.dart';
import 'package:wgoot/src/features/home/home_screen.dart';
import 'package:wgoot/src/features/monthly/monthly_screen.dart';
import 'package:wgoot/src/features/onboarding/welcome_screen.dart';
import 'package:wgoot/src/features/settings/settings_screen.dart';
import 'package:wgoot/src/notifications/notification_service.dart';
import 'package:wgoot/src/notifications/prayer_scheduler.dart';
import 'package:wgoot/src/settings/settings_controller.dart';
import 'package:wgoot/src/settings/settings_service.dart';

class Viewport {
  const Viewport(this.name, this.logicalSize, this.pixelRatio);

  final String name;
  final Size logicalSize;
  final double pixelRatio;

  int get widthInPixels => (logicalSize.width * pixelRatio).round();

  int get heightInPixels => (logicalSize.height * pixelRatio).round();
}

const Viewport kPhone = Viewport('phone', Size(360, 720), 3.0);
const Viewport kTablet7 = Viewport('tablet7', Size(600, 960), 2.0);
const Viewport kTablet10 = Viewport('tablet10', Size(800, 1280), 2.0);

const String kOutputDirectory = 'store/play/graphics/screenshots/raw';

final GlobalKey _captureKey = GlobalKey();

const MethodChannel _notificationChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);
const MethodChannel _timezoneChannel = MethodChannel('flutter_timezone');
const MethodChannel _homeWidgetChannel = MethodChannel('home_widget');

final City _riyadh = kCities.firstWhere((City city) => city.id == 'sa-riyadh');

Future<void> _loadFontFamily(String family, List<String> paths) async {
  final FontLoader loader = FontLoader(family);
  bool any = false;
  for (final String path in paths) {
    final File file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    any = true;
    loader.addFont(
      file.readAsBytes().then(
            (Uint8List bytes) => ByteData.sublistView(bytes),
          ),
    );
  }
  if (any) {
    await loader.load();
  }
}

String? _flutterRoot() {
  final String? fromEnvironment = Platform.environment['FLUTTER_ROOT'];
  if (fromEnvironment != null && fromEnvironment.isNotEmpty) {
    return fromEnvironment.replaceAll(r'\', '/');
  }
  final String executable = Platform.resolvedExecutable.replaceAll(r'\', '/');
  final int marker = executable.indexOf('/bin/cache/dart-sdk/');
  return marker == -1 ? null : executable.substring(0, marker);
}

Future<void> _loadFonts() async {
  final String? root = _flutterRoot();
  final List<String> emoji = <String>[
    if (root != null)
      '$root/engine/src/flutter/txt/third_party/fonts/NotoColorEmoji.ttf',
  ];

  await _loadFontFamily('IBMPlexSansArabic', <String>[
    'assets/fonts/IBMPlexSansArabic-Regular.ttf',
    'assets/fonts/IBMPlexSansArabic-Medium.ttf',
    'assets/fonts/IBMPlexSansArabic-SemiBold.ttf',
    'assets/fonts/IBMPlexSansArabic-Bold.ttf',
    ...emoji,
  ]);
  await _loadFontFamily('Amiri', <String>[
    'assets/fonts/Amiri-Regular.ttf',
    'assets/fonts/Amiri-Bold.ttf',
    ...emoji,
  ]);

  if (root == null) {
    return;
  }
  await _loadFontFamily('MaterialIcons', <String>[
    '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  ]);
  await _loadFontFamily('Roboto', <String>[
    '$root/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    ...emoji,
  ]);
}

void _useViewport(WidgetTester tester, Viewport viewport) {
  tester.view.physicalSize = Size(
    viewport.widthInPixels.toDouble(),
    viewport.heightInPixels.toDouble(),
  );
  tester.view.devicePixelRatio = viewport.pixelRatio;
  addTearDown(tester.view.reset);
}

Future<SettingsController> _controller({bool withCity = true}) async {
  // ignore: invalid_use_of_visible_for_testing_member
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
    await controller.setCity(_riyadh);
    await controller.refreshSchedule();
  }
  return controller;
}

Widget _frame(
  SettingsController controller,
  Widget screen, {
  ThemeMode themeMode = ThemeMode.light,
}) {
  return RepaintBoundary(
    key: _captureKey,
    child: ChangeNotifierProvider<SettingsController>.value(
      value: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        locale: const Locale('ar'),
        supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(textDirection: TextDirection.rtl, child: screen),
      ),
    ),
  );
}

Future<void> _save(WidgetTester tester, Viewport viewport, String name) async {
  final RenderRepaintBoundary boundary =
      _captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(
      pixelRatio: viewport.pixelRatio,
    );
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    Directory(kOutputDirectory).createSync(recursive: true);
    final File file = File('$kOutputDirectory/$name.png');
    file.writeAsBytesSync(data!.buffer.asUint8List());

    // ignore: avoid_print
    print('wrote ${file.path} '
        '${viewport.widthInPixels}x${viewport.heightInPixels}');
  });
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

bool _hasFlagGlyph(String? text) {
  if (text == null) {
    return false;
  }
  return text.runes.any((int rune) => rune >= 0x1F1E6 && rune <= 0x1F1FF);
}

/// Scrolls a list until every country flag sits outside the captured frame,
/// and fails if one is still visible. Flag emoji render as empty boxes under
/// `flutter test`, so a screenshot showing one is unusable.
Future<void> _scrollPastFlags(
  WidgetTester tester,
  Viewport viewport,
  double logicalPixels,
) async {
  await tester.drag(find.byType(ListView).first, Offset(0, -logicalPixels));
  await tester.pump();

  final Iterable<Element> flags = find
      .byWidgetPredicate(
        (Widget widget) => widget is Text && _hasFlagGlyph(widget.data),
      )
      .evaluate();

  for (final Element element in flags) {
    final RenderBox box = element.renderObject! as RenderBox;
    final double top = box.localToGlobal(Offset.zero).dy;
    expect(
      top + box.size.height <= 0 || top >= viewport.logicalSize.height,
      isTrue,
      reason: 'a flag glyph is in frame at y=$top',
    );
  }
}

void _tabletShot(
  Viewport viewport,
  String index,
  String label,
  Future<void> Function(WidgetTester tester) build,
) {
  testWidgets('${viewport.name} $label', (WidgetTester tester) async {
    _useViewport(tester, viewport);
    await build(tester);
    await _save(tester, viewport, '${viewport.name}-$index');
    await _unmount(tester);
  }, timeout: const Timeout(Duration(minutes: 2)));
}

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HijriCalendar.setLocal('ar');
    await _loadFonts();
  });

  setUp(() {
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _notificationChannel,
      (MethodCall call) async {
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
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _homeWidgetChannel,
      (MethodCall call) async => true,
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(_notificationChannel, null)
      ..setMockMethodCallHandler(_timezoneChannel, null)
      ..setMockMethodCallHandler(_homeWidgetChannel, null);
  });

  testWidgets('city picker', (WidgetTester tester) async {
    _useViewport(tester, kPhone);
    final SettingsController controller = await _controller();
    await tester.pumpWidget(_frame(controller, const CityPickerScreen()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'ال');
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -128));
    await tester.pump();

    await _save(tester, kPhone, 'gen-cities');
    await _unmount(tester);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('adjustments', (WidgetTester tester) async {
    _useViewport(tester, kPhone);
    final SettingsController controller = await _controller();
    await controller.setAdjustment(PrayerSlot.fajr, -2);
    await controller.setAdjustment(PrayerSlot.maghrib, 3);
    await tester.pumpWidget(_frame(controller, const AdjustmentsScreen()));
    await tester.pump();

    await _save(tester, kPhone, 'gen-adjust');
    await _unmount(tester);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('welcome', (WidgetTester tester) async {
    _useViewport(tester, kPhone);
    final SettingsController controller = await _controller(withCity: false);
    await tester.pumpWidget(_frame(controller, const WelcomeScreen()));
    await tester.pump();

    await _save(tester, kPhone, 'gen-welcome');
    await _unmount(tester);
  }, timeout: const Timeout(Duration(minutes: 2)));

  _tabletShot(kTablet7, '01', 'home', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(_frame(controller, const HomeScreen()));
    await tester.pump();
  });

  _tabletShot(kTablet7, '02', 'monthly', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(_frame(controller, const MonthlyScreen()));
    await tester.pump();
  });

  _tabletShot(kTablet7, '03', 'cities', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(_frame(controller, const CityPickerScreen()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'السعودية');
    await tester.pump();

    await _scrollPastFlags(tester, kTablet7, 200);
  });

  _tabletShot(kTablet7, '04', 'settings', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(_frame(controller, const SettingsScreen()));
    await tester.pump();

    await _scrollPastFlags(tester, kTablet7, 205);
  });

  _tabletShot(kTablet7, '05', 'adjust', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await controller.setAdjustment(PrayerSlot.fajr, -2);
    await controller.setAdjustment(PrayerSlot.maghrib, 3);
    await tester.pumpWidget(_frame(controller, const AdjustmentsScreen()));
    await tester.pump();
  });

  _tabletShot(kTablet7, '06', 'about', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(_frame(controller, const AboutScreen()));
    await tester.pump();
  });

  _tabletShot(kTablet7, '07', 'home dark', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(
      _frame(controller, const HomeScreen(), themeMode: ThemeMode.dark),
    );
    await tester.pump();
  });

  _tabletShot(kTablet7, '08', 'settings dark', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(
      _frame(controller, const SettingsScreen(), themeMode: ThemeMode.dark),
    );
    await tester.pump();

    await _scrollPastFlags(tester, kTablet7, 500);
  });

  _tabletShot(kTablet10, '01', 'home', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(_frame(controller, const HomeScreen()));
    await tester.pump();
  });

  _tabletShot(kTablet10, '02', 'monthly', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(_frame(controller, const MonthlyScreen()));
    await tester.pump();
  });

  _tabletShot(kTablet10, '03', 'adjust', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await controller.setAdjustment(PrayerSlot.fajr, -2);
    await controller.setAdjustment(PrayerSlot.maghrib, 3);
    await tester.pumpWidget(_frame(controller, const AdjustmentsScreen()));
    await tester.pump();
  });

  _tabletShot(kTablet10, '04', 'about', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(_frame(controller, const AboutScreen()));
    await tester.pump();
  });

  _tabletShot(kTablet10, '05', 'home dark', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(
      _frame(controller, const HomeScreen(), themeMode: ThemeMode.dark),
    );
    await tester.pump();
  });

  _tabletShot(kTablet10, '06', 'monthly dark', (WidgetTester tester) async {
    final SettingsController controller = await _controller();
    await tester.pumpWidget(
      _frame(controller, const MonthlyScreen(), themeMode: ThemeMode.dark),
    );
    await tester.pump();
  });
}
