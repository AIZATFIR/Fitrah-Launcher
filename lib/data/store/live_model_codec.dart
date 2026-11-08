import '../../domain/focus_intent.dart';
import '../../models/focus_intent_document.dart';
// ignore_for_file: type_literal_in_constant_pattern
import 'package:isar_community/isar.dart';
import '../../core/time_math.dart';
import '../../models/preset.dart';
import '../../models/activity.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';
import '../../models/habit.dart';
import '../../models/habit_entry.dart';
import '../../models/daily_reflection.dart';
import '../../models/timer_session.dart';

/// Lossless storage codec. Portable backups intentionally have different rules.
class LiveModelCodec {
  static const version = 1;
  static const maxExactId = 9007199254740991;
  static void validateId(int id) {
    if (id < -maxExactId || id > maxExactId) {
      throw FormatException('ID is outside the exact browser integer range');
    }
  }

  static String collectionFor<T>() => switch (T) {
    FocusIntentDocument => 'FocusIntentDocument',
    Preset => 'Preset',
    Activity => 'Activity',
    AppSettings => 'AppSettings',
    Task => 'Task',
    Habit => 'Habit',
    HabitEntry => 'HabitEntry',
    DailyReflection => 'DailyReflection',
    TimerSession => 'TimerSession',
    _ => throw ArgumentError('Unknown model $T'),
  };
  static int id(Object row) => switch (row) {
    FocusIntentDocument x => x.id,
    Preset x => x.id,
    Activity x => x.id,
    AppSettings x => x.id,
    Task x => x.id,
    Habit x => x.id,
    HabitEntry x => x.id,
    DailyReflection x => x.id,
    TimerSession x => x.id,
    _ => throw ArgumentError('Unknown model'),
  };
  static void setId(Object row, int id) {
    if (id != Isar.autoIncrement) validateId(id);
    switch (row) {
      case FocusIntentDocument x:
        x.id = id;
      case Preset x:
        x.id = id;
      case Activity x:
        x.id = id;
      case AppSettings x:
        x.id = id;
      case Task x:
        x.id = id;
      case Habit x:
        x.id = id;
      case HabitEntry x:
        x.id = id;
      case DailyReflection x:
        x.id = id;
      case TimerSession x:
        x.id = id;
      default:
        throw ArgumentError('Unknown model');
    }
  }

  static Map<String, Object?> encode(Object row) {
    final data = switch (row) {
      FocusIntentDocument x => <String, Object?>{
        'id': x.id,
        'payload': IntentState.decode(x.payload).encode(),
      },
      Preset x => <String, Object?>{
        'id': x.id,
        'name': x.name,
        'colorValue': _integer(x.colorValue),
        'iconKey': x.iconKey,
        'createdAt': _date(x.createdAt, false),
      },
      Activity x => <String, Object?>{
        'id': x.id,
        'presetId': x.presetId == null ? null : _integer(x.presetId!),
        'iconKey': x.iconKey,
        'title': x.title,
        'startMinute': _integer(x.startMinute),
        'endMinute': _integer(x.endMinute),
        'ampmHalf': x.ampmHalf.index,
        'date': _date(x.date, true),
        'description': x.description,
        'colorValue': _integer(x.colorValue),
        'recurrence': x.recurrence,
        'groupId': x.groupId,
        'importance': _integer(x.importance),
        'deadline': x.deadline == null ? null : _date(x.deadline!, true),
        'isCompleted': x.isCompleted,
        'actualDurationSeconds': _integer(x.actualDurationSeconds),
        'isLocked': x.isLocked,
        'excludedDates': x.excludedDates.map((v) => _date(v, true)).toList(),
        'createdAt': _date(x.createdAt, false),
        'updatedAt': _date(x.updatedAt, false),
      },
      AppSettings x => <String, Object?>{
        'id': x.id,
        'is24h': x.is24h,
        'is24hTime': x.is24hTime,
        'is24hDial': x.is24hDial,
        'showCurrentTime': x.showCurrentTime,
        'currentTimeFormat': x.currentTimeFormat,
        'floatTimeText': x.floatTimeText,
        'glowStyle': x.glowStyle,
        'notifLeadMinutes': _integer(x.notifLeadMinutes),
        'themeMode': x.themeMode,
        'themePalette': x.themePalette,
        'trueBlack': x.trueBlack,
        'clockHandsMode': _integer(x.clockHandsMode),
        'showMinuteLabels': x.showMinuteLabels,
        'clockFaceTheme': _integer(x.clockFaceTheme),
        'keyLeftPanel': x.keyLeftPanel,
        'keyRightPanel': x.keyRightPanel,
        'keyAiChat': x.keyAiChat,
        'keyPrecisionMode': x.keyPrecisionMode,
        'keyPlanningMode': x.keyPlanningMode,
        'enableAiAssistant': x.enableAiAssistant,
        'enableLeftPanel': x.enableLeftPanel,
        'enableRightPanel': x.enableRightPanel,
        'aiBaseUrl': x.aiBaseUrl,
        'aiApiKey': x.aiApiKey,
        'aiModel': x.aiModel,
        'hasCompletedOnboarding': x.hasCompletedOnboarding,
      },
      Task x => <String, Object?>{
        'id': x.id,
        'title': x.title,
        'description': x.description,
        'importance': _integer(x.importance),
        'deadline': x.deadline == null ? null : _date(x.deadline!, true),
        'isCompleted': x.isCompleted,
        'createdAt': _date(x.createdAt, false),
        'updatedAt': x.updatedAt == null ? null : _date(x.updatedAt!, false),
        'activityId': x.activityId == null ? null : _integer(x.activityId!),
        'startMinute': x.startMinute == null ? null : _integer(x.startMinute!),
        'endMinute': x.endMinute == null ? null : _integer(x.endMinute!),
        'date': x.date == null ? null : _date(x.date!, true),
        'ampmHalf': x.ampmHalf.index,
        'subtasks': List<String>.of(x.subtasks),
      },
      Habit x => <String, Object?>{
        'id': x.id,
        'name': x.name,
        'iconKey': x.iconKey,
        'target': _integer(x.target),
        'unit': x.unit.index,
        'thingType': x.thingType.index,
        'habitType': x.habitType,
        'allowedPackages': List<String>.of(x.allowedPackages),
        'progressionPlanJson': x.progressionPlanJson,
        'currentProgressionIndex': _integer(x.currentProgressionIndex),
        'hybridSets': _integer(x.hybridSets),
        'hybridDurationSeconds': _integer(x.hybridDurationSeconds),
        'hybridRestSeconds': _integer(x.hybridRestSeconds),
        'category': x.category,
        'preferredTime': x.preferredTime,
        'timerEnabled': x.timerEnabled,
        'colorValue': _integer(x.colorValue),
        'recurrence': x.recurrence,
        'orderIndex': _integer(x.orderIndex),
        'isArchived': x.isArchived,
        'createdAt': _date(x.createdAt, false),
        'updatedAt': x.updatedAt == null ? null : _date(x.updatedAt!, false),
      },
      HabitEntry x => <String, Object?>{
        'id': x.id,
        'habitId': _integer(x.habitId),
        'dateString': x.dateString,
        'status': x.status.index,
        'valueCompleted': _integer(x.valueCompleted),
        'targetSnapshot': _integer(x.targetSnapshot),
        'actualDurationMinutes': _integer(x.actualDurationMinutes),
        'actualDurationSeconds': _integer(x.actualDurationSeconds),
        'completedAt': x.completedAt == null
            ? null
            : _date(x.completedAt!, false),
        'source': x.source,
        'note': x.note,
        'createdAt': x.createdAt == null ? null : _date(x.createdAt!, false),
        'updatedAt': _date(x.updatedAt, false),
      },
      DailyReflection x => <String, Object?>{
        'id': x.id,
        'dateString': x.dateString,
        'feeling': x.feeling.index,
        'proudOfToday': x.proudOfToday,
        'note': x.note,
        'completedCount': _integer(x.completedCount),
        'totalCount': _integer(x.totalCount),
        'updatedAt': _date(x.updatedAt, false),
      },
      TimerSession x => <String, Object?>{
        'id': x.id,
        'habitId': _integer(x.habitId),
        'habitName': x.habitName,
        'sourceKindIndex': x.sourceKindIndex == null
            ? null
            : _integer(x.sourceKindIndex!),
        'activityId': x.activityId == null ? null : _integer(x.activityId!),
        'sourceIdentity': x.sourceIdentity,
        'sourceColorValue': x.sourceColorValue == null
            ? null
            : _integer(x.sourceColorValue!),
        'targetSeconds': _integer(x.targetSeconds),
        'startedAt': x.startedAt == null ? null : _date(x.startedAt!, false),
        'attributionLocalDate': x.attributionLocalDate,
        'runningSince': x.runningSince == null
            ? null
            : _date(x.runningSince!, false),
        'pausedAt': x.pausedAt == null ? null : _date(x.pausedAt!, false),
        'accumulatedDurationSeconds': _integer(x.accumulatedDurationSeconds),
        'status': x.status.index,
        'updatedAt': _date(x.updatedAt, false),
      },
      _ => throw ArgumentError('Unknown model'),
    };
    return {'version': version, 'data': data};
  }

  static T decode<T>(Map<String, dynamic> envelope) {
    if (envelope['version'] != version ||
        envelope['data'] is! Map<String, dynamic>) {
      throw const FormatException('Unsupported or corrupt live record');
    }
    final m = envelope['data'] as Map<String, dynamic>;
    final Object result = switch (T) {
      FocusIntentDocument =>
        FocusIntentDocument()
          ..id = _readInt(m['id'])
          ..payload = IntentState.decode(m['payload'] as String).encode(),
      Preset =>
        Preset()
          ..id = _readInt(m['id'])
          ..name = m['name'] as String
          ..colorValue = _readInt(m['colorValue'])
          ..iconKey = m['iconKey'] == null ? null : m['iconKey'] as String
          ..createdAt = _readDate(m['createdAt'], false),
      Activity =>
        Activity()
          ..id = _readInt(m['id'])
          ..presetId = m['presetId'] == null ? null : _readInt(m['presetId'])
          ..iconKey = m['iconKey'] == null ? null : m['iconKey'] as String
          ..title = m['title'] as String
          ..startMinute = _readInt(m['startMinute'])
          ..endMinute = _readInt(m['endMinute'])
          ..ampmHalf = AmPmHalf.values[_readInt(m['ampmHalf'])]
          ..date = _readDate(m['date'], true)
          ..description = m['description'] as String
          ..colorValue = _readInt(m['colorValue'])
          ..recurrence = m['recurrence'] as String
          ..groupId = m['groupId'] == null ? null : m['groupId'] as String
          ..importance = _readInt(m['importance'])
          ..deadline = m['deadline'] == null
              ? null
              : _readDate(m['deadline'], true)
          ..isCompleted = m['isCompleted'] as bool
          ..actualDurationSeconds = _readInt(m['actualDurationSeconds'])
          ..isLocked = m['isLocked'] as bool
          ..excludedDates = (m['excludedDates'] as List)
              .map((v) => _readDate(v, true))
              .toList()
          ..createdAt = _readDate(m['createdAt'], false)
          ..updatedAt = _readDate(m['updatedAt'], false),
      AppSettings =>
        AppSettings()
          ..id = _readInt(m['id'])
          ..is24h = m['is24h'] as bool
          ..is24hTime = m['is24hTime'] as bool
          ..is24hDial = m['is24hDial'] as bool
          ..showCurrentTime = m['showCurrentTime'] as bool
          ..currentTimeFormat = m['currentTimeFormat'] as String
          ..floatTimeText = m['floatTimeText'] as bool
          ..glowStyle = m['glowStyle'] as String
          ..notifLeadMinutes = _readInt(m['notifLeadMinutes'])
          ..themeMode = m['themeMode'] as String
          ..themePalette = m['themePalette'] as String
          ..trueBlack = m['trueBlack'] as bool
          ..clockHandsMode = _readInt(m['clockHandsMode'])
          ..showMinuteLabels = m['showMinuteLabels'] as bool
          ..clockFaceTheme = _readInt(m['clockFaceTheme'])
          ..keyLeftPanel = m['keyLeftPanel'] as String
          ..keyRightPanel = m['keyRightPanel'] as String
          ..keyAiChat = m['keyAiChat'] as String
          ..keyPrecisionMode = m['keyPrecisionMode'] as String
          ..keyPlanningMode = m['keyPlanningMode'] as String
          ..enableAiAssistant = m['enableAiAssistant'] as bool
          ..enableLeftPanel = m['enableLeftPanel'] as bool
          ..enableRightPanel = m['enableRightPanel'] as bool
          ..aiBaseUrl = m['aiBaseUrl'] as String
          ..aiApiKey = m['aiApiKey'] as String
          ..aiModel = m['aiModel'] as String
          ..hasCompletedOnboarding = m['hasCompletedOnboarding'] as bool,
      Task =>
        Task()
          ..id = _readInt(m['id'])
          ..title = m['title'] as String
          ..description = m['description'] == null
              ? null
              : m['description'] as String
          ..importance = _readInt(m['importance'])
          ..deadline = m['deadline'] == null
              ? null
              : _readDate(m['deadline'], true)
          ..isCompleted = m['isCompleted'] as bool
          ..createdAt = _readDate(m['createdAt'], false)
          ..updatedAt = m['updatedAt'] == null
              ? null
              : _readDate(m['updatedAt'], false)
          ..activityId = m['activityId'] == null
              ? null
              : _readInt(m['activityId'])
          ..startMinute = m['startMinute'] == null
              ? null
              : _readInt(m['startMinute'])
          ..endMinute = m['endMinute'] == null ? null : _readInt(m['endMinute'])
          ..date = m['date'] == null ? null : _readDate(m['date'], true)
          ..ampmHalf = AmPmHalf.values[_readInt(m['ampmHalf'])]
          ..subtasks = (m['subtasks'] as List).cast<String>().toList(),
      Habit =>
        Habit()
          ..id = _readInt(m['id'])
          ..name = m['name'] as String
          ..iconKey = m['iconKey'] as String
          ..target = _readInt(m['target'])
          ..unit = HabitUnit.values[_readInt(m['unit'])]
          ..thingType = ThingType.values[_readInt(m['thingType'])]
          ..habitType = m['habitType'] as String
          ..allowedPackages = (m['allowedPackages'] as List)
              .cast<String>()
              .toList()
          ..progressionPlanJson = m['progressionPlanJson'] == null
              ? null
              : m['progressionPlanJson'] as String
          ..currentProgressionIndex = _readInt(m['currentProgressionIndex'])
          ..hybridSets = _readInt(m['hybridSets'])
          ..hybridDurationSeconds = _readInt(m['hybridDurationSeconds'])
          ..hybridRestSeconds = _readInt(m['hybridRestSeconds'])
          ..category = m['category'] as String
          ..preferredTime = m['preferredTime'] == null
              ? null
              : m['preferredTime'] as String
          ..timerEnabled = m['timerEnabled'] as bool
          ..colorValue = _readInt(m['colorValue'])
          ..recurrence = m['recurrence'] as String
          ..orderIndex = _readInt(m['orderIndex'])
          ..isArchived = m['isArchived'] as bool
          ..createdAt = _readDate(m['createdAt'], false)
          ..updatedAt = m['updatedAt'] == null
              ? null
              : _readDate(m['updatedAt'], false),
      HabitEntry =>
        HabitEntry()
          ..id = _readInt(m['id'])
          ..habitId = _readInt(m['habitId'])
          ..dateString = m['dateString'] as String
          ..status = HabitStatus.values[_readInt(m['status'])]
          ..valueCompleted = _readInt(m['valueCompleted'])
          ..targetSnapshot = _readInt(m['targetSnapshot'])
          ..actualDurationMinutes = _readInt(m['actualDurationMinutes'])
          ..actualDurationSeconds = _readInt(m['actualDurationSeconds'])
          ..completedAt = m['completedAt'] == null
              ? null
              : _readDate(m['completedAt'], false)
          ..source = m['source'] as String
          ..note = m['note'] == null ? null : m['note'] as String
          ..createdAt = m['createdAt'] == null
              ? null
              : _readDate(m['createdAt'], false)
          ..updatedAt = _readDate(m['updatedAt'], false),
      DailyReflection =>
        DailyReflection()
          ..id = _readInt(m['id'])
          ..dateString = m['dateString'] as String
          ..feeling = ReflectionFeeling.values[_readInt(m['feeling'])]
          ..proudOfToday = m['proudOfToday'] as String
          ..note = m['note'] as String
          ..completedCount = _readInt(m['completedCount'])
          ..totalCount = _readInt(m['totalCount'])
          ..updatedAt = _readDate(m['updatedAt'], false),
      TimerSession =>
        TimerSession()
          ..id = _readInt(m['id'])
          ..habitId = _readInt(m['habitId'])
          ..habitName = m['habitName'] as String
          ..sourceKindIndex = m['sourceKindIndex'] == null
              ? null
              : _readInt(m['sourceKindIndex'])
          ..activityId = m['activityId'] == null
              ? null
              : _readInt(m['activityId'])
          ..sourceIdentity = m['sourceIdentity'] == null
              ? null
              : m['sourceIdentity'] as String
          ..sourceColorValue = m['sourceColorValue'] == null
              ? null
              : _readInt(m['sourceColorValue'])
          ..targetSeconds = _readInt(m['targetSeconds'])
          ..startedAt = m['startedAt'] == null
              ? null
              : _readDate(m['startedAt'], false)
          ..attributionLocalDate = m['attributionLocalDate'] == null
              ? null
              : m['attributionLocalDate'] as String
          ..runningSince = m['runningSince'] == null
              ? null
              : _readDate(m['runningSince'], false)
          ..pausedAt = m['pausedAt'] == null
              ? null
              : _readDate(m['pausedAt'], false)
          ..accumulatedDurationSeconds = _readInt(
            m['accumulatedDurationSeconds'],
          )
          ..status = TimerStateStatus.values[_readInt(m['status'])]
          ..updatedAt = _readDate(m['updatedAt'], false),
      _ => throw ArgumentError('Unknown model $T'),
    };
    validateId(id(result));
    return result as T;
  }

  static int _integer(int value) {
    validateId(value);
    return value;
  }

  static int _readInt(Object? value) {
    if (value is! int) throw const FormatException('Expected exact integer');
    return _integer(value);
  }

  static Object _date(DateTime value, bool calendar) => calendar
      ? [value.year, value.month, value.day]
      : {'micros': value.microsecondsSinceEpoch, 'utc': value.isUtc};
  static DateTime _readDate(Object? value, bool calendar) {
    if (calendar) {
      final parts = value as List;
      if (parts.length != 3) {
        throw const FormatException('Invalid calendar date');
      }
      final y = _readInt(parts[0]),
          m = _readInt(parts[1]),
          d = _readInt(parts[2]);
      final date = DateTime(y, m, d);
      if (date.year != y || date.month != m || date.day != d) {
        throw const FormatException('Invalid calendar date');
      }
      return date;
    }
    final instant = value as Map<String, dynamic>;
    return DateTime.fromMicrosecondsSinceEpoch(
      _readInt(instant['micros']),
      isUtc: instant['utc'] as bool,
    );
  }
}
