@TestOn('browser')
library;

import 'dart:async';
import 'package:drift/wasm.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;
import 'package:focus_clock_web_storage_spike/browser_store.dart';
import 'package:focus_clock_web_storage_spike/store.dart';

void main() {
  late String name;
  final connections = <SpikeStore>[];
  Future<SpikeStore> open() async {
    final result = await openStore(name);
    requireSafeStorage(result.mode);
    print(
      'backend=${result.mode.name}; userAgent=${web.window.navigator.userAgent}',
    );
    connections.add(result.db);
    return result.db;
  }

  setUp(() {
    name = '$databasePrefix${DateTime.now().microsecondsSinceEpoch}';
  });
  tearDown(() async {
    for (final db in connections) {
      await db.close();
    }
    connections.clear();
    await deleteStore(name);
    expect(
      (await probe(name)).existingDatabases.where((db) => db.$2 == name),
      isEmpty,
    );
  });
  Future<void> close(SpikeStore db) async {
    await db.close();
    connections.remove(db);
  }

  test('running live fixtures survive close and reopen exactly', () async {
    var db = await open();
    await db.seed();
    await db.start('session-73');
    final activity = await db.select(db.activities).getSingle();
    final habit = await db.select(db.habits).getSingle();
    final settings = await db.select(db.settings).getSingle();
    final timer = await db.select(db.sessions).getSingle();
    await close(db);
    db = await open();
    expect(await db.select(db.activities).getSingle(), activity);
    expect(await db.select(db.habits).getSingle(), habit);
    expect(await db.select(db.settings).getSingle(), settings);
    expect(await db.select(db.sessions).getSingle(), timer);
    expect(timer.status, 'running');
    expect(timer.actualSeconds, 67);
    expect(timer.localDate, '2026-11-06');
    expect(settings.goal, 'Baca 20 halaman — tujuan 🌱');
    expect(settings.credential, 'SYNTHETIC-NON-SECRET');
    await db.complete();
    final entry = await db.select(db.entries).getSingle();
    await close(db);
    db = await open();
    expect(await db.select(db.entries).getSingle(), entry);
    expect(entry.actualSeconds, 67);
    expect(entry.localDate, '2026-11-06');
    expect(entry.habitId, habit.id);
    expect(entry.sessionId, timer.sessionId);
  });

  test(
    'completion commits atomically and repeated completion is idempotent',
    () async {
      var db = await open();
      await db.seed();
      await db.start('completion');
      await db.complete();
      await db.complete();
      await close(db);
      db = await open();
      expect(await db.snapshot(), {
        'activities': 1,
        'completed': 1,
        'entries': 1,
        'sessions': 0,
      });
    },
  );

  test(
    'injected failure preserves activity evidence and timer after reopen',
    () async {
      var db = await open();
      await db.seed();
      await db.start('rollback');
      final before = await db.snapshot();
      final activity = await db.select(db.activities).getSingle();
      final timer = await db.select(db.sessions).getSingle();
      await expectLater(db.complete(injectFailure: true), throwsStateError);
      await close(db);
      db = await open();
      expect(await db.snapshot(), before);
      expect(await db.select(db.activities).getSingle(), activity);
      expect(await db.select(db.sessions).getSingle(), timer);
      await db.complete();
      expect((await db.select(db.entries).getSingle()).actualSeconds, 67);
    },
  );

  test(
    'two independent same-page clients race with one winner and no orphan',
    () async {
      final a = await open();
      await a.seed();
      final b = await open();
      // Force both independent Drift connections to be ready before the race.
      await b.snapshot();
      final failures = <Object>[];
      Future<bool> start(SpikeStore db, String id) async {
        try {
          await db.start(id);
          return true;
        } catch (error) {
          failures.add(error);
          return false;
        }
      }

      final results = await Future.wait([start(a, 'a'), start(b, 'b')]);
      expect(results.where((won) => won), hasLength(1));
      expect(failures, hasLength(1));
      expect(
        failures.single.toString(),
        contains('UNIQUE constraint failed: sessions.id'),
      );
      await close(a);
      await close(b);
      final reopened = await open();
      expect(await reopened.snapshot(), {
        'activities': 1,
        'completed': 0,
        'entries': 0,
        'sessions': 1,
      });
      final session = await reopened.select(reopened.sessions).getSingle();
      expect(
        (await reopened.select(reopened.activities).getSingle()).id,
        session.activityId,
      );
    },
  );

  test(
    'watcher sees only committed snapshots from another connection',
    () async {
      final db = await open();
      await db.seed();
      await db.start('watch');
      final writer = await open();
      await writer.snapshot();
      final observed = <Map<String, dynamic>>[];
      final first = Completer<void>();
      final completed = Completer<void>();
      final subscription = db.snapshotQuery().watchSingle().listen(
        (row) {
          observed.add(row.data);
          if (!first.isCompleted) first.complete();
          if (row.data['completed'] == 1 && !completed.isCompleted)
            completed.complete();
        },
        onError: (Object error, StackTrace stack) {
          fail('Watcher failed: $error\n$stack');
        },
      );
      addTearDown(subscription.cancel);
      await first.future.timeout(const Duration(seconds: 5));
      await expectLater(writer.complete(injectFailure: true), throwsStateError);
      // Bounded observation window detects erroneous rollback notifications.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(
        observed.every(
          (s) => s['completed'] == 0 && s['entries'] == 0 && s['sessions'] == 1,
        ),
        isTrue,
      );
      await writer.complete();
      await completed.future.timeout(const Duration(seconds: 5));
      expect(observed.last, {
        'activities': 1,
        'completed': 1,
        'entries': 1,
        'sessions': 0,
      });
      expect(
        observed.every(
          (s) =>
              (s['completed'] == 0 &&
                  s['entries'] == 0 &&
                  s['sessions'] == 1) ||
              (s['completed'] == 1 && s['entries'] == 1 && s['sessions'] == 0),
        ),
        isTrue,
      );
      await subscription.cancel();
    },
  );

  test('unsafe capabilities are rejected before any opener can write', () {
    for (final mode in [
      WasmStorageImplementation.inMemory,
      WasmStorageImplementation.unsafeIndexedDb,
    ]) {
      expect(
        () => requireSafeStorage(mode),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'actionable error',
            contains('SharedWorker'),
          ),
        ),
      );
    }
  });
}
