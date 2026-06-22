import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:main_app/modules/ui/adsorption_line/pages/adsorption_line_page.dart';
import 'package:main_app/modules/ui/adsorption_line/state/drawing_state.dart';

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
}
