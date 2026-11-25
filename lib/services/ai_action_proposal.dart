/// A model-requested change that stays inert until the user approves it.
class AiActionProposal {
  AiActionProposal({
    required this.name,
    required this.summary,
    required Map<String, dynamic> arguments,
    required Future<Object?> Function() apply,
  }) : arguments = Map.unmodifiable(arguments),
       _apply = apply;

  final String name;
  final String summary;
  final Map<String, dynamic> arguments;
  final Future<Object?> Function() _apply;
  bool _pending = true;
  bool _applying = false;
  bool _applied = false;

  bool get isPending => _pending;
  bool get isApplied => _applied;

  Future<Object?> approve() async {
    if (!_pending || _applying) return null;
    _applying = true;
    try {
      final result = await _apply();
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
