import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/ui/download_animation/pages/download_animation_page.dart';
import 'package:flutter_forge_app/modules/ui/download_animation/pages/download_comparison_page.dart';
import 'package:flutter_forge_app/modules/ui/download_animation/pages/paint_animation_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping download flies an item and reports completion', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DownloadAnimationPage()));
    await tester.pumpAndSettle();

    final downloadChips = find.text('下载');
    expect(downloadChips, findsAtLeastNWidgets(1));
    await tester.ensureVisible(downloadChips.first);

    await tester.tap(downloadChips.first, warnIfMissed: false);
    // The chip uses onTapDown: press-and-hold semantics trigger the flight.
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(
      find.textContaining('下载完成'),
      findsAtLeastNWidgets(1),
      reason: '飞入动画结束后应弹出完成提示',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings toggle shows and hides the parameter panel', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DownloadAnimationPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('动画设置'));
    await tester.pumpAndSettle();
    expect(find.text('动画参数设置'), findsOneWidget);

    await tester.tap(find.byTooltip('动画设置'));
    await tester.pumpAndSettle();
    expect(find.text('动画参数设置'), findsNothing);
  });

  testWidgets('comparison and paint pages render without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DownloadComparisonPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(home: PaintAnimationPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
