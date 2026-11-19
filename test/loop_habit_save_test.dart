import 'dart:async';

import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/features/launcher/widgets/loop_habit_grid_widget.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailOnceRepository extends SadarRepository {
  _FailOnceRepository() : super(null);
  bool failNext = true;

  @override
  Future<int> upsertHabit(Habit habit) async {
    if (failNext) {
      failNext = false;
      throw StateError('storage unavailable');
    }
    return super.upsertHabit(habit);
  }
}

class _PendingRepository extends SadarRepository {
  _PendingRepository() : super(null);
  final pending = Completer<void>();
  int writes = 0;

  @override
  Future<int> upsertHabit(Habit habit) async {
    writes++;
    await pending.future;
    return super.upsertHabit(habit);
  }
}

void main() {
  testWidgets('habit save failure keeps input for a successful retry', (
    tester,
  ) async {
    final repo = _FailOnceRepository();
    for (final habit in await repo.getHabits()) {
      await repo.deleteHabit(habit.id, hardDelete: true);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sadarRepoProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: LoopHabitGridWidget()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Tambah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Latihan LKS');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Belum tersimpan. Coba lagi.'), findsOneWidget);
    expect(find.text('Latihan LKS'), findsOneWidget);
    expect(await repo.getHabits(), isEmpty);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect((await repo.getHabits()).single.name, 'Latihan LKS');
    expect(find.text('Habit baru'), findsNothing);
  });

  testWidgets(
    'pending save keeps the editor open and cannot be submitted twice',
    (tester) async {
      final repo = _PendingRepository();
      for (final habit in await repo.getHabits()) {
        await repo.deleteHabit(habit.id, hardDelete: true);
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sadarRepoProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: LoopHabitGridWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Tambah'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Latihan LKS');
      await tester.tap(find.text('Simpan'));
      await tester.pump();
      expect(find.text('Menyimpan…'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Kebiasaan baru'), findsOneWidget);
      expect(repo.writes, 1);

      repo.pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Kebiasaan baru'), findsNothing);
      expect((await repo.getHabits()).single.name, 'Latihan LKS');
    },
  );
}
