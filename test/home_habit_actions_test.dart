import 'dart:async';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/features/launcher/widgets/loop_habit_grid_widget.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/habit_entry.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class ActionRepository extends SadarRepository {
  ActionRepository() : super(null);
  bool fail = false;
  Completer<void>? pending;
  int writes = 0;
  Future<void> gate() async {
    writes++;
    await pending?.future;
    if (fail) {
      fail = false;
      throw StateError('storage unavailable');
    }
  }

  @override
  Future<HabitEntry> updateHabitEntryNote({
    required int habitId,
    required String dateString,
    required String note,
  }) async {
    await gate();
    return super.updateHabitEntryNote(
      habitId: habitId,
      dateString: dateString,
      note: note,
    );
  }

  @override
  Future<HabitEntry> setHabitCount({
    required int habitId,
    required String dateString,
    required int value,
  }) async {
    await gate();
    return super.setHabitCount(
      habitId: habitId,
      dateString: dateString,
      value: value,
    );
  }

  @override
  Future<HabitEntry> recordEntryStatus({
    required int habitId,
    required String dateString,
    required HabitStatus status,
    int? valueCompleted,
    int? targetSnapshot,
    int? actualDurationMinutes,
    bool preserveDuration = false,
    String? source,
    DateTime? completedAt,
    String? note,
  }) async {
    await gate();
    return super.recordEntryStatus(
      habitId: habitId,
      dateString: dateString,
      status: status,
      valueCompleted: valueCompleted,
      targetSnapshot: targetSnapshot,
      actualDurationMinutes: actualDurationMinutes,
      preserveDuration: preserveDuration,
      source: source,
      completedAt: completedAt,
      note: note,
    );
  }
}

void main() {
  Future<Habit> seed(
    ActionRepository repo, {
    HabitUnit unit = HabitUnit.min,
    String type = 'timed',
    String name = 'Habit',
  }) async {
    for (final h in await repo.getHabits()) {
      await repo.deleteHabit(h.id, hardDelete: true);
    }
    final habit = Habit()
      ..name = name
      ..habitType = type
      ..unit = unit
      ..target = 10
      ..createdAt = DateTime.now()
      ..colorValue = 0;
    await repo.upsertHabit(habit);
    return habit;
  }

  Future<void> mount(
    WidgetTester tester,
    ActionRepository repo, {
    void Function(Habit)? timer,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sadarRepoProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 1800),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: LoopHabitGridWidget(onStartTimer: timer),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expand(WidgetTester tester) async {
    // The seven weekly cells are the only GestureDetectors with a 32dp container.
    final cells = find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.maxHeight == 32,
    );
    await tester.tap(cells.first);
    await tester.pumpAndSettle();
  }

  Future<void> expandToday(WidgetTester tester) async {
    final cells = find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.maxHeight == 32,
    );
    await tester.tap(cells.at(DateTime.now().weekday - 1));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'only timed/min with callback offers Play; historical selection cannot start',
    (tester) async {
      final repo = ActionRepository();
      final h = await seed(repo);
      final started = <int>[];
      await mount(tester, repo, timer: (h) => started.add(h.id));
      await tester.tap(find.byTooltip('Mulai di Focus Clock'));
      expect(started, [h.id]);
      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
      await tester.pumpAndSettle();
      await expand(tester);
      expect(find.byTooltip('Mulai di Focus Clock'), findsNothing);
      expect(find.text('Mulai fokus'), findsNothing);
      await mount(tester, repo);
      expect(find.byTooltip('Mulai di Focus Clock'), findsNothing);
    },
  );
  testWidgets(
    'non-today selection hides every collapsed row Play within current week',
    (tester) async {
      final repo = ActionRepository();
      await seed(repo);
      await repo.upsertHabit(
        Habit()
          ..name = 'Second timed habit'
          ..target = 10
          ..createdAt = DateTime.now()
          ..colorValue = 0,
      );
      await mount(
        tester,
        repo,
        timer: (_) => fail('non-today selection started timer'),
      );
      expect(find.byTooltip('Mulai di Focus Clock'), findsNWidgets(2));
      // Always choose a different day, including a future day when today is Monday.
      final differentDay = DateTime.now().weekday % 7;
      await tester.tap(
        find.text(
          ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][differentDay],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mulai di Focus Clock'), findsNothing);
      final cells = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxHeight == 32,
      );
      await tester.tap(cells.at(differentDay));
      await tester.pumpAndSettle();
      expect(find.text('Catatan'), findsOneWidget);
      expect(find.byTooltip('Mulai di Focus Clock'), findsNothing);
      expect(find.text('Mulai fokus'), findsNothing);
    },
  );
  testWidgets('count validates, retains failed input, and retries same ID/date', (
    tester,
  ) async {
    final repo = ActionRepository();
    final h = await seed(repo, unit: HabitUnit.count);
    await repo.upsertHabit(
      Habit()
        ..name = h.name
        ..habitType = 'count'
        ..unit = HabitUnit.count
        ..target = 10
        ..createdAt = DateTime.now()
        ..colorValue = 0,
    );
    await mount(tester, repo, timer: (_) => fail('count started timer'));
    expect(find.byTooltip('Mulai di Focus Clock'), findsNothing);
    await expand(tester);
    await tester.tap(find.text('Catat jumlah'));
    await tester.pumpAndSettle();
    for (final invalid in ['-1', '1.5', '10000']) {
      await tester.enterText(find.byType(TextField), invalid);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Masukkan jumlah'), findsOneWidget);
    }
    repo.fail = true;
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('storage unavailable'), findsOneWidget);
    repo.pending = Completer<void>();
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(repo.writes, 2);
    repo.pending!.complete();
    await tester.pumpAndSettle();
    final entries = await repo.getEntriesForDateRange(
      '2000-01-01',
      '2100-01-01',
    );
    expect(entries.single.habitId, h.id);
    expect(entries.single.valueCompleted, 3);
    expect(entries.single.status, HabitStatus.unmarked);
    expect(entries.single.actualDurationMinutes, 0);
    final selected = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    expect(
      entries.single.dateString,
      '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}',
    );
    await tester.tap(find.text('Catat jumlah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '10');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    final fulfilled = (await repo.getEntriesForDateRange(
      '2000-01-01',
      '2100-01-01',
    )).single;
    expect(fulfilled.id, entries.single.id);
    expect(fulfilled.status, HabitStatus.yes);
  });
  testWidgets(
    'pending note blocks dismiss/duplicate; failed note keeps draft and retry does not complete',
    (tester) async {
      final repo = ActionRepository();
      await seed(repo);
      await mount(tester, repo);
      await expand(tester);
      await tester.tap(find.text('Catatan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Keep this note');
      repo.pending = Completer<void>();
      repo.fail = true;
      await tester.tap(find.text('Simpan'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(repo.writes, 1);
      repo.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Keep this note'), findsOneWidget);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      final entry = (await repo.getEntriesForDateRange(
        '2000-01-01',
        '2100-01-01',
      )).single;
      expect(entry.status, HabitStatus.unmarked);
      expect(entry.note, 'Keep this note');
      expect(entry.actualDurationSeconds, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('binary status failure is recoverable and never optimistic', (
    tester,
  ) async {
    final repo = ActionRepository();
    await seed(repo, unit: HabitUnit.binary);
    await mount(tester, repo, timer: (_) => fail('binary started timer'));
    await expand(tester);
    repo.fail = true;
    repo.pending = Completer<void>();
    await tester.tap(find.text('Tandai dilakukan'));
    await tester.pump();
    await tester.tap(find.text('Tandai dilakukan'));
    await tester.pump();
    expect(repo.writes, 1);
    expect(find.text('Batalkan selesai'), findsNothing);
    repo.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum tersimpan'), findsOneWidget);
    expect(find.text('Tandai dilakukan'), findsOneWidget);
    await tester.tap(find.text('Tandai dilakukan'));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan selesai'), findsOneWidget);
    final entry = (await repo.getEntriesForDateRange(
      '2000-01-01',
      '2100-01-01',
    )).single;
    expect(entry.actualDurationMinutes, 0);
    await tester.tap(find.text('Batalkan selesai'));
    await tester.pumpAndSettle();
    final undone = (await repo.getEntriesForDateRange(
      '2000-01-01',
      '2100-01-01',
    )).single;
    expect(undone.id, entry.id);
    expect(undone.status, HabitStatus.unmarked);
    expect(undone.actualDurationMinutes, 0);
    expect(find.text('Tandai dilakukan'), findsOneWidget);
  });
  for (final unit in [HabitUnit.binary, HabitUnit.count]) {
    testWidgets('$unit actions fit at 320dp/200% with accessible hit targets', (
      tester,
    ) async {
      final repo = ActionRepository();
      await seed(
        repo,
        unit: unit,
        name: 'A very long habit name that needs multiple lines',
      );
      tester.view.physicalSize = const Size(320, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, repo, scale: 2);
      await expand(tester);
      final button = find.ancestor(
        of: find.text(
          unit == HabitUnit.binary ? 'Tandai dilakukan' : 'Catat jumlah',
        ),
        matching: find.byType(TextButton),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('hybrid habits start their configured focus session from Home', (
    tester,
  ) async {
    final repo = ActionRepository();
    final habit = await seed(repo, type: 'hybrid');
    final started = <Habit>[];
    await mount(tester, repo, timer: started.add);

    expect(find.byTooltip('Mulai di Focus Clock'), findsOneWidget);
    await tester.tap(find.byTooltip('Mulai di Focus Clock'));
    await tester.pumpAndSettle();
    expect(started.single.id, habit.id);

    await expandToday(tester);
    expect(find.text('Mulai fokus'), findsOneWidget);
    expect(
      find.textContaining('Pencatatan langkah/set belum didukung'),
      findsNothing,
    );
    expect(find.text('Tandai dilakukan'), findsNothing);
    expect(find.text('Tidak dilakukan'), findsNothing);
    expect(find.text('Lewati'), findsNothing);
  });

  testWidgets('progression step can be completed and safely undone from Home', (
    tester,
  ) async {
    final repo = ActionRepository();
    await seed(repo, type: 'progression');
    await mount(tester, repo);
    await expandToday(tester);

    expect(find.text('Catat langkah'), findsOneWidget);
    expect(find.textContaining('Push Up'), findsOneWidget);
    expect(
      find.textContaining('Pencatatan langkah/set belum didukung'),
      findsNothing,
    );

    await tester.tap(find.text('Catat langkah'));
    await tester.pumpAndSettle();
    expect(find.text('Catat langkah hari ini?'), findsOneWidget);
    final date = DateTime.now().toIso8601String().substring(0, 10);
    expect(await repo.getEntriesForDateRange(date, date), isEmpty);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    var entry = (await repo.getEntriesForDateRange(date, date)).single;
    expect(entry.status, HabitStatus.yes);
    expect(entry.progressionCompletionSnapshot?.step.title, 'Push Up');
    expect((await repo.getHabits()).single.currentProgressionIndex, 1);

    await tester.tap(find.text('Batalkan langkah'));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan langkah hari ini?'), findsOneWidget);
    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    entry = (await repo.getEntriesForDateRange(date, date)).single;
    expect(entry.status, HabitStatus.unmarked);
    expect(entry.progressionCompletionSnapshot, isNull);
    expect((await repo.getHabits()).single.currentProgressionIndex, 0);
    expect(find.text('Catat langkah'), findsOneWidget);
  });
}
