import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Uri(
      scheme: 'focusclock',
      host: 'timer',
      queryParameters: {
        'habitId': habitId.toString(),
        'title': title,
        'duration': durationMinutes.toString(),
        'icon': ?iconKey,
        'color': ?colorValue?.toString(),
        'callback': ?callbackUrl,
      },
    );
  }

  static TimerLaunchParams? fromUri(Uri uri) {
    if (uri.scheme != 'focusclock' || uri.host != 'timer') return null;
    final params = uri.queryParameters;
    final id = int.tryParse(params['habitId'] ?? '');
    final duration = int.tryParse(params['duration'] ?? '');
    final title = params['title'];
    if (id == null || duration == null || title == null) return null;

    return TimerLaunchParams(
      habitId: id,
      title: title,
      durationMinutes: duration,
      iconKey: params['icon'],
      colorValue: int.tryParse(params['color'] ?? ''),
      callbackUrl: params['callback'],
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
