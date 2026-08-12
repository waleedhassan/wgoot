import 'package:adhan/adhan.dart';

const List<CalculationMethod> kSelectableMethods = <CalculationMethod>[
  CalculationMethod.umm_al_qura,
  CalculationMethod.muslim_world_league,
  CalculationMethod.egyptian,
  CalculationMethod.karachi,
  CalculationMethod.dubai,
  CalculationMethod.kuwait,
  CalculationMethod.qatar,
  CalculationMethod.turkey,
  CalculationMethod.singapore,
  CalculationMethod.north_america,
  CalculationMethod.moon_sighting_committee,
  CalculationMethod.tehran,
];

String methodTitle(CalculationMethod method) {
  switch (method) {
    case CalculationMethod.umm_al_qura:
      return 'أم القرى — مكة المكرمة';
    case CalculationMethod.muslim_world_league:
      return 'رابطة العالم الإسلامي';
    case CalculationMethod.egyptian:
      return 'الهيئة المصرية العامة للمساحة';
    case CalculationMethod.karachi:
      return 'جامعة العلوم الإسلامية — كراتشي';
    case CalculationMethod.dubai:
      return 'دبي والخليج';
    case CalculationMethod.kuwait:
      return 'الكويت';
    case CalculationMethod.qatar:
      return 'قطر';
    case CalculationMethod.turkey:
      return 'ديانت — تركيا';
    case CalculationMethod.singapore:
      return 'سنغافورة وجنوب شرق آسيا';
    case CalculationMethod.north_america:
      return 'أمريكا الشمالية (ISNA)';
    case CalculationMethod.moon_sighting_committee:
      return 'لجنة رؤية الهلال';
    case CalculationMethod.tehran:
      return 'جامعة طهران';
    case CalculationMethod.other:
      return 'مخصّصة';
  }
}

String methodSubtitle(CalculationMethod method) {
  final CalculationParameters parameters = method.getParameters();
  final String fajr = 'الفجر ${_angle(parameters.fajrAngle)}°';
  if (parameters.ishaInterval > 0) {
    return '$fajr · العشاء بعد المغرب بـ${parameters.ishaInterval} دقيقة';
  }
  final double? isha = parameters.ishaAngle;
  if (isha == null) {
    return fajr;
  }
  return '$fajr · العشاء ${_angle(isha)}°';
}

String _angle(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

String madhabTitle(Madhab madhab) =>
    madhab == Madhab.hanafi ? 'الحنفي' : 'الجمهور (شافعي ومالكي وحنبلي)';

String madhabSubtitle(Madhab madhab) => madhab == Madhab.hanafi
    ? 'العصر عند بلوغ ظل الشيء مثليه'
    : 'العصر عند بلوغ ظل الشيء مثله';

String highLatitudeTitle(HighLatitudeRule rule) {
  switch (rule) {
    case HighLatitudeRule.middle_of_the_night:
      return 'منتصف الليل';
    case HighLatitudeRule.seventh_of_the_night:
      return 'سُبع الليل';
    case HighLatitudeRule.twilight_angle:
      return 'زاوية الشفق';
  }
}
