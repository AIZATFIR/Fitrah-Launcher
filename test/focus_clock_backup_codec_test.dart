import 'package:fitrah_launcher/domain/focus_intent.dart';
import 'package:fitrah_launcher/models/focus_intent_document.dart';
import 'dart:convert';
import 'package:fitrah_launcher/data/store/live_model_codec.dart';

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
import 'package:fitrah_launcher/models/terminal_focus_session.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FocusClockBackupCodec', () {
    test('legacy backup without icon preference keeps visible icons', () {
      final root =
          jsonDecode(utf8.decode(FocusClockBackupCodec.encode(_sampleData())))
              as Map<String, dynamic>;
      (root['data']['launcherSettings'] as Map).remove('showAppIcons');
      _refreshChecksum(root);
      final decoded = FocusClockBackupCodec.decode(
        utf8.encode(jsonEncode(root)),
      );
      expect(decoded.data.launcherSettings.showAppIcons, isTrue);
      expect(decoded.data.launcherSettings.autoFocusSearch, isTrue);
    });

    test(
      'live records preserve links and decode absent legacy fields as null',
      () {
        final data = _sampleData();
        final activity = data.activities.single
          ..habitId = data.habits.single.id;
        final session = data.timerSessions.single..habitTargetSnapshot = 45;
        final activityRow = Map<String, dynamic>.from(
          LiveModelCodec.encode(activity),
        );
        final sessionRow = Map<String, dynamic>.from(
          LiveModelCodec.encode(session),
        );
        expect(
          LiveModelCodec.decode<Activity>(activityRow).habitId,
          activity.habitId,
        );
        expect(
          LiveModelCodec.decode<TimerSession>(sessionRow).habitTargetSnapshot,
          45,
        );
        (activityRow['data'] as Map).remove('habitId');
        (sessionRow['data'] as Map).remove('habitTargetSnapshot');
        expect(LiveModelCodec.decode<Activity>(activityRow).habitId, isNull);
        expect(
          LiveModelCodec.decode<TimerSession>(sessionRow).habitTargetSnapshot,
          isNull,
        );
      },
    );

    test('v5 keeps session history; v1-v4 remain compatible', () {
      final data = _sampleData();
      data.activities.single.habitId = data.habits.single.id;
      data.timerSessions.single.habitId = data.habits.single.id;
      data.timerSessions.single.habitTargetSnapshot = 45;
      final bytes = FocusClockBackupCodec.encode(data);
      final decoded = FocusClockBackupCodec.decode(bytes);
      expect(decoded.formatVersion, 5);
      expect(decoded.data.activities.single.habitId, data.habits.single.id);
      expect(decoded.data.timerSessions.single.habitTargetSnapshot, 45);
      for (final version in [1, 2, 3, 4]) {
        final root = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        root['formatVersion'] = version;
        root['data']['activities'][0].remove('habitId');
        root['data']['timerSessions'][0].remove('habitTargetSnapshot');
        root['data'].remove('terminalFocusSessions');
        _refreshChecksum(root);
        final old = FocusClockBackupCodec.decode(utf8.encode(jsonEncode(root)));
        expect(old.data.activities.single.habitId, isNull);
        expect(old.data.timerSessions.single.habitTargetSnapshot, isNull);
        expect(old.data.terminalFocusSessions, isEmpty);
      }
      data.activities.single.habitId = -1;
      expect(() => FocusClockBackupCodec.encode(data), throwsFormatException);
      data.activities.single.habitId = 999999;
      data.timerSessions.single.habitTargetSnapshot = 0;
      expect(() => FocusClockBackupCodec.encode(data), throwsFormatException);
      data.timerSessions.single.habitTargetSnapshot = 45;
      data.timerSessions.single.habitId = 0;
      expect(() => FocusClockBackupCodec.encode(data), throwsFormatException);
    });

    test(
      'round-trips supported records and preserves IDs and exact seconds',
      () {
        final data = _sampleData();
        final decoded = FocusClockBackupCodec.decode(
          FocusClockBackupCodec.encode(data),
        );

        final intent = IntentState.decode(
          decoded.data.intentDocuments.single.payload,
        );
        expect(intent.sourceStoreId, '11111111-1111-4111-8111-111111111111');
        expect(intent.pinnedGoal!.title, 'Long direction');
        expect(
          intent.selectionFor('2026-11-05')!.sourceId,
          intent.sources.single.id,
        );
        expect(decoded.data.counts['Tujuan dan pilihan'], 1);
        expect(decoded.data.activities.single.id, 17);
        expect(decoded.data.habits.single.id, 23);
        expect(decoded.data.habitEntries.single.actualDurationSeconds, 91);
        expect(decoded.data.appSettings.single.id, 0);
        expect(decoded.data.timerSessions.single.id, 1);
        expect(decoded.data.launcherSettings.focusGoal, 'Menang LKS nasional');
        expect(decoded.data.launcherSettings.showAppIcons, isFalse);
        expect(decoded.data.launcherSettings.autoFocusSearch, isTrue);
        expect(decoded.data.dailyReflections.single.note, 'private note');
        expect(
          decoded.formatVersion,
          FocusClockBackupCodec.currentFormatVersion,
        );
      },
    );

    test(
      'v5 round-trips terminal ledger and rejects duplicate session UUIDs',
      () {
        final base = _sampleData();
        TerminalFocusSession row() => TerminalFocusSession()
          ..id = 41
          ..sessionId = 'stable-session-id'
          ..sourceKind = 'free'
          ..titleSnapshot = 'Focus snapshot'
          ..goalId = '22222222-2222-4222-8222-222222222222'
          ..goalTitleSnapshot = 'Win nationals'
          ..startedAt = DateTime.utc(2026, 11, 5, 9)
          ..completedAt = DateTime.utc(2026, 11, 5, 9, 15)
          ..actualDurationSeconds = 900
          ..status = TerminalSessionStatus.completed;
        final data = FocusClockBackupData(
          presets: base.presets,
          activities: base.activities,
          appSettings: base.appSettings,
          tasks: base.tasks,
          habits: base.habits,
          habitEntries: base.habitEntries,
          dailyReflections: base.dailyReflections,
          timerSessions: base.timerSessions,
          launcherSettings: base.launcherSettings,
          intentDocuments: base.intentDocuments,
          terminalFocusSessions: [row()],
        );
        final restored = FocusClockBackupCodec.decode(
          FocusClockBackupCodec.encode(data),
        ).data.terminalFocusSessions.single;
        expect(restored.sessionId, 'stable-session-id');
        expect(restored.actualDurationSeconds, 900);
        expect(restored.goalId, '22222222-2222-4222-8222-222222222222');
        expect(restored.goalTitleSnapshot, 'Win nationals');
      final missingLedger = jsonDecode(
        utf8.decode(FocusClockBackupCodec.encode(base)),
      ) as Map<String, dynamic>;
      (missingLedger['data'] as Map<String, dynamic>).remove('terminalFocusSessions');
      _refreshChecksum(missingLedger);
      expect(
        () => FocusClockBackupCodec.decode(utf8.encode(jsonEncode(missingLedger))),
        throwsFormatException,
      );
        final duplicate = FocusClockBackupData(
          presets: data.presets,
          activities: data.activities,
          appSettings: data.appSettings,
          tasks: data.tasks,
          habits: data.habits,
          habitEntries: data.habitEntries,
          dailyReflections: data.dailyReflections,
          timerSessions: data.timerSessions,
          launcherSettings: data.launcherSettings,
          intentDocuments: data.intentDocuments,
          terminalFocusSessions: [row(), row()..id = 42],
        );
        expect(
          () => FocusClockBackupCodec.encode(duplicate),
          throwsFormatException,
        );
      },
    );

    test('v1 imports without notes and v2 preserves and validates notes', () {
      final root =
          jsonDecode(utf8.decode(FocusClockBackupCodec.encode(_sampleData())))
              as Map<String, dynamic>;
      root['data']['launcherSettings']['dailyNotes'] = {
        '2026-11-07': 'Exact\ntext',
      };
      _refreshChecksum(root);
      final decoded = FocusClockBackupCodec.decode(
        utf8.encode(jsonEncode(root)),
      );
      expect(
        decoded.data.launcherSettings.dailyNotes['2026-11-07'],
        'Exact\ntext',
      );
      root['data']['launcherSettings']['dailyNotes'] = {'2026-02-30': 'bad'};
      _refreshChecksum(root);
      expect(
        () => FocusClockBackupCodec.decode(utf8.encode(jsonEncode(root))),
        throwsFormatException,
      );
      root['formatVersion'] = 1;
      root['data']['launcherSettings'].remove('dailyNotes');
      _refreshChecksum(root);
      expect(
        FocusClockBackupCodec.decode(
          utf8.encode(jsonEncode(root)),
        ).data.launcherSettings.dailyNotes,
        isEmpty,
      );
    });

    test(
      'v1/v2 without intent remain readable; v3 requires validated intent',
      () {
        final root =
            jsonDecode(utf8.decode(FocusClockBackupCodec.encode(_sampleData())))
                as Map<String, dynamic>;
        root['data'].remove('intentDocuments');
        for (final version in [1, 2]) {
          root['formatVersion'] = version;
          _refreshChecksum(root);
          expect(
            FocusClockBackupCodec.decode(
              utf8.encode(jsonEncode(root)),
            ).data.intentDocuments,
            isEmpty,
          );
        }
        root['formatVersion'] = 3;
        _refreshChecksum(root);
        expect(
          () => FocusClockBackupCodec.decode(utf8.encode(jsonEncode(root))),
          throwsFormatException,
        );
        root['data']['intentDocuments'] = [
          {
            'id': 1,
            'state': {'version': 999},
          },
        ];
        _refreshChecksum(root);
        expect(
          () => FocusClockBackupCodec.decode(utf8.encode(jsonEncode(root))),
          throwsFormatException,
        );
      },
    );

    test('backup collection lists cannot be structurally mutated', () {
      final data = _sampleData();
      expect(() => data.habits.add(Habit()), throwsA(isA<UnsupportedError>()));
    });

    test('omits credentials and potentially credential-bearing endpoint', () {
      final bytes = FocusClockBackupCodec.encode(_sampleData());
      final text = utf8.decode(bytes);

      expect(text, isNot(contains('secret-api-key')));
      expect(text, isNot(contains('private-token-in-url')));
      expect(text, isNot(contains('api.example')));
    });

    test('rejects checksum mismatch and unsupported future version', () {
      final source =
          jsonDecode(utf8.decode(FocusClockBackupCodec.encode(_sampleData())))
              as Map<String, dynamic>;
      source['data']['habits'][0]['name'] = 'tampered';
      expect(
        () => FocusClockBackupCodec.decode(utf8.encode(jsonEncode(source))),
        throwsA(isA<FormatException>()),
      );

      source['formatVersion'] = FocusClockBackupCodec.currentFormatVersion + 1;
      expect(
        () => FocusClockBackupCodec.decode(utf8.encode(jsonEncode(source))),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
      'rejects duplicate IDs, broken references, and invalid singleton IDs',
      () {
        final bytes = FocusClockBackupCodec.encode(_sampleData());
        final base = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

        final duplicate = jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
        duplicate['data']['habits'].add(duplicate['data']['habits'][0]);
        _refreshChecksum(duplicate);
        expect(
          () =>
              FocusClockBackupCodec.decode(utf8.encode(jsonEncode(duplicate))),
          throwsA(isA<FormatException>()),
        );

        final brokenReference =
            jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
        brokenReference['data']['habitEntries'][0]['habitId'] = 0;
        _refreshChecksum(brokenReference);
        expect(
          () => FocusClockBackupCodec.decode(
            utf8.encode(jsonEncode(brokenReference)),
          ),
          throwsA(isA<FormatException>()),
        );

        final invalidSingleton =
            jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
        invalidSingleton['data']['timerSessions'][0]['id'] = 2;
        _refreshChecksum(invalidSingleton);
        expect(
          () => FocusClockBackupCodec.decode(
            utf8.encode(jsonEncode(invalidSingleton)),
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('preserves positive stale IDs used as soft references', () {
      final backup =
          jsonDecode(utf8.decode(FocusClockBackupCodec.encode(_sampleData())))
              as Map<String, dynamic>;
      backup['data']['habitEntries'][0]['habitId'] = 999;
      backup['data']['tasks'][0]['activityId'] = 998;
      _refreshChecksum(backup);

      final decoded = FocusClockBackupCodec.decode(
        utf8.encode(jsonEncode(backup)),
      );

      expect(decoded.data.habitEntries.single.habitId, 999);
      expect(decoded.data.tasks.single.activityId, 998);
    });

    test('rejects impossible dates and invalid task times before restore', () {
      final base =
          jsonDecode(utf8.decode(FocusClockBackupCodec.encode(_sampleData())))
              as Map<String, dynamic>;

      final impossibleDate =
          jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
      impossibleDate['data']['dailyReflections'][0]['dateString'] =
          '2026-02-31';
      _refreshChecksum(impossibleDate);
      expect(
        () => FocusClockBackupCodec.decode(
          utf8.encode(jsonEncode(impossibleDate)),
        ),
        throwsA(isA<FormatException>()),
      );

      final invalidTask = jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
      invalidTask['data']['tasks'][0]['startMinute'] = 720;
      _refreshChecksum(invalidTask);
      expect(
        () =>
            FocusClockBackupCodec.decode(utf8.encode(jsonEncode(invalidTask))),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'normalizes a running timer to paused while preserving elapsed seconds',
      () {
        final now = DateTime.now();
        final data = _sampleData();
        data.timerSessions.single
          ..status = TimerStateStatus.running
          ..accumulatedDurationSeconds = 60
          ..runningSince = now.subtract(const Duration(seconds: 31));

        final decoded = FocusClockBackupCodec.decode(
          FocusClockBackupCodec.encode(data),
        );

        expect(
          decoded.data.timerSessions.single.status,
          TimerStateStatus.paused,
        );
        expect(
          decoded.data.timerSessions.single.accumulatedDurationSeconds,
          greaterThanOrEqualTo(90),
        );
        expect(decoded.data.timerSessions.single.runningSince, isNull);
      },
    );
  });
}

void _refreshChecksum(Map<String, dynamic> root) {
  root['checksum'] = FocusClockBackupCodec.checksumFor(root['data']);
}

FocusClockBackupData _sampleData() {
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
    ..aiApiKey = 'secret-api-key'
    ..aiBaseUrl = 'https://api.example/?token=private-token-in-url';
  final timer = TimerSession()..updatedAt = DateTime.utc(2026, 11, 5);

  return FocusClockBackupData(
    intentDocuments: [
      FocusIntentDocument()
        ..payload = IntentState(
          sourceStoreId: '11111111-1111-4111-8111-111111111111',
          legacyImported: true,
          goals: [
            const IntentGoal(
              id: '22222222-2222-4222-8222-222222222222',
              title: 'Long direction',
              pinned: true,
            ),
          ],
          sources: [
            const IntentSource(
              id: '33333333-3333-4333-8333-333333333333',
              sourceStoreId: '11111111-1111-4111-8111-111111111111',
              type: IntentSourceType.habit,
              legacyId: 23,
            ),
          ],
          links: [
            const IntentLink(
              sourceId: '33333333-3333-4333-8333-333333333333',
              goalId: '22222222-2222-4222-8222-222222222222',
            ),
          ],
          selections: [
            TodaySelection(
              localDate: '2026-11-05',
              sourceId: '33333333-3333-4333-8333-333333333333',
              chosenAtUtc: DateTime.utc(2026, 11, 5),
            ),
          ],
        ).encode(),
    ],
    presets: [preset],
    activities: [activity],
    appSettings: [settings],
    tasks: [task],
    habits: [habit],
    habitEntries: [entry],
    dailyReflections: [reflection],
    timerSessions: [timer],
    launcherSettings: LauncherSettings(
      focusGoal: 'Menang LKS nasional',
      showAppIcons: false,
      autoFocusSearch: true,
    ),
  );
}
