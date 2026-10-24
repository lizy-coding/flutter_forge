import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/shared/multi_window/multi_window_manager.dart';
import 'package:flutter_forge_app/shared/multi_window/mac_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native cleanup waits for inventory removal, not just the close reply',
    () async {
      const channel = MethodChannel('mixin.one/desktop_multi_window');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var closed = false;
      var inventoryReads = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'window_close') return null;
        if (call.method == 'getAllWindows') {
          inventoryReads++;
          if (inventoryReads < 3) {
            return [
              {'windowId': 'native-1', 'windowArgument': ''},
            ];
          }
          closed = true;
          return [];
        }
        throw StateError('unexpected native method ${call.method}');
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await const DesktopMultiWindowPlatform().closeWindow(
        MultiWindowController(
          windowId: 'native-1',
          arguments: '',
          nativeController: WindowController.fromWindowId('native-1'),
        ),
      );
      expect(closed, isTrue);
      expect(inventoryReads, 3);
    },
  );

  test(
    'a close race is successful only when native inventory confirms absence',
    () async {
      const channel = MethodChannel('mixin.one/desktop_multi_window');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'window_close') {
          throw PlatformException(code: 'WINDOW_CLOSED');
        }
        return [];
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await const DesktopMultiWindowPlatform().closeWindow(
        MultiWindowController(
          windowId: 'gone',
          arguments: '',
          nativeController: WindowController.fromWindowId('gone'),
        ),
      );
    },
  );

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

  test(
    'hidden startup waits for readiness before showing or publishing',
    () async {
      final ready = Completer<void>();
      final waiting = Completer<void>();
      final platform = _FakeMultiWindowPlatform()
        ..beforeReady = (_) {
          waiting.complete();
          return ready.future;
        };
      final manager = MultiWindowManager.forTesting(platform);
      final opened = manager.createCategoryWindow(ModuleCategory.basic);
      await waiting.future;
      expect(platform.createRequests.single.hiddenAtLaunch, isTrue);
      expect(platform.shownWindowIds, isEmpty);
      expect(manager.isCategoryOpen(ModuleCategory.basic), isFalse);
      ready.complete();
      expect(await opened, 'created-1');
      expect(platform.shownWindowIds, ['created-1']);
      expect(manager.isCategoryOpen(ModuleCategory.basic), isTrue);
    },
  );

  test(
    'failed readiness closes the hidden window and permits a new attempt',
    () async {
      final platform = _FakeMultiWindowPlatform()
        ..beforeReady = (_) async {
          throw StateError('bootstrap failed');
        };
      final manager = MultiWindowManager.forTesting(platform);
      await expectLater(
        manager.createCategoryWindow(ModuleCategory.basic),
        throwsStateError,
      );
      expect(platform.closedWindowIds, ['created-1']);
      expect(platform.windows, isEmpty);
      expect(manager.isCategoryOpen(ModuleCategory.basic), isFalse);
      platform.beforeReady = null;
      expect(
        await manager.createCategoryWindow(ModuleCategory.basic),
        'created-2',
      );
      expect(platform.shownWindowIds, ['created-2']);
    },
  );

  test('startup timeout cleans up and ignores a late ready response', () async {
    final ready = Completer<void>();
    final platform = _FakeMultiWindowPlatform()
      ..beforeReady = (_) => ready.future;
    final manager = MultiWindowManager.forTesting(
      platform,
      startupTimeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      manager.createCategoryWindow(ModuleCategory.basic),
      throwsA(isA<TimeoutException>()),
    );
    ready.complete();
    await Future<void>.delayed(Duration.zero);
    expect(platform.closedWindowIds, ['created-1']);
    expect(platform.shownWindowIds, isEmpty);
    expect(manager.isCategoryOpen(ModuleCategory.basic), isFalse);
  });

  test('a native window returned after creation timeout is closed', () async {
    final create = Completer<void>();
    final platform = _FakeMultiWindowPlatform()
      ..beforeCreateWindow = (_) => create.future;
    final manager = MultiWindowManager.forTesting(
      platform,
      startupTimeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      manager.createCategoryWindow(ModuleCategory.basic),
      throwsA(isA<TimeoutException>()),
    );
    create.complete();
    await Future<void>.delayed(Duration.zero);
    expect(platform.closedWindowIds, ['created-1']);
    expect(platform.windows, isEmpty);
    expect(platform.shownWindowIds, isEmpty);
  });

  test(
    'failed cleanup must succeed before another native window is created',
    () async {
      final platform = _FakeMultiWindowPlatform()
        ..beforeReady = (_) async {
          throw StateError('bootstrap failed');
        }
        ..failClose = true;
      final manager = MultiWindowManager.forTesting(platform);
      await expectLater(
        manager.createCategoryWindow(ModuleCategory.basic),
        throwsStateError,
      );
      await expectLater(
        manager.createCategoryWindow(ModuleCategory.basic),
        throwsStateError,
      );
      expect(platform.createRequests, hasLength(1));
      platform.failClose = false;
      platform.beforeReady = null;
      expect(
        await manager.createCategoryWindow(ModuleCategory.basic),
        'created-2',
      );
      expect(platform.windows.map((window) => window.windowId), ['created-2']);
    },
  );

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
    expect(platform.createRequests.single.enableFlutterGpu, isTrue);

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
  final List<String> closedWindowIds = [];
  Future<void> Function(MultiWindowController)? beforeReady;
  bool failClose = false;
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
  Future<void> waitUntilReady(MultiWindowController controller) async {
    await beforeReady?.call(controller);
  }

  @override
  Future<void> closeWindow(MultiWindowController controller) async {
    if (failClose) throw StateError('native close failed');
    closedWindowIds.add(controller.windowId);
    windows.removeWhere((window) => window.windowId == controller.windowId);
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
