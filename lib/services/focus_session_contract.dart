/// Focus Session Contract (v1)
/// As specified in PRD 3 Section 2, Section 35, and Section 84.
/// 
/// Provides a versioned, decoupled integration boundary between
/// Sadar and Focus Clock without circular or tightly coupled imports.
library;

class FocusSessionRequest {
  final int habitId;
  final String title;
  final int targetMinutes;
  final DateTime requestedAt;

  const FocusSessionRequest({
    required this.habitId,
    required this.title,
    required this.targetMinutes,
    required this.requestedAt,
  });

  Map<String, dynamic> toJson() => {
    'version': FocusSessionContract.version,
    'habitId': habitId,
    'title': title,
    'targetMinutes': targetMinutes,
    'requestedAt': requestedAt.toIso8601String(),
  };

  factory FocusSessionRequest.fromJson(Map<String, dynamic> json) {
    return FocusSessionRequest(
      habitId: json['habitId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      targetMinutes: json['targetMinutes'] as int? ?? 20,
      requestedAt: DateTime.tryParse(json['requestedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class FocusSessionResult {
  final String sessionId;
  final int habitId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int actualDurationMinutes;
  final String status; // 'completed', 'cancelled', 'interrupted'

  const FocusSessionResult({
    required this.sessionId,
    required this.habitId,
    required this.startedAt,
    required this.endedAt,
    required this.actualDurationMinutes,
    required this.status,
  });

  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toJson() => {
    'version': FocusSessionContract.version,
    'sessionId': sessionId,
    'habitId': habitId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'actualDurationMinutes': actualDurationMinutes,
    'status': status,
  };

  factory FocusSessionResult.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return FocusSessionResult(
      sessionId: json['sessionId'] as String? ?? '',
      habitId: json['habitId'] as int? ?? 0,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? now,
      endedAt: DateTime.tryParse(json['endedAt'] as String? ?? '') ?? now,
      actualDurationMinutes: json['actualDurationMinutes'] as int? ?? 0,
      status: json['status'] as String? ?? 'completed',
    );
  }
}

class FocusSessionContract {
  static const String version = 'v1';
  static const String schemeFocusClock = 'focusclock';
  static const String schemeSadar = 'sadar';

  /// Generates URI for launching a Focus Clock session from Sadar
  static Uri buildFocusClockUri(FocusSessionRequest request) {
    return Uri(
      scheme: schemeFocusClock,
      host: 'timer',
      queryParameters: {
        'version': version,
        'habitId': request.habitId.toString(),
        'title': request.title,
        'minutes': request.targetMinutes.toString(),
        'timestamp': request.requestedAt.millisecondsSinceEpoch.toString(),
      },
    );
  }

  /// Parses an incoming Focus Clock URI
  static FocusSessionRequest? parseFocusClockUri(Uri uri) {
    if (uri.scheme != schemeFocusClock || uri.host != 'timer') return null;
    final habitId = int.tryParse(uri.queryParameters['habitId'] ?? '') ?? 0;
    final title = uri.queryParameters['title'] ?? '';
    final minutes = int.tryParse(uri.queryParameters['minutes'] ?? '') ?? 20;
    final ts = int.tryParse(uri.queryParameters['timestamp'] ?? '');
    final requestedAt = ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : DateTime.now();

    return FocusSessionRequest(
      habitId: habitId,
      title: title,
      targetMinutes: minutes,
      requestedAt: requestedAt,
    );
  }

  /// Generates URI for returning completed session data from Focus Clock to Sadar
  static Uri buildSadarCompletedUri(FocusSessionResult result) {
    return Uri(
      scheme: schemeSadar,
      host: 'completed',
      queryParameters: {
        'version': version,
        'sessionId': result.sessionId,
        'habitId': result.habitId.toString(),
        'startedAt': result.startedAt.millisecondsSinceEpoch.toString(),
        'endedAt': result.endedAt.millisecondsSinceEpoch.toString(),
        'duration': result.actualDurationMinutes.toString(),
        'status': result.status,
      },
    );
  }

  /// Parses an incoming Sadar completion URI
  static FocusSessionResult? parseSadarCompletedUri(Uri uri) {
    if (uri.scheme != schemeSadar || uri.host != 'completed') return null;
    final habitId = int.tryParse(uri.queryParameters['habitId'] ?? '') ?? 0;
    final sessionId = uri.queryParameters['sessionId'] ?? '';
    final startTs = int.tryParse(uri.queryParameters['startedAt'] ?? '');
    final endTs = int.tryParse(uri.queryParameters['endedAt'] ?? '');
    final duration = int.tryParse(uri.queryParameters['duration'] ?? '') ?? 0;
    final status = uri.queryParameters['status'] ?? 'completed';

    final now = DateTime.now();
    return FocusSessionResult(
      sessionId: sessionId,
      habitId: habitId,
      startedAt: startTs != null ? DateTime.fromMillisecondsSinceEpoch(startTs) : now,
      endedAt: endTs != null ? DateTime.fromMillisecondsSinceEpoch(endTs) : now,
      actualDurationMinutes: duration,
      status: status,
    );
  }
}
