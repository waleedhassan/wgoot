import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/about/about_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'settings/settings_controller.dart';

class WgootApp extends StatelessWidget {
  const WgootApp({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsController>.value(
      value: settingsController,
      child: Consumer<SettingsController>(
        builder: (BuildContext context, SettingsController settings, _) {
          return MaterialApp(
            title: 'وقوت الصلاة',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            locale: const Locale('ar'),
            supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            scrollBehavior: const _AppScrollBehavior(),
            builder: (BuildContext context, Widget? child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: settings.hasChosenCity
                ? const HomeScreen()
                : const WelcomeScreen(),
            routes: <String, WidgetBuilder>{
              AboutScreen.routeName: (_) => const AboutScreen(),
            },
          );
        },
      ),
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
