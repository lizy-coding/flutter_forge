import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/android_privacy_consent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localesTestValue = [
      const Locale('zh'),
    ];
  });
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearLocalesTestValue();
  });
  test(
    'new installs and upgrades without explicit consent require notice',
    () async {
      SharedPreferences.setMockInitialValues({'flutter_forge.locale': 'en'});
      final preferences = await SharedPreferences.getInstance();
      final consent = AndroidPrivacyConsent(preferences);
      expect(consent.accepted, isFalse);
      await preferences.setString(
        AndroidPrivacyConsent.preferenceKey,
        'old-policy',
      );
      expect(consent.accepted, isFalse);
      expect(await consent.accept(), isTrue);
      expect(AndroidPrivacyConsent(preferences).accepted, isTrue);
      expect(preferences.getString('flutter_forge.locale'), 'en');
      await preferences.remove(AndroidPrivacyConsent.preferenceKey);
      expect(AndroidPrivacyConsent(preferences).accepted, isFalse);
    },
  );

  testWidgets('reading policy or declining never accepts or starts modules', (
    tester,
  ) async {
    var saves = 0;
    var starts = 0;
    var exits = 0;
    await tester.pumpWidget(
      AndroidPrivacyConsentApp(
        saveConsent: () async {
          saves++;
          return true;
        },
        onAccepted: () async {
          starts++;
        },
        onDeclined: () async {
          exits++;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('隐私说明'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('startup-privacy-policy')));
    await tester.pumpAndSettle();
    expect(find.text(AndroidPrivacyConsent.policy), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('不同意并退出'));
    await tester.pumpAndSettle();
    expect(exits, 1);
    expect(saves, 0);
    expect(starts, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exits, 2);
    expect(saves, 0);
  });

  testWidgets('save failure remains visible and retry starts only after save', (
    tester,
  ) async {
    var starts = 0;
    var succeed = false;
    await tester.pumpWidget(
      AndroidPrivacyConsentApp(
        saveConsent: () async => succeed,
        onAccepted: () async {
          starts++;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('同意并继续'));
    await tester.pumpAndSettle();
    expect(starts, 0);
    expect(find.text('未能保存你的选择，请重试；尚未进入应用。'), findsOneWidget);
    succeed = true;
    await tester.tap(find.text('同意并继续'));
    await tester.pumpAndSettle();
    expect(starts, 1);
  });

  testWidgets('pending save disables duplicate acceptance', (tester) async {
    final saving = Completer<bool>();
    var starts = 0;
    await tester.pumpWidget(
      AndroidPrivacyConsentApp(
        saveConsent: () => saving.future,
        onAccepted: () async {
          starts++;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('同意并继续'));
    await tester.pump();
    expect(find.text('正在保存…'), findsOneWidget);
    expect(starts, 0);
    saving.complete(true);
    await tester.pumpAndSettle();
    expect(starts, 1);
  });

  testWidgets('compact English notice and policy stay readable at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      AndroidPrivacyConsentApp(
        saveConsent: () async => true,
        onAccepted: () async {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Privacy notice'), findsOneWidget);
    expect(find.text('Agree and continue'), findsOneWidget);
    final policy = find.byKey(const ValueKey('startup-privacy-policy'));
    await tester.ensureVisible(policy);
    await tester.tap(policy);
    await tester.pumpAndSettle();
    expect(find.text(AndroidPrivacyConsent.policy), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
