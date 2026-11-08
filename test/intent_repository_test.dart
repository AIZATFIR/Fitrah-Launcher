import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrah_launcher/providers/intent_providers.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/features/launcher/providers/launcher_settings_provider.dart';
import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:fitrah_launcher/data/isar_service.dart';
import 'package:fitrah_launcher/data/repositories/intent_repository.dart';
import 'package:fitrah_launcher/data/store/native_focus_store.dart';
import 'package:fitrah_launcher/data/store/live_model_codec.dart';
import 'package:fitrah_launcher/domain/focus_intent.dart';
import 'package:fitrah_launcher/domain/today_intent_projection.dart';
import 'package:fitrah_launcher/models/focus_intent_document.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/habit_entry.dart';
import 'package:fitrah_launcher/models/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (Platform.isLinux) {
      final config =
          jsonDecode(
                await File('.dart_tool/package_config.json').readAsString(),
              )
              as Map<String, dynamic>;
      final pkg = (config['packages'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['name'] == 'isar_community_flutter_libs');
      await Isar.initializeIsarCore(
        libraries: {
          ffi.Abi.current():
              '${Uri.parse(pkg['rootUri'] as String).path}/linux/libisar.so',
        },
      );
    }
  });
  late Directory dir;
  late NativeFocusStore store;
  late IntentRepository repo;
  var now = DateTime(2026, 11, 8, 23, 59);
  setUp(() async {
    now = DateTime(2026, 11, 8, 23, 59);
    dir = await Directory.systemTemp.createTemp('intent_');
    store = NativeFocusStore((await IsarService.openAt(dir.path)).isar!);
    repo = IntentRepository(store, now: () => now);
  });
  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });

  test(
    'legacy import once, edits archive and reopen never resurrect old text',
    () async {
      final first = await repo.importLegacy('Long direction');
      final id = first.goals.single.id;
      expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(id), true);
      await repo.saveGoal(
        id: id,
        title: 'My edit',
        expectedRevision: 1,
        archived: true,
      );
      await store.close();
      store = NativeFocusStore((await IsarService.openAt(dir.path)).isar!);
      repo = IntentRepository(store, now: () => now);
      final reopened = await repo.importLegacy('Long direction');
      expect(reopened.legacyMappings.single.stableId, id);
      expect(reopened.goals.single.id, id);
      expect(reopened.goals.single.title, 'My edit');
      expect(reopened.goals.single.archived, true);
      expect(reopened.pinnedGoal, isNull);
    },
  );

  test(
    'legacy waits for successful hydration and unrelated notes never restart import',
    () async {
      final storage = _SettingsStorage()..gate = Completer<String?>();
      final container = ProviderContainer(
        overrides: [
          focusStoreProvider.overrideWithValue(store),
          secureStorageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      final loaded = container.read(intentStateProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(await store.all<FocusIntentDocument>(), isEmpty);
      storage.gate!.complete(
        LauncherSettings(focusGoal: 'Hydrated direction').toJson(),
      );
      final state = await loaded;
      expect(state.pinnedGoal!.title, 'Hydrated direction');
      final revision = state.revision;
      await container
          .read(launcherSettingsProvider.notifier)
          .setDailyNote('2026-11-08', 'A note');
      await Future<void>.delayed(Duration.zero);
      expect((await repo.read()).revision, revision);
      expect((await repo.read()).legacyMappings.single.legacyId, 'focusGoal');
    },
  );

  test(
    'failed migration preserves legacy preferences and malformed original document',
    () async {
      final storage = _SettingsStorage()
        ..raw = LauncherSettings(focusGoal: 'Keep original cue').toJson();
      await store.writeTxn(
        () => store.put(FocusIntentDocument()..payload = '{"version":999}'),
      );
      final container = ProviderContainer(
        overrides: [
          focusStoreProvider.overrideWithValue(store),
          secureStorageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(intentStateProvider.future),
        throwsFormatException,
      );
      expect(
        LauncherSettings.fromJson(storage.raw!).focusGoal,
        'Keep original cue',
      );
      expect(
        (await store.get<FocusIntentDocument>(1))!.payload,
        '{"version":999}',
      );
    },
  );

  test(
    'independent duplicate titles, pin persists, latest owners preserve independent edits and reject stale',
    () async {
      await repo.read();
      final other = IntentRepository(store, now: () => now);
      final a = IntentRepository.newId(), b = IntentRepository.newId();
      await Future.wait([
        repo.saveGoal(id: a, title: 'Same', pinned: true),
        other.saveGoal(id: b, title: 'Same'),
      ]);
      final state = await repo.read();
      expect(state.goals.length, 2);
      expect(state.pinnedGoal!.id, a);
      await other.saveGoal(
        id: b,
        title: 'Second',
        expectedRevision: 1,
        pinned: true,
      );
      expect((await repo.read()).pinnedGoal!.id, b);
      await expectLater(
        repo.saveGoal(id: a, title: 'Stale', expectedRevision: 1),
        throwsA(isA<IntentConflict>()),
      );
      await expectLater(
        repo.saveGoal(id: IntentRepository.newId(), title: ''),
        throwsFormatException,
      );
      expect((await repo.read()).goals.length, 2);
    },
  );

  test(
    'choice uses exact source identity, retains dates, clear revision and source links after archive',
    () async {
      final habit = Habit()
        ..colorValue = 0xff123456
        ..name = 'Same'
        ..unit = HabitUnit.binary
        ..habitType = 'binary'
        ..createdAt = now;
      final task = Task()
        ..title = 'Same'
        ..createdAt = now;
      await store.writeTxn(() async {
        await store.put(habit);
        await store.put(task);
      });
      final goal = IntentRepository.newId();
      await repo.saveGoal(id: goal, title: 'Goal', pinned: true);
      final day1 = await repo.choose(
        localDate: '2026-11-08',
        type: IntentSourceType.habit,
        legacyId: habit.id,
        goalId: goal,
      );
      final source = day1.sourceFor(day1.selectionFor('2026-11-08')!.sourceId)!;
      habit.name = 'Renamed';
      await store.writeTxn(() => store.put(habit));
      final projection = TodayIntentProjection.calculate(
        state: day1,
        actualDate: '2026-11-08',
        habits: [habit],
        tasks: [task],
        entries: [],
      );
      expect(projection!.title, 'Renamed');
      expect(projection.kind, IntentActionKind.binary);
      now = DateTime(2026, 11, 9);
      expect(
        TodayIntentProjection.calculate(
          state: day1,
          actualDate: '2026-11-09',
          habits: [habit],
          tasks: [task],
          entries: [],
        ),
        isNull,
      );
      await expectLater(repo.choose(localDate: '2026-11-08'), throwsStateError);
      final day2 = await repo.choose(
        localDate: '2026-11-09',
        type: IntentSourceType.habit,
        legacyId: habit.id,
      );
      expect(day2.selections.length, 2);
      expect(day2.selectionFor('2026-11-09')!.sourceId, source.id);
      final cleared = await repo.choose(
        localDate: '2026-11-09',
        expectedRevision: 1,
      );
      expect(cleared.selectionFor('2026-11-09')!.sourceId, isNull);
      await expectLater(
        repo.choose(localDate: '2026-11-09', expectedRevision: 1),
        throwsA(isA<IntentConflict>()),
      );
      await repo.choose(
        localDate: '2026-11-09',
        type: IntentSourceType.habit,
        legacyId: habit.id,
        goalId: goal,
        expectedRevision: 2,
      );
      await repo.saveGoal(
        id: goal,
        title: 'Goal',
        expectedRevision: 1,
        archived: true,
      );
      expect(
        (await repo.read()).selectionFor('2026-11-08')!.sourceId,
        source.id,
      );
      expect(await store.get<Habit>(habit.id), isNotNull);
      await store.close();
      store = NativeFocusStore((await IsarService.openAt(dir.path)).isar!);
      repo = IntentRepository(store, now: () => now);
      final reopened = await repo.read();
      expect(reopened.selectionFor('2026-11-09')!.sourceId, source.id);
      expect(reopened.links.single.goalId, goal);
      expect(reopened.goals.single.archived, true);
    },
  );

  test(
    'source mapping distinguishes separate stores and rejects unavailable references',
    () async {
      final habit = Habit()
        ..colorValue = 0xff123456
        ..name = 'H'
        ..createdAt = now;
      await store.writeTxn(() => store.put(habit));
      final state = await repo.choose(
        localDate: '2026-11-08',
        type: IntentSourceType.habit,
        legacyId: habit.id,
      );
      final external = IntentSource(
        id: IntentRepository.newId(),
        sourceStoreId: IntentRepository.newId(),
        type: IntentSourceType.habit,
        legacyId: habit.id,
      );
      final copy = state.copyWith(
        sources: [...state.sources, external],
        selections: [
          TodaySelection(
            localDate: '2026-11-08',
            sourceId: external.id,
            chosenAtUtc: now.toUtc(),
          ),
        ],
      );
      expect(IntentState.decode(copy.encode()).sources.length, 2);
      expect(
        TodayIntentProjection.calculate(
          state: copy,
          actualDate: '2026-11-08',
          habits: [habit],
          tasks: [],
          entries: [],
        )!.kind,
        IntentActionKind.unavailable,
      );
      habit.isArchived = true;
      await store.writeTxn(() => store.put(habit));
      await expectLater(
        repo.choose(
          localDate: '2026-11-08',
          type: IntentSourceType.habit,
          legacyId: habit.id,
          expectedRevision: 1,
        ),
        throwsStateError,
      );
      await expectLater(
        repo.choose(
          localDate: '2026-11-08',
          type: IntentSourceType.task,
          legacyId: 999,
          expectedRevision: 1,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'unsupported and malformed documents stay intact, transaction rolls back',
    () async {
      await repo.importLegacy('Original');
      final old = (await store.get<FocusIntentDocument>(1))!.payload;
      await expectLater(
        store.writeTxn(() async {
          await store.put(FocusIntentDocument()..payload = 'broken');
          throw StateError('write failed');
        }),
        throwsStateError,
      );
      expect((await store.get<FocusIntentDocument>(1))!.payload, old);
      await store.writeTxn(
        () => store.put(FocusIntentDocument()..payload = '{"version":999}'),
      );
      await expectLater(
        repo.saveGoal(id: IntentRepository.newId(), title: 'New'),
        throwsFormatException,
      );
      expect(
        (await store.get<FocusIntentDocument>(1))!.payload,
        '{"version":999}',
      );
      await expectLater(IntentRepository(null).read(), throwsStateError);
    },
  );

  test(
    'live codec roundtrip preserves aggregate identity and validates nested refs',
    () async {
      final state = await repo.importLegacy('Direction');
      final row = FocusIntentDocument()..payload = state.encode();
      final encoded = LiveModelCodec.encode(row);
      final decoded = LiveModelCodec.decode<FocusIntentDocument>(
        jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
      );
      expect(decoded.payload, row.payload);
      expect(
        LiveModelCodec.collectionFor<FocusIntentDocument>(),
        'FocusIntentDocument',
      );
      final bad = state.toJson();
      bad['links'] = [
        {'sourceId': IntentRepository.newId(), 'goalId': state.goals.single.id},
      ];
      expect(() => IntentState.fromJson(bad), throwsFormatException);
    },
  );

  test(
    'binary/count units and unsupported progression/hybrid project honestly without writes',
    () async {
      final state = await repo.read();
      for (final type in [
        'binary',
        'count',
        'timed',
        'progression',
        'hybrid',
        'unknown',
      ]) {
        final habit = Habit()
          ..id = 1
          ..name = type
          ..habitType = type
          ..unit = (type == 'binary'
              ? HabitUnit.binary
              : type == 'count'
              ? HabitUnit.count
              : HabitUnit.min)
          ..createdAt = now;
        final source = IntentSource(
          id: IntentRepository.newId(),
          sourceStoreId: state.sourceStoreId,
          type: IntentSourceType.habit,
          legacyId: 1,
        );
        final selected = state.copyWith(
          sources: [source],
          selections: [
            TodaySelection(
              localDate: '2026-11-08',
              sourceId: source.id,
              chosenAtUtc: now.toUtc(),
            ),
          ],
        );
        final before = selected.encode();
        final projected = TodayIntentProjection.calculate(
          state: selected,
          actualDate: '2026-11-08',
          habits: [habit],
          tasks: [],
          entries: [],
        )!;
        expect(projected.completed, false);
        expect(projected.kind, switch (type) {
          'binary' => IntentActionKind.binary,
          'count' => IntentActionKind.count,
          'timed' => IntentActionKind.timed,
          _ => IntentActionKind.unsupported,
        });
        final done = HabitEntry()
          ..habitId = 1
          ..dateString = '2026-11-08'
          ..status = HabitStatus.yes
          ..updatedAt = now;
        expect(
          TodayIntentProjection.calculate(
            state: selected,
            actualDate: '2026-11-08',
            habits: [habit],
            tasks: [],
            entries: [done],
          )!.completed,
          true,
        );
        expect(selected.encode(), before);
      }
    },
  );
}

class _SettingsStorage extends SecureStorageService {
  Completer<String?>? gate;
  String? raw;
  @override
  Future<String?> readCustomKey(String key) async =>
      gate == null ? raw : gate!.future;
  @override
  Future<void> writeCustomKey(String key, String value) async {
    raw = value;
  }
}
