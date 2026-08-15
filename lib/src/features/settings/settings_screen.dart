import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_text.dart';
import '../../data/calculation_labels.dart';
import '../../data/cities.dart';
import '../../data/models/prayer_slot.dart';
import '../../settings/settings_controller.dart';
import '../adjust/adjustments_screen.dart';
import '../city/city_picker_screen.dart';

const String _automaticMethodKey = 'auto';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        children: <Widget>[
          _Section(
            title: 'الموقع والمواقيت',
            icon: Icons.public_rounded,
            children: <Widget>[
              _Tile(
                icon: Icons.location_on_rounded,
                title: 'المدينة',
                subtitle: '${settings.city.name} · ${settings.city.country}',
                trailing: Text(
                  settings.city.flag,
                  style: const TextStyle(fontSize: 20),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CityPickerScreen(),
                  ),
                ),
              ),
              _Tile(
                icon: Icons.calculate_rounded,
                title: 'طريقة الحساب',
                subtitle: settings.usesAutomaticMethod
                    ? 'تلقائي — ${methodTitle(settings.method)}'
                    : methodTitle(settings.method),
                onTap: () => _showMethodSheet(context, settings),
              ),
              _Tile(
                icon: Icons.timelapse_rounded,
                title: 'مذهب حساب العصر',
                subtitle: madhabSubtitle(settings.madhab),
                onTap: () => _showMadhabSheet(context, settings),
              ),
              _Tile(
                icon: Icons.explore_rounded,
                title: 'قاعدة خطوط العرض العالية',
                subtitle: highLatitudeTitle(settings.highLatitudeRule),
                onTap: () => _showHighLatitudeSheet(context, settings),
              ),
              _Tile(
                icon: Icons.more_time_rounded,
                title: 'تعديل المواقيت يدوياً',
                subtitle: settings.hasAnyAdjustment()
                    ? _adjustmentSummary(settings)
                    : 'بدون تعديل على أي وقت',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdjustmentsScreen(),
                  ),
                ),
              ),
            ],
          ),
          _Section(
            title: 'تنبيه الأذان',
            icon: Icons.notifications_active_rounded,
            children: <Widget>[
              SwitchListTile(
                value: settings.notificationsEnabled,
                onChanged: settings.setNotificationsEnabled,
                secondary: const Icon(Icons.notifications_rounded),
                title: const Text('تنبيه عند دخول الوقت'),
                subtitle: Text(
                  settings.notificationsEnabled
                      ? 'مجدولة للأيام العشرة القادمة · '
                            '${toArabicNumerals(settings.scheduledCount)} تنبيه'
                      : 'لن يصلك تنبيه عند دخول الوقت',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              SwitchListTile(
                value: settings.adhanSoundEnabled,
                onChanged: settings.notificationsEnabled
                    ? settings.setAdhanSoundEnabled
                    : null,
                secondary: const Icon(Icons.volume_up_rounded),
                title: const Text('صوت التنبيه'),
                subtitle: Text(
                  'إيقافه يجعل التنبيه صامتاً مع اهتزاز فقط',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              _Tile(
                icon: Icons.timer_outlined,
                title: 'تذكير قبل الأذان',
                subtitle: settings.preAlertMinutes == 0
                    ? 'بدون تذكير مسبق'
                    : 'قبل ${toArabicNumerals(settings.preAlertMinutes)} دقيقة',
                onTap: () => _showPreAlertSheet(context, settings),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'الصلوات المنبَّه عليها',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final PrayerSlot slot in kFardSlots)
                          FilterChip(
                            label: Text(slot.title),
                            selected: !settings.isMuted(slot),
                            onSelected: settings.notificationsEnabled
                                ? (bool selected) =>
                                      settings.setMuted(slot, !selected)
                                : null,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          _Section(
            title: 'التقويم والعرض',
            icon: Icons.calendar_today_rounded,
            children: <Widget>[
              _Tile(
                icon: Icons.event_rounded,
                title: 'تعديل التاريخ الهجري',
                subtitle: _hijriOffsetLabel(settings.hijriOffset),
                trailing: _Stepper(
                  value: settings.hijriOffset,
                  min: -3,
                  max: 3,
                  onChanged: settings.setHijriOffset,
                ),
              ),
              SwitchListTile(
                value: settings.use24HourClock,
                onChanged: settings.setUse24HourClock,
                secondary: const Icon(Icons.schedule_rounded),
                title: const Text('نظام ٢٤ ساعة'),
                subtitle: Text(
                  settings.use24HourClock
                      ? 'مثال: ${toArabicNumerals('17:45')}'
                      : 'مثال: ${toArabicNumerals('5:45')} م',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              _Tile(
                icon: Icons.brightness_6_rounded,
                title: 'المظهر',
                subtitle: _themeLabel(settings.themeMode),
                onTap: () => _showThemeSheet(context, settings),
              ),
            ],
          ),
          if (settings.homeScreenWidgetSupported)
            const _Section(
              title: 'شاشة الجهاز الرئيسية',
              icon: Icons.widgets_rounded,
              children: <Widget>[_HomeScreenWidgetTile()],
            ),
        ],
      ),
    );
  }

  String _hijriOffsetLabel(int offset) {
    if (offset == 0) {
      return 'مطابق لتقويم أم القرى';
    }
    final String direction = offset > 0 ? 'تقديم' : 'تأخير';
    final int days = offset.abs();
    final String unit = days == 1 ? 'يوم' : (days == 2 ? 'يومين' : 'أيام');
    return '$direction ${days > 2 ? '${toArabicNumerals(days)} ' : ''}$unit';
  }

  String _adjustmentSummary(SettingsController settings) {
    final List<String> parts = <String>[];
    for (final PrayerSlot slot in PrayerSlot.values) {
      final int minutes = settings.adjustmentFor(slot);
      if (minutes != 0) {
        parts.add('${slot.title} ${formatSignedMinutes(minutes)}');
      }
    }
    return parts.join(' · ');
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'حسب النظام';
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
    }
  }

  Future<void> _showMethodSheet(
    BuildContext context,
    SettingsController settings,
  ) {
    return _showChoiceSheet<String>(
      context,
      title: 'طريقة الحساب',
      description: 'زوايا الفجر والعشاء المعتمدة لدى الجهات المختلفة.',
      groupValue: settings.usesAutomaticMethod
          ? _automaticMethodKey
          : settings.method.name,
      onChanged: (String? value) {
        if (value == null) {
          return;
        }
        if (value == _automaticMethodKey) {
          settings.setMethod(null);
          return;
        }
        settings.setMethod(
          kSelectableMethods.firstWhere(
            (CalculationMethod method) => method.name == value,
          ),
        );
      },
      options: <_ChoiceOption<String>>[
        _ChoiceOption<String>(
          value: _automaticMethodKey,
          title: 'تلقائي حسب الدولة',
          subtitle: methodTitle(suggestedMethodFor(settings.city)),
        ),
        for (final CalculationMethod method in kSelectableMethods)
          _ChoiceOption<String>(
            value: method.name,
            title: methodTitle(method),
            subtitle: methodSubtitle(method),
          ),
      ],
    );
  }

  Future<void> _showMadhabSheet(
    BuildContext context,
    SettingsController settings,
  ) {
    return _showChoiceSheet<Madhab>(
      context,
      title: 'مذهب حساب العصر',
      groupValue: settings.madhab,
      onChanged: (Madhab? value) {
        if (value != null) {
          settings.setMadhab(value);
        }
      },
      options: <_ChoiceOption<Madhab>>[
        for (final Madhab madhab in Madhab.values)
          _ChoiceOption<Madhab>(
            value: madhab,
            title: madhabTitle(madhab),
            subtitle: madhabSubtitle(madhab),
          ),
      ],
    );
  }

  Future<void> _showHighLatitudeSheet(
    BuildContext context,
    SettingsController settings,
  ) {
    return _showChoiceSheet<HighLatitudeRule>(
      context,
      title: 'قاعدة خطوط العرض العالية',
      description:
          'تُستخدم في البلاد التي لا يغيب فيها الشفق صيفاً لتقدير الفجر والعشاء.',
      groupValue: settings.highLatitudeRule,
      onChanged: (HighLatitudeRule? value) {
        if (value != null) {
          settings.setHighLatitudeRule(value);
        }
      },
      options: <_ChoiceOption<HighLatitudeRule>>[
        for (final HighLatitudeRule rule in HighLatitudeRule.values)
          _ChoiceOption<HighLatitudeRule>(
            value: rule,
            title: highLatitudeTitle(rule),
          ),
      ],
    );
  }

  Future<void> _showPreAlertSheet(
    BuildContext context,
    SettingsController settings,
  ) {
    return _showChoiceSheet<int>(
      context,
      title: 'تذكير قبل الأذان',
      groupValue: settings.preAlertMinutes,
      onChanged: (int? value) {
        if (value != null) {
          settings.setPreAlertMinutes(value);
        }
      },
      options: <_ChoiceOption<int>>[
        for (final int minutes in SettingsController.preAlertChoices)
          _ChoiceOption<int>(
            value: minutes,
            title: minutes == 0
                ? 'بدون تذكير'
                : 'قبل ${toArabicNumerals(minutes)} دقيقة',
          ),
      ],
    );
  }

  Future<void> _showThemeSheet(
    BuildContext context,
    SettingsController settings,
  ) {
    return _showChoiceSheet<ThemeMode>(
      context,
      title: 'المظهر',
      groupValue: settings.themeMode,
      onChanged: (ThemeMode? value) {
        if (value != null) {
          settings.setThemeMode(value);
        }
      },
      options: <_ChoiceOption<ThemeMode>>[
        for (final ThemeMode mode in ThemeMode.values)
          _ChoiceOption<ThemeMode>(value: mode, title: _themeLabel(mode)),
      ],
    );
  }

  Future<void> _showChoiceSheet<T>(
    BuildContext context, {
    required String title,
    String? description,
    required T? groupValue,
    required ValueChanged<T?> onChanged,
    required List<_ChoiceOption<T>> options,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final ThemeData theme = Theme.of(sheetContext);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.82,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: theme.textTheme.titleLarge),
                      if (description != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(description, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                Flexible(
                  child: RadioGroup<T>(
                    groupValue: groupValue,
                    onChanged: (T? value) {
                      onChanged(value);
                      Navigator.of(sheetContext).pop();
                    },
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 12),
                      children: <Widget>[
                        for (final _ChoiceOption<T> option in options)
                          RadioListTile<T>(
                            value: option.value,
                            title: Text(option.title),
                            subtitle: option.subtitle == null
                                ? null
                                : Text(option.subtitle!),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeScreenWidgetTile extends StatefulWidget {
  const _HomeScreenWidgetTile();

  @override
  State<_HomeScreenWidgetTile> createState() => _HomeScreenWidgetTileState();
}

class _HomeScreenWidgetTileState extends State<_HomeScreenWidgetTile> {
  bool _canPin = false;

  @override
  void initState() {
    super.initState();
    _resolvePinSupport();
  }

  Future<void> _resolvePinSupport() async {
    final bool canPin = await context
        .read<SettingsController>()
        .canPinHomeScreenWidget();
    if (mounted) {
      setState(() => _canPin = canPin);
    }
  }

  Future<void> _pin() async {
    final SettingsController settings = context.read<SettingsController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await settings.pinHomeScreenWidget();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('اختر مكان المربع ثم أكّد الإضافة من الشاشة الرئيسية.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Tile(
      icon: Icons.dashboard_customize_rounded,
      title: 'مربع المواقيت',
      subtitle: _canPin
          ? 'يعرض الصلاة القادمة والوقت المتبقي ومواقيت اليوم'
          : 'أضفه بالضغط مطولاً على شاشة جهازك ثم اختيار «وقوت الصلاة»',
      trailing: _canPin
          ? const Icon(Icons.add_circle_outline_rounded, size: 22)
          : null,
      onTap: _canPin ? _pin : null,
    );
  }
}

class _ChoiceOption<T> {
  const _ChoiceOption({
    required this.value,
    required this.title,
    this.subtitle,
  });

  final T value;
  final String title;
  final String? subtitle;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 19, color: palette.gold),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.gold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: theme.colorScheme.surfaceContainerLowest,
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : const Icon(Icons.chevron_right_rounded, size: 22)),
      shape: const RoundedRectangleBorder(),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          visualDensity: VisualDensity.compact,
        ),
        SizedBox(
          width: 34,
          child: Text(
            value == 0
                ? toArabicNumerals(0)
                : '${value > 0 ? '+' : '−'}${toArabicNumerals(value.abs())}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
