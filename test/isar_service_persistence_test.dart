import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/data/isar_service.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/app_settings.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/habit_entry.dart';
import 'package:fitrah_launcher/models/preset.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

void main() {
  setUpAll(() async {
    if (Platform.isLinux) {
      final config =
          jsonDecode(
                await File('.dart_tool/package_config.json').readAsString(),
              )
              as Map<String, dynamic>;
      final packages = config['packages'] as List<dynamic>;
      final isarPackage = packages.cast<Map<String, dynamic>>().firstWhere(
        (package) => package['name'] == 'isar_community_flutter_libs',
      );
      final packageRoot = Uri.parse(isarPackage['rootUri'] as String);
      final libraryPath = switch (ffi.Abi.current()) {
        ffi.Abi.linuxX64 || ffi.Abi.linuxArm64 => 'linux/libisar.so',
        ffi.Abi.macosArm64 || ffi.Abi.macosX64 => 'macos/libisar.dylib',
        ffi.Abi.windowsArm64 || ffi.Abi.windowsX64 => 'windows/isar.dll',
        _ => throw UnsupportedError(
          'Isar native test unsupported on this ABI.',
        ),
      };
      final library = File('${packageRoot.path}/$libraryPath');
      await Isar.initializeIsarCore(
        libraries: {ffi.Abi.current(): library.path},
      );
    }
  });

  test(
    'fresh store only seeds settings and preserves activity after reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'focus_clock_isar_',
      );
      addTearDown(() => directory.delete(recursive: true));

      final firstOpen = await IsarService.openAt(directory.path);
      final firstDb = firstOpen.isar!;

      expect(await firstDb.appSettings.count(), 1);
      expect(await firstDb.presets.count(), 0);
      expect(await firstDb.habits.count(), 0);
      expect(await firstDb.activitys.count(), 0);

      final now = DateTime(2026, 11, 4, 9);
      final activity = Activity()
        ..title = 'Latihan LKS'
        ..startMinute = 9 * 60
        ..endMinute = 10 * 60
        ..ampmHalf = AmPmHalf.am
        ..date = dateOnly(now)
        ..colorValue = 0xFF8BAE9A
        ..createdAt = now
        ..updatedAt = now;
      final id = await firstDb.writeTxn(() => firstDb.activitys.put(activity));

      final repository = SadarRepository(firstDb);
      final session = TimerSession()
        ..habitId = 42
        ..habitName = 'Latihan LKS'
        ..targetSeconds = 1200
        ..startedAt = now
        ..status = TimerStateStatus.completed
        ..accumulatedDurationSeconds = 615
        ..updatedAt = now;
      await repository.saveTimerSession(session);
      await repository.completeTimerSession(
        habitId: 42,
        dateString: '2026-11-04',
        actualDurationMinutes: 10,
        targetSnapshot: 20,
        completedAt: now,
      );
      await repository.saveTimerSession(
        TimerSession()
          ..habitId = 42
          ..habitName = 'Latihan LKS'
          ..targetSeconds = 1200
          ..startedAt = now.add(const Duration(hours: 1))
          ..status = TimerStateStatus.completed
          ..accumulatedDurationSeconds = 8 * 60
          ..updatedAt = now,
      );
      await repository.completeTimerSession(
        habitId: 42,
        dateString: '2026-11-04',
        actualDurationMinutes: 8,
        targetSnapshot: 20,
        completedAt: now.add(const Duration(hours: 1)),
      );

      await firstDb.close();

      final secondOpen = await IsarService.openAt(directory.path);
      addTearDown(() => secondOpen.isar!.close());
      final restored = await secondOpen.isar!.activitys.get(id);

      expect(restored, isNotNull);
      expect(restored!.title, 'Latihan LKS');
      expect(restored.startMinute, 540);
      expect(restored.date, dateOnly(now));
      expect(await secondOpen.isar!.activitys.count(), 1);
      expect(await secondOpen.isar!.appSettings.count(), 1);
      final restoredEntry = await secondOpen.isar!.habitEntrys
          .filter()
          .habitIdEqualTo(42)
          .dateStringEqualTo('2026-11-04')
          .findFirst();
      expect(restoredEntry?.actualDurationMinutes, 18);
      expect(restoredEntry?.valueCompleted, 18);
      expect(restoredEntry?.targetSnapshot, 20);
      expect(await secondOpen.isar!.timerSessions.count(), 0);
    },
  );

  test('unavailable store keeps timer session for recovery', () async {
    final directory = await Directory.systemTemp.createTemp(
      'focus_clock_failed_timer_',
    );
    addTearDown(() => directory.delete(recursive: true));

    final opened = await IsarService.openAt(directory.path);
    final db = opened.isar!;
    final repository = SadarRepository(db);
    final session = TimerSession()
      ..habitId = 42
      ..habitName = 'Latihan LKS'
      ..targetSeconds = 1200
      ..startedAt = DateTime(2026, 11, 4, 9)
      ..status = TimerStateStatus.completed
      ..accumulatedDurationSeconds = 615
      ..updatedAt = DateTime(2026, 11, 4, 9);
    await repository.saveTimerSession(session);
    await db.close();

    await expectLater(
      repository.completeTimerSession(
        habitId: 42,
        dateString: '2026-11-04',
        actualDurationMinutes: 10,
        targetSnapshot: 20,
        completedAt: DateTime(2026, 11, 4, 9, 11),
      ),
      throwsA(anything),
    );

    final reopened = await IsarService.openAt(directory.path);
    addTearDown(() => reopened.isar!.close());
    expect(await reopened.isar!.timerSessions.get(1), isNotNull);
    expect(await reopened.isar!.habitEntrys.count(), 0);
  });
}
