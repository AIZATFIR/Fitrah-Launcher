import 'dart:async';

import 'package:fitrah_launcher/features/launcher/widgets/minimalist_app_drawer.dart';
import 'package:fitrah_launcher/features/sadar/widgets/allowed_apps_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> showDrawer(WidgetTester tester, {double textScale = 1}) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const MinimalistAppDrawer(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

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
      await tester.tap(find.text('App info'));
      await tester.pumpAndSettle();
      expect(find.text('App info'), findsNothing);
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
