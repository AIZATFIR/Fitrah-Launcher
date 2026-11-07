import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../features/launcher/models/launcher_settings.dart';
import '../services/secure_storage_service.dart';
import 'focus_clock_backup.dart';
import 'store/focus_store.dart';
import 'store/native_focus_store.dart';

class FocusClockBackupService {
  FocusClockBackupService({
    this.isar,
    this.store,
    required this.secureStorage,
    Future<Directory> Function()? supportDirectory,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final Isar? isar;
  final FocusStore? store;
  final SecureStorageService secureStorage;
  final Future<Directory> Function() _supportDirectory;

  static const launcherSettingsKey = 'fitrah_launcher_settings_v1';
  static const recoveryDirectoryName = 'focus-clock-recovery';

  Future<FocusClockBackupData> readCurrentData() async {
    final db = _requireDatabase();
    final rawSettings = await secureStorage.readCustomKey(launcherSettingsKey);
    final launcherSettings = rawSettings == null || rawSettings.isEmpty
        ? LauncherSettings()
        : LauncherSettings.fromJson(rawSettings);
    final snapshot = await db.txn(
      () async => (
        presets: await db.presets.all(),
        activities: await db.activitys.all(),
        appSettings: await db.appSettings.all(),
        tasks: await db.tasks.all(),
        habits: await db.habits.all(),
        habitEntries: await db.habitEntrys.all(),
        dailyReflections: await db.dailyReflections.all(),
        timerSessions: await db.timerSessions.all(),
      ),
    );
    return FocusClockBackupData(
      presets: snapshot.presets,
      activities: snapshot.activities,
      appSettings: snapshot.appSettings,
      tasks: snapshot.tasks,
      habits: snapshot.habits,
      habitEntries: snapshot.habitEntries,
      dailyReflections: snapshot.dailyReflections,
      timerSessions: snapshot.timerSessions,
      launcherSettings: launcherSettings,
    );
  }

  Future<Uint8List> exportBytes() async =>
      FocusClockBackupCodec.encode(await readCurrentData());

  /// Replaces both durable stores. The recovery file is written before either
  /// store changes, and a normal storage failure triggers compensation.
  Future<String> restore(DecodedFocusClockBackup backup) async {
    final db = _requireDatabase();

    final oldData = await readCurrentData();
    final oldBytes = FocusClockBackupCodec.encode(oldData);
    final recoveryPath = db is RecoveryJournal
        ? await (db as RecoveryJournal).saveRecovery(oldBytes)
        : (await _writeRecoveryFile(oldBytes)).path;
    final oldLauncherRaw = await secureStorage.readCustomKey(
      launcherSettingsKey,
    );
    final currentSettings = oldData.appSettings.single;
    final incoming = backup.data;

    // Credentials are local configuration and are intentionally excluded from
    // the file. Keep the current install's values when restoring preferences.
    final restoredAppSettings =
        FocusClockBackupCodec.copySettings(incoming.appSettings.single)
          ..aiApiKey = currentSettings.aiApiKey
          ..aiBaseUrl = currentSettings.aiBaseUrl;

    var databaseCommitted = false;
    try {
      await db.writeTxn(() async {
        await _replaceDatabase(
          db,
          presets: incoming.presets,
          activities: incoming.activities,
          appSettings: [restoredAppSettings],
          tasks: incoming.tasks,
          habits: incoming.habits,
          habitEntries: incoming.habitEntries,
          dailyReflections: incoming.dailyReflections,
          timerSessions: incoming.timerSessions,
        );
      });
      databaseCommitted = true;
      await secureStorage.writeCustomKey(
        launcherSettingsKey,
        incoming.launcherSettings.toJson(),
      );
      return recoveryPath;
    } catch (error) {
      Object? rollbackError;
      try {
        if (databaseCommitted) {
          await db.writeTxn(() async {
            await _replaceDatabase(
              db,
              presets: oldData.presets,
              activities: oldData.activities,
              appSettings: oldData.appSettings,
              tasks: oldData.tasks,
              habits: oldData.habits,
              habitEntries: oldData.habitEntries,
              dailyReflections: oldData.dailyReflections,
              timerSessions: oldData.timerSessions,
            );
          });
        }
        if (oldLauncherRaw == null) {
          await secureStorage.deleteCustomKey(launcherSettingsKey);
        } else {
          await secureStorage.writeCustomKey(
            launcherSettingsKey,
            oldLauncherRaw,
          );
        }
      } catch (restoreError) {
        rollbackError = restoreError;
      }
      if (rollbackError != null) {
        throw StateError(
          'Restore gagal ($error) dan pemulihan otomatis gagal ($rollbackError). '
          'Salinan lokal tersedia di $recoveryPath.',
        );
      }
      Error.throwWithStackTrace(
        StateError('Restore gagal; data sebelumnya dipulihkan. ($error)'),
        StackTrace.current,
      );
    }
  }

  Future<Uint8List?> latestRecoveryBytes() async {
    final db = _requireDatabase();
    if (db is RecoveryJournal) return (db as RecoveryJournal).latestRecovery();
    final directory = await _supportDirectory();
    final recovery = Directory(
      '${directory.path}${Platform.pathSeparator}$recoveryDirectoryName',
    );
    if (!await recovery.exists()) return null;
    final files = await recovery
        .list()
        .where((item) => item is File && item.path.endsWith('.json'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files.isEmpty ? null : files.first.readAsBytes();
  }

  Future<File> _writeRecoveryFile(Uint8List bytes) async {
    final directory = await _supportDirectory();
    final recoveryDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}$recoveryDirectoryName',
    );
    await recoveryDirectory.create(recursive: true);
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final file = File(
      '${recoveryDirectory.path}${Platform.pathSeparator}before-restore-$stamp.json',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  FocusStore _requireDatabase() {
    final db = store ?? (isar == null ? null : NativeFocusStore(isar!));
    if (db == null) {
      throw StateError('Penyimpanan belum siap. Coba lagi setelah app pulih.');
    }
    return db;
  }

  static Future<void> _replaceDatabase(
    FocusStore db, {
    required List<dynamic> presets,
    required List<dynamic> activities,
    required List<dynamic> appSettings,
    required List<dynamic> tasks,
    required List<dynamic> habits,
    required List<dynamic> habitEntries,
    required List<dynamic> dailyReflections,
    required List<dynamic> timerSessions,
  }) async {
    await db.clear();
    await db.presets.putAll(presets.cast());
    await db.activitys.putAll(activities.cast());
    await db.appSettings.putAll(appSettings.cast());
    await db.tasks.putAll(tasks.cast());
    await db.habits.putAll(habits.cast());
    await db.habitEntrys.putAll(habitEntries.cast());
    await db.dailyReflections.putAll(dailyReflections.cast());
    await db.timerSessions.putAll(timerSessions.cast());
  }
}
