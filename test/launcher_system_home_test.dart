import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';
import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/features/launcher/fitrah_launcher_shell.dart';
import 'package:fitrah_launcher/features/launcher/services/app_launcher_service.dart';
import 'package:fitrah_launcher/providers/intent_providers.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'launcher_daily_note_test.dart' show NoteStorage;

const channel = MethodChannel('fitrah_launcher/home');

Future<void> sendHome(WidgetTester tester, [String method = 'home']) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    channel.name,
    const StandardMethodCodec().encodeMethodCall(MethodCall(method)),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('HOME dismisses settings and selects current goal Home', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(NoteStorage()),
          isarProvider.overrideWithValue(null),
          installedAppsFutureProvider.overrideWith((_) async => []),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          home: const FitrahLauncherShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final page = tester.widget<PageView>(find.byType(PageView));
    page.controller!.jumpToPage(2);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FitrahLauncherShell)),
    );
    final engine = container.read(timerEngineProvider.notifier);
    await engine.startNonHabit(
      title: 'Preserved Home session',
      targetSeconds: 900,
      sourceKind: TimerSessionSourceKind.preset,
    );
    final session = await container
        .read(sadarRepoProvider)
        .getActiveTimerSession();
    container.read(currentDateProvider.notifier).state = DateTime(2030);
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('settings route')),
      ),
    );
    await tester.pumpAndSettle();
    await sendHome(tester);
    expect(find.text('settings route'), findsNothing);
    expect(page.controller!.page, 1);
    expect(
      container.read(currentDateProvider),
      dateOnly(container.read(intentNowProvider)),
    );
    expect(container.read(timerEngineProvider).isRunning, isTrue);
    expect(
      (await container.read(sadarRepoProvider).getActiveTimerSession())?.id,
      session?.id,
    );
    await engine.pause();
    final paused = container.read(timerEngineProvider);
    await sendHome(tester);
    expect(container.read(timerEngineProvider), same(paused));
    expect(page.controller!.page, 1);
    await engine.cancel();
    await tester.pumpWidget(const SizedBox());
    await sendHome(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'resume and unknown events preserve route; guarded HOME terminates',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      var blockedPops = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(NoteStorage()),
            isarProvider.overrideWithValue(null),
          ],
          child: MaterialApp(
            navigatorKey: navigator,
            home: const FitrahLauncherShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) blockedPops++;
            },
            child: const Scaffold(body: Text('pending editor')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await sendHome(tester, 'unknown');
      expect(find.text('pending editor'), findsOneWidget);
      await sendHome(tester);
      expect(find.text('pending editor'), findsOneWidget);
      expect(blockedPops, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
