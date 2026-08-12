import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_text.dart';
import '../../../data/models/prayer_slot.dart';

class PrayerRow extends StatelessWidget {
  const PrayerRow({
    super.key,
    required this.slot,
    required this.time,
    required this.isCurrent,
    required this.isNext,
    required this.adjustment,
    required this.use24HourClock,
    required this.isMuted,
    required this.onToggleMute,
  });

  final PrayerSlot slot;
  final DateTime time;
  final bool isCurrent;
  final bool isNext;
  final int adjustment;
  final bool use24HourClock;
  final bool isMuted;
  final VoidCallback? onToggleMute;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    final ColorScheme scheme = theme.colorScheme;
    final bool highlight = isCurrent || isNext;
    final Color accent = isNext ? scheme.primary : palette.gold;

    return Container(
      decoration: BoxDecoration(
        color: highlight ? palette.activeRow : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: highlight
                  ? accent.withValues(alpha: 0.16)
                  : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              slot.icon,
              size: 20,
              color: highlight ? accent : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      slot.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: highlight ? accent : scheme.onSurface,
                      ),
                    ),
                    if (isNext) ...<Widget>[
                      const SizedBox(width: 8),
                      _Badge(label: 'التالية', color: scheme.primary),
                    ] else if (isCurrent) ...<Widget>[
                      const SizedBox(width: 8),
                      _Badge(label: 'الوقت الحالي', color: palette.gold),
                    ],
                  ],
                ),
                if (adjustment != 0)
                  Text(
                    'تعديل يدوي ${formatSignedMinutes(adjustment)}',
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ),
          Text(
            formatClock(time, use24Hour: use24HourClock),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              color: highlight ? accent : scheme.onSurface,
            ),
          ),
          if (slot.isFard)
            IconButton(
              onPressed: onToggleMute,
              tooltip: isMuted ? 'تفعيل تنبيه ${slot.title}' : 'كتم تنبيه ${slot.title}',
              icon: Icon(
                isMuted
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined,
                size: 20,
                color: isMuted ? scheme.onSurfaceVariant : accent,
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
