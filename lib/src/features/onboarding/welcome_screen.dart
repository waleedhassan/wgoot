import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_text.dart';
import '../../core/widgets/ornament_divider.dart';
import '../../data/cities.dart';
import '../../data/models/city.dart';
import '../../settings/settings_controller.dart';
import '../city/city_picker_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const List<String> _suggestedIds = <String>[
    'sa-makkah',
    'sa-riyadh',
    'eg-cairo',
    'ae-dubai',
    'tr-istanbul',
    'gb-london',
  ];

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.read<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          children: <Widget>[
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: <Color>[palette.heroStart, palette.heroEnd],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'وَقُوتُ الصَّلاة',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'مواقيت الصلاة والتاريخ الهجري وتنبيه الأذان',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            OrnamentDivider(color: palette.gold),
            const SizedBox(height: 22),
            Text(
              'اختر مدينتك لنحسب لك المواقيت',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                for (final String id in _suggestedIds)
                  if (cityById(id) case final City city)
                    ActionChip(
                      avatar: Text(city.flag),
                      label: Text(city.name),
                      onPressed: () => settings.setCity(city),
                    ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CityPickerScreen(),
                ),
              ),
              icon: const Icon(Icons.search_rounded),
              label: Text(
                'تصفّح ${toArabicNumerals(kCities.length)} مدينة',
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => settings.setCity(kDefaultCity),
              child: const Text('المتابعة بمكة المكرمة'),
            ),
          ],
        ),
      ),
    );
  }
}
