import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:fitrah_launcher/data/focus_clock_backup.dart';
import 'package:fitrah_launcher/data/focus_clock_backup_service.dart';
import 'package:fitrah_launcher/data/isar_service.dart';
import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/features/launcher/providers/launcher_settings_provider.dart';
import 'package:fitrah_launcher/models/app_settings.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (Platform.isLinux) {
      final config =
          jsonDecode(
                await File('.dart_tool/package_config.json').readAsString(),
              )
              as Map<String, dynamic>;
      final packages = config['packages'] as List<dynamic>;
      final isarPackage = packages.cast<Map<String, dynamic>>().firstWhere(
        (package) => package['name'] == 'isar_community_flutter_libs',
      );
      final packageRoot = Uri.parse(isarPackage['rootUri'] as String);
      final library = File('${packageRoot.path}/linux/libisar.so');
      await Isar.initializeIsarCore(
        libraries: {ffi.Abi.current(): library.path},
      );
    }
  });
  late Directory root;
  late IsarService store;
  late _MemorySecureStorage secureStorage;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('focus-clock-backup-');
    final dbDirectory = await Directory('${root.path}/db').create();
    store = await IsarService.openAt(dbDirectory.path);
    secureStorage = _MemorySecureStorage();
    secureStorage.values[FocusClockBackupService.launcherSettingsKey] =
        LauncherSettings(focusGoal: 'Current goal').toJson();
  });

  tearDown(() async {
    await store.isar!.close(deleteFromDisk: true);
    await root.delete(recursive: true);
  });

  test('replaces durable records and retains local credentials', () async {
    final settingsNotifier = LauncherSettingsNotifier(secureStorage);
    await settingsNotifier.reload();
    expect(settingsNotifier.state.focusGoal, 'Current goal');
    final db = store.isar!;
    final localSettings = await db.appSettings.get(0);
    localSettings!
      ..aiApiKey = 'local-secret'
      ..aiBaseUrl = 'https://local-provider.example';
    final oldHabit = Habit()
      ..id = 4
      ..name = 'Old habit'
      ..colorValue = 0xff123456
      ..createdAt = DateTime.utc(2026);
    await db.writeTxn(() async {
      await db.appSettings.put(localSettings);
      await db.habits.put(oldHabit);
    });

    final incomingSettings = AppSettings()
      ..aiApiKey = 'should-not-import'
      ..aiBaseUrl = 'https://remote-provider.example';
    final backupData = FocusClockBackupData(
      presets: [],
      activities: [],
      appSettings: [incomingSettings],
      tasks: [],
      habits: [
        Habit()
          ..id = 8
          ..name = 'Restored habit'
          ..colorValue = 0xffabcdef
          ..createdAt = DateTime.utc(2026),
      ],
      habitEntries: [],
      dailyReflections: [],
      timerSessions: [],
      launcherSettings: LauncherSettings(
        focusGoal: 'Menang LKS',
        dailyNotes: {'2026-11-07': 'first\nline', '2026-11-08': 'second'},
      ),
    );
    final parsed = FocusClockBackupCodec.decode(
      FocusClockBackupCodec.encode(backupData),
    );
    final service = FocusClockBackupService(
      isar: db,
      secureStorage: secureStorage,
      supportDirectory: () async => root,
    );

    final recoveryPath = await service.restore(parsed);

    expect(File(recoveryPath).existsSync(), isTrue);
    expect((await db.habits.where().findAll()).map((x) => x.id), [8]);
    final restoredSettings = await db.appSettings.get(0);
    expect(restoredSettings!.aiApiKey, 'local-secret');
    expect(restoredSettings.aiBaseUrl, 'https://local-provider.example');
    expect(
      LauncherSettings.fromJson(
        secureStorage.values[FocusClockBackupService.launcherSettingsKey]!,
      ).focusGoal,
      'Menang LKS',
    );
    expect(parsed.formatVersion, 2);
    expect(
      LauncherSettings.fromJson(
        secureStorage.values[FocusClockBackupService.launcherSettingsKey]!,
      ).dailyNotes,
      {'2026-11-07': 'first\nline', '2026-11-08': 'second'},
    );
    await settingsNotifier.reload();
    expect(settingsNotifier.state.focusGoal, 'Menang LKS');
    settingsNotifier.dispose();
  });

  test('Isar rolls back a failed multi-collection write transaction', () async {
    final db = store.isar!;
    final original = Habit()
      ..id = 18
      ..name = 'Keep after rollback'
      ..colorValue = 0xff123456
      ..createdAt = DateTime.utc(2026);
    await db.writeTxn(() => db.habits.put(original));

    await expectLater(
      db.writeTxn(() async {
        await db.clear();
        throw StateError('simulated failure after clear');
      }),
      throwsA(isA<StateError>()),
    );

    expect(
      (await db.habits.where().findAll()).single.name,
      'Keep after rollback',
    );
  });

  test(
    'compensates the database when launcher preference write fails',
    () async {
      final db = store.isar!;
      final oldHabit = Habit()
        ..id = 12
        ..name = 'Keep this'
        ..colorValue = 0xff123456
        ..createdAt = DateTime.utc(2026);
      await db.writeTxn(() => db.habits.put(oldHabit));
      final oldSettings =
          secureStorage.values[FocusClockBackupService.launcherSettingsKey];
      secureStorage.failNextLauncherWrite = true;

      final parsed = FocusClockBackupCodec.decode(
        FocusClockBackupCodec.encode(
          FocusClockBackupData(
            presets: [],
            activities: [],
            appSettings: [AppSettings()],
            tasks: [],
            habits: [
              Habit()
                ..id = 13
                ..name = 'Do not keep'
                ..colorValue = 0xffabcdef
                ..createdAt = DateTime.utc(2026),
            ],
            habitEntries: [],
            dailyReflections: [],
            timerSessions: [],
            launcherSettings: LauncherSettings(focusGoal: 'New goal'),
          ),
        ),
      );
      final service = FocusClockBackupService(
        isar: db,
        secureStorage: secureStorage,
        supportDirectory: () async => root,
      );

      await expectLater(service.restore(parsed), throwsA(isA<StateError>()));

      expect((await db.habits.where().findAll()).map((x) => x.id), [12]);
      expect(
        secureStorage.values[FocusClockBackupService.launcherSettingsKey],
        oldSettings,
      );
    },
  );
}

class _MemorySecureStorage extends SecureStorageService {
  final Map<String, String> values = {};
  bool failNextLauncherWrite = false;

  @override
  Future<String?> readCustomKey(String key) async => values[key];

  @override
  Future<void> writeCustomKey(String key, String value) async {
    if (key == FocusClockBackupService.launcherSettingsKey &&
        failNextLauncherWrite) {
      failNextLauncherWrite = false;
      throw StateError('simulated secure-storage failure');
    }
    values[key] = value;
  }

  @override
  Future<void> deleteCustomKey(String key) async => values.remove(key);
}
