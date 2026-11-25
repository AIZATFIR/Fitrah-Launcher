import '../domain/goal_plan_proposal.dart';

/// Approval gate paired with an editable domain proposal. The callback is the
/// only place that reaches the durable application use case.
class AiGoalPlanProposal {
  AiGoalPlanProposal({
    required this.proposal,
    required this.apply,
    this.goalId,
    this.expectedGoalRevision,
  });
  final PlanProposal proposal;
  final String? goalId;
  final int? expectedGoalRevision;
  final Future<Object?> Function(PlanProposal edited) apply;
  bool _pending = true;
  bool _applying = false;
  bool _applied = false;
  bool get isPending => _pending;
  bool get isApplied => _applied;

  Future<Object?> approve(PlanProposal edited) async {
    if (!_pending || _applying) return null;
    _applying = true;
    try {
      final result = await apply(edited);
      _pending = false;
      _applied = true;
      return result;
    } finally {
      _applying = false;
    }
  }

  void dismiss() {
    if (_pending && !_applying) _pending = false;
  }
}
