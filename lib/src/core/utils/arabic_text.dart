const String _diacriticRanges =
    '\u{0610}-\u{061A}\u{064B}-\u{065F}\u{0670}\u{06D6}-\u{06ED}\u{0640}';

final RegExp _diacritics = RegExp('[$_diacriticRanges]');
final RegExp _nonSearchable = RegExp('[^\u{0621}-\u{064A}0-9a-zA-Z ]');
final RegExp _whitespace = RegExp(r'\s+');

String normalizeArabic(String input) {
  final String stripped = input.replaceAll(_diacritics, '');
  final StringBuffer buffer = StringBuffer();
  for (final int rune in stripped.runes) {
    switch (rune) {
      case 0x0622:
      case 0x0623:
      case 0x0625:
      case 0x0671:
        buffer.writeCharCode(0x0627);
      case 0x0649:
        buffer.writeCharCode(0x064A);
      case 0x0629:
        buffer.writeCharCode(0x0647);
      case 0x0624:
      case 0x0626:
        buffer.writeCharCode(0x0621);
      default:
        if (rune >= 0x0660 && rune <= 0x0669) {
          buffer.writeCharCode(rune - 0x0660 + 0x30);
        } else if (rune >= 0x06F0 && rune <= 0x06F9) {
          buffer.writeCharCode(rune - 0x06F0 + 0x30);
        } else {
          buffer.writeCharCode(rune);
        }
    }
  }
  return buffer
      .toString()
      .replaceAll(_nonSearchable, ' ')
      .replaceAll(_whitespace, ' ')
      .trim()
      .toLowerCase();
}

const List<String> _arabicIndicDigits = <String>[
  '٠',
  '١',
  '٢',
  '٣',
  '٤',
  '٥',
  '٦',
  '٧',
  '٨',
  '٩',
];

String toArabicNumerals(Object value) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in value.toString().runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      buffer.write(_arabicIndicDigits[rune - 0x30]);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

String _pad(int value) => value.toString().padLeft(2, '0');

String formatClock(DateTime time, {required bool use24Hour}) {
  if (use24Hour) {
    return toArabicNumerals('${_pad(time.hour)}:${_pad(time.minute)}');
  }
  final int rawHour = time.hour % 12;
  final int hour = rawHour == 0 ? 12 : rawHour;
  final String suffix = time.hour < 12 ? 'ص' : 'م';
  return '${toArabicNumerals('$hour:${_pad(time.minute)}')} $suffix';
}

String formatCountdown(Duration remaining) {
  final Duration span = remaining.isNegative ? Duration.zero : remaining;
  final int hours = span.inHours;
  final int minutes = span.inMinutes.remainder(60);
  final int seconds = span.inSeconds.remainder(60);
  if (hours > 0) {
    return toArabicNumerals(
      '${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}',
    );
  }
  return toArabicNumerals('${_pad(minutes)}:${_pad(seconds)}');
}

String describeRemaining(Duration remaining) {
  final Duration span = remaining.isNegative ? Duration.zero : remaining;
  final int hours = span.inHours;
  final int minutes = span.inMinutes.remainder(60);
  if (hours == 0 && minutes == 0) {
    return 'أقل من دقيقة';
  }
  final List<String> parts = <String>[];
  if (hours > 0) {
    parts.add(_plural(hours, 'ساعة', 'ساعتان', 'ساعات'));
  }
  if (minutes > 0) {
    parts.add(_plural(minutes, 'دقيقة', 'دقيقتان', 'دقائق'));
  }
  return parts.join(' و');
}

String _plural(int count, String single, String dual, String plural) {
  if (count == 1) {
    return single;
  }
  if (count == 2) {
    return dual;
  }
  if (count <= 10) {
    return '${toArabicNumerals(count)} $plural';
  }
  return '${toArabicNumerals(count)} $single';
}

String formatSignedMinutes(int minutes) {
  if (minutes == 0) {
    return 'بدون تعديل';
  }
  final String sign = minutes > 0 ? '+' : '−';
  return '$sign${toArabicNumerals(minutes.abs())} د';
}

const List<String> gregorianMonthNames = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const List<String> weekdayNames = <String>[
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

String formatGregorian(DateTime date) {
  return '${toArabicNumerals(date.day)} '
      '${gregorianMonthNames[date.month - 1]} '
      '${toArabicNumerals(date.year)}';
}

String weekdayName(DateTime date) => weekdayNames[date.weekday - 1];
