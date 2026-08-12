import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_text.dart';
import '../../data/calculation_labels.dart';
import '../../data/cities.dart';
import '../../data/models/city.dart';
import '../../settings/settings_controller.dart';

class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    final List<City> matches = searchCities(_query);
    final Map<String, List<City>> grouped = groupByCountry(matches);
    final List<String> countries = grouped.keys.toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('اختيار المدينة')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'ابحث باسم المدينة أو الدولة...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          if (matches.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.travel_explore_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد مدينة مطابقة',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'جرّب اسماً آخر، أو اختر أقرب مدينة كبيرة إليك.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                itemCount: countries.length,
                itemBuilder: (BuildContext context, int index) {
                  final String country = countries[index];
                  final List<City> cities = grouped[country]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                        child: Row(
                          children: <Widget>[
                            Text(
                              cities.first.flag,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              country,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: palette.gold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Divider(color: palette.divider),
                            ),
                          ],
                        ),
                      ),
                      for (final City city in cities)
                        _CityTile(
                          city: city,
                          isSelected: city.id == settings.city.id,
                          onTap: () async {
                            await settings.setCity(city);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  final City city;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? palette.activeRow : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.location_city_rounded,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(city.name, style: theme.textTheme.titleSmall),
                      Text(
                        methodTitle(suggestedMethodFor(city)),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  _coordinates(city),
                  style: theme.textTheme.labelSmall,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _coordinates(City city) {
    final String lat =
        '${toArabicNumerals(city.latitude.abs().toStringAsFixed(1))}°'
        '${city.latitude >= 0 ? 'ش' : 'ج'}';
    final String lng =
        '${toArabicNumerals(city.longitude.abs().toStringAsFixed(1))}°'
        '${city.longitude >= 0 ? 'ق' : 'غ'}';
    return '$lat  $lng';
  }
}
