import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/automation/app_fixture.dart';
import '../test/support/automation/smoke_scenarios.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final platform = AppPlatformSnapshot.detect();
  const expected = String.fromEnvironment('FORGE_AUTOMATION_PLATFORM');
  testWidgets('smoke.core.${platform.platform.name}', (tester) async {
    if (expected.isNotEmpty) expect(platform.platform.name, expected);
    await withApp(tester, platform, (app) => runCoreSmoke(tester, app));
  });
}
