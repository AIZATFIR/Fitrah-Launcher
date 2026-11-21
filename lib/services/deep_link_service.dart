import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'focus_session_contract.dart';

class TimerLaunchParams {
  final int habitId;
  final String title;
  final int durationMinutes;
  final String? iconKey;
  final int? colorValue;
  final String? callbackUrl;

  const TimerLaunchParams({
    required this.habitId,
    required this.title,
    required this.durationMinutes,
    this.iconKey,
    this.colorValue,
    this.callbackUrl,
  });

  Uri toUri() {
    final uri = FocusSessionContract.buildFocusClockUri(
      FocusSessionRequest(
        habitId: habitId,
        title: title,
        targetMinutes: durationMinutes,
        requestedAt: DateTime.now(),
        callbackUrl: callbackUrl,
      ),
    );
    final params = Map<String, String>.from(uri.queryParameters);
    if (iconKey != null) params['icon'] = iconKey!;
    if (colorValue != null) params['color'] = colorValue!.toString();
    return uri.replace(queryParameters: params);
  }

  static TimerLaunchParams? fromUri(Uri uri) {
    final request = FocusSessionContract.parseFocusClockUri(uri);
    if (request == null) return null;
    final params = uri.queryParameters;
    return TimerLaunchParams(
      habitId: request.habitId,
      title: request.title,
      durationMinutes: request.targetMinutes,
      iconKey: params['icon'],
      colorValue: int.tryParse(params['color'] ?? ''),
      callbackUrl: request.callbackUrl,
    );
  }
}

class DeepLinkService {
  /// Attempts to launch Focus Clock native timer via URL scheme.
  /// Returns true if successfully launched, false if not supported or app not installed.
  static Future<bool> launchFocusClockTimer(TimerLaunchParams params) async {
    final uri = params.toUri();
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('DeepLinkService.launchFocusClockTimer error: $e');
    }
    return false;
  }

  /// Sends completion callback back to Sadar.
  static Future<bool> notifySadarCompleted({
    required String callbackUrl,
    required int habitId,
    required int completedMinutes,
  }) async {
    try {
      final baseUri = Uri.parse(callbackUrl);
      final uri = baseUri.replace(
        queryParameters: {
          ...baseUri.queryParameters,
          'habitId': habitId.toString(),
          'duration': completedMinutes.toString(),
          'status': 'completed',
        },
      );
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('DeepLinkService.notifySadarCompleted error: $e');
    }
    return false;
  }
}
