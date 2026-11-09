import 'dart:async';

import 'package:fitrah_launcher/features/launcher/widgets/default_home_status_control.dart';
import 'package:fitrah_launcher/features/launcher/services/app_launcher_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service extends AppLauncherService {
  _Service(this.supported);
  final bool supported;
  @override
  bool get isSupported => supported;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('fitrah_launcher/apps');
  var supported = true;
  setUp(() => supported = true);
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> show(WidgetTester tester, {double scale = 1}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLauncherServiceProvider.overrideWithValue(_Service(supported)),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: ListView(children: const [DefaultHomeStatusControl()]),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('slow read disables choice; true and false report OS status', (
    tester,
  ) async {
    final query = Completer<bool>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) => query.future,
    );
    await show(tester);
    expect(find.text('Memeriksa launcher default…'), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    query.complete(true);
    await tester.pumpAndSettle();
    expect(
      find.text('Fitrah adalah launcher default Android.'),
      findsOneWidget,
    );
  });

  testWidgets('held status opens Home Settings to change launcher', (
    tester,
  ) async {
    final actions = <String>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'isDefaultHome') return true;
      actions.add(call.method);
      return true;
    });
    await show(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah launcher default'));
    await tester.pumpAndSettle();
    expect(actions, ['openHomeSettings']);
    expect(
      find.text('Fitrah adalah launcher default Android.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'cancel or another selection never claims success; resume refreshes',
    (tester) async {
      var selected = false;
      var reads = 0;
      var requests = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'isDefaultHome') {
          reads++;
          return selected;
        }
        expect(call.method, 'requestDefaultHome');
        requests++;
        return true;
      });
      await show(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilih launcher default'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(
        find.text('Fitrah belum menjadi launcher default Android.'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
      selected = true;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(reads, greaterThanOrEqualTo(3));
      expect(
        find.text('Fitrah adalah launcher default Android.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'bad reads show unknown with retry; failed requests stay retryable',
    (tester) async {
      Object? status;
      Object? action = false;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'isDefaultHome') return status;
        if (action is Exception) throw action;
        return action;
      });
      await show(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Status launcher default belum dapat diperiksa.'),
        findsOneWidget,
      );
      expect(
        find.text('Fitrah belum menjadi launcher default Android.'),
        findsNothing,
      );
      status = false;
      await tester.tap(find.text('Periksa lagi'));
      await tester.pumpAndSettle();
      for (final failure in [false, PlatformException(code: 'unavailable')]) {
        action = failure;
        await tester.tap(find.text('Pilih launcher default'));
        await tester.pumpAndSettle();
        expect(
          find.text('Pilihan launcher tidak dapat dibuka. Coba lagi.'),
          findsOneWidget,
        );
        expect(
          tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNotNull,
        );
      }
    },
  );

  testWidgets(
    'pending request rejects repeat taps and is safe after disposal',
    (tester) async {
      final request = Completer<bool>();
      var requests = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) {
        if (call.method == 'isDefaultHome') return Future.value(false);
        requests++;
        return request.future;
      });
      await show(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilih launcher default'));
      await tester.pump();
      await tester.tap(find.text('Membuka pilihan Android…'));
      expect(requests, 1);
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      request.complete(true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unsupported platform explains capability without native calls', (
    tester,
  ) async {
    supported = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
      fail('Unsupported host invoked native');
    });
    await show(tester);
    expect(
      find.text('Launcher default hanya tersedia di Android.'),
      findsOneWidget,
    );
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('320dp at 200 percent remains scrollable with 48dp controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => null,
    );
    await show(tester, scale: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final button in find.byType(TextButton).evaluate()) {
      expect(
        tester.getSize(find.byWidget(button.widget)).height,
        greaterThanOrEqualTo(48),
      );
    }
    await tester.scrollUntilVisible(find.text('Pilih launcher default'), 120);
    expect(tester.takeException(), isNull);
  });
}
