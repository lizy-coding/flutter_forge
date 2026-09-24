@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_catalog_utils.dart';
import 'package:flutter_forge_app/modules/platform/dio_interceptor/module_entry.dart';
import 'package:flutter_forge_app/modules/platform/file_picker/module_entry.dart';
import 'package:flutter_forge_app/modules/platform/online_video_player/state/video_player_adapter.dart';
import 'package:flutter_forge_app/modules/ui/font_picker/module_entry.dart';
import 'package:flutter_forge_app/modules/ui/gcode_visualizer/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const web = AppPlatformSnapshot(platform: AppTargetPlatform.web);

  test('Web catalog keeps native-only capabilities unavailable', () {
    for (final path in [
      '/isolate-basic',
      '/isolate-stream',
      '/webview',
      '/gcode-visualizer',
      '/usb-detector',
    ]) {
      final module = AppRouteTable.modules.singleWhere(
        (entry) => entry.path == path,
      );
      expect(isModuleAvailable(module, web), isFalse, reason: path);
    }
  });

  test('Web catalog exposes the connected platform modules', () {
    for (final path in [
      '/dio-interceptor',
      '/file-picker',
      '/online-video-player',
    ]) {
      final module = AppRouteTable.modules.singleWhere(
        (entry) => entry.path == path,
      );
      expect(isModuleAvailable(module, web), isTrue, reason: path);
    }
  });

  test('Web video policy skips probing and waits for a user gesture', () {
    final adapter = VideoPlayerPluginAdapter();

    expect(adapter.probeBeforeOpen, isFalse);
    expect(adapter.startAutomatically, isFalse);
    expect(
      defaultSampleStreamUri.path,
      endsWith('/media/flutter-forge-sample.mp4'),
    );
    adapter.dispose();
  });

  test('Dio Web support does not fabricate a native host allowlist', () {
    final module = AppRouteTable.modules.singleWhere(
      (entry) => entry.path == '/dio-interceptor',
    );

    for (final platform in [
      AppTargetPlatform.android,
      AppTargetPlatform.macOS,
      AppTargetPlatform.windows,
    ]) {
      expect(
        isModuleAvailable(module, AppPlatformSnapshot(platform: platform)),
        isTrue,
      );
    }
    expect(module.platformSupport.excludedPlatforms, isEmpty);
  });

  testWidgets('Web entries render safe compatibility states', (tester) async {
    for (final entry in const <Widget>[
      InterceptorTestEntry(),
      FilePickerEntry(),
      FontPickerEntry(),
      GcodeVisualizerEntry(),
    ]) {
      await tester.pumpWidget(MaterialApp(home: entry));
      expect(tester.takeException(), isNull);
    }

    expect(find.textContaining('Web'), findsWidgets);
  });
}
