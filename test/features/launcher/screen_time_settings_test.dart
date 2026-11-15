import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/features/launcher/providers/launcher_settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrah_launcher/features/launcher/services/screen_time_service.dart';
import 'package:fitrah_launcher/features/launcher/widgets/fitrah_settings_screen.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import '../../launcher_daily_note_test.dart' show NoteStorage;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('fitrah_launcher/apps');
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('legacy settings keep both screen-time controls off', () {
    final settings = LauncherSettings.fromMap({'focusGoal': 'keep'});
    expect(settings.screenTimeCueEnabled, isFalse);
    expect(settings.gentleLimitEnabled, isFalse);
    expect(settings.dailyLimitMinutes, 120);
    expect(settings.gentleWaitSeconds, 20);
    final roundTrip = LauncherSettings.fromJson(settings.toJson());
    expect(roundTrip.screenTimeCueEnabled, isFalse);
    expect(roundTrip.gentleLimitEnabled, isFalse);
  });

  test('screen-time settings persist thresholds and switches', () async {
    final store = NoteStorage();
    final notifier = LauncherSettingsNotifier(store);
    await notifier.hydration;
    expect(await notifier.setScreenTimeThreshold(limitMinutes: 180), isTrue);
    expect(await notifier.setScreenTimeThreshold(waitSeconds: 30), isTrue);
    expect(await notifier.setScreenTimeCueEnabled(true), isTrue);
    expect(await notifier.setGentleLimitEnabled(true), isTrue);

    final reopened = LauncherSettingsNotifier(store);
    await reopened.hydration;
    expect(reopened.state.screenTimeCueEnabled, isTrue);
    expect(reopened.state.gentleLimitEnabled, isTrue);
    expect(reopened.state.dailyLimitMinutes, 180);
    expect(reopened.state.gentleWaitSeconds, 30);
    notifier.dispose();
    reopened.dispose();
  });

  test('screen-time thresholds are clamped to safe ranges', () {
    final settings = LauncherSettings.fromMap({
      'dailyLimitMinutes': -20,
      'gentleWaitSeconds': 0,
    });
    expect(settings.dailyLimitMinutes, 15);
    expect(settings.gentleWaitSeconds, 5);
  });

  test('service reports denied or unavailable usage honestly', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'checkUsageStatsPermission') return false;
      if (call.method == 'checkOverlayPermission') return true;
      return null;
    });
    final service = ScreenTimeService();
    expect(service.supported, isTrue);
    expect(await service.hasUsageAccess(), isFalse);
    expect(await service.hasOverlayAccess(), isTrue);
    expect((await service.today()).available, isFalse);
  });

  test(
    'null usage total remains unavailable when Usage Access is granted',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'checkUsageStatsPermission') return true;
        if (call.method == 'getTodayScreenTimeMinutes') return null;
        return null;
      });
      final usage = await ScreenTimeService().today();
      expect(usage.available, isFalse);
      expect(usage.minutes, isNull);
    },
  );

  test('usage is refreshed on every read across a local-day change', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var reads = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'checkUsageStatsPermission') return true;
      if (call.method == 'getTodayScreenTimeMinutes') {
        return reads++ == 0 ? 90 : 0;
      }
      return null;
    });
    final service = ScreenTimeService();
    expect((await service.today()).minutes, 90);
    expect((await service.today()).minutes, 0);
  });

  test('opt-out and revoked overlay both sync removal to native cue', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var overlayGranted = true;
    final syncValues = <bool>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'checkUsageStatsPermission') return true;
      if (call.method == 'checkOverlayPermission') return overlayGranted;
      if (call.method == 'syncScreenTimeCue') {
        syncValues.add((call.arguments as Map)['enabled'] as bool);
      }
      return null;
    });
    final service = ScreenTimeService();
    final enabled = await service.cueAvailable(optedIn: true);
    await service.sync(cueEnabled: enabled);
    overlayGranted = false;
    final revoked = await service.cueAvailable(optedIn: true);
    await service.sync(cueEnabled: revoked);
    await service.sync(cueEnabled: await service.cueAvailable(optedIn: false));
    expect(syncValues, [true, false, false]);
  });

  test('cue is active only when the native window confirms it', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var windowAvailable = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'syncScreenTimeCue') {
        return (call.arguments as Map)['enabled'] == true && windowAvailable;
      }
      return null;
    });
    final service = ScreenTimeService();
    expect(await service.sync(cueEnabled: true), isFalse);
    windowAvailable = true;
    expect(await service.sync(cueEnabled: true), isTrue);
    expect(await service.sync(cueEnabled: false), isFalse);
  });

  testWidgets('screen-time settings remain readable at 320dp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(NoteStorage()),
        ],
        child: const MaterialApp(home: FitrahSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Waktu layar'), findsOneWidget);
    expect(find.text('120 menit'), findsOneWidget);
    expect(find.text('20 detik'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unsupported platforms label and disable Android-only controls',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(NoteStorage()),
          ],
          child: const MaterialApp(home: FitrahSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Android saja — tidak tersedia di platform ini'),
        findsNWidgets(2),
      );
      final cueSwitch = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('screen-time-cue-switch')),
      );
      final limitSwitch = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Batas harian lembut'),
      );
      expect(cueSwitch.onChanged, isNull);
      expect(limitSwitch.onChanged, isNull);
      expect(
        find.text('Cue Android saja — tidak tersedia di platform ini'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'first enable explains access and Later has no OS side effect',
    (tester) async {
      final store = NoteStorage();
      var openUsageSettingsCalls = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'checkUsageStatsPermission') return false;
        if (call.method == 'checkOverlayPermission') return false;
        if (call.method == 'openUsageStatsSettings') openUsageSettingsCalls++;
        return true;
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [secureStorageServiceProvider.overrideWithValue(store)],
          child: const MaterialApp(home: FitrahSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('screen-time-cue-switch')));
      await tester.pumpAndSettle();
      expect(find.text('Usage Access diperlukan'), findsOneWidget);
      await tester.tap(find.text('Nanti'));
      await tester.pumpAndSettle();
      expect(openUsageSettingsCalls, 0);
      expect(store.raw, isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
