import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:isar_community/isar.dart';
import 'package:fitrah_launcher/data/isar_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/habit_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (Platform.isLinux) {
      final config =
          jsonDecode(
                await File('.dart_tool/package_config.json').readAsString(),
              )
              as Map<String, dynamic>;
      final package = (config['packages'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['name'] == 'isar_community_flutter_libs');
      final root = Uri.parse(package['rootUri'] as String);
      await Isar.initializeIsarCore(
        libraries: {ffi.Abi.current(): '${root.path}/linux/libisar.so'},
      );
    }
  });
  for (final native in [false, true]) {
    group(native ? 'native' : 'preview', () {
      late SadarRepository repo;
      Isar? db;
      Directory? directory;
      setUp(() async {
        if (native) {
          directory = await Directory.systemTemp.createTemp('habit_actions_');
          db = (await IsarService.openAt(directory!.path)).isar!;
        }
        repo = SadarRepository(db);
        await repo.upsertHabit(
          Habit()
            ..id = 1
            ..name = 'Timed'
            ..target = 45
            ..createdAt = DateTime.now()
            ..colorValue = 0,
        );
      });
      tearDown(() async {
        await db?.close();
        await directory?.delete(recursive: true);
      });
      test(
        'manual changes preserve exact evidence and explicit durations stay supported',
        () async {
          const date = '2026-11-07';
          final before = await repo.recordEntryStatus(
            habitId: 1,
            dateString: date,
            status: HabitStatus.unmarked,
            targetSnapshot: 45,
            actualDurationMinutes: 8,
            source: 'timer',
            note: 'keep',
          );
          before.actualDurationSeconds = 480;
          if (native) await db!.writeTxn(() => db!.habitEntrys.put(before));
          final updated = await repo.recordEntryStatus(
            habitId: 1,
            dateString: date,
            status: HabitStatus.yes,
            valueCompleted: 1,
            targetSnapshot: 99,
          );
          expect(updated.actualDurationSeconds, 480);
          expect(updated.actualDurationMinutes, 8);
          expect(updated.targetSnapshot, 45);
          expect(updated.note, 'keep');
          await repo.updateHabitEntryNote(
            habitId: 1,
            dateString: date,
            note: 'new note',
          );
          final explicit = await repo.recordEntryStatus(
            habitId: 1,
            dateString: date,
            status: HabitStatus.skip,
            actualDurationMinutes: 12,
          );
          expect(explicit.actualDurationMinutes, 12);
          expect(explicit.actualDurationSeconds, 480);
          if (native) {
            await db!.close();
            db = (await IsarService.openAt(directory!.path)).isar!;
            repo = SadarRepository(db);
          }
          final persisted = (await repo.getEntriesForDateRange(
            date,
            date,
          )).single;
          expect(persisted.note, 'new note');
          expect(persisted.actualDurationSeconds, 480);
          expect(persisted.targetSnapshot, 45);
        },
      );
      test('count increments are atomic and validate live habit', () async {
        final habit = Habit()
          ..name = 'Same name'
          ..habitType = 'count'
          ..unit = HabitUnit.count
          ..target = 10
          ..createdAt = DateTime.now()
          ..colorValue = 0;
        final id = await repo.upsertHabit(habit);
        await Future.wait(
          List.generate(
            10,
            (_) => repo.incrementHabitCount(
              habitId: id,
              dateString: '2026-11-09',
              delta: 1,
            ),
          ),
        );
        final entry = (await repo.getEntriesForDateRange(
          '2026-11-09',
          '2026-11-09',
        )).single;
        expect(entry.valueCompleted, 10);
        expect(entry.actualDurationMinutes, 0);
        await repo.deleteHabit(id);
        await expectLater(
          repo.setHabitCount(habitId: id, dateString: '2026-11-09', value: 1),
          throwsStateError,
        );
        await expectLater(
          repo.updateHabitEntryNote(
            habitId: 99999,
            dateString: '2026-11-09',
            note: 'missing',
          ),
          throwsStateError,
        );
      });
      test('manual status never infers time from target or count', () async {
        final entry = await repo.recordEntryStatus(
          habitId: 1,
          dateString: '2026-11-09',
          status: HabitStatus.yes,
          valueCompleted: 10,
        );
        expect(entry.actualDurationMinutes, 0);
        expect(entry.actualDurationSeconds, 0);
      });
      for (final status in [
        HabitStatus.unmarked,
        HabitStatus.yes,
        HabitStatus.skip,
      ]) {
        test(
          'note write/clear preserves all existing $status evidence',
          () async {
            const date = '2026-11-06';
            final original = await repo.recordEntryStatus(
              habitId: 1,
              dateString: date,
              status: status,
              valueCompleted: 8,
              targetSnapshot: 45,
              actualDurationMinutes: 8,
              source: 'timer',
              completedAt: DateTime(2026, 11, 6, 8),
            );
            original.actualDurationSeconds = 480;
            if (native) await db!.writeTxn(() => db!.habitEntrys.put(original));
            for (final note in ['reflection', '']) {
              final updated = await repo.updateHabitEntryNote(
                habitId: 1,
                dateString: date,
                note: note,
              );
              expect(updated.note, note);
              expect(updated.status, status);
              expect(updated.valueCompleted, 8);
              expect(updated.targetSnapshot, 45);
              expect(updated.actualDurationMinutes, 8);
              expect(updated.actualDurationSeconds, 480);
              expect(updated.source, 'timer');
              expect(updated.completedAt, DateTime(2026, 11, 6, 8));
            }
          },
        );
      }
      test('notes alone do not complete or change existing evidence', () async {
        final entry = await repo.updateHabitEntryNote(
          habitId: 1,
          dateString: '2026-11-09',
          note: 'draft',
        );
        expect(entry.status, HabitStatus.unmarked);
        expect(entry.targetSnapshot, 0);
        final original = await repo.recordEntryStatus(
          habitId: 1,
          dateString: '2026-11-08',
          status: HabitStatus.skip,
          actualDurationMinutes: 8,
          targetSnapshot: 45,
          source: 'timer',
        );
        final updated = await repo.updateHabitEntryNote(
          habitId: 1,
          dateString: '2026-11-08',
          note: '',
        );
        expect(updated.status, HabitStatus.skip);
        expect(updated.actualDurationMinutes, 8);
        expect(updated.actualDurationSeconds, 0);
        expect(updated.source, 'timer');
        expect(updated.targetSnapshot, 45);
        expect(updated.completedAt, original.completedAt);
      });
      test(
        'absolute counts retain frozen target and legacy measured evidence',
        () async {
          final h = Habit()
            ..name = 'Count'
            ..habitType = 'count'
            ..unit = HabitUnit.count
            ..target = 10
            ..createdAt = DateTime.now()
            ..colorValue = 0;
          final id = await repo.upsertHabit(h);
          await repo.recordEntryStatus(
            habitId: id,
            dateString: '2026-11-09',
            status: HabitStatus.unmarked,
            targetSnapshot: 10,
            actualDurationMinutes: 8,
            source: 'timer',
          );
          h.target = 2;
          await repo.upsertHabit(h);
          var entry = await repo.setHabitCount(
            habitId: id,
            dateString: '2026-11-09',
            value: 3,
          );
          expect(entry.status, HabitStatus.unmarked);
          expect(entry.targetSnapshot, 10);
          expect(entry.actualDurationMinutes, 8);
          expect(entry.actualDurationSeconds, 480);
          entry = await repo.incrementHabitCount(
            habitId: id,
            dateString: '2026-11-09',
            delta: 7,
          );
          expect(entry.valueCompleted, 10);
          expect(entry.status, HabitStatus.yes);
          for (final value in [-1, 10000]) {
            await expectLater(
              repo.setHabitCount(
                habitId: id,
                dateString: '2026-11-09',
                value: value,
              ),
              throwsArgumentError,
            );
          }
        },
      );
    });
  }
}
