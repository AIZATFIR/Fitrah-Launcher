import 'dart:async';
import '../store/focus_store.dart';
import '../store/native_focus_store.dart';

import 'package:isar_community/isar.dart';

import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../services/notification_service.dart';

class ActivityRepository {
  ActivityRepository(Isar? isar, this._notifier)
    : _isar = isar == null ? null : NativeFocusStore(isar);
  ActivityRepository.store(this._isar, this._notifier);
  final FocusStore? _isar;
  final NotificationService _notifier;

  // In-Memory Fallback when Isar is unavailable (Web without IndexedDB/WASM or test runner)
  final Map<int, Activity> _memStore = {};
  int _memIdCounter = 1;
  final StreamController<void> _memController =
      StreamController<void>.broadcast();

  Stream<List<Activity>> watchByDateAndHalf(DateTime date, AmPmHalf half) {
    final d = dateOnly(date);
    if (_isar == null) {
      return _watchMemoryByDate(d, half: half);
    }
    // Direct activities for this date+half
    final direct = _isar.activitys
        .select(
          where: (x) => x.date == d && x.ampmHalf == half,
          compare: (a, b) {
            return a.startMinute.compareTo(b.startMinute);
          },
        )
        .watch(fireImmediately: true);

    // Merge with recurring activities
    return _mergeWithRecurring(direct, d, half: half);
  }

  Stream<List<Activity>> watchByDate(DateTime date) {
    final d = dateOnly(date);
    if (_isar == null) {
      return _watchMemoryByDate(d);
    }
    final direct = _isar.activitys
        .select(
          where: (x) => x.date == d,
          compare: (a, b) {
            final c0 = a.ampmHalf.index.compareTo(b.ampmHalf.index);
            if (c0 != 0) return c0;
            return a.startMinute.compareTo(b.startMinute);
          },
        )
        .watch(fireImmediately: true);

    return _mergeWithRecurring(direct, d);
  }

  Stream<List<Activity>> _watchMemoryByDate(
    DateTime targetDate, {
    AmPmHalf? half,
  }) async* {
    List<Activity> query() {
      final list = _memStore.values.where((a) {
        if (dateOnly(a.date) != targetDate) return false;
        if (half != null && a.ampmHalf != half) return false;
        return true;
      }).toList();
      list.sort((a, b) {
        final hc = a.ampmHalf.index.compareTo(b.ampmHalf.index);
        return hc != 0 ? hc : a.startMinute.compareTo(b.startMinute);
      });
      return list;
    }

    yield query();
    await for (final _ in _memController.stream) {
      yield query();
    }
  }

  /// Merges direct activities with projected recurring activities.
  Stream<List<Activity>> _mergeWithRecurring(
    Stream<List<Activity>> direct,
    DateTime targetDate, {
    AmPmHalf? half,
  }) {
    return direct.asyncMap((list) async {
      final recurring = await _getRecurring(targetDate, half: half);
      // Only add recurring entries not already covered by an explicit entry
      final existingIds = list.map((activity) => activity.id).toSet();
      final projected = recurring.where(
        (activity) => !existingIds.contains(activity.id),
      );
      final all = [...list, ...projected];
      all.sort((a, b) {
        final halfCmp = a.ampmHalf.index.compareTo(b.ampmHalf.index);
        if (halfCmp != 0) return halfCmp;
        return a.startMinute.compareTo(b.startMinute);
      });
      return all;
    });
  }

  Future<List<Activity>> _getRecurring(
    DateTime targetDate, {
    AmPmHalf? half,
  }) async {
    if (_isar == null) return [];
    final all = await _isar.activitys
        .select(where: (x) => !(x.recurrence == 'none'))
        .findAll();
    final groups = <String, List<Activity>>{};
    for (final activity in all) {
      final key = activity.groupId == null
          ? 'activity:${activity.id}'
          : 'group:${activity.groupId}';
      groups.putIfAbsent(key, () => []).add(activity);
    }

    final projected = <Activity>[];
    for (final sourceGroup in groups.values) {
      sourceGroup.sort((a, b) {
        final date = dateOnly(a.date).compareTo(dateOnly(b.date));
        if (date != 0) return date;
        final h = a.ampmHalf.index.compareTo(b.ampmHalf.index);
        return h != 0 ? h : a.startMinute.compareTo(b.startMinute);
      });
      final anchor = sourceGroup.first;
      final anchorDate = dateOnly(anchor.date);
      for (final activity in sourceGroup) {
        if (half != null && activity.ampmHalf != half) continue;
        final offsetDays = dateOnly(
          activity.date,
        ).difference(anchorDate).inDays;
        final occurrenceAnchor = dateOnly(
          targetDate.subtract(Duration(days: offsetDays)),
        );
        if (occurrenceAnchor.isBefore(anchorDate) ||
            !_repeatsOn(anchor, occurrenceAnchor)) {
          continue;
        }
        // The stored source segment already represents the original occurrence.
        if (dateOnly(activity.date) == dateOnly(targetDate)) continue;
        if (activity.excludedDates.any(
          (date) => dateOnly(date) == dateOnly(targetDate),
        )) {
          continue;
        }
        projected.add(_projectActivity(activity, targetDate));
      }
    }
    return projected;
  }

  bool _repeatsOn(Activity source, DateTime occurrenceDate) {
    if (source.recurrence == 'daily') return true;
    if (source.recurrence == 'weekday') {
      return occurrenceDate.weekday >= DateTime.monday &&
          occurrenceDate.weekday <= DateTime.friday;
    }
    if (source.recurrence == 'weekly') {
      return dateOnly(source.date).weekday == occurrenceDate.weekday;
    }
    return false;
  }

  Activity _projectActivity(Activity source, DateTime targetDate) => Activity()
    ..id = source.id
    ..habitId = source.habitId
    ..presetId = source.presetId
    ..iconKey = source.iconKey
    ..title = source.title
    ..startMinute = source.startMinute
    ..endMinute = source.endMinute
    ..ampmHalf = source.ampmHalf
    ..date = dateOnly(targetDate)
    ..description = source.description
    ..colorValue = source.colorValue
    ..recurrence = source.recurrence
    ..isLocked = source.isLocked
    ..excludedDates = source.excludedDates
    ..createdAt = source.createdAt
    ..updatedAt = source.updatedAt;

  Future<int> upsert(Activity a, {int notifLeadMinutes = 1}) async {
    a.date = dateOnly(a.date);
    a.updatedAt = DateTime.now();
    if (_isar == null) {
      if (a.id == Isar.autoIncrement || a.id <= 0) {
        a.id = _memIdCounter++;
      }
      _memStore[a.id] = a;
      _memController.add(null);
      return a.id;
    }
    final id = await _isar.writeTxn(() => _isar.activitys.put(a));
    await _notifier.scheduleForActivity(a, leadMinutes: notifLeadMinutes);
    return id;
  }

  /// Delete only a single instance of a recurring activity for [targetDate].
  Future<void> deleteSingleInstance(Activity a, DateTime targetDate) async {
    final target = dateOnly(targetDate);
    final source = _isar == null
        ? _memStore[a.id]
        : await _isar.activitys.get(a.id);
    if (source == null || source.recurrence == 'none') {
      await deleteGroupOf(a);
      return;
    }
    final group = await _recurringGroup(source);
    final anchor = _recurrenceAnchorForTarget(group, source, target);
    final now = DateTime.now();
    for (final row in group) {
      if (row.recurrence == 'none') continue;
      final occurrenceDate = dateOnly(
        anchor.add(dateOnly(row.date).difference(dateOnly(group.first.date))),
      );
      if (!row.excludedDates.any((date) => dateOnly(date) == occurrenceDate)) {
        row.excludedDates = [...row.excludedDates, occurrenceDate];
      }
      row.updatedAt = now;
    }
    if (_isar == null) {
      for (final row in group) {
        _memStore[row.id] = row;
      }
      _memController.add(null);
    } else {
      await _isar.writeTxn(() => _isar.activitys.putAll(group));
    }
  }

  /// Replace one date in a recurring series with a standalone edited activity.
  /// The series row and its completion/timer history stay intact.
  Future<int> editSingleInstance(
    Activity occurrence,
    DateTime targetDate,
    Activity edited,
  ) => editSingleInstanceSpan(occurrence, targetDate, [edited]);

  /// Replace one recurrence occurrence, including every segment in its block.
  /// [targetAnchorDate] is the date the logical block starts on.
  Future<int> editSingleInstanceSpan(
    Activity occurrence,
    DateTime targetAnchorDate,
    List<Activity> editedSegments,
  ) async {
    if (editedSegments.isEmpty) {
      throw ArgumentError.value(editedSegments, 'editedSegments');
    }
    final targetAnchor = dateOnly(targetAnchorDate);
    final source = _isar == null
        ? _memStore[occurrence.id]
        : await _isar.activitys.get(occurrence.id);
    if (source == null || source.recurrence == 'none') {
      throw StateError('Recurring activity no longer exists');
    }
    final group = await _recurringGroup(source);
    final sourceAnchor = dateOnly(group.first.date);
    final now = DateTime.now();
    for (final row in group) {
      if (row.recurrence == 'none') continue;
      final occurrenceDate = dateOnly(
        targetAnchor.add(dateOnly(row.date).difference(sourceAnchor)),
      );
      if (!row.excludedDates.any((date) => dateOnly(date) == occurrenceDate)) {
        row.excludedDates = [...row.excludedDates, occurrenceDate];
      }
      row.updatedAt = now;
    }
    for (final edited in editedSegments) {
      edited
        ..date = dateOnly(edited.date)
        ..recurrence = 'none'
        ..excludedDates = []
        ..isCompleted = false
        ..actualDurationSeconds = 0
        ..createdAt = now
        ..updatedAt = now;
    }
    if (_isar == null) {
      for (final row in group) {
        _memStore[row.id] = row;
      }
      for (final edited in editedSegments) {
        if (edited.id == Isar.autoIncrement || edited.id <= 0) {
          edited.id = _memIdCounter++;
        }
        _memStore[edited.id] = edited;
      }
      _memController.add(null);
      return editedSegments.first.id;
    }
    final id = await _isar.writeTxn(() async {
      await _isar.activitys.putAll(group);
      final ids = await _isar.activitys.putAll(editedSegments);
      return ids.first;
    });
    await _notifier.scheduleForActivity(editedSegments.first);
    return id;
  }

  Future<List<Activity>> _recurringGroup(Activity source) async {
    if (source.groupId == null) return [source];
    final rows = _isar == null
        ? _memStore.values
              .where((row) => row.groupId == source.groupId)
              .toList()
        : await _isar.activitys
              .select(where: (row) => row.groupId == source.groupId)
              .findAll();
    rows.sort((a, b) {
      final date = dateOnly(a.date).compareTo(dateOnly(b.date));
      if (date != 0) return date;
      final half = a.ampmHalf.index.compareTo(b.ampmHalf.index);
      return half != 0 ? half : a.startMinute.compareTo(b.startMinute);
    });
    return rows;
  }

  DateTime _recurrenceAnchorForTarget(
    List<Activity> group,
    Activity source,
    DateTime targetDate,
  ) {
    final segmentOffset = dateOnly(
      source.date,
    ).difference(dateOnly(group.first.date));
    return dateOnly(targetDate.subtract(segmentOffset));
  }

  /// Duplicate [a] as a new standalone activity on [targetDate].
  Future<int> duplicateActivity(Activity a, DateTime targetDate) async {
    final now = DateTime.now();
    final copy = Activity()
      ..habitId = a.habitId
      ..presetId = a.presetId
      ..iconKey = a.iconKey
      ..title = '${a.title} (Copy)'
      ..startMinute = a.startMinute
      ..endMinute = a.endMinute
      ..ampmHalf = a.ampmHalf
      ..date = dateOnly(targetDate)
      ..description = a.description
      ..colorValue = a.colorValue
      ..recurrence = 'none'
      ..importance = a.importance
      ..deadline = a.deadline
      ..isCompleted = false
      ..isLocked = false
      ..createdAt = now
      ..updatedAt = now;

    return upsert(copy);
  }

  /// Toggle lock status of [a].
  Future<void> toggleLock(Activity a, bool locked) async {
    if (_isar == null) {
      final memAct = _memStore[a.id];
      if (memAct != null) {
        memAct.isLocked = locked;
        _memController.add(null);
      }
      return;
    }
    final dbActivity = await _isar.activitys.get(a.id);
    if (dbActivity == null) return;
    dbActivity.isLocked = locked;
    dbActivity.updatedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.activitys.put(dbActivity));
  }

  Future<List<Activity>> getGroup(String groupId) async {
    if (_isar == null) {
      return _memStore.values.where((a) => a.groupId == groupId).toList();
    }
    return _isar.activitys
        .select(
          where: (x) => x.groupId == groupId,
          compare: (a, b) {
            return a.date.compareTo(b.date);
          },
        )
        .findAll();
  }

  /// Replace [original] (and its whole group, if any) with [segments]
  /// in one transaction. Used for cross-midnight spans.
  Future<void> replaceSpan({
    required Activity original,
    required List<Activity> segments,
    int notifLeadMinutes = 1,
  }) async {
    final oldRows = original.groupId != null
        ? await getGroup(original.groupId!)
        : (original.id > 0 && original.id != Isar.autoIncrement
              ? [if (await get(original.id) case final Activity row) row]
              : <Activity>[]);
    oldRows.sort((a, b) {
      final date = dateOnly(a.date).compareTo(dateOnly(b.date));
      if (date != 0) return date;
      final half = a.ampmHalf.index.compareTo(b.ampmHalf.index);
      return half != 0 ? half : a.startMinute.compareTo(b.startMinute);
    });

    if (oldRows.length > segments.length) {
      for (final removed in oldRows.skip(segments.length)) {
        final hasTimerHistory =
            _isar != null &&
            await _isar.timerSessions
                    .select(
                      where: (session) => session.activityId == removed.id,
                    )
                    .findFirst() !=
                null;
        if (removed.isCompleted ||
            removed.actualDurationSeconds > 0 ||
            hasTimerHistory) {
          throw StateError(
            'A schedule segment with history cannot be removed by this edit.',
          );
        }
      }
    }

    for (
      var index = 0;
      index < segments.length && index < oldRows.length;
      index++
    ) {
      final previous = oldRows[index];
      segments[index]
        ..id = previous.id
        ..createdAt = previous.createdAt
        ..isCompleted = previous.isCompleted
        ..actualDurationSeconds = previous.actualDurationSeconds
        ..excludedDates = List<DateTime>.from(previous.excludedDates);
    }

    final now = DateTime.now();
    for (final s in segments) {
      s.date = dateOnly(s.date);
      s.updatedAt = now;
    }
    if (_isar == null) {
      for (final old in oldRows.skip(segments.length)) {
        _memStore.remove(old.id);
      }
      for (final s in segments) {
        if (s.id == Isar.autoIncrement || s.id <= 0) {
          s.id = _memIdCounter++;
        }
        _memStore[s.id] = s;
      }
      _memController.add(null);
      return;
    }
    final removedIds = oldRows
        .skip(segments.length)
        .map((row) => row.id)
        .toList();
    await _isar.writeTxn(() async {
      await _isar.activitys.deleteAll(removedIds);
      await _isar.activitys.putAll(segments);
    });
    for (final id in oldRows.map((row) => row.id)) {
      await _notifier.cancelForActivity(id);
    }
    // One reminder at the block's true start (first segment)
    await _notifier.scheduleForActivity(
      segments.first,
      leadMinutes: notifLeadMinutes,
    );
  }

  /// Delete activity; if it belongs to a group, delete every segment.
  Future<void> deleteGroupOf(Activity a) async {
    if (_isar == null) {
      if (a.groupId == null) {
        _memStore.remove(a.id);
      } else {
        _memStore.removeWhere((_, act) => act.groupId == a.groupId);
      }
      _memController.add(null);
      return;
    }
    if (a.groupId == null) {
      await delete(a.id);
      return;
    }
    final group = await getGroup(a.groupId!);
    await _isar.writeTxn(
      () => _isar.activitys.deleteAll(group.map((x) => x.id).toList()),
    );
    for (final g in group) {
      await _notifier.cancelForActivity(g.id);
    }
  }

  Future<bool> delete(int id) async {
    if (_isar == null) {
      _memStore.remove(id);
      _memController.add(null);
      return true;
    }
    final result = await _isar.writeTxn(() => _isar.activitys.delete(id));
    await _notifier.cancelForActivity(id);
    return result;
  }

  Future<Activity?> get(int id) async {
    if (_isar == null) return _memStore[id];
    return _isar.activitys.get(id);
  }

  /// Watch activities for a whole week (Mon–Sun containing [date]).
  Stream<List<Activity>> watchWeek(DateTime date) {
    final d = dateOnly(date);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    if (_isar == null) {
      return Stream.value(
        _memStore.values.where((a) {
          final ad = dateOnly(a.date);
          return !ad.isBefore(monday) && !ad.isAfter(sunday);
        }).toList(),
      );
    }
    return _isar.activitys
        .select(
          where: (x) =>
              x.date.compareTo(monday) >= 0 && x.date.compareTo(sunday) <= 0,
          compare: (a, b) {
            final c0 = a.date.compareTo(b.date);
            if (c0 != 0) return c0;
            final c1 = a.ampmHalf.index.compareTo(b.ampmHalf.index);
            if (c1 != 0) return c1;
            return a.startMinute.compareTo(b.startMinute);
          },
        )
        .watch(fireImmediately: true);
  }

  /// Watch all activities from today through the next [days] days (for Eisenhower).
  Stream<List<Activity>> watchUpcoming({int days = 14}) {
    final today = dateOnly(DateTime.now());
    final end = today.add(Duration(days: days));
    if (_isar == null) {
      return Stream.value(
        _memStore.values.where((a) {
          final ad = dateOnly(a.date);
          return !ad.isBefore(today) && !ad.isAfter(end);
        }).toList(),
      );
    }
    return _isar.activitys
        .select(
          where: (x) =>
              x.date.compareTo(today) >= 0 && x.date.compareTo(end) <= 0,
          compare: (a, b) {
            final c0 = a.date.compareTo(b.date);
            if (c0 != 0) return c0;
            final c1 = a.ampmHalf.index.compareTo(b.ampmHalf.index);
            if (c1 != 0) return c1;
            return a.startMinute.compareTo(b.startMinute);
          },
        )
        .watch(fireImmediately: true);
  }

  Future<void> markComplete(Activity activity, bool done) async {
    if (_isar == null) {
      final act = _memStore[activity.id];
      if (act != null) {
        act.isCompleted = done;
        _memController.add(null);
      }
      return;
    }
    final dbActivity = await _isar.activitys.get(activity.id);
    if (dbActivity == null) return;

    if (dbActivity.recurrence != 'none' &&
        dateOnly(dbActivity.date) != dateOnly(activity.date)) {
      final clone = _cloneForSpecificDate(dbActivity, activity.date)
        ..isCompleted = done;
      await _isar.writeTxn(() => _isar.activitys.put(clone));
    } else {
      dbActivity.isCompleted = done;
      dbActivity.updatedAt = DateTime.now();
      await _isar.writeTxn(() => _isar.activitys.put(dbActivity));
    }
  }

  Future<void> setImportance(Activity activity, int importance) async {
    if (_isar == null) {
      final act = _memStore[activity.id];
      if (act != null) {
        act.importance = importance;
        _memController.add(null);
      }
      return;
    }
    final dbActivity = await _isar.activitys.get(activity.id);
    if (dbActivity == null) return;

    if (dbActivity.recurrence != 'none' &&
        dateOnly(dbActivity.date) != dateOnly(activity.date)) {
      final clone = _cloneForSpecificDate(dbActivity, activity.date)
        ..importance = importance;
      await _isar.writeTxn(() => _isar.activitys.put(clone));
    } else {
      dbActivity.importance = importance;
      dbActivity.updatedAt = DateTime.now();
      await _isar.writeTxn(() => _isar.activitys.put(dbActivity));
    }
  }

  Future<void> setDeadline(Activity activity, DateTime? deadline) async {
    if (_isar == null) {
      final act = _memStore[activity.id];
      if (act != null) {
        act.deadline = deadline;
        _memController.add(null);
      }
      return;
    }
    final dbActivity = await _isar.activitys.get(activity.id);
    if (dbActivity == null) return;

    if (dbActivity.recurrence != 'none' &&
        dateOnly(dbActivity.date) != dateOnly(activity.date)) {
      final clone = _cloneForSpecificDate(dbActivity, activity.date)
        ..deadline = deadline;
      await _isar.writeTxn(() => _isar.activitys.put(clone));
    } else {
      dbActivity.deadline = deadline;
      dbActivity.updatedAt = DateTime.now();
      await _isar.writeTxn(() => _isar.activitys.put(dbActivity));
    }
  }

  Activity _cloneForSpecificDate(Activity dbActivity, DateTime targetDate) {
    return Activity()
      ..habitId = dbActivity.habitId
      ..presetId = dbActivity.presetId
      ..iconKey = dbActivity.iconKey
      ..title = dbActivity.title
      ..startMinute = dbActivity.startMinute
      ..endMinute = dbActivity.endMinute
      ..ampmHalf = dbActivity.ampmHalf
      ..date = dateOnly(targetDate)
      ..description = dbActivity.description
      ..colorValue = dbActivity.colorValue
      ..recurrence = 'none'
      ..importance = dbActivity.importance
      ..deadline = dbActivity.deadline
      ..isCompleted = dbActivity.isCompleted
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }

  Future<List<Activity>> getByDate(DateTime date) async {
    final d = dateOnly(date);
    if (_isar == null) {
      final list = _memStore.values
          .where((a) => dateOnly(a.date) == d)
          .toList();
      list.sort((a, b) {
        final hc = a.ampmHalf.index.compareTo(b.ampmHalf.index);
        return hc != 0 ? hc : a.startMinute.compareTo(b.startMinute);
      });
      return list;
    }
    final direct = await _isar.activitys
        .select(
          where: (x) => x.date == d,
          compare: (a, b) {
            final c0 = a.ampmHalf.index.compareTo(b.ampmHalf.index);
            if (c0 != 0) return c0;
            return a.startMinute.compareTo(b.startMinute);
          },
        )
        .findAll();
    final recurring = await _getRecurring(d);
    final existingIds = direct.map((activity) => activity.id).toSet();
    final projected = recurring.where(
      (activity) => !existingIds.contains(activity.id),
    );
    final all = [...direct, ...projected];
    all.sort((a, b) {
      final hc = a.ampmHalf.index.compareTo(b.ampmHalf.index);
      return hc != 0 ? hc : a.startMinute.compareTo(b.startMinute);
    });
    return all;
  }

  Future<List<Activity>> getConflicting(
    DateTime date,
    AmPmHalf half,
    int start,
    int end, {
    int? excludeId,
  }) async {
    final all = await getByDate(date);
    return all.where((a) {
      if (excludeId != null && a.id == excludeId) return false;
      if (a.ampmHalf != half) return false;
      return rangesOverlap(a.startMinute, a.endMinute, start, end);
    }).toList();
  }
}
