import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/platform/file_picker/pages/file_picker_page.dart';
import 'package:flutter_forge_app/modules/platform/file_picker/state/file_picker_controller.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/automation/app_fixture.dart';
import '../test/support/automation/interactions.dart';

const _filePickerRoute = '/file-picker';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Windows file picker returns a selection or cancellation', (
    tester,
  ) async {
    final platform = AppPlatformSnapshot.detect();
    expect(platform.platform, AppTargetPlatform.windows);
    await withApp(tester, platform, (app) async {
      await app.go(tester, _filePickerRoute);

      await tester.pump(const Duration(milliseconds: 500));

      // A native driver must select a text file or cancel the platform dialog.
      await tester.tap(find.text('文本'));
      await tester.pump();

      final chooseButton = find.byKey(const ValueKey('pick-file-button'));
      expect(chooseButton, findsOneWidget);
      await tester.tap(chooseButton);

      // Native dialogs do not participate in Flutter's frame/settle protocol.
      // The bounded poll lets the Windows driver close the dialog and return to
      // the page without waiting forever on a platform-owned animation.
      final controller = tester
          .widget<FilePickerPage>(find.byType(FilePickerPage))
          .controller;
      await waitForCondition(
        tester,
        () =>
            controller.state != FilePickerState.idle &&
            controller.state != FilePickerState.loading,
        reason:
            'Native dialog did not finish. The external driver must select or cancel; missing driver is not PASS.',
      );
      expect(
        controller.state,
        anyOf(FilePickerState.picked, FilePickerState.cancelled),
        reason: controller.errorMessage,
      );
      expectNoFlutterErrors(tester, 'Windows native file dialog');
    });
  }, skip: AppPlatformSnapshot.detect().platform != AppTargetPlatform.windows);
}
