import 'package:flutter_test/flutter_test.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/data/store/live_model_codec.dart';
import 'package:fitrah_launcher/models/terminal_focus_session.dart';
import 'package:fitrah_launcher/models/timer_session.dart';

void main() {
  test('terminal session is preserved by browser storage codec', () {
    final row = TerminalFocusSession()
      ..id = 4
      ..sessionId = 'a-stable-session-uuid'
      ..sourceKind = 'free'
      ..titleSnapshot = 'Study'
      ..startedAt = DateTime(2026, 11, 14, 10)
      ..completedAt = DateTime(2026, 11, 14, 10, 15)
      ..actualDurationSeconds = 900
      ..status = TerminalSessionStatus.completed;
    final decoded = LiveModelCodec.decode<TerminalFocusSession>(
      LiveModelCodec.encode(row),
    );
    expect(decoded.sessionId, row.sessionId);
    expect(decoded.actualDurationSeconds, 900);
  });

  test(
    'completed memory session writes exactly one measured history row',
    () async {
      final repository = SadarRepository.store(null);
      final started = DateTime.now();
      final session = TimerSession()
        ..sessionId = 'session-1'
        ..habitId = 1
        ..habitName = 'Focus snapshot'
        ..sourceKind = TimerSessionSourceKind.habit
        ..startedAt = started
        ..attributionLocalDate =
            '${started.year.toString().padLeft(4, '0')}-${started.month.toString().padLeft(2, '0')}-${started.day.toString().padLeft(2, '0')}'
        ..targetSeconds = 2700
        ..status = TimerStateStatus.running;
      await repository.saveTimerSession(session);
      await repository.completeTimerSession(
        habitId: 1,
        sessionId: 'session-1',
        dateString: session.attributionLocalDate!,
        actualDurationMinutes: 3,
        actualDurationSeconds: 211,
        targetSnapshot: 45,
        completedAt: started.add(const Duration(minutes: 3, seconds: 31)),
      );
      final rows = await repository.getTerminalFocusSessionsForDate(
        session.attributionLocalDate!,
      );
      expect(rows, hasLength(1));
      expect(rows.single.titleSnapshot, 'Focus snapshot');
      expect(rows.single.actualDurationSeconds, 211);
      expect(rows.single.status, TerminalSessionStatus.completed);
      await repository.completeTimerSession(
        habitId: 1,
        sessionId: 'session-1',
        dateString: session.attributionLocalDate!,
        actualDurationMinutes: 3,
        actualDurationSeconds: 211,
        targetSnapshot: 45,
        completedAt: started.add(const Duration(minutes: 3, seconds: 31)),
      );
      expect(
        await repository.getTerminalFocusSessionsForDate(
          session.attributionLocalDate!,
        ),
        hasLength(1),
      );
      expect(
        (await repository.getEntriesForDateRange(
          session.attributionLocalDate!,
          session.attributionLocalDate!,
        )).single.actualDurationSeconds,
        211,
      );
    },
  );

  test('cancellation is recorded with zero completed focus time', () async {
    final repository = SadarRepository.store(null);
    final now = DateTime.now();
    final session = TimerSession()
      ..sessionId = 'session-cancel'
      ..habitName = 'Cancelled focus'
      ..sourceKind = TimerSessionSourceKind.free
      ..startedAt = now
      ..targetSeconds = 600
      ..accumulatedDurationSeconds = 55
      ..status = TimerStateStatus.running;
    await repository.saveTimerSession(session);
    await repository.clearTimerSession();
    final date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final rows = await repository.getTerminalFocusSessionsForDate(date);
    expect(rows.single.status, TerminalSessionStatus.cancelled);
    expect(rows.single.actualDurationSeconds, 0);
  });

  test('legacy habit session without source kind is recorded as habit', () async {
    final repository = SadarRepository.store(null);
    final started = DateTime.now();
    final date =
        '${started.year.toString().padLeft(4, '0')}-${started.month.toString().padLeft(2, '0')}-${started.day.toString().padLeft(2, '0')}';
    await repository.saveTimerSession(
      TimerSession()
        ..sessionId = 'legacy-habit-session'
        ..habitId = 1
        ..habitName = 'Legacy habit'
        ..startedAt = started
        ..status = TimerStateStatus.running,
    );
    await repository.completeTimerSession(
      habitId: 1,
      sessionId: 'legacy-habit-session',
      dateString: date,
      actualDurationMinutes: 1,
      actualDurationSeconds: 60,
      targetSnapshot: 45,
      completedAt: started.add(const Duration(minutes: 1)),
    );
    expect(
      (await repository.getTerminalFocusSessionsForDate(
        date,
      )).single.sourceKind,
      'habit',
    );
  });
}
