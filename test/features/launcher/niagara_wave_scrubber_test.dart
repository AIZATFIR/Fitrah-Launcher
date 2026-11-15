import 'package:fitrah_launcher/core/theme.dart';
import 'package:fitrah_launcher/features/launcher/widgets/niagara_wave_scrubber.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alphabet = ['☆', 'A', 'B', '○'];

  Widget buildScrubber({
    required String selectedLetter,
    required ValueChanged<String> onLetterSelected,
  }) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 48,
          height: 400,
          child: NiagaraWaveScrubber(
            key: const ValueKey('scrubber'),
            alphabet: alphabet,
            selectedLetter: selectedLetter,
            onLetterSelected: onLetterSelected,
            topPadding: 0,
            bottomPadding: 0,
          ),
        ),
      ),
    ),
  );

  testWidgets('screen reader adjusts the selected section', (tester) async {
    final selected = <String>[];
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      buildScrubber(selectedLetter: 'A', onLetterSelected: selected.add),
    );

    final node = tester.getSemantics(
      find.bySemanticsLabel('Pilih bagian daftar aplikasi'),
    );
    expect(node.getSemanticsData().value, 'A');
    expect(node.getSemanticsData().increasedValue, 'B');
    expect(node.getSemanticsData().decreasedValue, 'Favorit');
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pump();

    expect(selected, ['B']);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Pilih bagian daftar aplikasi'))
          .getSemanticsData()
          .value,
      'B',
    );
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('screen reader adjustment clamps at both endpoints', (
    tester,
  ) async {
    final selected = <String>[];
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      buildScrubber(selectedLetter: '☆', onLetterSelected: selected.add),
    );
    final firstNode = tester.getSemantics(
      find.bySemanticsLabel('Pilih bagian daftar aplikasi'),
    );
    expect(
      firstNode.getSemanticsData().hasAction(SemanticsAction.decrease),
      isFalse,
    );
    expect(selected, isEmpty);

    await tester.pumpWidget(
      buildScrubber(selectedLetter: '○', onLetterSelected: selected.add),
    );
    final lastNode = tester.getSemantics(
      find.bySemanticsLabel('Pilih bagian daftar aplikasi'),
    );
    expect(
      lastNode.getSemanticsData().hasAction(SemanticsAction.increase),
      isFalse,
    );
    expect(selected, isEmpty);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('drag still selects the section under the finger', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      buildScrubber(selectedLetter: '☆', onLetterSelected: selected.add),
    );
    final rail = tester.getRect(find.byKey(const ValueKey('scrubber')));
    await tester.dragFrom(
      Offset(rail.center.dx, rail.top + 1),
      Offset(0, rail.height - 2),
    );
    await tester.pumpAndSettle();

    expect(selected, ['○']);
  });

  testWidgets(
    'uses Bookpaper feedback, Material shortcut icons, and 48dp width',
    (tester) async {
      await tester.pumpWidget(
        buildScrubber(selectedLetter: '☆', onLetterSelected: (_) {}),
      );

      expect(tester.getSize(find.byKey(const ValueKey('scrubber'))).width, 48);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.vertical_align_bottom_rounded), findsOneWidget);
      final favoriteIcon = tester.widget<Icon>(find.byIcon(Icons.star_rounded));
      expect(favoriteIcon.color, AppPalette.accent);
    },
  );
}
