import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/theme/app_theme.dart';
import '../../data/calculation_labels.dart';
import '../../data/hijri_date.dart';
import '../../data/models/prayer_slot.dart';
import '../../data/prayer_engine.dart';
import '../../settings/settings_controller.dart';
import '../about/about_screen.dart';
import '../city/city_picker_screen.dart';
import '../monthly/monthly_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/home_header.dart';
import 'widgets/prayer_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(context.read<SettingsController>().refreshSchedule());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      unawaited(context.read<SettingsController>().refreshSchedule());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  double _progressBetween(
    DayTimes today,
    DayTimes yesterday,
    UpcomingPrayer? next,
    tz.TZDateTime now,
  ) {
    if (next == null) {
      return 0;
    }
    tz.TZDateTime? previous;
    for (final DayTimes day in <DayTimes>[yesterday, today]) {
      for (final PrayerSlot slot in kFardSlots) {
        final tz.TZDateTime time = day.timeOf(slot);
        if (!time.isAfter(now)) {
          previous = time;
        }
      }
    }
    if (previous == null) {
      return 0;
    }
    final int total = next.time.difference(previous).inSeconds;
    if (total <= 0) {
      return 0;
    }
    return now.difference(previous).inSeconds / total;
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;

    final PrayerCalculationConfig config = settings.calculationConfig;
    final tz.TZDateTime now = PrayerEngine.nowIn(settings.city);
    final DayTimes today = PrayerEngine.compute(settings.city, config, now);
    final DayTimes yesterday = PrayerEngine.compute(
      settings.city,
      config,
      now.subtract(const Duration(days: 1)),
    );
    final UpcomingPrayer? next = PrayerEngine.nextPrayer(
      settings.city,
      config,
      from: now,
    );
    final PrayerSlot? current = PrayerEngine.currentPrayer(
      settings.city,
      config,
      from: now,
    );
    final HijriDate hijri = HijriDate.fromGregorian(
      now,
      offsetDays: settings.hijriOffset,
    );
    final PrayerSlot? nextToday = next != null && !next.isTomorrow
        ? next.slot
        : null;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        children: <Widget>[
          HomeHeader(
            city: settings.city,
            now: now,
            hijri: hijri,
            upcoming: next,
            progress: _progressBetween(today, yesterday, next, now),
            use24HourClock: settings.use24HourClock,
            onPickCity: _openCityPicker,
            onOpenSettings: _openSettings,
            onOpenAbout: _openAbout,
            onOpenMonth: _openMonth,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.divider),
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: <Color>[
                    palette.cardGradientStart,
                    palette.cardGradientEnd,
                  ],
                ),
              ),
              child: Column(
                children: <Widget>[
                  for (final PrayerSlot slot in PrayerSlot.values)
                    PrayerRow(
                      slot: slot,
                      time: today.timeOf(slot),
                      isCurrent: slot == current && slot != nextToday,
                      isNext: slot == nextToday,
                      adjustment: settings.adjustmentFor(slot),
                      use24HourClock: settings.use24HourClock,
                      isMuted: settings.isMuted(slot),
                      onToggleMute: () =>
                          settings.setMuted(slot, !settings.isMuted(slot)),
                    ),
                ],
              ),
            ),
          ),
          if (!settings.notificationsEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _Notice(
                icon: Icons.notifications_off_rounded,
                message: 'تنبيهات الأذان متوقفة حالياً.',
                actionLabel: 'تشغيل',
                onAction: () => settings.setNotificationsEnabled(true),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openMonth,
                    icon: const Icon(Icons.calendar_month_rounded, size: 20),
                    label: const Text('جدول الشهر'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    label: const Text('الإعدادات'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Text(
              'المواقيت محسوبة لموقع ${settings.city.name} بطريقة '
              '${methodTitle(settings.method)}'
              '${settings.hasAnyAdjustment() ? ' مع تعديلات يدوية' : ''}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  void _openCityPicker() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CityPickerScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  void _openAbout() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
    );
  }

  void _openMonth() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MonthlyScreen()),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: palette.goldSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: palette.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
