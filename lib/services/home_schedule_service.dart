import '../core/time_math.dart';
import '../data/store/focus_store.dart';
import '../models/activity.dart';

/// Persists a Home schedule and its existing task as one atomic change.
class HomeScheduleService {
  HomeScheduleService(this.store);
  final FocusStore store;

  Future<List<Activity>> schedule({
    int? taskId,
    required String title,
    required DateTime start,
    required int durationMinutes,
    required DateTime now,
    required int colorValue,
    String identity = '',
  }) async {
    if (!store.isDurable) throw StateError('Penyimpanan tidak tersedia.');
    if (start.isBefore(now)) throw StateError('Waktu mulai sudah lewat.');
    if (durationMinutes <= 0) throw StateError('Durasi tidak valid.');
    final segments = splitSpan(
      start,
      start.add(Duration(minutes: durationMinutes)),
    );
    return store.writeTxn(() async {
      final current = taskId == null ? null : await store.tasks.get(taskId);
      if (taskId != null &&
          (current == null ||
              current.isCompleted ||
              current.activityId != null ||
              current.startMinute != null ||
              current.endMinute != null)) {
        throw StateError('Tugas sudah dijadwalkan atau dihapus.');
      }
      final existing = await store.activitys.all();
      for (final segment in segments) {
        for (final a in existing) {
          final sameDate = dateOnly(a.date) == segment.date;
          final recurring =
              !a.excludedDates.any((d) => dateOnly(d) == segment.date) &&
              (a.recurrence == 'daily' ||
                  (a.recurrence == 'weekday' && segment.date.weekday <= 5) ||
                  (a.recurrence == 'weekly' &&
                      a.date.weekday == segment.date.weekday));
          if ((sameDate || recurring) &&
              a.ampmHalf == segment.half &&
              rangesOverlap(
                a.startMinute,
                a.endMinute,
                segment.start,
                segment.end,
              )) {
            throw StateError('Bentrok dengan ${a.title}.');
          }
        }
      }
      String? group;
      final created = <Activity>[];
      for (final segment in segments) {
        final a = Activity()
          ..title = current?.title ?? title
          ..date = segment.date
          ..ampmHalf = segment.half
          ..startMinute = segment.start
          ..endMinute = segment.end
          ..colorValue = colorValue
          ..description = identity.isEmpty ? '' : 'Identitas: $identity'
          ..groupId = group
          ..createdAt = now
          ..updatedAt = now;
        a.id = await store.activitys.put(a);
        if (segments.length > 1 && group == null) {
          group = 'activity-${a.id}';
          a.groupId = group;
          await store.activitys.put(a);
        }
        created.add(a);
      }
      if (current != null) {
        current.activityId = created.first.id;
        current.date = segments.first.date;
        current.ampmHalf = segments.first.half;
        current.startMinute = segments.first.start;
        current.endMinute = segments.first.end;
        current.updatedAt = now;
        await store.tasks.put(current);
      }
      return created;
    });
  }
}
