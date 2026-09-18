import 'dart:convert';

class LauncherSettings {
  final String wallpaperType; // 'amoled_black', 'midnight_slate', 'forest_night', 'deep_obsidian', 'warm_charcoal', 'custom_image'
  final String customImageUrl;
  final double wallpaperDimming; // 0.0 to 0.9
  final double wallpaperBlur; // 0.0 to 20.0
  final bool is24h;
  final bool showSeconds;
  final bool showDate;
  final bool showHeroEvent;
  final bool showAgendaWidget;
  final bool showHabitsWidget;
  final List<String> dockPackages; // Exactly 4 packages

  // Waktu Sholat (Muslim Fitrah Anchor)
  final bool showPrayerTimes;
  final String prayerSubuh;
  final String prayerSyuruq;
  final String prayerDzuhur;
  final String prayerAshar;
  final String prayerMaghrib;
  final String prayerIsya;

  /// Top widget display mode: 'prayer' or 'focus_clock'
  final String widgetDisplayMode;

  /// Automatically focus search and open keyboard on app drawer tab
  final bool autoFocusSearch;

  const LauncherSettings({
    this.wallpaperType = 'amoled_black',
    this.customImageUrl = '',
    this.wallpaperDimming = 0.35,
    this.wallpaperBlur = 0.0,
    this.is24h = true,
    this.showSeconds = false,
    this.showDate = true,
    this.showHeroEvent = true,
    this.showAgendaWidget = true,
    this.showHabitsWidget = true,
    this.dockPackages = const [
      'com.android.dialer',
      'com.android.mms',
      'com.android.browser',
      'com.android.camera',
    ],
    this.showPrayerTimes = true,
    this.prayerSubuh = '04:32',
    this.prayerSyuruq = '05:46',
    this.prayerDzuhur = '11:52',
    this.prayerAshar = '15:10',
    this.prayerMaghrib = '17:54',
    this.prayerIsya = '19:03',
    this.widgetDisplayMode = 'prayer',
    this.autoFocusSearch = true,
  });

  LauncherSettings copyWith({
    String? wallpaperType,
    String? customImageUrl,
    double? wallpaperDimming,
    double? wallpaperBlur,
    bool? is24h,
    bool? showSeconds,
    bool? showDate,
    bool? showHeroEvent,
    bool? showAgendaWidget,
    bool? showHabitsWidget,
    List<String>? dockPackages,
    bool? showPrayerTimes,
    String? prayerSubuh,
    String? prayerSyuruq,
    String? prayerDzuhur,
    String? prayerAshar,
    String? prayerMaghrib,
    String? prayerIsya,
    String? widgetDisplayMode,
    bool? autoFocusSearch,
  }) {
    return LauncherSettings(
      wallpaperType: wallpaperType ?? this.wallpaperType,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      wallpaperDimming: wallpaperDimming ?? this.wallpaperDimming,
      wallpaperBlur: wallpaperBlur ?? this.wallpaperBlur,
      is24h: is24h ?? this.is24h,
      showSeconds: showSeconds ?? this.showSeconds,
      showDate: showDate ?? this.showDate,
      showHeroEvent: showHeroEvent ?? this.showHeroEvent,
      showAgendaWidget: showAgendaWidget ?? this.showAgendaWidget,
      showHabitsWidget: showHabitsWidget ?? this.showHabitsWidget,
      dockPackages: dockPackages ?? this.dockPackages,
      showPrayerTimes: showPrayerTimes ?? this.showPrayerTimes,
      prayerSubuh: prayerSubuh ?? this.prayerSubuh,
      prayerSyuruq: prayerSyuruq ?? this.prayerSyuruq,
      prayerDzuhur: prayerDzuhur ?? this.prayerDzuhur,
      prayerAshar: prayerAshar ?? this.prayerAshar,
      prayerMaghrib: prayerMaghrib ?? this.prayerMaghrib,
      prayerIsya: prayerIsya ?? this.prayerIsya,
      widgetDisplayMode: widgetDisplayMode ?? this.widgetDisplayMode,
      autoFocusSearch: autoFocusSearch ?? this.autoFocusSearch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wallpaperType': wallpaperType,
      'customImageUrl': customImageUrl,
      'wallpaperDimming': wallpaperDimming,
      'wallpaperBlur': wallpaperBlur,
      'is24h': is24h,
      'showSeconds': showSeconds,
      'showDate': showDate,
      'showHeroEvent': showHeroEvent,
      'showAgendaWidget': showAgendaWidget,
      'showHabitsWidget': showHabitsWidget,
      'dockPackages': dockPackages,
      'showPrayerTimes': showPrayerTimes,
      'prayerSubuh': prayerSubuh,
      'prayerSyuruq': prayerSyuruq,
      'prayerDzuhur': prayerDzuhur,
      'prayerAshar': prayerAshar,
      'prayerMaghrib': prayerMaghrib,
      'prayerIsya': prayerIsya,
      'widgetDisplayMode': widgetDisplayMode,
      'autoFocusSearch': autoFocusSearch,
    };
  }

  factory LauncherSettings.fromMap(Map<String, dynamic> map) {
    return LauncherSettings(
      wallpaperType: map['wallpaperType'] as String? ?? 'amoled_black',
      customImageUrl: map['customImageUrl'] as String? ?? '',
      wallpaperDimming: (map['wallpaperDimming'] as num?)?.toDouble() ?? 0.35,
      wallpaperBlur: (map['wallpaperBlur'] as num?)?.toDouble() ?? 0.0,
      is24h: map['is24h'] as bool? ?? true,
      showSeconds: map['showSeconds'] as bool? ?? false,
      showDate: map['showDate'] as bool? ?? true,
      showHeroEvent: map['showHeroEvent'] as bool? ?? true,
      showAgendaWidget: map['showAgendaWidget'] as bool? ?? true,
      showHabitsWidget: map['showHabitsWidget'] as bool? ?? true,
      dockPackages: (map['dockPackages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [
            'com.android.dialer',
            'com.android.mms',
            'com.android.browser',
            'com.android.camera',
          ],
      showPrayerTimes: map['showPrayerTimes'] as bool? ?? true,
      prayerSubuh: map['prayerSubuh'] as String? ?? '04:32',
      prayerSyuruq: map['prayerSyuruq'] as String? ?? '05:46',
      prayerDzuhur: map['prayerDzuhur'] as String? ?? '11:52',
      prayerAshar: map['prayerAshar'] as String? ?? '15:10',
      prayerMaghrib: map['prayerMaghrib'] as String? ?? '17:54',
      prayerIsya: map['prayerIsya'] as String? ?? '19:03',
      widgetDisplayMode: map['widgetDisplayMode'] as String? ?? 'prayer',
      autoFocusSearch: map['autoFocusSearch'] as bool? ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory LauncherSettings.fromJson(String source) =>
      LauncherSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}
