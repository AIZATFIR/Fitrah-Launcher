import 'package:isar_community/isar.dart';

part 'terminal_focus_session.g.dart';

enum TerminalSessionStatus { completed, cancelled }

@collection
class TerminalFocusSession {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String sessionId;

  late String sourceKind;
  late String titleSnapshot;
  String? sourceIdentity;
  String? goalId;
  String? goalTitleSnapshot;
  int? habitId;
  int? activityId;
  late DateTime startedAt;
  late DateTime completedAt;
  late int actualDurationSeconds;
  @enumerated
  late TerminalSessionStatus status;

  void validate() {
    if (sessionId.trim().isEmpty ||
        sourceKind.trim().isEmpty ||
        titleSnapshot.trim().isEmpty ||
        actualDurationSeconds < 0 ||
        (goalId == null) != (goalTitleSnapshot == null) ||
        (goalTitleSnapshot != null && goalTitleSnapshot!.trim().isEmpty) ||
        (status == TerminalSessionStatus.cancelled &&
            actualDurationSeconds != 0)) {
      throw ArgumentError('Invalid terminal focus session.');
    }
  }
}
