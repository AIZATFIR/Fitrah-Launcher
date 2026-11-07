import 'dart:async';
import '../store/focus_store.dart';
import '../store/native_focus_store.dart';
import 'package:isar_community/isar.dart';

import '../../models/task.dart';

class TaskRepository {
  TaskRepository(Isar? isar)
    : isar = isar == null ? null : NativeFocusStore(isar);
  TaskRepository.store(this.isar);
  final FocusStore? isar;

  final List<Task> _memoryTasks = [];
  int _nextMemoryId = 1;
  final StreamController<void> _memController =
      StreamController<void>.broadcast();

  Future<List<Task>> getAll() async {
    if (isar == null) return List.unmodifiable(_memoryTasks);
    return isar!.tasks
        .select(
          compare: (a, b) {
            return b.createdAt.compareTo(a.createdAt);
          },
        )
        .findAll();
  }

  Stream<List<Task>> watchAll() {
    if (isar == null) {
      return _watchMemoryAll();
    }
    return isar!.tasks
        .select(
          compare: (a, b) {
            return b.createdAt.compareTo(a.createdAt);
          },
        )
        .watch(fireImmediately: true);
  }

  Stream<List<Task>> _watchMemoryAll() async* {
    yield List.unmodifiable(_memoryTasks);
    await for (final _ in _memController.stream) {
      yield List.unmodifiable(_memoryTasks);
    }
  }

  Stream<List<Task>> watchByActivity(int activityId) {
    if (isar == null) {
      return _watchMemoryByActivity(activityId);
    }
    return isar!.tasks
        .select(where: (x) => x.activityId == activityId)
        .watch(fireImmediately: true);
  }

  Stream<List<Task>> _watchMemoryByActivity(int activityId) async* {
    List<Task> query() =>
        _memoryTasks.where((t) => t.activityId == activityId).toList();
    yield query();
    await for (final _ in _memController.stream) {
      yield query();
    }
  }

  Future<int> add(Task task) async {
    if (isar == null) {
      task.createdAt = DateTime.now();
      task.id = _nextMemoryId++;
      _memoryTasks.add(task);
      _memController.add(null);
      return task.id;
    }
    return isar!.writeTxn(() async {
      task.createdAt = DateTime.now();
      return await isar!.tasks.put(task);
    });
  }

  Future<bool> update(Task task) async {
    if (isar == null) {
      task.updatedAt = DateTime.now();
      final idx = _memoryTasks.indexWhere((t) => t.id == task.id);
      if (idx >= 0) _memoryTasks[idx] = task;
      _memController.add(null);
      return true;
    }
    return isar!.writeTxn(() async {
      task.updatedAt = DateTime.now();
      await isar!.tasks.put(task);
      return true;
    });
  }

  Future<bool> delete(int id) async {
    if (isar == null) {
      _memoryTasks.removeWhere((t) => t.id == id);
      _memController.add(null);
      return true;
    }
    return isar!.writeTxn(() async {
      return await isar!.tasks.delete(id);
    });
  }

  Future<void> toggleCompletion(int id) async {
    if (isar == null) {
      final task = _memoryTasks.firstWhere(
        (t) => t.id == id,
        orElse: () => Task(),
      );
      if (task.title.isNotEmpty) {
        task.isCompleted = !task.isCompleted;
        task.updatedAt = DateTime.now();
        _memController.add(null);
      }
      return;
    }
    await isar!.writeTxn(() async {
      final task = await isar!.tasks.get(id);
      if (task != null) {
        task.isCompleted = !task.isCompleted;
        task.updatedAt = DateTime.now();
        await isar!.tasks.put(task);
      }
    });
  }

  Future<void> updateEisenhower(int id, int quadrant) async {
    if (isar == null) {
      final task = _memoryTasks.firstWhere(
        (t) => t.id == id,
        orElse: () => Task(),
      );
      if (task.title.isNotEmpty) {
        task.importance = (quadrant == 0 || quadrant == 1) ? 1 : 0;
        if (quadrant == 0 || quadrant == 2) {
          if (!task.isUrgent) {
            task.deadline = DateTime.now();
          }
        } else {
          task.deadline = null;
        }
        task.updatedAt = DateTime.now();
        _memController.add(null);
      }
      return;
    }
    await isar!.writeTxn(() async {
      final task = await isar!.tasks.get(id);
      if (task != null) {
        task.importance = (quadrant == 0 || quadrant == 1) ? 1 : 0;
        if (quadrant == 0 || quadrant == 2) {
          if (!task.isUrgent) {
            task.deadline = DateTime.now();
          }
        } else {
          task.deadline = null;
        }
        task.updatedAt = DateTime.now();
        await isar!.tasks.put(task);
      }
    });
  }
}
