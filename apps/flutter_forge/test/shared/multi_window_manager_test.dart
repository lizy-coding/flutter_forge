import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/shared/multi_window/multi_window_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  @override
  Future<List<MultiWindowController>> getAllWindows() async => [...windows];

  @override
  Future<MultiWindowController> createWindow(
    WindowConfiguration configuration,
  ) async {
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
}
