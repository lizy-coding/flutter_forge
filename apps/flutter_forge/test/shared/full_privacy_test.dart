import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/creator_home_page.dart';
import 'package:flutter_forge_app/app/full_privacy.dart';
import 'package:flutter_forge_app/app/offline_privacy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
