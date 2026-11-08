import '../../models/focus_intent_document.dart';
import 'dart:async';
import 'package:isar_community/isar.dart';
import 'focus_store.dart';
import '../../models/preset.dart';
import '../../models/activity.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';
import '../../models/habit.dart';
import '../../models/habit_entry.dart';
import '../../models/daily_reflection.dart';
import '../../models/timer_session.dart';

class NativeFocusStore extends FocusStore {
  NativeFocusStore(this.isar);
  final Isar isar;
  @override
  bool get isDurable => true;
  IsarCollection<T> _collection<T>() => isar.collection<T>();
  @override
  Future<List<T>> all<T>() => _collection<T>().where().findAll();
  @override
  Future<T?> get<T>(int id) => _collection<T>().get(id);
  @override
  Future<int> put<T>(T row) => _collection<T>().put(row);
  @override
  Future<bool> delete<T>(int id) => _collection<T>().delete(id);
  @override
  Future<void> clear() => isar.clear();
  @override
  Future<R> txn<R>(Future<R> Function() action) => isar.txn(action);
  @override
  Future<R> writeTxn<R>(Future<R> Function() action) => isar.writeTxn(action);
  @override
  Stream<void> watch() async* {
    final controller = StreamController<void>();
    final subscriptions = <StreamSubscription<void>>[
      isar.focusIntentDocuments.watchLazy().listen((_) => controller.add(null)),
      isar.presets.watchLazy().listen((_) => controller.add(null)),
      isar.activitys.watchLazy().listen((_) => controller.add(null)),
      isar.appSettings.watchLazy().listen((_) => controller.add(null)),
      isar.tasks.watchLazy().listen((_) => controller.add(null)),
      isar.habits.watchLazy().listen((_) => controller.add(null)),
      isar.habitEntrys.watchLazy().listen((_) => controller.add(null)),
      isar.dailyReflections.watchLazy().listen((_) => controller.add(null)),
      isar.timerSessions.watchLazy().listen((_) => controller.add(null)),
    ];
    controller.add(null);
    try {
      yield* controller.stream;
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await controller.close();
    }
  }

  @override
  Future<void> close() async {
    await isar.close();
  }
}
