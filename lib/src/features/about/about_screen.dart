import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_text.dart';
import '../../core/widgets/ornament_divider.dart';
import '../../data/calculation_labels.dart';
import '../../data/cities.dart';
import '../../settings/settings_controller.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String routeName = '/about';
  static const String version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('عن التطبيق')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 28,
        ),
        children: <Widget>[
          Center(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: <Color>[palette.heroStart, palette.heroEnd],
                ),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: palette.heroEnd.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mosque_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'وَقُوتُ الصَّلاة',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall,
          ),
          Text(
            'الإصدار ${toArabicNumerals(version)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          OrnamentDivider(color: palette.gold),
          const SizedBox(height: 18),
          _InfoCard(
            icon: Icons.menu_book_rounded,
            title: 'لماذا «وُقُوت الصلاة»؟',
            body:
                'سُمّي التطبيق بهذا الاسم اقتداءً بتسمية الإمام مالك بن أنس رحمه '
                'الله في «الموطأ»، فقد افتتح كتابه بـ«كتاب وُقُوت الصلاة»، '
                'و«الوُقُوت» جمع وقت، وهي اللفظة التي جرى عليها قلمه في تسمية '
                'أوقات الصلوات الخمس.',
          ),
          _InfoCard(
            icon: Icons.calculate_rounded,
            title: 'كيف تُحسب المواقيت؟',
            body:
                'تُحسب المواقيت فلكياً على جهازك دون اتصال بالإنترنت، اعتماداً '
                'على إحداثيات المدينة المختارة وزاويتَي الفجر والعشاء المعتمدتين '
                'لدى جهة الحساب. يمكنك تغيير طريقة الحساب أو مذهب العصر أو تعديل '
                'أي وقت يدوياً ليوافق أذان مسجدك.',
          ),
          _CurrentSetupCard(settings: settings),
          _InfoCard(
            icon: Icons.notifications_active_rounded,
            title: 'تنبيه الأذان',
            body:
                'يجدول التطبيق تنبيهات الصلوات الخمس للأيام العشرة القادمة، '
                'ويعيد جدولتها كلما فتحته أو غيّرت مدينتك. لضمان وصولها في '
                'وقتها اسمح للتطبيق بالتنبيهات وبالمنبّهات الدقيقة، واستثنِه من '
                'قيود توفير البطارية.',
          ),
          _InfoCard(
            icon: Icons.event_rounded,
            title: 'التاريخ الهجري',
            body:
                'التاريخ الهجري معتمد على تقويم أم القرى، ويمكن تقديمه أو '
                'تأخيره حتى ثلاثة أيام من الإعدادات ليوافق ما عليه بلدك.',
          ),
          _InfoCard(
            icon: Icons.font_download_rounded,
            title: 'الخطوط',
            body:
                'خط «أميري» وخط «IBM Plex Sans Arabic» — مرخّصان بموجب رخصة '
                'الخطوط المفتوحة (SIL Open Font License 1.1).',
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'إِنَّ الصَّلاةَ كانَتْ عَلَى المُؤْمِنينَ كِتاباً مَوْقوتاً',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 21,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'سورة النساء — الآية ${toArabicNumerals(103)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _CurrentSetupCard extends StatelessWidget {
  const _CurrentSetupCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.settings_suggest_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('إعداداتك الحالية', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          _Line(
            label: 'المدينة',
            value: '${settings.city.name} · ${settings.city.country}',
          ),
          _Line(
            label: 'طريقة الحساب',
            value: settings.usesAutomaticMethod
                ? '${methodTitle(settings.method)} (تلقائي)'
                : methodTitle(settings.method),
          ),
          _Line(label: 'مذهب العصر', value: madhabTitle(settings.madhab)),
          _Line(
            label: 'عدد المدن المتاحة',
            value: '${toArabicNumerals(kCities.length)} مدينة',
          ),
          _Line(
            label: 'التنبيهات المجدولة',
            value: settings.notificationsEnabled
                ? '${toArabicNumerals(settings.scheduledCount)} تنبيه'
                : 'متوقفة',
            color: palette.gold,
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 118,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = theme.extension<AppPalette>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
