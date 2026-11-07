import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_app_info/forge_app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('native contract preserves actual installed build number', () async {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getAll');
      return {
        'appName': 'Flutter Forge',
        'packageName': 'com.forge.forest',
        'version': '1.2.14',
        'buildNumber': '4009',
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final result = await PackageAppInfoPlatform().read() as AppInfoAvailable;
    expect(result.value.buildNumber, '4009');
    expect(result.value.version, '1.2.14');
  });
  test(
    'unavailable plugin and incomplete records degrade without throwing',
    () async {
      final failure = PackageAppInfoPlatform(
        loader: () async => throw MissingPluginException(),
      );
      expect(await failure.queryCapabilities(), isFalse);
      expect(await failure.read(), isA<AppInfoUnavailable>());
      final invalid = PackageAppInfoPlatform(
        loader: () async => PackageInfo(
          appName: 'Forge',
          packageName: '',
          version: '',
          buildNumber: '',
        ),
      );
      expect(
        (await invalid.read() as AppInfoUnavailable).reason,
        AppInfoReason.invalidData,
      );
    },
  );
}
