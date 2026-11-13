import 'package:flutter_test/flutter_test.dart';
import 'package:forge_app_info/forge_app_info.dart';

/// Installs deterministic installed-package data for unrelated About tests.
void useAppInfoFixture() {
  final previous = AppInfoPlatform.instance;
  AppInfoPlatform.instance = _FixtureAppInfo();
  addTearDown(() => AppInfoPlatform.instance = previous);
}

class _FixtureAppInfo extends AppInfoPlatform {
  @override
  Future<AppInfoOutcome> read() async => const AppInfoAvailable(
    InstalledAppInfo(
      version: '1.0.0',
      buildNumber: '1',
      packageName: 'fixture.forge',
    ),
  );
}
