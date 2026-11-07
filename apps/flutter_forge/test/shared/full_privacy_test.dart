import '../support/app_info_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/creator_home_page.dart';
import 'package:flutter_forge_app/app/full_privacy.dart';
import 'package:flutter_forge_app/app/offline_privacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_forge_app/app/workbench_history.dart';

void main() {
  setUp(useAppInfoFixture);
  testWidgets('full edition About exposes its own privacy notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CreatorHomePage())),
    );
    expect(find.byType(FullPrivacy), findsOneWidget);
    expect(find.byType(OfflinePrivacy), findsNothing);
  });

  testWidgets('privacy text expands and remains readable at compact width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: FullPrivacy())),
      ),
    );
    expect(find.text(fullPrivacyPolicy), findsNothing);
    await tester.tap(find.byKey(const ValueKey('full-privacy-notice')));
    await tester.pumpAndSettle();
    expect(find.text(fullPrivacyPolicy), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('data controls clear only recent visits at compact width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'unrelated.preference': 'keep'});
    final preferences = await SharedPreferences.getInstance();
    final history = WorkbenchHistory(preferences: preferences)
      ..record('/lesson');
    await tester.pumpWidget(
      WorkbenchHistoryScope(
        history: history,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: FullPrivacy())),
        ),
      ),
    );
    expect(find.text('隐私与数据'), findsOneWidget);
    expect(find.text('政策版本：$fullPrivacyVersion'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('privacy-data-controls')));
    await tester.pumpAndSettle();
    final clear = find.byKey(const ValueKey('privacy-clear-recent'));
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(history.recent, isEmpty);
    expect(preferences.getStringList(WorkbenchHistory.preferenceKey), isNull);
    expect(preferences.getString('unrelated.preference'), 'keep');
    expect(find.text('最近访问已清除'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    history.dispose();
  });

  test('clear serializes pending writes and preserves later visits', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final history = WorkbenchHistory(preferences: preferences);
    history.record('/before');
    final clearing = history.clear();
    history.record('/after');
    await clearing;
    await Future<void>.delayed(Duration.zero);
    expect(history.recent, ['/after']);
    expect(preferences.getStringList(WorkbenchHistory.preferenceKey), [
      '/after',
    ]);
    history.dispose();
  });
}
