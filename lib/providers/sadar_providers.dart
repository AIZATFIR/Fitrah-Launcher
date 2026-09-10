import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/sadar_repository.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';
import 'providers.dart';

final sadarRepoProvider = Provider<SadarRepository>((ref) {
  return SadarRepository(ref.watch(isarProvider));
});

final habitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(sadarRepoProvider).watchHabits();
});

final sadarSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Number of days displayed in the horizontal timeline strip (e.g. 14 days)
final sadarDateRangeDaysProvider = StateProvider<int>((ref) => 14);

/// Date range query record helper
class DateRangeQuery {
  final String start;
  final String end;

  const DateRangeQuery({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRangeQuery &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

final habitEntriesStreamProvider =
    StreamProvider.family<List<HabitEntry>, DateRangeQuery>((ref, range) {
  return ref.watch(sadarRepoProvider).watchEntriesForDateRange(range.start, range.end);
});

final dailyFulfillmentProvider =
    FutureProvider.family<DailyFulfillmentSummary, String>((ref, dateString) {
  return ref.watch(sadarRepoProvider).getDailyFulfillment(dateString);
});

final awarenessStatsProvider = FutureProvider<AwarenessStats>((ref) {
  return ref.watch(sadarRepoProvider).getAwarenessStats();
});
