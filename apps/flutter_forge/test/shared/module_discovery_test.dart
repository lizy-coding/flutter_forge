import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/theme/forge_glass.dart';
import 'package:flutter_forge_app/app/theme/forge_theme_tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/app/module_discovery_session.dart';
import 'package:flutter_forge_app/app/module_discovery_panel.dart';
import 'package:flutter_forge_app/module_registry/module_manifest.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/shared/genui/model_source.dart';

class MenuSource implements WorkbenchSource {
  int calls = 0;
  bool invalid = false;
  @override
  String get label => 'test';
  @override
  bool get isReplay => true;
  @override
  void dispose() {}
  @override
  Stream<String> generate(WorkbenchRequest request, CancelToken token) async* {
    calls++;
    for (final item in [
      {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': discoverySurface,
          'catalogId': discoveryCatalog,
        },
      },
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': discoverySurface,
          'components': [
            {
              'id': 'root',
              'component': 'Group',
              'layout': calls == 1 ? 'compare' : 'list',
              'children': ['card', 'choice'],
            },
            {
              'id': 'card',
              'component': 'ModuleCard',
              'moduleId': invalid ? '/invented' : '/constraint-layout',
              'reason': '观察约束如何影响尺寸',
            },
            {
              'id': 'choice',
              'component': 'RefineChoice',
              'label': '想先动手',
              'prompt': '请优先推荐交互实验',
            },
          ],
        },
      },
    ]) {
      yield '${jsonEncode(item)}\n';
    }
  }
}

void main() {
  testWidgets(
    'SDK renders menu, clarification updates it and opening stays local at 360dp',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = MenuSource();
      String? opened;
      final session = ModuleDiscoverySession(
        modules: moduleManifest,
        platform: const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
        openModule: (path) => opened = path,
        source: source,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ModuleDiscoveryPanel(
                  modules: moduleManifest,
                  platform: session.platform,
                  session: session,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('discovery-question')),
        '宽度为什么不生效',
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('discovery-submit')));
        for (var i = 0; i < 100 && session.busy; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
      expect(session.error, isNull);
      expect(find.text('约束与声明式布局'), findsOneWidget);
      await tester.ensureVisible(find.text('想先动手'));
      await tester.tap(find.text('想先动手'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      for (var i = 0; i < 50 && session.busy; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(session.busy, isFalse, reason: session.records.join(' | '));
      await tester.pumpAndSettle();
      expect(source.calls, 2);
      expect(session.components['root']!['layout'], 'list');
      expect(session.records.any((r) => r.contains('SDK 澄清动作')), isTrue);
      await tester.ensureVisible(find.text('进入模块'));
      await tester.tap(find.text('进入模块'));
      expect(opened, '/constraint-layout');
      expect(source.calls, 2);
      source.invalid = true;
      await tester.runAsync(() => session.submit('另一问题'));
      await tester.pumpAndSettle();
      expect(session.error, contains('不存在'));
      expect(session.components['card']!['moduleId'], '/constraint-layout');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
  testWidgets(
    'stored scroll offset and high contrast do not break the result panel',
    (tester) async {
      final source = MenuSource();
      final session = ModuleDiscoverySession(
        modules: moduleManifest,
        platform: const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
        source: source,
        openModule: (_) {},
      );
      final bucket = PageStorageBucket();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [ForgeThemeTokens.light.copyWith(glass: true)],
          ),
          home: MediaQuery(
            data: const MediaQueryData(
              highContrast: true,
              disableAnimations: true,
            ),
            child: Scaffold(
              body: PageStorage(
                bucket: bucket,
                child: Builder(
                  key: const PageStorageKey('home'),
                  builder: (context) {
                    bucket.writeState(context, 12.0);
                    return SingleChildScrollView(
                      child: ModuleDiscoveryPanel(
                        modules: moduleManifest,
                        platform: session.platform,
                        session: session,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => session.submit('宽度不生效'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgeGlassSurface), findsNothing);
      await tester.ensureVisible(find.text('查看探索记录'));
      await tester.tap(find.text('查看探索记录'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
  test('protocol rejects cyclic references', () {
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: const AppPlatformSnapshot(platform: AppTargetPlatform.web),
      openModule: (_) {},
    );
    addTearDown(session.dispose);
    expect(
      () => session.validate([
        {
          'id': 'root',
          'component': 'Group',
          'children': ['root'],
        },
      ], {}),
      throwsFormatException,
    );
  });
}
