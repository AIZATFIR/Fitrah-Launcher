import '../../models/focus_intent_document.dart';
import 'dart:async';
import 'dart:typed_data';

import '../../models/activity.dart';
import '../../models/app_settings.dart';
import '../../models/daily_reflection.dart';
import '../../models/habit.dart';
import '../../models/habit_entry.dart';
import '../../models/preset.dart';
import '../../models/task.dart';
import '../../models/timer_session.dart';
import '../../models/terminal_focus_session.dart';

/// Callers own transactions; collection writes never open nested transactions.
abstract class FocusStore {
  bool get isDurable;
  Future<List<T>> all<T>();
  Future<T?> get<T>(int id);
  Future<int> put<T>(T row);
  Future<bool> delete<T>(int id);
  Future<void> clear();
  Future<R> txn<R>(Future<R> Function() action);
  Future<R> writeTxn<R>(Future<R> Function() action);
  Stream<void> watch();
  Future<void> close();

  FocusCollection<T> collection<T>() => FocusCollection<T>(this);
  FocusCollection<FocusIntentDocument> get focusIntentDocuments => collection();
  FocusCollection<Preset> get presets => collection();
  FocusCollection<Activity> get activitys => collection();
  FocusCollection<AppSettings> get appSettings => collection();
  FocusCollection<Task> get tasks => collection();
  FocusCollection<Habit> get habits => collection();
  FocusCollection<HabitEntry> get habitEntrys => collection();
  FocusCollection<DailyReflection> get dailyReflections => collection();
  FocusCollection<TimerSession> get timerSessions => collection();
  FocusCollection<TerminalFocusSession> get terminalFocusSessions =>
      collection();
}

abstract interface class RecoveryJournal {
  Future<String> saveRecovery(Uint8List bytes);
  Future<Uint8List?> latestRecovery();
}

class FocusCollection<T> {
  FocusCollection(this.store);
  final FocusStore store;
  Future<List<T>> all() => store.all<T>();
  Future<T?> get(int id) => store.get<T>(id);
  Future<int> put(T row) => store.put<T>(row);
  Future<List<int>> putAll(List<T> rows) async {
    final ids = <int>[];
    for (final row in rows) {
      ids.add(await put(row));
    }
    return ids;
  }

  Future<bool> delete(int id) => store.delete<T>(id);
  Future<int> deleteAll(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      if (await delete(id)) count++;
    }
    return count;
  }

  Future<int> count() async => (await all()).length;
  StoreQuery<T> select({
    bool Function(T)? where,
    int Function(T, T)? compare,
  }) => StoreQuery(this, where, compare);
  Stream<T?> watchObject(int id, {bool fireImmediately = false}) =>
      store.watch().asyncMap((_) => get(id));
}

/// Repository predicates run on detached rows for both storage engines.
class StoreQuery<T> {
  StoreQuery(this.collection, this.predicate, this.compare);
  final FocusCollection<T> collection;
  final bool Function(T)? predicate;
  final int Function(T, T)? compare;
  Future<List<T>> findAll() async {
    final rows = (await collection.all())
        .where(predicate ?? (_) => true)
        .toList();
    if (compare != null) rows.sort(compare);
    return rows;
  }

  Future<T?> findFirst() async => (await findAll()).firstOrNull;
  Stream<List<T>> watch({bool fireImmediately = false}) =>
      collection.store.watch().asyncMap((_) => findAll());
}
