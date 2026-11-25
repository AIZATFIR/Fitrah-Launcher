import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/data/repositories/intent_repository.dart';
import 'package:fitrah_launcher/data/store/native_focus_store.dart';
import 'package:fitrah_launcher/domain/focus_intent.dart';
import 'package:fitrah_launcher/models/focus_intent_document.dart';
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

  test(
    'export and restore preserve unavailable habit references after hard deletion',
    () async {
      final db = store.isar!;
      final now = DateTime(2026, 11, 8, 10);
      final repo = SadarRepository(db);
      final habit = Habit()
        ..id = 7
        ..name = 'LKS'
        ..target = 45
        ..createdAt = now
        ..colorValue = 0;
      final activity = Activity()
        ..id = 19
        ..habitId = 7
        ..title = 'LKS schedule'
        ..date = now
        ..ampmHalf = AmPmHalf.am
        ..startMinute = 600
        ..endMinute = 645
        ..colorValue = 0
        ..createdAt = now
        ..updatedAt = now;
      final unlinked = Activity()
        ..id = 20
        ..title = 'Unlinked'
        ..date = now
        ..ampmHalf = AmPmHalf.am
        ..startMinute = 650
        ..endMinute = 660
        ..colorValue = 0
        ..createdAt = now
        ..updatedAt = now;
      await db.writeTxn(() async {
        await db.habits.put(habit);
        await db.activitys.put(activity);
        await db.activitys.put(unlinked);
      });
      await repo.saveTimerSession(
        TimerSession()
          ..activityId = 19
          ..sourceKind = TimerSessionSourceKind.activity
          ..habitName = 'LKS'
          ..targetSeconds = 2700
          ..startedAt = now
          ..attributionLocalDate = '2026-11-08'
          ..status = TimerStateStatus.paused
          ..accumulatedDurationSeconds = 480
          ..updatedAt = now,
      );
      await repo.deleteHabit(7, hardDelete: true);
      final service = FocusClockBackupService(
        isar: db,
        secureStorage: secureStorage,
        supportDirectory: () async => root,
      );
      final decoded = FocusClockBackupCodec.decode(await service.exportBytes());
      expect(decoded.data.habits, isEmpty);
      expect(decoded.data.activities.firstWhere((a) => a.id == 19).habitId, 7);
      expect(decoded.data.timerSessions.single.habitId, 7);
      expect(decoded.data.timerSessions.single.habitTargetSnapshot, 45);
      // Restore itself exports recovery before replacing data, exercising both paths.
      final recovery = await service.restore(decoded);
      expect(File(recovery).existsSync(), isTrue);
      expect(await db.habits.count(), 0);
      expect((await db.activitys.get(19))!.habitId, 7);
      expect((await db.activitys.get(20))!.habitId, isNull);
      final saved = (await db.timerSessions.get(1))!;
      expect(saved.habitId, 7);
      expect(saved.habitTargetSnapshot, 45);
      expect(saved.activityId, 19);
      expect(saved.accumulatedDurationSeconds, 480);
    },
  );

  test('replaces durable records and retains local credentials', () async {
    final settingsNotifier = LauncherSettingsNotifier(secureStorage);
    await settingsNotifier.reload();
    expect(settingsNotifier.state.focusGoal, 'Current goal');
    final db = store.isar!;
    final localSettings = await db.appSettings.get(0);
    localSettings!
      ..aiApiKey = 'local-secret'
      ..aiBaseUrl = 'https://local-provider.example'
      ..aiModel = 'local-model';
    final oldHabit = Habit()
      ..id = 4
      ..name = 'Old habit'
      ..colorValue = 0xff123456
      ..createdAt = DateTime.utc(2026);
    await db.writeTxn(() async {
      await db.appSettings.put(localSettings);
      await db.habits.put(oldHabit);
    });

    final intentRow = FocusIntentDocument()
      ..payload = IntentState(
        sourceStoreId: '11111111-1111-4111-8111-111111111111',
        legacyImported: true,
      ).encode();
    final incomingSettings = AppSettings()
      ..aiApiKey = 'should-not-import'
      ..aiBaseUrl = 'https://remote-provider.example'
      ..aiModel = 'remote-model';
    final backupData = FocusClockBackupData(
      intentDocuments: [intentRow],
      presets: [],
      activities: [
        Activity()
          ..id = 19
          ..habitId = 8
          ..title = 'Scheduled restored habit'
          ..date = DateTime(2026, 11, 8)
          ..ampmHalf = AmPmHalf.am
          ..startMinute = 600
          ..endMinute = 645
          ..colorValue = 0xffabcdef
          ..createdAt = DateTime.utc(2026)
          ..updatedAt = DateTime.utc(2026),
      ],
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
    expect(restoredSettings!.aiApiKey, isEmpty);
    expect(restoredSettings.aiBaseUrl, 'https://local-provider.example');
    expect(restoredSettings.aiModel, 'local-model');
    expect(secureStorage.values['ai_provider_api_key'], 'local-secret');
    expect(
      LauncherSettings.fromJson(
        secureStorage.values[FocusClockBackupService.launcherSettingsKey]!,
      ).focusGoal,
      'Menang LKS',
    );
    expect((await db.focusIntentDocuments.get(1))!.payload, intentRow.payload);
    expect(parsed.formatVersion, FocusClockBackupCodec.currentFormatVersion);
    expect((await db.activitys.get(19))!.habitId, 8);
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

  test(
    'restoring v1/v2 refreshes mounted intent stream with restored legacy cue exactly once',
    () async {
      final db = store.isar!;
      final repo = IntentRepository(NativeFocusStore(db));
      await repo.importLegacy('Before restore');
      final incoming = FocusClockBackupData(
        presets: [],
        activities: [],
        appSettings: [AppSettings()],
        tasks: [],
        habits: [],
        habitEntries: [],
        dailyReflections: [],
        timerSessions: [],
        launcherSettings: LauncherSettings(focusGoal: 'Restored legacy'),
      );
      final rootMap =
          jsonDecode(utf8.decode(FocusClockBackupCodec.encode(incoming)))
              as Map<String, dynamic>;
      rootMap['formatVersion'] = 2;
      rootMap['data'].remove('intentDocuments');
      rootMap['checksum'] = FocusClockBackupCodec.checksumFor(rootMap['data']);
      final backup = FocusClockBackupCodec.decode(
        utf8.encode(jsonEncode(rootMap)),
      );
      final observed = repo.watch().firstWhere(
        (s) => s.pinnedGoal?.title == 'Restored legacy',
      );
      final service = FocusClockBackupService(
        isar: db,
        secureStorage: secureStorage,
        supportDirectory: () async => root,
      );
      await service.restore(backup);
      final visible = await observed.timeout(const Duration(seconds: 5));
      expect(visible.legacyImported, true);
      expect(visible.legacyMappings.single.stableId, visible.goals.single.id);
      final reopened = await repo.importLegacy('Before restore');
      expect(reopened.goals.single.id, visible.goals.single.id);
      expect(reopened.goals.single.title, 'Restored legacy');
      await service.restore(backup);
      final repeated = await repo.read();
      expect(repeated.sourceStoreId, visible.sourceStoreId);
      expect(repeated.goals.single.id, visible.goals.single.id);
    },
  );

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
      final oldIntent = FocusIntentDocument()
        ..payload = IntentState(
          sourceStoreId: '22222222-2222-4222-8222-222222222222',
          legacyImported: true,
        ).encode();
      await db.writeTxn(() => db.focusIntentDocuments.put(oldIntent));
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

      expect(
        (await db.focusIntentDocuments.get(1))!.payload,
        oldIntent.payload,
      );
      final recovery = FocusClockBackupCodec.decode(
        (await service.latestRecoveryBytes())!,
      );
      expect(recovery.data.intentDocuments.single.payload, oldIntent.payload);
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
  Future<String?> migrateAiProviderApiKey({
    String? legacyAppSettingsKey,
  }) async {
    final current = values['ai_provider_api_key'];
    if (current != null && current.isNotEmpty) return current;
    final key = (legacyAppSettingsKey?.isNotEmpty ?? false)
        ? legacyAppSettingsKey!
        : values['gemini_api_key'] ?? values['openrouter_api_key'];
    if (key == null || key.isEmpty) return null;
    values['ai_provider_api_key'] = key;
    values.remove('gemini_api_key');
    values.remove('openrouter_api_key');
    return key;
  }

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
