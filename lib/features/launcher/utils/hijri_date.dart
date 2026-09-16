class HijriCalendarHelper {
  static const List<String> hijriMonthNames = [
    'Muharram',
    'Safar',
    "Rabi' al-awwal",
    "Rabi' al-thani",
    'Jumada al-awwal',
    'Jumada al-thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  static int _gregorianToJdn(int year, int month, int day) {
    int y = year;
    int m = month;
    if (m < 3) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524;
  }

  /// Calculates the Hijri date for a given Gregorian DateTime, with an optional day adjustment
  static String formatHijri(DateTime date, {int adjustmentDays = 2}) {
    final adjustedDate = date.add(Duration(days: adjustmentDays));
    final jd = _gregorianToJdn(adjustedDate.year, adjustedDate.month, adjustedDate.day);
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l1 = l - 10631 * n + 354;
    final j = (((10985 - l1) / 5316).floor()) * (((50 * l1) / 17719).floor()) +
        ((l1 / 5670).floor()) * (((43 * l1) / 15238).floor());
    final l2 = l1 - (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) -
        ((j / 16).floor()) * (((15238 * j) / 43).floor()) + 29;
    final m = ((24 * l2) / 709).floor();
    final d = l2 - ((709 * m) / 24).floor();
    final y = 30 * n + j - 30;

    final monthName = (m >= 1 && m <= 12) ? hijriMonthNames[m - 1] : "Rabi' al-thani";
    return "$d $monthName $y AH";
  }
}
