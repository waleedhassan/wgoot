import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_text.dart';
import '../../data/models/prayer_slot.dart';
import '../../data/prayer_engine.dart';
import '../../settings/settings_controller.dart';

class AdjustmentsScreen extends StatelessWidget {
  const AdjustmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    final DayTimes today = PrayerEngine.today(
      settings.city,
      settings.calculationConfig,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المواقيت'),
        actions: <Widget>[
          if (settings.hasAnyAdjustment())
            TextButton(
              onPressed: settings.clearAdjustments,
              child: const Text('إعادة الضبط'),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.info_outline_rounded, color: palette.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'إن اختلف الوقت المحسوب عن أذان مسجدك، عدّله هنا بالدقائق. '
                    'ينعكس التعديل على الجدول والتنبيهات معاً.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final PrayerSlot slot in PrayerSlot.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AdjustmentCard(
                slot: slot,
                minutes: settings.adjustmentFor(slot),
                resultingTime: formatClock(
                  today.timeOf(slot),
                  use24Hour: settings.use24HourClock,
                ),
                onChanged: (int value) => settings.setAdjustment(slot, value),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdjustmentCard extends StatelessWidget {
  const _AdjustmentCard({
    required this.slot,
    required this.minutes,
    required this.resultingTime,
    required this.onChanged,
  });

  final PrayerSlot slot;
  final int minutes;
  final String resultingTime;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(slot.icon, size: 20, color: palette.gold),
              const SizedBox(width: 10),
              Text(slot.title, style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                resultingTime,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              IconButton(
                onPressed: minutes > -SettingsController.maxAdjustment
                    ? () => onChanged(minutes - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Expanded(
                child: Slider(
                  value: minutes.toDouble(),
                  min: -SettingsController.maxAdjustment.toDouble(),
                  max: SettingsController.maxAdjustment.toDouble(),
                  divisions: SettingsController.maxAdjustment * 2,
                  label: formatSignedMinutes(minutes),
                  onChanged: (double value) => onChanged(value.round()),
                ),
              ),
              IconButton(
                onPressed: minutes < SettingsController.maxAdjustment
                    ? () => onChanged(minutes + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              formatSignedMinutes(minutes),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: minutes == 0 ? null : palette.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
