import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  for (var count = 3; count <= 6; count++) {
    for (var target = 1; target < count - 1; target++) {
      testWidgets('$count segments: slow drag settles on segment $target',
          (tester) async {
        final selections = await _pumpControl(tester, count: count);
        final start = tester.getCenter(find.text('Segment 0'));
        final end = tester.getCenter(find.text('Segment $target'));

        await tester.timedDragFrom(
            start, end - start, const Duration(seconds: 2));
        await tester.pumpAndSettle();

        _expectSelection(tester, selections, target);
      });
    }
  }

  for (final direction in Axis.values) {
    for (final initialIndex in [0, 2]) {
      testWidgets(
          '${direction.name}: fast drag from $initialIndex selects the middle',
          (tester) async {
        final selections = await _pumpControl(
          tester,
          direction: direction,
          selectedIndex: initialIndex,
        );
        final start = tester.getCenter(find.text('Segment $initialIndex'));
        final end = tester.getCenter(find.text('Segment 1'));

        await tester.timedDragFrom(
          start,
          end - start,
          const Duration(milliseconds: 60),
        );
        await tester.pumpAndSettle();

        _expectSelection(tester, selections, 1);
      });
    }

    testWidgets('${direction.name}: cancelled drag snaps to the middle',
        (tester) async {
      final selections = await _pumpControl(tester, direction: direction);
      final start = tester.getCenter(find.text('Segment 0'));
      final end = tester.getCenter(find.text('Segment 1'));
      final gesture = await tester.startGesture(start);
      await gesture.moveTo(Offset.lerp(start, end, 0.5)!);
      await tester.pump();
      await gesture.moveTo(end);
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();

      _expectSelection(tester, selections, 1);
    });
  }

  testWidgets('RTL drag settles on the middle segment', (tester) async {
    final selections = await _pumpControl(
      tester,
      textDirection: TextDirection.rtl,
    );
    final start = tester.getCenter(find.text('Segment 0'));
    final end = tester.getCenter(find.text('Segment 1'));

    await tester.timedDragFrom(
      start,
      end - start,
      const Duration(milliseconds: 60),
    );
    await tester.pumpAndSettle();

    _expectSelection(tester, selections, 1);
  });
}

Future<List<int>> _pumpControl(
  WidgetTester tester, {
  int count = 3,
  int selectedIndex = 0,
  Axis direction = Axis.horizontal,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  final selections = <int>[];
  var currentIndex = selectedIndex;
  await tester.pumpWidget(
    CupertinoApp(
      home: Directionality(
        textDirection: textDirection,
        child: Center(
          child: SizedBox(
            width: direction == Axis.horizontal ? 360 : 96,
            child: StatefulBuilder(
              builder: (context, setState) => GlassSegmentedControl(
                segments: [
                  for (var index = 0; index < count; index++)
                    GlassSegment(label: 'Segment $index'),
                ],
                selectedIndex: currentIndex,
                onSegmentSelected: (index) {
                  selections.add(index);
                  setState(() => currentIndex = index);
                },
                direction: direction,
                height: direction == Axis.horizontal ? 32 : 96,
                segmentExtent: 64,
                quality: GlassQuality.minimal,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return selections;
}

void _expectSelection(WidgetTester tester, List<int> selections, int expected) {
  expect(selections, [expected]);
  expect(
    tester
        .widget<GlassSegmentedControl>(find.byType(GlassSegmentedControl))
        .selectedIndex,
    expected,
  );
  expect(tester.takeException(), isNull);
}
