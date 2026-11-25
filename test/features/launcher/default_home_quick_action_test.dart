import 'package:fitrah_launcher/features/launcher/services/app_launcher_service.dart';
import 'package:fitrah_launcher/features/launcher/widgets/default_home_status_control.dart';
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
  tearDown(
    () =>
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
  );

  Future<void> show(WidgetTester tester, {bool supported = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLauncherServiceProvider.overrideWithValue(_Service(supported)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DefaultHomeQuickAction()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('keeps the setup action usable at 320dp and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLauncherServiceProvider.overrideWithValue(_Service(true)),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: DefaultHomeQuickAction(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Jadikan layar utama'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('offers compact action only when Android confirms not default', (
    tester,
  ) async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      expect(call.method, 'isDefaultHome');
      return false;
    });
    await show(tester);
    expect(find.text('Jadikan layar utama'), findsOneWidget);
  });

  testWidgets(
    'dispatches system choice and hides when status becomes default',
    (tester) async {
      var held = false;
      var requested = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'isDefaultHome') return held;
        expect(call.method, 'requestDefaultHome');
        requested++;
        held = true;
        return true;
      });
      await show(tester);
      await tester.tap(find.text('Jadikan layar utama'));
      await tester.pumpAndSettle();
      expect(requested, 1);
      expect(find.text('Jadikan layar utama'), findsNothing);
    },
  );

  testWidgets('stays absent off Android and while status is unknown', (
    tester,
  ) async {
    await show(tester, supported: false);
    expect(find.text('Jadikan layar utama'), findsNothing);

    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => null,
    );
    await show(tester);
    expect(find.text('Jadikan layar utama'), findsNothing);
  });
}
