import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/app/app_version_panel.dart';
import 'package:flutter_forge_app/shared/platform/build_features.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_app_info/forge_app_info.dart';

class _FakeInfo extends AppInfoPlatform {
  AppInfoOutcome result = const AppInfoAvailable(
    InstalledAppInfo(
      version: '1.2.14',
      buildNumber: '4009',
      packageName: 'com.forge.forest',
    ),
  );
  @override
  Future<AppInfoOutcome> read() async => result;
}

void main() {
  late _FakeInfo fake;
  setUp(() {
    final original = AppInfoPlatform.instance;
    fake = _FakeInfo();
    AppInfoPlatform.instance = fake;
    addTearDown(() => AppInfoPlatform.instance = original);
  });
  testWidgets(
    'copies installed version and edition, reports clipboard failure honestly',
    (tester) async {
      String? copied;
      var fail = true;
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          if (fail) throw PlatformException(code: 'denied');
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppVersionPanel())),
      );
      await tester.pumpAndSettle();
      expect(find.text('版本 1.2.14 · 构建 4009'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('copy-version-info')));
      await tester.pumpAndSettle();
      expect(find.text('复制失败，请重试。'), findsOneWidget);
      expect(copied, isNull);
      fail = false;
      await tester.tap(find.byKey(const ValueKey('copy-version-info')));
      await tester.pump();
      expect(
        copied,
        'Flutter Forge\nVersion: 1.2.14\nBuild: 4009\nPackage: com.forge.forest\nEdition: ${offlineEdition ? 'Offline' : 'Full'}',
      );
    },
  );
  testWidgets('read failure can retry and cannot copy invented version', (
    tester,
  ) async {
    fake.result = const AppInfoUnavailable(AppInfoReason.unavailable);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppVersionPanel())),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('copy-version-info')), findsNothing);
    expect(find.text('暂时无法读取版本信息，请重试。'), findsOneWidget);
    fake.result = const AppInfoAvailable(
      InstalledAppInfo(
        version: '2.0.0',
        buildNumber: '5010',
        packageName: 'com.forge.forest',
      ),
    );
    await tester.tap(find.byKey(const ValueKey('version-retry')));
    await tester.pumpAndSettle();
    expect(find.text('版本 2.0.0 · 构建 5010'), findsOneWidget);
  });
}
