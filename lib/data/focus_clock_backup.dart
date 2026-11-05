import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../core/time_math.dart';
import '../features/launcher/models/launcher_settings.dart';
import '../models/activity.dart';
import '../models/app_settings.dart';
import '../models/daily_reflection.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';
import '../models/preset.dart';
import '../models/task.dart';
import '../models/timer_session.dart';

const _maxBackupBytes = 20 * 1024 * 1024;

class FocusClockBackupData {
  FocusClockBackupData({
    required List<Preset> presets,
    required List<Activity> activities,
    required List<AppSettings> appSettings,
    required List<Task> tasks,
    required List<Habit> habits,
    required List<HabitEntry> habitEntries,
    required List<DailyReflection> dailyReflections,
    required List<TimerSession> timerSessions,
    required this.launcherSettings,
  }) : presets = List.unmodifiable(presets),
       activities = List.unmodifiable(activities),
       appSettings = List.unmodifiable(appSettings),
       tasks = List.unmodifiable(tasks),
       habits = List.unmodifiable(habits),
       habitEntries = List.unmodifiable(habitEntries),
       dailyReflections = List.unmodifiable(dailyReflections),
       timerSessions = List.unmodifiable(timerSessions);

  final List<Preset> presets;
  final List<Activity> activities;
  final List<AppSettings> appSettings;
  final List<Task> tasks;
  final List<Habit> habits;
  final List<HabitEntry> habitEntries;
  final List<DailyReflection> dailyReflections;
  final List<TimerSession> timerSessions;
  final LauncherSettings launcherSettings;

  Map<String, int> get counts => {
    'Presets': presets.length,
    'Jadwal': activities.length,
    'Tugas': tasks.length,
    'Habit': habits.length,
    'Riwayat habit': habitEntries.length,
    'Refleksi': dailyReflections.length,
    'Preferensi': appSettings.length,
    'Sesi timer': timerSessions.length,
  };
}

class DecodedFocusClockBackup {
  const DecodedFocusClockBackup({
    required this.data,
    required this.exportedAtUtc,
    required this.formatVersion,
  });

  final FocusClockBackupData data;
  final DateTime exportedAtUtc;
  final int formatVersion;
}

/// Portable, explicit JSON format. Never use Isar generated serializers here:
/// their field layout is a database implementation detail, not a file format.
class FocusClockBackupCodec {
  FocusClockBackupCodec._();

  static const currentFormatVersion = 1;
  static const sourceApp = 'focus-clock';

  /// Copy an app-owned Isar model before applying installation-only values.
  static AppSettings copySettings(AppSettings value) =>
      _settingsFromJson(_settingsToJson(value));

  static Uint8List encode(FocusClockBackupData data, {DateTime? exportedAt}) {
    _validate(data);
    final payload = _toJson(data);
    final root = <String, dynamic>{
      'formatVersion': currentFormatVersion,
      'sourceApp': sourceApp,
      'exportedAtUtc': (exportedAt ?? DateTime.now().toUtc())
          .toUtc()
          .toIso8601String(),
      'checksum': checksumFor(payload),
      'data': payload,
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(root)));
    if (bytes.length > _maxBackupBytes) {
      throw const FormatException('Backup terlalu besar (maksimum 20 MB).');
    }
    return bytes;
  }

  static DecodedFocusClockBackup decode(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > _maxBackupBytes) {
      throw const FormatException('Ukuran file backup tidak valid.');
    }
    try {
      final root = _map(jsonDecode(utf8.decode(bytes)), 'backup');
      final version = _int(root['formatVersion'], 'formatVersion');
      if (version > currentFormatVersion) {
        throw UnsupportedError(
          'Backup versi $version lebih baru dari versi aplikasi ini.',
        );
      }
      if (version != currentFormatVersion) {
        throw FormatException('Versi backup $version tidak didukung.');
      }
      if (root['sourceApp'] != sourceApp) {
        throw const FormatException('File ini bukan backup Focus Clock.');
      }
      final exportedAtUtc = _date(
        root['exportedAtUtc'],
        'exportedAtUtc',
      ).toUtc();
      final payload = _map(root['data'], 'data');
      final expected = _string(root['checksum'], 'checksum');
      if (checksumFor(payload) != expected) {
        throw const FormatException(
          'Checksum tidak cocok; file mungkin rusak.',
        );
      }
      final data = _fromJson(payload);
      _validate(data);
      return DecodedFocusClockBackup(
        data: data,
        exportedAtUtc: exportedAtUtc,
        formatVersion: version,
      );
    } on UnsupportedError {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Isi backup tidak valid: $error');
    }
  }

  static String checksumFor(Object? value) =>
      sha256.convert(utf8.encode(jsonEncode(_canonical(value)))).toString();

  static Map<String, dynamic> _toJson(FocusClockBackupData d) => {
    'presets': d.presets
        .map(
          (x) => {
            'id': x.id,
            'name': x.name,
            'colorValue': x.colorValue,
            'iconKey': x.iconKey,
            'createdAt': _dateString(x.createdAt),
          },
        )
        .toList(),
    'activities': d.activities
        .map(
          (x) => {
            'id': x.id,
            'presetId': x.presetId,
            'iconKey': x.iconKey,
            'title': x.title,
            'startMinute': x.startMinute,
            'endMinute': x.endMinute,
            'ampmHalf': x.ampmHalf.name,
            'date': _dateString(x.date),
            'description': x.description,
            'colorValue': x.colorValue,
            'recurrence': x.recurrence,
            'groupId': x.groupId,
            'importance': x.importance,
            'deadline': _dateString(x.deadline),
            'isCompleted': x.isCompleted,
            'actualDurationSeconds': x.actualDurationSeconds,
            'isLocked': x.isLocked,
            'excludedDates': x.excludedDates.map(_dateString).toList(),
            'createdAt': _dateString(x.createdAt),
            'updatedAt': _dateString(x.updatedAt),
          },
        )
        .toList(),
    'appSettings': d.appSettings.map(_settingsToJson).toList(),
    'tasks': d.tasks
        .map(
          (x) => {
            'id': x.id,
            'title': x.title,
            'description': x.description,
            'importance': x.importance,
            'deadline': _dateString(x.deadline),
            'isCompleted': x.isCompleted,
            'createdAt': _dateString(x.createdAt),
            'updatedAt': _dateString(x.updatedAt),
            'activityId': x.activityId,
            'startMinute': x.startMinute,
            'endMinute': x.endMinute,
            'date': _dateString(x.date),
            'ampmHalf': x.ampmHalf.name,
            'subtasks': x.subtasks,
          },
        )
        .toList(),
    'habits': d.habits
        .map(
          (x) => {
            'id': x.id,
            'name': x.name,
            'iconKey': x.iconKey,
            'target': x.target,
            'unit': x.unit.name,
            'thingType': x.thingType.name,
            'habitType': x.habitType,
            'allowedPackages': x.allowedPackages,
            'progressionPlanJson': x.progressionPlanJson,
            'currentProgressionIndex': x.currentProgressionIndex,
            'hybridSets': x.hybridSets,
            'hybridDurationSeconds': x.hybridDurationSeconds,
            'hybridRestSeconds': x.hybridRestSeconds,
            'category': x.category,
            'preferredTime': x.preferredTime,
            'timerEnabled': x.timerEnabled,
            'colorValue': x.colorValue,
            'recurrence': x.recurrence,
            'orderIndex': x.orderIndex,
            'isArchived': x.isArchived,
            'createdAt': _dateString(x.createdAt),
            'updatedAt': _dateString(x.updatedAt),
          },
        )
        .toList(),
    'habitEntries': d.habitEntries
        .map(
          (x) => {
            'id': x.id,
            'habitId': x.habitId,
            'dateString': x.dateString,
            'status': x.status.name,
            'valueCompleted': x.valueCompleted,
            'targetSnapshot': x.targetSnapshot,
            'actualDurationMinutes': x.actualDurationMinutes,
            'actualDurationSeconds': x.actualDurationSeconds,
            'completedAt': _dateString(x.completedAt),
            'source': x.source,
            'note': x.note,
            'createdAt': _dateString(x.createdAt),
            'updatedAt': _dateString(x.updatedAt),
          },
        )
        .toList(),
    'dailyReflections': d.dailyReflections
        .map(
          (x) => {
            'id': x.id,
            'dateString': x.dateString,
            'feeling': x.feeling.name,
            'proudOfToday': x.proudOfToday,
            'note': x.note,
            'completedCount': x.completedCount,
            'totalCount': x.totalCount,
            'updatedAt': _dateString(x.updatedAt),
          },
        )
        .toList(),
    'timerSessions': d.timerSessions
        .map(
          (x) => {
            'id': x.id,
            'habitId': x.habitId,
            'habitName': x.habitName,
            'sourceKind': x.sourceKind?.name,
            'activityId': x.activityId,
            'sourceIdentity': x.sourceIdentity,
            'sourceColorValue': x.sourceColorValue,
            'targetSeconds': x.targetSeconds,
            'startedAt': _dateString(x.startedAt),
            'attributionLocalDate': x.attributionLocalDate,
            'runningSince': _dateString(x.runningSince),
            'pausedAt': _dateString(x.pausedAt),
            'accumulatedDurationSeconds': x.accumulatedDurationSeconds,
            'status': x.status.name,
            'updatedAt': _dateString(x.updatedAt),
          },
        )
        .toList(),
    'launcherSettings': _launcherSettingsToJson(d.launcherSettings),
  };

  static Map<String, dynamic> _settingsToJson(AppSettings x) => {
    'id': x.id,
    'is24h': x.is24h,
    'is24hTime': x.is24hTime,
    'is24hDial': x.is24hDial,
    'showCurrentTime': x.showCurrentTime,
    'currentTimeFormat': x.currentTimeFormat,
    'floatTimeText': x.floatTimeText,
    'glowStyle': x.glowStyle,
    'notifLeadMinutes': x.notifLeadMinutes,
    'themeMode': x.themeMode,
    'themePalette': x.themePalette,
    'trueBlack': x.trueBlack,
    'clockHandsMode': x.clockHandsMode,
    'clockFaceTheme': x.clockFaceTheme,
    'showMinuteLabels': x.showMinuteLabels,
    'keyLeftPanel': x.keyLeftPanel,
    'keyRightPanel': x.keyRightPanel,
    'keyAiChat': x.keyAiChat,
    'keyPrecisionMode': x.keyPrecisionMode,
    'keyPlanningMode': x.keyPlanningMode,
    'enableAiAssistant': x.enableAiAssistant,
    'enableLeftPanel': x.enableLeftPanel,
    'enableRightPanel': x.enableRightPanel,
    'aiModel': x.aiModel,
    'hasCompletedOnboarding': x.hasCompletedOnboarding,
  };

  static Map<String, dynamic> _launcherSettingsToJson(LauncherSettings x) {
    final map = x.toMap();
    map.remove('customImageUrl'); // URLs can contain embedded access tokens.
    if (map['wallpaperType'] == 'custom_image') {
      map['wallpaperType'] = 'system';
    }
    return map;
  }

  static FocusClockBackupData _fromJson(Map<String, dynamic> map) {
    return FocusClockBackupData(
      presets: _list(
        map,
        'presets',
        (m) => Preset()
          ..id = _int(m['id'], 'presets.id')
          ..name = _string(m['name'], 'presets.name')
          ..colorValue = _int(m['colorValue'], 'presets.colorValue')
          ..iconKey = _nullableString(m['iconKey'], 'presets.iconKey')
          ..createdAt = _date(m['createdAt'], 'presets.createdAt'),
      ),
      activities: _list(map, 'activities', _activityFromJson),
      appSettings: _list(map, 'appSettings', _settingsFromJson),
      tasks: _list(map, 'tasks', _taskFromJson),
      habits: _list(map, 'habits', _habitFromJson),
      habitEntries: _list(map, 'habitEntries', _entryFromJson),
      dailyReflections: _list(map, 'dailyReflections', _reflectionFromJson),
      timerSessions: _list(map, 'timerSessions', _timerFromJson),
      launcherSettings: LauncherSettings.fromMap(
        _map(map['launcherSettings'], 'launcherSettings'),
      ),
    );
  }

  static Activity _activityFromJson(Map<String, dynamic> m) => Activity()
    ..id = _int(m['id'], 'activities.id')
    ..presetId = _nullableInt(m['presetId'], 'activities.presetId')
    ..iconKey = _nullableString(m['iconKey'], 'activities.iconKey')
    ..title = _string(m['title'], 'activities.title')
    ..startMinute = _int(m['startMinute'], 'activities.startMinute')
    ..endMinute = _int(m['endMinute'], 'activities.endMinute')
    ..ampmHalf = _enumByName(
      AmPmHalf.values,
      m['ampmHalf'],
      'activities.ampmHalf',
    )
    ..date = _date(m['date'], 'activities.date')
    ..description = _string(m['description'], 'activities.description')
    ..colorValue = _int(m['colorValue'], 'activities.colorValue')
    ..recurrence = _string(m['recurrence'], 'activities.recurrence')
    ..groupId = _nullableString(m['groupId'], 'activities.groupId')
    ..importance = _int(m['importance'], 'activities.importance')
    ..deadline = _nullableDate(m['deadline'], 'activities.deadline')
    ..isCompleted = _bool(m['isCompleted'], 'activities.isCompleted')
    ..actualDurationSeconds = _int(
      m['actualDurationSeconds'],
      'activities.actualDurationSeconds',
    )
    ..isLocked = _bool(m['isLocked'], 'activities.isLocked')
    ..excludedDates = _stringList(
      m['excludedDates'],
      'activities.excludedDates',
    ).map((x) => _date(x, 'activities.excludedDates')).toList()
    ..createdAt = _date(m['createdAt'], 'activities.createdAt')
    ..updatedAt = _date(m['updatedAt'], 'activities.updatedAt');

  static AppSettings _settingsFromJson(Map<String, dynamic> m) => AppSettings()
    ..id = _int(m['id'], 'appSettings.id')
    ..is24h = _bool(m['is24h'], 'appSettings.is24h')
    ..is24hTime = _bool(m['is24hTime'], 'appSettings.is24hTime')
    ..is24hDial = _bool(m['is24hDial'], 'appSettings.is24hDial')
    ..showCurrentTime = _bool(
      m['showCurrentTime'],
      'appSettings.showCurrentTime',
    )
    ..currentTimeFormat = _string(
      m['currentTimeFormat'],
      'appSettings.currentTimeFormat',
    )
    ..floatTimeText = _bool(m['floatTimeText'], 'appSettings.floatTimeText')
    ..glowStyle = _string(m['glowStyle'], 'appSettings.glowStyle')
    ..notifLeadMinutes = _int(
      m['notifLeadMinutes'],
      'appSettings.notifLeadMinutes',
    )
    ..themeMode = _string(m['themeMode'], 'appSettings.themeMode')
    ..themePalette = _string(m['themePalette'], 'appSettings.themePalette')
    ..trueBlack = _bool(m['trueBlack'], 'appSettings.trueBlack')
    ..clockHandsMode = _int(m['clockHandsMode'], 'appSettings.clockHandsMode')
    ..clockFaceTheme = _int(m['clockFaceTheme'], 'appSettings.clockFaceTheme')
    ..showMinuteLabels = _bool(
      m['showMinuteLabels'],
      'appSettings.showMinuteLabels',
    )
    ..keyLeftPanel = _string(m['keyLeftPanel'], 'appSettings.keyLeftPanel')
    ..keyRightPanel = _string(m['keyRightPanel'], 'appSettings.keyRightPanel')
    ..keyAiChat = _string(m['keyAiChat'], 'appSettings.keyAiChat')
    ..keyPrecisionMode = _string(
      m['keyPrecisionMode'],
      'appSettings.keyPrecisionMode',
    )
    ..keyPlanningMode = _string(
      m['keyPlanningMode'],
      'appSettings.keyPlanningMode',
    )
    ..enableAiAssistant = _bool(
      m['enableAiAssistant'],
      'appSettings.enableAiAssistant',
    )
    ..enableLeftPanel = _bool(
      m['enableLeftPanel'],
      'appSettings.enableLeftPanel',
    )
    ..enableRightPanel = _bool(
      m['enableRightPanel'],
      'appSettings.enableRightPanel',
    )
    ..aiModel = _string(m['aiModel'], 'appSettings.aiModel')
    ..hasCompletedOnboarding = _bool(
      m['hasCompletedOnboarding'],
      'appSettings.hasCompletedOnboarding',
    );

  static Task _taskFromJson(Map<String, dynamic> m) => Task()
    ..id = _int(m['id'], 'tasks.id')
    ..title = _string(m['title'], 'tasks.title')
    ..description = _nullableString(m['description'], 'tasks.description')
    ..importance = _int(m['importance'], 'tasks.importance')
    ..deadline = _nullableDate(m['deadline'], 'tasks.deadline')
    ..isCompleted = _bool(m['isCompleted'], 'tasks.isCompleted')
    ..createdAt = _date(m['createdAt'], 'tasks.createdAt')
    ..updatedAt = _nullableDate(m['updatedAt'], 'tasks.updatedAt')
    ..activityId = _nullableInt(m['activityId'], 'tasks.activityId')
    ..startMinute = _nullableInt(m['startMinute'], 'tasks.startMinute')
    ..endMinute = _nullableInt(m['endMinute'], 'tasks.endMinute')
    ..date = _nullableDate(m['date'], 'tasks.date')
    ..ampmHalf = _enumByName(AmPmHalf.values, m['ampmHalf'], 'tasks.ampmHalf')
    ..subtasks = _stringList(m['subtasks'], 'tasks.subtasks');

  static Habit _habitFromJson(Map<String, dynamic> m) => Habit()
    ..id = _int(m['id'], 'habits.id')
    ..name = _string(m['name'], 'habits.name')
    ..iconKey = _string(m['iconKey'], 'habits.iconKey')
    ..target = _int(m['target'], 'habits.target')
    ..unit = _enumByName(HabitUnit.values, m['unit'], 'habits.unit')
    ..thingType = _enumByName(
      ThingType.values,
      m['thingType'],
      'habits.thingType',
    )
    ..habitType = _string(m['habitType'], 'habits.habitType')
    ..allowedPackages = _stringList(
      m['allowedPackages'],
      'habits.allowedPackages',
    )
    ..progressionPlanJson = _nullableString(
      m['progressionPlanJson'],
      'habits.progressionPlanJson',
    )
    ..currentProgressionIndex = _int(
      m['currentProgressionIndex'],
      'habits.currentProgressionIndex',
    )
    ..hybridSets = _int(m['hybridSets'], 'habits.hybridSets')
    ..hybridDurationSeconds = _int(
      m['hybridDurationSeconds'],
      'habits.hybridDurationSeconds',
    )
    ..hybridRestSeconds = _int(
      m['hybridRestSeconds'],
      'habits.hybridRestSeconds',
    )
    ..category = _string(m['category'], 'habits.category')
    ..preferredTime = _nullableString(
      m['preferredTime'],
      'habits.preferredTime',
    )
    ..timerEnabled = _bool(m['timerEnabled'], 'habits.timerEnabled')
    ..colorValue = _int(m['colorValue'], 'habits.colorValue')
    ..recurrence = _string(m['recurrence'], 'habits.recurrence')
    ..orderIndex = _int(m['orderIndex'], 'habits.orderIndex')
    ..isArchived = _bool(m['isArchived'], 'habits.isArchived')
    ..createdAt = _date(m['createdAt'], 'habits.createdAt')
    ..updatedAt = _nullableDate(m['updatedAt'], 'habits.updatedAt');

  static HabitEntry _entryFromJson(Map<String, dynamic> m) => HabitEntry()
    ..id = _int(m['id'], 'habitEntries.id')
    ..habitId = _int(m['habitId'], 'habitEntries.habitId')
    ..dateString = _string(m['dateString'], 'habitEntries.dateString')
    ..status = _enumByName(
      HabitStatus.values,
      m['status'],
      'habitEntries.status',
    )
    ..valueCompleted = _int(m['valueCompleted'], 'habitEntries.valueCompleted')
    ..targetSnapshot = _int(m['targetSnapshot'], 'habitEntries.targetSnapshot')
    ..actualDurationMinutes = _int(
      m['actualDurationMinutes'],
      'habitEntries.actualDurationMinutes',
    )
    ..actualDurationSeconds = _int(
      m['actualDurationSeconds'],
      'habitEntries.actualDurationSeconds',
    )
    ..completedAt = _nullableDate(m['completedAt'], 'habitEntries.completedAt')
    ..source = _string(m['source'], 'habitEntries.source')
    ..note = _nullableString(m['note'], 'habitEntries.note')
    ..createdAt = _nullableDate(m['createdAt'], 'habitEntries.createdAt')
    ..updatedAt = _date(m['updatedAt'], 'habitEntries.updatedAt');

  static DailyReflection _reflectionFromJson(Map<String, dynamic> m) =>
      DailyReflection()
        ..id = _int(m['id'], 'dailyReflections.id')
        ..dateString = _string(m['dateString'], 'dailyReflections.dateString')
        ..feeling = _enumByName(
          ReflectionFeeling.values,
          m['feeling'],
          'dailyReflections.feeling',
        )
        ..proudOfToday = _string(
          m['proudOfToday'],
          'dailyReflections.proudOfToday',
        )
        ..note = _string(m['note'], 'dailyReflections.note')
        ..completedCount = _int(
          m['completedCount'],
          'dailyReflections.completedCount',
        )
        ..totalCount = _int(m['totalCount'], 'dailyReflections.totalCount')
        ..updatedAt = _date(m['updatedAt'], 'dailyReflections.updatedAt');

  static TimerSession _timerFromJson(Map<String, dynamic> m) {
    final x = TimerSession()
      ..id = _int(m['id'], 'timerSessions.id')
      ..habitId = _int(m['habitId'], 'timerSessions.habitId')
      ..habitName = _string(m['habitName'], 'timerSessions.habitName')
      ..activityId = _nullableInt(m['activityId'], 'timerSessions.activityId')
      ..sourceIdentity = _nullableString(
        m['sourceIdentity'],
        'timerSessions.sourceIdentity',
      )
      ..sourceColorValue = _nullableInt(
        m['sourceColorValue'],
        'timerSessions.sourceColorValue',
      )
      ..targetSeconds = _int(m['targetSeconds'], 'timerSessions.targetSeconds')
      ..startedAt = _nullableDate(m['startedAt'], 'timerSessions.startedAt')
      ..attributionLocalDate = _nullableString(
        m['attributionLocalDate'],
        'timerSessions.attributionLocalDate',
      )
      ..runningSince = _nullableDate(
        m['runningSince'],
        'timerSessions.runningSince',
      )
      ..pausedAt = _nullableDate(m['pausedAt'], 'timerSessions.pausedAt')
      ..accumulatedDurationSeconds = _int(
        m['accumulatedDurationSeconds'],
        'timerSessions.accumulatedDurationSeconds',
      )
      ..status = _enumByName(
        TimerStateStatus.values,
        m['status'],
        'timerSessions.status',
      )
      ..updatedAt = _date(m['updatedAt'], 'timerSessions.updatedAt');
    final sourceKind = _nullableString(
      m['sourceKind'],
      'timerSessions.sourceKind',
    );
    if (sourceKind != null) {
      x.sourceKind = _enumByName(
        TimerSessionSourceKind.values,
        sourceKind,
        'timerSessions.sourceKind',
      );
    }
    if (x.status == TimerStateStatus.running) {
      final now = DateTime.now();
      final started = x.runningSince;
      if (started != null) {
        final elapsed = now.difference(started).inSeconds;
        if (elapsed > 0) x.accumulatedDurationSeconds += elapsed;
      }
      x.runningSince = null;
      x.pausedAt = now;
      x.status = TimerStateStatus.paused;
      x.updatedAt = now;
    }
    return x;
  }

  static void _validate(FocusClockBackupData d) {
    _unique(d.presets.map((x) => x.id), 'presets');
    _unique(d.activities.map((x) => x.id), 'activities');
    _unique(d.tasks.map((x) => x.id), 'tasks');
    _unique(d.habits.map((x) => x.id), 'habits');
    _unique(d.habitEntries.map((x) => x.id), 'habitEntries');
    _unique(d.dailyReflections.map((x) => x.id), 'dailyReflections');
    if (d.appSettings.length != 1 || d.appSettings.single.id != 0) {
      throw const FormatException(
        'Backup harus berisi satu AppSettings dengan ID 0.',
      );
    }
    if (d.timerSessions.length > 1 || d.timerSessions.any((x) => x.id != 1)) {
      throw const FormatException('TimerSession hanya boleh memakai ID 1.');
    }
    for (final x in d.activities) {
      if (x.title.trim().isEmpty ||
          (x.presetId != null && x.presetId! <= 0) ||
          x.startMinute < 0 ||
          x.startMinute >= 720 ||
          x.endMinute < 0 ||
          x.endMinute > 720 ||
          x.endMinute <= x.startMinute ||
          x.actualDurationSeconds < 0) {
        throw FormatException(
          'Activity ${x.id} memiliki nilai yang tidak valid.',
        );
      }
    }
    for (final x in d.tasks) {
      if (x.title.trim().isEmpty ||
          x.importance < 0 ||
          x.importance > 1 ||
          (x.startMinute != null &&
              (x.startMinute! < 0 || x.startMinute! >= 720)) ||
          (x.endMinute != null && (x.endMinute! < 0 || x.endMinute! > 720)) ||
          (x.startMinute != null &&
              x.endMinute != null &&
              x.endMinute! <= x.startMinute!)) {
        throw FormatException('Task ${x.id} memiliki nilai yang tidak valid.');
      }
      if (x.activityId != null && x.activityId! <= 0) {
        throw FormatException(
          'Task ${x.id} memiliki ID jadwal yang tidak valid.',
        );
      }
    }
    for (final x in d.habitEntries) {
      if (x.habitId <= 0) {
        throw FormatException(
          'Riwayat habit ${x.id} memiliki ID habit yang tidak valid.',
        );
      }
      if (!_isValidDateOnly(x.dateString) ||
          x.actualDurationSeconds < 0 ||
          x.actualDurationMinutes < 0) {
        throw FormatException(
          'Riwayat habit ${x.id} memiliki nilai yang tidak valid.',
        );
      }
    }
    for (final x in d.dailyReflections) {
      if (!_isValidDateOnly(x.dateString)) {
        throw FormatException(
          'Refleksi ${x.id} memiliki tanggal yang tidak valid.',
        );
      }
    }
    for (final x in d.timerSessions) {
      if (x.habitId < 0) {
        throw const FormatException(
          'Sesi timer memiliki ID habit yang tidak valid.',
        );
      }
      if (x.activityId != null && x.activityId! <= 0) {
        throw const FormatException(
          'Sesi timer memiliki ID jadwal yang tidak valid.',
        );
      }
      if (!x.hasValidSourceKind ||
          x.targetSeconds < 0 ||
          x.accumulatedDurationSeconds < 0) {
        throw const FormatException(
          'Sesi timer memiliki nilai yang tidak valid.',
        );
      }
    }
  }

  static void _unique(Iterable<int> ids, String collection) {
    final values = ids.toList();
    if (values.any((id) => id <= 0) || values.toSet().length != values.length) {
      throw FormatException('$collection memiliki ID kosong atau duplikat.');
    }
  }
}

String? _dateString(DateTime? value) => value?.toIso8601String();

bool _isValidDateOnly(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parts = value.split('-').map(int.parse).toList();
  final parsed = DateTime(parts[0], parts[1], parts[2]);
  return parsed.year == parts[0] &&
      parsed.month == parts[1] &&
      parsed.day == parts[2];
}

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((x) => x.toString()).toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) return value.map(_canonical).toList();
  return value;
}

Map<String, dynamic> _map(Object? value, String path) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  throw FormatException('$path harus berupa object.');
}

List<T> _list<T>(
  Map<String, dynamic> root,
  String key,
  T Function(Map<String, dynamic>) read,
) {
  final value = root[key];
  if (value is! List) throw FormatException('$key harus berupa list.');
  return value.indexed
      .map((entry) => read(_map(entry.$2, '$key[${entry.$1}]')))
      .toList();
}

String _string(Object? value, String path) {
  if (value is String) return value;
  throw FormatException('$path harus berupa teks.');
}

String? _nullableString(Object? value, String path) =>
    value == null ? null : _string(value, path);

bool _bool(Object? value, String path) {
  if (value is bool) return value;
  throw FormatException('$path harus berupa true atau false.');
}

int _int(Object? value, String path) {
  if (value is int) return value;
  throw FormatException('$path harus berupa bilangan bulat.');
}

int? _nullableInt(Object? value, String path) =>
    value == null ? null : _int(value, path);

DateTime _date(Object? value, String path) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('$path harus berupa tanggal ISO-8601.');
}

DateTime? _nullableDate(Object? value, String path) =>
    value == null ? null : _date(value, path);

List<String> _stringList(Object? value, String path) {
  if (value is List && value.every((entry) => entry is String)) {
    return value.cast<String>();
  }
  throw FormatException('$path harus berupa list teks.');
}

T _enumByName<T extends Enum>(List<T> values, Object? value, String path) {
  if (value is String) {
    for (final entry in values) {
      if (entry.name == value) return entry;
    }
  }
  throw FormatException('$path memiliki pilihan yang tidak dikenal.');
}
