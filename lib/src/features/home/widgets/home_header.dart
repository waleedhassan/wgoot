import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_text.dart';
import '../../../core/widgets/ornament_divider.dart';
import '../../../data/hijri_date.dart';
import '../../../data/models/city.dart';
import '../../../data/prayer_engine.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.city,
    required this.now,
    required this.hijri,
    required this.upcoming,
    required this.progress,
    required this.use24HourClock,
    required this.onPickCity,
    required this.onOpenSettings,
    required this.onOpenAbout,
    required this.onOpenMonth,
  });

  final City city;
  final DateTime now;
  final HijriDate hijri;
  final UpcomingPrayer? upcoming;
  final double progress;
  final bool use24HourClock;
  final VoidCallback onPickCity;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenMonth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    final double topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 10, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[palette.heroStart, palette.heroEnd],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.heroEnd.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _CircleButton(
                icon: Icons.tune_rounded,
                tooltip: 'الإعدادات',
                onTap: onOpenSettings,
              ),
              const Spacer(),
              _CircleButton(
                icon: Icons.calendar_month_rounded,
                tooltip: 'جدول الشهر',
                onTap: onOpenMonth,
              ),
              const SizedBox(width: 8),
              _CircleButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'عن التطبيق',
                onTap: onOpenAbout,
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'وُقُوتُ الصّلاةِ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.scriptFontFamily,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Center(child: _CityChip(city: city, onTap: onPickCity)),
          const SizedBox(height: 12),
          OrnamentDivider(color: Colors.white.withValues(alpha: 0.75)),
          const SizedBox(height: 10),
          Text(
            hijri.formatted,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.scriptFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${weekdayName(now)} — ${formatGregorian(now)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 18),
          _NextPrayerPanel(
            upcoming: upcoming,
            now: now,
            progress: progress,
            use24HourClock: use24HourClock,
          ),
        ],
      ),
    );
  }
}

class _NextPrayerPanel extends StatelessWidget {
  const _NextPrayerPanel({
    required this.upcoming,
    required this.now,
    required this.progress,
    required this.use24HourClock,
  });

  final UpcomingPrayer? upcoming;
  final DateTime now;
  final double progress;
  final bool use24HourClock;

  @override
  Widget build(BuildContext context) {
    final UpcomingPrayer? next = upcoming;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: next == null
          ? Text(
              'تعذّر حساب الصلاة القادمة لهذا الموقع',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            )
          : Column(
              children: <Widget>[
                Text(
                  'الصلاة القادمة',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      next.slot.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      next.slot.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatClock(next.time, use24Hour: use24HourClock),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  formatCountdown(next.time.difference(now)),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'يتبقى ${describeRemaining(next.time.difference(now))}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({required this.city, required this.onTap});

  final City city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.location_on_rounded,
                size: 17,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                '${city.name} · ${city.country}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }
}
