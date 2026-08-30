import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_forge_app/modules/ui/adsorption_line/pages/adsorption_line_page.dart';
import 'package:flutter_forge_app/modules/ui/adsorption_line/state/drawing_state.dart';
import 'package:flutter_forge_app/modules/ui/adsorption_line/models/drawing_element.dart';
import 'package:flutter_forge_app/modules/ui/adsorption_line/widgets/drawing_canvas.dart';

void main() {
  testWidgets('AdsorptionLinePage renders teaching components', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => DrawingState(),
          child: const AdsorptionLinePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('🎯 学习目标'), findsOneWidget);
    expect(find.text('⚠️ 常见误区'), findsOneWidget);
  });

  test('drawing state throttles drag updates within one frame', () {
    final state = DrawingState();
    state.addElement(
      const DrawingElement(
        id: 'dragged',
        position: Offset.zero,
        size: Size(20, 20),
        type: ElementType.rectangle,
      ),
    );
    state.selectElement('dragged');
    var notifications = 0;
    state.addListener(() => notifications++);
    state.startDrag(const Offset(1, 1));
    final beforeUpdates = notifications;

    state.updateDrag(const Offset(2, 2));
    state.updateDrag(const Offset(3, 3));

    expect(notifications, lessThanOrEqualTo(beforeUpdates + 1));
    state.endDrag();
    state.dispose();
  });

  test('drawing painter repaints only when version or selection changes', () {
    const element = DrawingElement(
      id: 'one',
      position: Offset.zero,
      size: Size(20, 20),
      type: ElementType.rectangle,
    );
    final first = DrawingCanvasPainter(elements: [element], elementsVersion: 1);
    final same = DrawingCanvasPainter(elements: [element], elementsVersion: 1);
    final changed = DrawingCanvasPainter(
      elements: [element],
      elementsVersion: 2,
    );

    expect(first.shouldRepaint(same), isFalse);
    expect(first.shouldRepaint(changed), isTrue);
  });
}
