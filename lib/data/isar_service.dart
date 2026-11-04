import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/activity.dart';
import '../models/app_settings.dart';
import '../models/preset.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';
import '../models/daily_reflection.dart';
import '../models/timer_session.dart';

class IsarService {
  IsarService._(this.isar);
  IsarService.fallback() : isar = null;
  final Isar? isar;

  static List<CollectionSchema<dynamic>> get schemas => [
    PresetSchema,
    ActivitySchema,
    AppSettingsSchema,
    TaskSchema,
    HabitSchema,
    HabitEntrySchema,
    DailyReflectionSchema,
    TimerSessionSchema,
  ];

  static Future<IsarService> open() async {
    if (kIsWeb) {
      await Isar.initializeIsarCore(download: true);
      final isar = await Isar.open(schemas, directory: '', inspector: false);
      await _seed(isar);
      return IsarService._(isar);
    }

    final dir = await getApplicationDocumentsDirectory();
    return openAt(dir.path, inspector: true);
  }

  /// Open a native Isar store at an explicit path.
  /// Used by migration and reopen checks that must not touch the user's store.
  static Future<IsarService> openAt(
    String directory, {
    bool inspector = false,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'An explicit directory is only available natively.',
      );
    }
    final isar = await Isar.open(
      schemas,
      directory: directory,
      inspector: inspector,
    );
    await _seed(isar);
    return IsarService._(isar);
  }

  static Future<void> _seed(Isar isar) async {
    final hasSettings = await isar.appSettings.count() > 0;
    if (!hasSettings) {
      await isar.writeTxn(() async {
        await isar.appSettings.put(AppSettings());
      });
    }
  }
}
