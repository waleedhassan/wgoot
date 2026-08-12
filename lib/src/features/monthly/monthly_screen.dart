import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_text.dart';
import '../../data/hijri_date.dart';
import '../../data/models/prayer_slot.dart';
import '../../data/prayer_engine.dart';
import '../../settings/settings_controller.dart';

class MonthlyScreen extends StatefulWidget {
  const MonthlyScreen({super.key});

  @override
  State<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends State<MonthlyScreen> {
  int _monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;

    final tz.Location location = PrayerEngine.locationFor(settings.city);
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    final tz.TZDateTime anchor = tz.TZDateTime(
      location,
      now.year,
      now.month + _monthOffset,
      1,
    );
    final List<DayTimes> days = PrayerEngine.month(
      settings.city,
      settings.calculationConfig,
      anchor,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('جدول الشهر')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => setState(() => _monthOffset--),
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'الشهر السابق',
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        '${gregorianMonthNames[anchor.month - 1]} '
                        '${toArabicNumerals(anchor.year)}',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        _hijriSpan(days, settings.hijriOffset),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _monthOffset++),
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'الشهر التالي',
                ),
              ],
            ),
          ),
          _TableHeader(palette: palette),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              itemCount: days.length,
              itemBuilder: (BuildContext context, int index) {
                final DayTimes day = days[index];
                final bool isToday =
                    day.day.year == now.year &&
                    day.day.month == now.month &&
                    day.day.day == now.day;
                return _TableRow(
                  day: day,
                  hijri: HijriDate.fromGregorian(
                    day.day,
                    offsetDays: settings.hijriOffset,
                  ),
                  isToday: isToday,
                  use24HourClock: settings.use24HourClock,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _hijriSpan(List<DayTimes> days, int offset) {
    if (days.isEmpty) {
      return '';
    }
    final HijriDate first = HijriDate.fromGregorian(
      days.first.day,
      offsetDays: offset,
    );
    final HijriDate last = HijriDate.fromGregorian(
      days.last.day,
      offsetDays: offset,
    );
    if (first.month == last.month) {
      return '${first.monthName} ${toArabicNumerals(first.year)} هـ';
    }
    return '${first.monthName} — ${last.monthName} '
        '${toArabicNumerals(last.year)} هـ';
  }
}

const List<PrayerSlot> _columns = <PrayerSlot>[
  PrayerSlot.fajr,
  PrayerSlot.sunrise,
  PrayerSlot.dhuhr,
  PrayerSlot.asr,
  PrayerSlot.maghrib,
  PrayerSlot.isha,
];

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 56,
            child: Text(
              'اليوم',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: palette.gold),
            ),
          ),
          for (final PrayerSlot slot in _columns)
            Expanded(
              child: Text(
                slot.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.day,
    required this.hijri,
    required this.isToday,
    required this.use24HourClock,
  });

  final DayTimes day;
  final HijriDate hijri;
  final bool isToday;
  final bool use24HourClock;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    final bool isFriday = day.day.weekday == DateTime.friday;
    final TextStyle? cellStyle = theme.textTheme.labelSmall?.copyWith(
      color: isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? palette.activeRow
            : (isFriday ? palette.goldSoft.withValues(alpha: 0.4) : null),
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 56,
            child: Column(
              children: <Widget>[
                Text(
                  toArabicNumerals(day.day.day),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isToday ? theme.colorScheme.primary : null,
                  ),
                ),
                Text(
                  toArabicNumerals(hijri.day),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.gold,
                  ),
                ),
              ],
            ),
          ),
          for (final PrayerSlot slot in _columns)
            Expanded(
              child: Text(
                formatClock(day.timeOf(slot), use24Hour: use24HourClock),
                textAlign: TextAlign.center,
                style: cellStyle,
              ),
            ),
        ],
      ),
    );
  }
}
