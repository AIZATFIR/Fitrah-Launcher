import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrah_launcher/services/notification_service.dart';
import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/models/activity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'startup initialization does not request notification permission',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return call.method == 'areNotificationsEnabled' ? false : true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final service = NotificationService();
      await service.init();

      expect(calls, contains('initialize'));
      expect(calls, isNot(contains('requestNotificationsPermission')));

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      Activity scheduledActivity(int id) => Activity()
        ..id = id
        ..title = 'Study'
        ..startMinute = 600
        ..endMinute = 660
        ..ampmHalf = AmPmHalf.am
        ..date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day)
        ..colorValue = 0xFFFFFFFF
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await service.scheduleForActivity(scheduledActivity(10));
      await service.scheduleForActivity(scheduledActivity(11));

      expect(
        calls.where((method) => method == 'requestNotificationsPermission'),
        hasLength(1),
      );
      expect(calls.where((method) => method == 'zonedSchedule'), hasLength(2));
    },
  );

  test('enabled notifications do not show a permission prompt', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final service = NotificationService();
    await service.init();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final activity = Activity()
      ..id = 12
      ..title = 'Study'
      ..startMinute = 600
      ..endMinute = 660
      ..ampmHalf = AmPmHalf.am
      ..date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day)
      ..colorValue = 0xFFFFFFFF
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    await service.scheduleForActivity(activity);

    expect(calls, contains('areNotificationsEnabled'));
    expect(calls, isNot(contains('requestNotificationsPermission')));
    expect(calls, contains('zonedSchedule'));
  });

  test(
    'running timer does not request permission when notifications are disabled',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'areNotificationsEnabled' ? false : true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final service = NotificationService();
      await service.init();
      await service.scheduleTimerCompletion(remainingSeconds: 900);

      expect(
        calls.map((call) => call.method),
        contains('areNotificationsEnabled'),
      );
      expect(
        calls.map((call) => call.method),
        isNot(contains('requestNotificationsPermission')),
      );
      expect(
        calls.map((call) => call.method),
        isNot(contains('zonedSchedule')),
      );

      await service.cancelTimerCompletion();
    },
  );

  test(
    'running timer schedules its reminder when notifications are enabled',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final service = NotificationService();
      await service.init();
      await service.scheduleTimerCompletion(remainingSeconds: 900);

      expect(calls.map((call) => call.method), contains('zonedSchedule'));
      expect(
        calls.map((call) => call.method),
        isNot(contains('requestNotificationsPermission')),
      );
      final scheduled = calls.singleWhere(
        (call) => call.method == 'zonedSchedule',
      );
      final arguments = Map<Object?, Object?>.from(scheduled.arguments as Map);
      expect(
        arguments['id'],
        NotificationService.timerCompletionNotificationId,
      );
      expect(arguments['title'], 'Waktu sesi tercapai');
      expect(arguments['body'], 'Buka Focus Clock untuk meninjau sesi.');

      await service.cancelTimerCompletion();
      final cancelled = calls.lastWhere((call) => call.method == 'cancel');
      expect(
        (cancelled.arguments as Map)['id'],
        NotificationService.timerCompletionNotificationId,
      );
    },
  );
}
