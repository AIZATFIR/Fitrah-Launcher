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
}
