import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/shared/multi_window/multi_window_manager.dart';
import 'package:flutter_forge_app/shared/multi_window/mac_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mac window protocol carries category and lifecycle state', () {
    const handle = MacWindowHandle(
      id: 'window-1',
      category: ModuleCategory.basic,
    );
    const event = MacWindowEvent(
      handle: handle,
      lifecycle: MacWindowLifecycle.firstFrameReady,
      elapsed: Duration(milliseconds: 12),
    );

    expect(event.handle.category, ModuleCategory.basic);
    expect(event.lifecycle, MacWindowLifecycle.firstFrameReady);
    expect(event.elapsed.inMilliseconds, 12);
  });

  test('reuses a live category window', () async {
    final diagnostics = <Map<String, Object>>[];
    final platform = _FakeMultiWindowPlatform()
      ..windows.add(_categoryWindow('live', ModuleCategory.basic));
    final manager = MultiWindowManager.forTesting(
      platform,
      diagnosticSink: diagnostics.add,
    );

    final windowId = await manager.createCategoryWindow(ModuleCategory.basic);

    expect(windowId, 'live');
    expect(platform.shownWindowIds, ['live']);
    expect(platform.createdWindowIds, isEmpty);
    expect(diagnostics.single, containsPair('operation', 'reuse_window'));
    expect(diagnostics.single, containsPair('category', 'basic'));
    expect(diagnostics.single, containsPair('argumentsType', 'String'));
    expect(diagnostics.single, containsPair('controllerId', 'live'));
    expect(diagnostics.single['elapsedMs'], isA<int>());
  });

  test('concurrent requests for one category create one window', () async {
    final creationStarted = Completer<void>();
    final allowCreation = Completer<void>();
    final platform = _FakeMultiWindowPlatform()
      ..beforeCreateWindow = (_) async {
        if (!creationStarted.isCompleted) creationStarted.complete();
        await allowCreation.future;
      };
    final manager = MultiWindowManager.forTesting(platform);

    final first = manager.createCategoryWindow(ModuleCategory.basic);
    final second = manager.createCategoryWindow(ModuleCategory.basic);
    await creationStarted.future;
    allowCreation.complete();

    expect(await Future.wait([first, second]), ['created-1', 'created-1']);
    expect(platform.createRequests, hasLength(1));
    expect(platform.createdWindowIds, ['created-1']);
  });

  test('failed shared creation is cleared so the category can retry', () async {
    final creationStarted = Completer<void>();
    final allowFailure = Completer<void>();
    final platform = _FakeMultiWindowPlatform()
      ..failedCreateAttempts.add(1)
      ..beforeCreateWindow = (_) async {
        if (!creationStarted.isCompleted) creationStarted.complete();
        await allowFailure.future;
      };
    final manager = MultiWindowManager.forTesting(platform);

    final first = manager.createCategoryWindow(ModuleCategory.ui);
    final second = manager.createCategoryWindow(ModuleCategory.ui);
    final failures = Future.wait([
      expectLater(first, throwsStateError),
      expectLater(second, throwsStateError),
    ]);
    await creationStarted.future;
    allowFailure.complete();
    await failures;

    expect(platform.createRequests, hasLength(1));
    expect(manager.isCategoryOpen(ModuleCategory.ui), isFalse);
    expect(await manager.createCategoryWindow(ModuleCategory.ui), 'created-1');
    expect(platform.createRequests, hasLength(2));
    expect(platform.createdWindowIds, ['created-1']);
    expect(manager.isCategoryOpen(ModuleCategory.ui), isTrue);
  });

  test(
    'an older calibration cannot erase a concurrently created category',
    () async {
      final oldSnapshotRequested = Completer<void>();
      final oldSnapshot = Completer<List<MultiWindowController>>();
      var reads = 0;
      final platform = _FakeMultiWindowPlatform();
      platform.readWindows = () {
        reads++;
        if (reads == 1) {
          oldSnapshotRequested.complete();
          return oldSnapshot.future;
        }
        return Future.value([...platform.windows]);
      };
      final manager = MultiWindowManager.forTesting(platform);

      final first = manager.createCategoryWindow(ModuleCategory.basic);
      await oldSnapshotRequested.future;
      // Another category must finish while the first category is still waiting.
      expect(
        await manager.createCategoryWindow(ModuleCategory.state),
        'created-1',
      );
      expect(manager.isCategoryOpen(ModuleCategory.state), isTrue);

      oldSnapshot.complete([]);
      expect(await first, 'created-2');
      expect(manager.isCategoryOpen(ModuleCategory.basic), isTrue);
      expect(manager.isCategoryOpen(ModuleCategory.state), isTrue);
      expect(platform.createdWindowIds, ['created-1', 'created-2']);
    },
  );

  test(
    'an unchanged newer calibration still rejects an older snapshot',
    () async {
      final platform = _FakeMultiWindowPlatform()
        ..windows.add(_categoryWindow('state-window', ModuleCategory.state));
      final manager = MultiWindowManager.forTesting(platform);
      expect(
        await manager.createCategoryWindow(ModuleCategory.state),
        'state-window',
      );

      final oldSnapshotRequested = Completer<void>();
      final oldSnapshot = Completer<List<MultiWindowController>>();
      final uiCreationStarted = Completer<void>();
      final allowUiCreation = Completer<void>();
      var reads = 0;
      platform.readWindows = () {
        reads++;
        if (reads == 1) {
          oldSnapshotRequested.complete();
          return oldSnapshot.future;
        }
        return Future.value([...platform.windows]);
      };
      platform.beforeCreateWindow = (configuration) async {
        final arguments = MultiWindowManager.parseArguments(
          configuration.arguments,
        );
        if (arguments.category == ModuleCategory.ui) {
          uiCreationStarted.complete();
          await allowUiCreation.future;
        }
      };

      final basic = manager.createCategoryWindow(ModuleCategory.basic);
      await oldSnapshotRequested.future;
      final ui = manager.createCategoryWindow(ModuleCategory.ui);
      await uiCreationStarted.future;
      oldSnapshot.complete([]);
      expect(await basic, 'created-1');
      allowUiCreation.complete();
      expect(await ui, 'created-2');

      expect(manager.isCategoryOpen(ModuleCategory.state), isTrue);
      expect(manager.isCategoryOpen(ModuleCategory.basic), isTrue);
      expect(manager.isCategoryOpen(ModuleCategory.ui), isTrue);
      expect(platform.createdWindowIds, ['created-1', 'created-2']);
    },
  );

  test('does not reuse a controller that closes before show', () async {
    final diagnostics = <Map<String, Object>>[];
    final platform = _FakeMultiWindowPlatform()
      ..windows.add(_categoryWindow('stale', ModuleCategory.state))
      ..failShowWindowIds.add('stale');
    final manager = MultiWindowManager.forTesting(
      platform,
      diagnosticSink: diagnostics.add,
    );

    final windowId = await manager.createCategoryWindow(ModuleCategory.state);

    expect(windowId, 'created-1');
    expect(platform.createdWindowIds, ['created-1']);
    expect(manager.isCategoryOpen(ModuleCategory.state), isTrue);
    expect(diagnostics.map((fields) => fields['operation']), [
      'show_window_failed',
      'create_window',
    ]);
    expect(diagnostics.first, contains('error'));
    expect(diagnostics.first, contains('stackTrace'));
  });

  test(
    'calibration removes a closed category entry before reopening',
    () async {
      final platform = _FakeMultiWindowPlatform()
        ..windows.add(_categoryWindow('first', ModuleCategory.platform));
      final manager = MultiWindowManager.forTesting(platform);

      expect(
        await manager.createCategoryWindow(ModuleCategory.platform),
        'first',
      );
      platform.windows.clear();

      expect(
        await manager.createCategoryWindow(ModuleCategory.platform),
        'created-1',
      );
      expect(platform.createdWindowIds, ['created-1']);
    },
  );

  test('category window arguments carry the active theme selection', () async {
    final platform = _FakeMultiWindowPlatform();
    final manager = MultiWindowManager.forTesting(platform)
      ..setThemeSelectionPayload(
        '{"version":1,"mode":"dark","palette":"graphiteForge"}',
      );

    await manager.createCategoryWindow(ModuleCategory.ui);

    final arguments = MultiWindowManager.parseArguments(
      platform.windows.single.arguments,
    );
    expect(
      arguments.themeSelectionPayload,
      '{"version":1,"mode":"dark","palette":"graphiteForge"}',
    );
  });

  test('theme changes are sent only to category windows', () async {
    final platform = _FakeMultiWindowPlatform()
      ..windows.add(_categoryWindow('category', ModuleCategory.basic))
      ..windows.add(
        const MultiWindowController(
          windowId: 'main',
          arguments: '{"type":"main"}',
          nativeController: null,
        ),
      );
    final manager = MultiWindowManager.forTesting(platform);

    await manager.updateThemeSelection('dark');

    expect(platform.invocations, [
      ('category', MultiWindowManager.themeSelectionMethod, 'dark'),
    ]);
  });
}

MultiWindowController _categoryWindow(
  String windowId,
  ModuleCategory category,
) => MultiWindowController(
  windowId: windowId,
  arguments: '{"type":"category","category":"${category.name}"}',
  nativeController: null,
);

class _FakeMultiWindowPlatform implements MultiWindowPlatform {
  final List<MultiWindowController> windows = [];
  final Set<String> failShowWindowIds = {};
  final List<String> shownWindowIds = [];
  final List<String> createdWindowIds = [];
  final List<(String, String, Object?)> invocations = [];
  final List<WindowConfiguration> createRequests = [];
  final Set<int> failedCreateAttempts = {};
  Future<void> Function(WindowConfiguration)? beforeCreateWindow;
  Future<List<MultiWindowController>> Function()? readWindows;

  @override
  Future<List<MultiWindowController>> getAllWindows() async =>
      readWindows == null ? [...windows] : await readWindows!();

  @override
  Future<MultiWindowController> createWindow(
    WindowConfiguration configuration,
  ) async {
    createRequests.add(configuration);
    final attempt = createRequests.length;
    await beforeCreateWindow?.call(configuration);
    if (failedCreateAttempts.contains(attempt)) {
      throw StateError('window creation failed');
    }
    final controller = MultiWindowController(
      windowId: 'created-${createdWindowIds.length + 1}',
      arguments: configuration.arguments,
      nativeController: null,
    );
    createdWindowIds.add(controller.windowId);
    windows.add(controller);
    return controller;
  }

  @override
  Future<void> showWindow(MultiWindowController controller) async {
    shownWindowIds.add(controller.windowId);
    if (failShowWindowIds.contains(controller.windowId)) {
      windows.removeWhere((window) => window.windowId == controller.windowId);
      throw StateError('window closed before show');
    }
  }

  @override
  Future<void> invokeMethod(
    MultiWindowController controller,
    String method,
    Object? arguments,
  ) async {
    invocations.add((controller.windowId, method, arguments));
  }
}
