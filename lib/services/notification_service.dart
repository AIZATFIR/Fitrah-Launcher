import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/time_math.dart';
import '../models/activity.dart';

class NotificationService {
  static const int timerCompletionNotificationId = 0x7ffffffe;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _requestedNotificationPermission = false;

  /// Desktop platforms lack zonedSchedule — fall back to in-process timers.
  final Map<int, Timer> _timers = {};

  bool get _useTimerFallback =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> init() async {
    if (_ready) return;
    if (kIsWeb) {
      _ready = true;
      return;
    }
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const init = InitializationSettings(android: android, linux: linux);
    await _plugin.initialize(init);

    _ready = true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'focus_clock_activity',
      'Activity reminders',
      channelDescription: '1 minute before activity start',
      importance: Importance.high,
      priority: Priority.high,
    ),
    linux: LinuxNotificationDetails(),
  );

  static const _timerDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'focus_clock_timer',
      'Focus session reminders',
      channelDescription:
          'A private reminder when a focus session reaches its planned time',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      visibility: NotificationVisibility.private,
    ),
    linux: LinuxNotificationDetails(),
  );

  Future<void> _ensureNotificationPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android ||
        _requestedNotificationPermission) {
      return;
    }
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await androidImpl?.areNotificationsEnabled() != true) {
      _requestedNotificationPermission = true;
      await androidImpl?.requestNotificationsPermission();
    }
  }

  /// Schedule a generic reminder; goal and habit names stay off the lock screen.
  Future<void> scheduleTimerCompletion({required int remainingSeconds}) async {
    if (!_ready || remainingSeconds <= 0) return;
    try {
      await cancelTimerCompletion();
      // A focus session must start without a notification prompt. The reminder
      // is a convenience; schedule it only when Android notifications are
      // already enabled. Activity reminders can still request permission from
      // their explicit scheduling flow below.
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (await androidImpl?.areNotificationsEnabled() != true) return;
      }
      final fire = DateTime.now().add(Duration(seconds: remainingSeconds));
      if (_useTimerFallback) {
        _timers[timerCompletionNotificationId] = Timer(
          Duration(seconds: remainingSeconds),
          () {
            _timers.remove(timerCompletionNotificationId);
            _plugin.show(
              timerCompletionNotificationId,
              'Waktu sesi tercapai',
              'Buka Focus Clock untuk meninjau sesi.',
              _timerDetails,
            );
          },
        );
        return;
      }
      if (kIsWeb) return;
      await _plugin.zonedSchedule(
        timerCompletionNotificationId,
        'Waktu sesi tercapai',
        'Buka Focus Clock untuk meninjau sesi.',
        tz.TZDateTime.from(fire, tz.local),
        _timerDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (error) {
      if (kDebugMode) debugPrint('timer reminder schedule failed: $error');
    }
  }

  Future<void> cancelTimerCompletion() async {
    if (!_ready) return;
    _timers.remove(timerCompletionNotificationId)?.cancel();
    try {
      await _plugin.cancel(timerCompletionNotificationId);
    } catch (error) {
      if (kDebugMode) debugPrint('timer reminder cancel failed: $error');
    }
  }

  Future<void> scheduleForActivity(Activity a, {int leadMinutes = 1}) async {
    if (!_ready) return;
    try {
      await cancelForActivity(a.id);
      final start = toDateTime(a.date, a.ampmHalf, a.startMinute);
      final fire = start.subtract(Duration(minutes: leadMinutes));
      if (fire.isBefore(DateTime.now())) return;

      await _ensureNotificationPermission();

      final title = a.title.isEmpty ? 'Activity' : a.title;
      final body = 'Mulai $leadMinutes menit lagi';

      if (_useTimerFallback) {
        _timers[a.id] = Timer(fire.difference(DateTime.now()), () {
          _timers.remove(a.id);
          _plugin.show(a.id, title, body, _details);
        });
        return;
      }

      await _plugin.zonedSchedule(
        a.id,
        title,
        body,
        tz.TZDateTime.from(fire, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('notif schedule failed: $e');
    }
  }

  Future<void> cancelForActivity(int id) async {
    if (!_ready) return;
    _timers.remove(id)?.cancel();
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  /// Show an instant notification (e.g. for Sadar timer completion)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(id, title, body, _details);
    } catch (e) {
      if (kDebugMode) debugPrint('showNotification failed: $e');
    }
  }
}
