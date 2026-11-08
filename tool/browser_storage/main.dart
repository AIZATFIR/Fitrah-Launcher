import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:fitrah_launcher/data/focus_clock_backup.dart';
import 'package:fitrah_launcher/data/focus_clock_backup_service.dart';
import 'package:fitrah_launcher/data/repositories/activity_repository.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/data/repositories/settings_repository.dart';
import 'package:fitrah_launcher/data/repositories/task_repository.dart';
import 'package:fitrah_launcher/data/store/browser_focus_store.dart';
import 'package:fitrah_launcher/data/store/live_model_codec.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/services/notification_service.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'fixture.dart';

@JS('productionCommand')
external set productionCommand(JSFunction callback);

class _Preferences extends SecureStorageService {
  bool failNextWrite = false;
  @override
  Future<void> writeCustomKey(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Injected preference failure');
    }
    await super.writeCustomKey(key, value);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final name = Uri.base.queryParameters['db']!;
    if (!name.startsWith('focus_clock_production_test_')) {
      throw ArgumentError('Isolated name required');
    }
    final store = await BrowserFocusStore.open(name: name);
    final preferences = _Preferences();
    final service = FocusClockBackupService(
      store: store,
      secureStorage: preferences,
    );
    final sadar = SadarRepository.store(store);
    final settings = SettingsRepository.store(store);
    final tasks = TaskRepository.store(store);
    final activities = ActivityRepository.store(store, NotificationService());
    final now = DateTime.utc(2026, 11, 6, 9);
    final snapshots = <String>[];
    final subscription = store
        .watch()
        .asyncMap(
          (_) => store.txn(
            () async => jsonEncode({
              'activities': (await store.all<Activity>()).length,
              'sessions': (await store.all<TimerSession>()).length,
            }),
          ),
        )
        .listen(snapshots.add);
    Future<Map<String, dynamic>> snapshot() async {
      final data = await service.readCurrentData();
      return {
        'mode': store.mode.name,
        'goal': data.launcherSettings.focusGoal,
        'credentials': data.appSettings.single.aiApiKey,
        'endpoint': data.appSettings.single.aiBaseUrl,
        'counts': data.counts,
        'activitySeconds': data.activities
            .map((x) => x.actualDurationSeconds)
            .toList(),
        'entrySeconds': data.habitEntries
            .map((x) => x.actualDurationSeconds)
            .toList(),
        'timer': data.timerSessions.isEmpty
            ? null
            : LiveModelCodec.encode(data.timerSessions.single),
        'records': [
          ...data.presets.map(LiveModelCodec.encode),
          ...data.activities.map(LiveModelCodec.encode),
          ...data.appSettings.map(LiveModelCodec.encode),
          ...data.tasks.map(LiveModelCodec.encode),
          ...data.habits.map(LiveModelCodec.encode),
          ...data.habitEntries.map(LiveModelCodec.encode),
          ...data.dailyReflections.map(LiveModelCodec.encode),
          ...data.timerSessions.map(LiveModelCodec.encode),
          ...data.intentDocuments.map(LiveModelCodec.encode),
        ],
      };
    }

    Future<String> command(String action) async {
      try {
        switch (action) {
          case 'seed':
            final data = browserFixture();
            data.timerSessions.single
              ..sourceKindIndex = 999
              ..runningSince = now
              ..startedAt = now
              ..status = TimerStateStatus.running
              ..attributionLocalDate = '2026-11-06';
            data.activities.single
              ..recurrence = 'daily'
              ..excludedDates = [DateTime(2026, 11, 8)];
            data.tasks.single.subtasks = [
              '{"title":"sub","isCompleted":false}',
            ];
            data.habits.single
              ..allowedPackages = ['a', 'b']
              ..progressionPlanJson = 'raw-value';
            await store.writeTxn(() async {
              await store.presets.putAll(data.presets);
              await store.activitys.putAll(data.activities);
              await store.appSettings.putAll(data.appSettings);
              await store.tasks.putAll(data.tasks);
              await store.habits.putAll(data.habits);
              await store.habitEntrys.putAll(data.habitEntries);
              await store.dailyReflections.putAll(data.dailyReflections);
              await store.timerSessions.putAll(data.timerSessions);
              await store.focusIntentDocuments.putAll(data.intentDocuments);
            });
            await preferences.writeCustomKey(
              FocusClockBackupService.launcherSettingsKey,
              data.launcherSettings.toJson(),
            );
          case 'prepare':
            await store.writeTxn(() => store.timerSessions.delete(1));
            await sadar.getActiveTimerSession();
          case 'observe':
            await sadar.getActiveTimerSession();
          case 'start':
            await sadar.saveTimerSession(
              TimerSession()
                ..habitId = 23
                ..habitName = 'Practice'
                ..sourceKind = TimerSessionSourceKind.habit
                ..startedAt = DateTime.now()
                ..runningSince = now
                ..targetSeconds = 1200
                ..attributionLocalDate = '2026-11-06'
                ..status = TimerStateStatus.running
                ..updatedAt = now,
            );
          case 'start-activity':
            final activity = browserFixture().activities.single
              ..id = Isar.autoIncrement
              ..recurrence = 'none';
            await sadar.createActivityAndStartTimerSession(
              activity,
              TimerSession()
                ..sourceKind = TimerSessionSourceKind.activity
                ..startedAt = DateTime.now()
                ..updatedAt = now,
            );
          case 'complete':
            await sadar.completeTimerSession(
              habitId: 23,
              dateString: '2026-11-06',
              actualDurationMinutes: 1,
              actualDurationSeconds: 67,
              targetSnapshot: 20,
              completedAt: now,
            );
          case 'complete-activity':
            final current = await store.get<TimerSession>(1);
            if (current != null) {
              await sadar.completeActivityTimerSession(
                activityId: current.activityId!,
                actualDurationSeconds: 67,
                completedAt: now,
              );
            }
          case 'cancel':
            await sadar.clearTimerSession();
          case 'rollback':
            final before = snapshots.length;
            final activity = browserFixture().activities.single
              ..id = Isar.autoIncrement;
            try {
              await store.writeTxn(() async {
                await store.put(activity);
                await store.delete<TimerSession>(1);
                throw StateError('Injected transaction failure');
              });
            } catch (_) {
              // The exception is the expected result of this rollback probe.
            }
            await Future<void>.delayed(const Duration(milliseconds: 100));
            if (activity.id != Isar.autoIncrement) {
              throw StateError('Uncommitted allocation escaped');
            }
            if (snapshots
                .skip(before)
                .any((x) => jsonDecode(x)['sessions'] == 0)) {
              throw StateError('Partial watcher state');
            }
          case 'recurrence':
            if ((await activities.getByDate(DateTime(2026, 11, 7))).length !=
                    1 ||
                (await activities.getByDate(
                  DateTime(2026, 11, 8),
                )).isNotEmpty) {
              throw StateError('Recurrence/exclusion failed');
            }
            final task = (await tasks.getAll()).single;
            await tasks.toggleCompletion(task.id);
            final config = await settings.get();
            config.trueBlack = true;
            await settings.update(config);
          case 'restore':
            final backup = FocusClockBackupCodec.decode(
              await service.exportBytes(),
            );
            await service.restore(backup);
            final recovery = await service.latestRecoveryBytes();
            if (recovery == null ||
                FocusClockBackupCodec.decode(
                      recovery,
                    ).data.launcherSettings.focusGoal !=
                    'Menang LKS nasional') {
              throw StateError('Missing recovery');
            }
          case 'preference-failure':
            final before = await snapshot();
            final backup = FocusClockBackupCodec.decode(
              await service.exportBytes(),
            );
            preferences.failNextWrite = true;
            try {
              await service.restore(backup);
              throw StateError('Expected preference failure');
            } catch (error) {
              if (!error.toString().contains('data sebelumnya dipulihkan')) {
                rethrow;
              }
            }
            if (jsonEncode(before) != jsonEncode(await snapshot())) {
              throw StateError('Compensation changed live fields');
            }
          case 'recovery':
            final bytes = await service.latestRecoveryBytes();
            return jsonEncode({
              'bytes': bytes,
              'decoded': bytes == null
                  ? null
                  : FocusClockBackupCodec.decode(bytes).data.counts,
            });
          case 'unsafe-id':
            try {
              await store.writeTxn(
                () => store.put(
                  browserFixture().habits.single..id = 9007199254740992,
                ),
              );
              throw StateError('Expected unsafe ID rejection');
            } on FormatException {
              // Expected for IDs JavaScript cannot represent exactly.
            }
          case 'nested':
            try {
              await store.writeTxn(() => store.writeTxn(() async {}));
              throw StateError('Expected transaction guard');
            } on StateError catch (error) {
              if (!error.toString().contains('Nested')) {
                rethrow;
              }
            }
          case 'read':
            break;
          case 'close':
            await subscription.cancel();
            await store.close();
            return '{}';
          default:
            throw ArgumentError(action);
        }
        return jsonEncode(await snapshot());
      } catch (error, stack) {
        return jsonEncode({
          'error': error.toString(),
          'stack': stack.toString(),
        });
      }
    }

    productionCommand = ((JSString action) => command(
      action.toDart,
    ).then((value) => value.toJS).toJS).toJS;
    runApp(const MaterialApp(home: Text('Production storage journey ready')));
  } catch (error) {
    runApp(MaterialApp(home: Text('Storage probe failed: $error')));
  }
}
