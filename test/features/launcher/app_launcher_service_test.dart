import 'dart:async';

import 'package:fitrah_launcher/features/launcher/services/app_launcher_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('fitrah_launcher/apps');
  late AppLauncherService service;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    service = AppLauncherService();
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('unsupported platforms never list or dispatch sample apps', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(service.isSupported, isFalse);
    await expectLater(service.getInstalledApps(), throwsUnsupportedError);
    expect(await service.launchApp('real.package'), isFalse);
    expect(await service.launchClock(), isFalse);
  });

  test(
    'valid listing preserves labels, sorts and deduplicates packages',
    () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => [
          {'appName': 'Zulu', 'packageName': 'real.z', 'isSystem': true},
          {'appName': 'Alpha', 'packageName': 'real.a', 'isSystem': false},
          {
            'appName': 'Another alias',
            'packageName': 'real.z',
            'isSystem': true,
          },
        ],
      );
      final apps = await service.getInstalledApps();
      expect(apps.map((app) => app.appName), ['Alpha', 'Zulu']);
      expect(apps.map((app) => app.packageName), ['real.a', 'real.z']);
    },
  );

  test('empty list is real data and null or malformed lists fail', () async {
    for (final payload in <Object?>[
      null,
      'invalid',
      [null],
      [
        {'appName': '', 'packageName': 'real.a'},
      ],
      [
        {'appName': 'Alpha', 'packageName': 4},
      ],
      [
        {'appName': 'Alpha', 'packageName': 'real.a', 'isSystem': 'yes'},
      ],
    ]) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => payload,
      );
      await expectLater(service.getInstalledApps(), throwsFormatException);
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => [],
    );
    expect(await service.getInstalledApps(), isEmpty);
  });

  test('listing channel failures propagate for retry', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'failure'),
    );
    await expectLater(
      service.getInstalledApps(),
      throwsA(isA<PlatformException>()),
    );
  });

  test('Focus Clock launch targets the installed app package', () async {
    Map<Object?, Object?>? arguments;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      expect(call.method, 'launchApp');
      arguments = Map<Object?, Object?>.from(call.arguments as Map);
      return true;
    });

    expect(await service.launchFocusClock(), isTrue);
    expect(arguments, {'packageName': 'com.aizatfir.focus_clock'});
  });

  test('all action wrappers accept only a true dispatch result', () async {
    final actions = <Future<bool> Function()>[
      () => service.launchApp('real.a'),
      service.launchSadar,
      service.launchFocusClock,
      () => service.openAppDetails('real.a'),
      service.openHomeSettings,
      service.requestDefaultHome,
      service.openNotificationListenerSettings,
      service.launchClock,
      service.launchCalendar,
      service.launchDialer,
      service.launchCamera,
      () => service.uninstallApp('real.a'),
      service.expandNotificationsPanel,
    ];
    for (final result in [true, false, null, 'invalid']) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => result,
      );
      for (final action in actions) {
        expect(await action(), result == true);
      }
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'failure'),
    );
    for (final action in actions) {
      expect(await action(), isFalse);
    }
  });

  test(
    'default Home strictly decodes actual status and propagates read errors',
    () async {
      for (final value in [true, false, null, 'true', 1]) {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
          call,
        ) async {
          expect(call.method, 'isDefaultHome');
          return value;
        });
        if (value is bool) {
          expect(await service.isDefaultHome(), value);
        } else {
          await expectLater(service.isDefaultHome(), throwsFormatException);
        }
      }
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        _,
      ) async {
        throw PlatformException(code: 'read-failed');
      });
      await expectLater(
        service.isDefaultHome(),
        throwsA(isA<PlatformException>()),
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      await expectLater(
        service.isDefaultHome(),
        throwsA(isA<MissingPluginException>()),
      );
      expect(await service.requestDefaultHome(), isFalse);
    },
  );

  test('unsupported Home capabilities never invoke native', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
      fail('Native channel invoked on unsupported host');
    });
    await expectLater(service.isDefaultHome(), throwsUnsupportedError);
    expect(await service.requestDefaultHome(), isFalse);
  });

  test(
    'Home resume refresh ignores stale results and disposes listener',
    () async {
      final old = Completer<bool>();
      var calls = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) {
        calls++;
        return calls == 1 ? old.future : Future.value(true);
      });
      final container = ProviderContainer();
      final sub = container.listen(defaultHomeStatusProvider, (_, _) {});
      container.read(defaultHomeStatusProvider);
      await Future<void>.delayed(Duration.zero);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(await container.read(defaultHomeStatusProvider.future), isTrue);
      old.complete(false);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(defaultHomeStatusProvider).value, isTrue);
      expect(calls, 2);
      sub.close();
      container.dispose();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);
    },
  );

  test('icon errors recover without permanent failure caching', () async {
    var calls = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
      if (++calls == 1) throw PlatformException(code: 'temporary');
      return Uint8List.fromList([1, 2]);
    });
    expect(await service.getAppIcon('real.a'), isNull);
    expect(await service.getAppIcon('real.a'), [1, 2]);
    expect(await service.getAppIcon('real.a'), [1, 2]);
    expect(calls, 2);
  });

  test('old icon completion cannot replace a refreshed cache', () async {
    final old = Completer<Uint8List>();
    var calls = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) {
      if (++calls == 1) return old.future;
      return Future.value(Uint8List.fromList([2]));
    });
    final pending = service.getAppIcon('real.a');
    await Future<void>.delayed(Duration.zero);
    service.clearIconCache();
    expect(await service.getAppIcon('real.a'), [2]);
    old.complete(Uint8List.fromList([1]));
    expect(await pending, [1]);
    expect(await service.getAppIcon('real.a'), [2]);
    expect(calls, 2);
  });

  test(
    'retry and resume refresh listing and icons without duplicate listeners',
    () async {
      var listCalls = 0;
      var iconCalls = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'getAppIcon') {
          iconCalls++;
          if (iconCalls == 1) throw PlatformException(code: 'temporary icon');
          return Uint8List.fromList([iconCalls]);
        }
        if (++listCalls == 1) throw PlatformException(code: 'temporary');
        return [
          {'appName': 'Real $listCalls', 'packageName': 'real.a'},
        ];
      });
      final container = ProviderContainer();
      final sub = container.listen(installedAppsFutureProvider, (_, _) {});
      await expectLater(
        container.read(installedAppsFutureProvider.future),
        throwsA(isA<PlatformException>()),
      );
      container.invalidate(installedAppsFutureProvider);
      expect(
        (await container.read(
          installedAppsFutureProvider.future,
        )).single.appName,
        'Real 2',
      );
      expect(await container.read(appIconProvider('real.a').future), isNull);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(
        (await container.read(
          installedAppsFutureProvider.future,
        )).single.appName,
        'Real 3',
      );
      expect(await container.read(appIconProvider('real.a').future), [2]);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      await container.read(installedAppsFutureProvider.future);
      expect(listCalls, 4);
      sub.close();
      container.dispose();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(listCalls, 4);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
