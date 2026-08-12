import 'package:hijri/hijri_calendar.dart';

import '../core/utils/arabic_text.dart';

const List<String> hijriMonthNames = <String>[
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

class HijriDate {
  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
  });

  factory HijriDate.fromGregorian(DateTime date, {int offsetDays = 0}) {
    final DateTime shifted = DateTime(
      date.year,
      date.month,
      date.day,
    ).add(Duration(days: offsetDays));
    final HijriCalendar converted = HijriCalendar.fromDate(shifted);
    return HijriDate(
      year: converted.hYear,
      month: converted.hMonth,
      day: converted.hDay,
    );
  }

  final int year;
  final int month;
  final int day;

  String get monthName => hijriMonthNames[month - 1];

  String get formatted =>
      '${toArabicNumerals(day)} $monthName ${toArabicNumerals(year)} هـ';

  String get shortFormatted =>
      toArabicNumerals('$day/$month/$year');

  bool get isRamadan => month == 9;
}
