import '../../launcher_daily_note_test.dart' show NoteStorage;
import 'package:fitrah_launcher/services/secure_storage_service.dart';
import 'dart:async';

import 'package:fitrah_launcher/features/launcher/widgets/minimalist_app_drawer.dart';
import 'package:fitrah_launcher/features/launcher/widgets/niagara_wave_scrubber.dart';
import 'package:fitrah_launcher/features/launcher/models/launcher_settings.dart';
import 'package:fitrah_launcher/features/sadar/widgets/allowed_apps_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('fitrah_launcher/apps');
  const realApps = [
    {
      'appName': 'Real Device App',
      'packageName': 'real.device.app',
      'isSystem': false,
    },
  ];
  tearDown(
    () =>
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
  );

  Future<void> showDrawer(
    WidgetTester tester, {
    double textScale = 1,
    NoteStorage? storage,
    VoidCallback? onBackToHome,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(
            storage ?? NoteStorage(),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: MinimalistAppDrawer(onBackToHome: onBackToHome),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets(
    'daily limit waits before drawer launch and offers immediate goal return',
    (tester) async {
      final storage = NoteStorage()
        ..raw = LauncherSettings(
          gentleLimitEnabled: true,
          dailyLimitMinutes: 120,
          gentleWaitSeconds: 5,
        ).toJson();
      var launches = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'getInstalledApps') return realApps;
        if (call.method == 'getAppIcon') return null;
        if (call.method == 'checkUsageStatsPermission') return true;
        if (call.method == 'getTodayScreenTimeMinutes') return 125;
        if (call.method == 'launchApp') {
          launches++;
          return true;
        }
        return false;
      });
      await showDrawer(tester, storage: storage);
      await tester.tap(find.text('Real Device App'));
      await tester.pumpAndSettle();
      expect(find.textContaining('sudah 125 menit'), findsOneWidget);
      expect(launches, 0);
      expect(find.text('Lanjut setelah 5 dtk'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('Lanjutkan'), findsOneWidget);
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(launches, 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'unavailable usage fails open and launches without claiming zero minutes',
    (tester) async {
      final storage = NoteStorage()
        ..raw = LauncherSettings(gentleLimitEnabled: true).toJson();
      var launches = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'getInstalledApps') return realApps;
        if (call.method == 'checkUsageStatsPermission') return false;
        if (call.method == 'launchApp') {
          launches++;
          return true;
        }
        return null;
      });
      await showDrawer(tester, storage: storage);
      await tester.tap(find.text('Real Device App'));
      await tester.pumpAndSettle();
      expect(launches, 1);
      expect(find.text('Saatnya melihat tujuan'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'goal return closes the limit prompt without launching app',
    (tester) async {
      final storage = NoteStorage()
        ..raw = LauncherSettings(
          gentleLimitEnabled: true,
          dailyLimitMinutes: 60,
          gentleWaitSeconds: 20,
        ).toJson();
      var launches = 0;
      var returnedHome = false;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'getInstalledApps') return realApps;
        if (call.method == 'checkUsageStatsPermission') return true;
        if (call.method == 'getTodayScreenTimeMinutes') return 75;
        if (call.method == 'launchApp') launches++;
        return null;
      });
      await showDrawer(
        tester,
        storage: storage,
        onBackToHome: () => returnedHome = true,
      );
      await tester.tap(find.text('Real Device App'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lihat tujuan'));
      await tester.pumpAndSettle();
      expect(returnedHome, isTrue);
      expect(launches, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'listing failure retries into actual apps and failed launch is visible',
    (tester) async {
      var listCalls = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'getInstalledApps') {
          if (++listCalls == 1) {
            throw PlatformException(
              code: 'temporary',
              message: 'private trace',
            );
          }
          return realApps;
        }
        if (call.method == 'getAppIcon') return null;
        return false;
      });
      await showDrawer(tester);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.textContaining('private trace'), findsNothing);
      expect(find.text('Browser'), findsNothing);
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Real Device App'), findsOneWidget);
      await tester.tap(find.text('Real Device App'));
      await tester.pump();
      expect(
        find.textContaining('Tindakan tidak dapat dibuka'),
        findsOneWidget,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'sheet action completes after dismissal using drawer feedback context',
    (tester) async {
      final details = Completer<bool>();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'getInstalledApps') return realApps;
        if (call.method == 'openAppDetails') return details.future;
        return null;
      });
      await showDrawer(tester);
      await tester.longPress(find.text('Real Device App'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Info aplikasi'));
      await tester.pumpAndSettle();
      expect(find.text('Info aplikasi'), findsNothing);
      details.complete(false);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Tindakan tidak dapat dibuka'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'native app details action releases search keyboard before dispatch',
    (tester) async {
      var dispatched = false;
      var keyboardFocusedAtDispatch = true;
      FocusNode? searchFocus;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'getInstalledApps') return realApps;
        if (call.method == 'openAppDetails') {
          dispatched = true;
          keyboardFocusedAtDispatch = searchFocus?.hasFocus ?? false;
          return true;
        }
        return null;
      });
      await showDrawer(tester);
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      searchFocus = tester.widget<TextField>(find.byType(TextField)).focusNode;
      await tester.enterText(find.byType(TextField), 'Real');
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Real Device App'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Info aplikasi'));
      await tester.pumpAndSettle();

      expect(dispatched, isTrue);
      expect(keyboardFocusedAtDispatch, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'unsupported drawer at 320dp and 200% text explains capability without retry',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await showDrawer(tester, textScale: 2);
      expect(
        find.text('Daftar aplikasi perangkat hanya tersedia di Android.'),
        findsOneWidget,
      );
      expect(find.text('Coba lagi'), findsNothing);
      expect(find.text('Browser'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'failure retry fits compact large text and remains at least 48dp',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'failure'),
      );
      await showDrawer(tester, textScale: 2);
      final retry = find.widgetWithText(TextButton, 'Coba lagi');
      expect(retry, findsOneWidget);
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'active app index fits a 320dp screen with a 48dp touch rail',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'getInstalledApps' ? realApps : null,
      );

      await showDrawer(tester);

      final index = find.byType(NiagaraWaveScrubber);
      expect(index, findsOneWidget);
      expect(tester.getSize(index).width, greaterThanOrEqualTo(48));
      final search = find
          .ancestor(
            of: find.byIcon(Icons.search_rounded),
            matching: find.byWidgetPredicate(
              (widget) => widget is GestureDetector && widget.onTap != null,
            ),
          )
          .first;
      expect(tester.getRect(index).overlaps(tester.getRect(search)), isFalse);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'choosing a letter with no installed apps leaves the drawer usable',
    (tester) async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'getInstalledApps' ? realApps : null,
      );
      final semantics = tester.ensureSemantics();
      await showDrawer(tester);

      for (var i = 0; i < 2; i++) {
        final index = tester.getSemantics(
          find.bySemanticsLabel('Pilih bagian daftar aplikasi'),
        );
        index.owner!.performAction(index.id, SemanticsAction.increase);
        await tester.pumpAndSettle();
      }

      expect(find.text('Real Device App'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Pilih bagian daftar aplikasi'))
            .getSemanticsData()
            .value,
        'A',
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'real empty and search without matches have distinct messages',
    (tester) async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => [],
      );
      await showDrawer(tester);
      expect(
        find.text('Tidak ada aplikasi terpasang yang dapat dibuka.'),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pump();
      expect(
        find.text('Tidak ada aplikasi yang cocok dengan pencarian.'),
        findsOneWidget,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'allowed selections survive listing failure and recovery',
    (tester) async {
      var listCalls = 0;
      List<String>? saved;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (++listCalls == 1) throw PlatformException(code: 'temporary');
        return realApps;
      });
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AllowedAppsSelectorDialog(
                initialAllowed: const ['previously.installed.app'],
                onSaved: (packages) => saved = packages,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Simpan (1 Aplikasi Diizinkan)'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Real Device App'), findsOneWidget);
      await tester.tap(find.text('Simpan (1 Aplikasi Diizinkan)'));
      await tester.pump();
      expect(saved, ['previously.installed.app']);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
