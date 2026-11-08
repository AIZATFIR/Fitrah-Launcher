import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/activity.dart';
import '../models/habit.dart';
import '../models/task.dart';
import '../models/habit_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/intent_repository.dart';
import '../domain/focus_intent.dart';
import '../features/launcher/providers/launcher_settings_provider.dart';
import 'providers.dart';

final intentRepositoryProvider = Provider<IntentRepository>(
  (ref) => IntentRepository(ref.watch(focusStoreProvider)),
);
final intentInitializationProvider = FutureProvider<void>((ref) async {
  final store = ref.watch(focusStoreProvider);
  if (store == null || !store.isDurable) {
    throw StateError('Penyimpanan tujuan tidak tersedia.');
  }
  final notifier = ref.read(launcherSettingsProvider.notifier);
  await notifier.hydration;
  if (!notifier.isLoaded) await notifier.reload();
  if (!notifier.isLoaded) {
    throw StateError('Tujuan lama belum dapat dibaca. Coba lagi.');
  }
  await ref
      .read(intentRepositoryProvider)
      .importLegacy(ref.read(launcherSettingsProvider).focusGoal);
});
final intentStateProvider = StreamProvider<IntentState>((ref) async* {
  await ref.watch(intentInitializationProvider.future);
  yield* ref.watch(intentRepositoryProvider).watch();
});

/// The actual date never follows currentDateProvider's historical browsing.
final actualIntentDateProvider = Provider.autoDispose<String>((ref) {
  final now = ref.watch(intentNowProvider);
  return intentLocalDate(now);
});

final intentSourceDataProvider = StreamProvider<IntentSourceData>((ref) async* {
  final db = ref.watch(focusStoreProvider);
  if (db == null || !db.isDurable) {
    throw StateError('Penyimpanan tidak tersedia.');
  }
  Future<IntentSourceData> read() => db.txn(
    () async => IntentSourceData(
      await db.habits.all(),
      await db.tasks.all(),
      await db.habitEntrys.all(),
    ),
  );
  yield await read();
  await for (final _ in db.watch()) {
    yield await read();
  }
});

class IntentSourceData {
  const IntentSourceData(this.habits, this.tasks, this.entries);
  final List<Habit> habits;
  final List<Task> tasks;
  final List<HabitEntry> entries;
}

final intentAgendaProvider = StreamProvider.autoDispose<List<Activity>>((ref) {
  final day = ref.watch(actualIntentDateProvider);
  return ref.watch(activityRepoProvider).watchByDate(DateTime.parse(day));
});

final intentNowProvider = Provider.autoDispose<DateTime>(
  (ref) => ref.watch(_intentClockProvider),
);
final _intentClockProvider =
    StateNotifierProvider.autoDispose<_IntentClock, DateTime>(
      (ref) => _IntentClock(),
    );

class _IntentClock extends StateNotifier<DateTime> with WidgetsBindingObserver {
  _IntentClock() : super(_minute(DateTime.now())) {
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }
  late final Timer _ticker;
  static DateTime _minute(DateTime date) =>
      DateTime(date.year, date.month, date.day, date.hour, date.minute);
  void _refresh() {
    final value = _minute(DateTime.now());
    if (value != state) state = value;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState value) {
    if (value == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _ticker.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
