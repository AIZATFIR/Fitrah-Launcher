class PrayerItem {
  final String name;
  final String time; // 'HH:mm'
  final int minuteOfDay; // 0 - 1439
  final String iconType; // 'subuh', 'syuruq', 'dzuhur', 'ashar', 'maghrib', 'isya'

  const PrayerItem({
    required this.name,
    required this.time,
    required this.minuteOfDay,
    required this.iconType,
  });

  static int parseMinute(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return h * 60 + m;
      }
    } catch (_) {}
    return 0;
  }
}
