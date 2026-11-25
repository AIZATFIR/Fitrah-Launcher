import 'package:fitrah_launcher/data/storage_unavailable_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('storage failure explains data safety and offers retry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      StorageUnavailableApp(
        onRetry: () async {
          retries++;
        },
      ),
    );

    expect(find.text('Data belum dapat dibuka'), findsOneWidget);
    expect(find.textContaining('tidak tersimpan sementara'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(retries, 1);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
