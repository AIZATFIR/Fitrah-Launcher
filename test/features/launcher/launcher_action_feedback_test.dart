import 'dart:async';

import 'package:fitrah_launcher/features/launcher/services/app_launcher_service.dart';
import 'package:fitrah_launcher/features/launcher/widgets/launcher_action_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service extends AppLauncherService {
  _Service({this.supported = true});
  final bool supported;
  @override
  bool get isSupported => supported;
}

void main() {
  testWidgets(
    'feedback waits for dispatch and reports false or thrown results',
    (tester) async {
      final result = Completer<bool>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => runLauncherAction(
                    context,
                    _Service(),
                    (_) => result.future,
                  ),
                  child: const Text('Buka'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
      result.complete(false);
      await tester.pump();
      expect(
        find.textContaining('Tindakan tidak dapat dibuka'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => runLauncherAction(
                    context,
                    _Service(),
                    (_) async => throw StateError('private trace'),
                  ),
                  child: const Text('Coba'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Coba'));
      await tester.pump();
      expect(find.textContaining('private trace'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('accepted dispatch has no success claim', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () =>
                    runLauncherAction(context, _Service(), (_) async => true),
                child: const Text('Buka'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('unsupported action explains Android requirement', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => runLauncherAction(
                  context,
                  _Service(supported: false),
                  (_) async => false,
                ),
                child: const Text('Buka'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pump();
    expect(find.textContaining('hanya tersedia di Android'), findsOneWidget);
  });

  testWidgets(
    'completion after parent disposal does not touch disposed context',
    (tester) async {
      final result = Completer<bool>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => runLauncherAction(
                    context,
                    _Service(),
                    (_) => result.future,
                  ),
                  child: const Text('Buka'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pumpWidget(const SizedBox());
      result.complete(false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
