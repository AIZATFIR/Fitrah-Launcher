import 'package:fitrah_launcher/data/focus_clock_backup.dart';
import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/app_settings.dart';
import 'package:fitrah_launcher/models/daily_reflection.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/habit_entry.dart';
import 'package:fitrah_launcher/models/preset.dart';
import 'package:fitrah_launcher/models/task.dart';
import 'package:fitrah_launcher/models/timer_session.dart';

FocusClockBackupData browserFixture() {
  final preset = Preset()
    ..id = 3
    ..name = 'Study'
    ..colorValue = 0xff123456
    ..createdAt = DateTime.utc(2026, 11, 5);
  final activity = Activity()
    ..id = 17
    ..title = 'LKS practice'
    ..startMinute = 20
    ..endMinute = 50
    ..ampmHalf = AmPmHalf.pm
    ..date = DateTime(2026, 11, 5)
    ..colorValue = 0xff123456
    ..presetId = preset.id
    ..createdAt = DateTime.utc(2026, 11, 1)
    ..updatedAt = DateTime.utc(2026, 11, 5);
  final habit = Habit()
    ..id = 23
    ..name = 'Practice'
    ..colorValue = 0xffabcdef
    ..createdAt = DateTime.utc(2026, 10, 1);
  final entry = HabitEntry()
    ..id = 29
    ..habitId = habit.id
    ..dateString = '2026-11-05'
    ..actualDurationSeconds = 91
    ..targetSnapshot = 120
    ..updatedAt = DateTime.utc(2026, 11, 5);
  final task = Task()
    ..id = 31
    ..title = 'Open laptop'
    ..createdAt = DateTime.utc(2026, 11, 5)
    ..activityId = activity.id;
  final reflection = DailyReflection()
    ..id = 37
    ..dateString = '2026-11-05'
    ..note = 'private note'
    ..updatedAt = DateTime.utc(2026, 11, 5);
  final settings = AppSettings()
    ..aiApiKey = 'SYNTHETIC-NON-SECRET'
    ..aiBaseUrl = 'https://api.example/?token=SYNTHETIC-URL-TOKEN';
  final timer = TimerSession()..updatedAt = DateTime.utc(2026, 11, 5);

  return FocusClockBackupData(
    presets: [preset],
    activities: [activity],
    appSettings: [settings],
    tasks: [task],
    habits: [habit],
    habitEntries: [entry],
    dailyReflections: [reflection],
    timerSessions: [timer],
    launcherSettings: LauncherSettings(focusGoal: 'Menang LKS nasional'),
  );
}
