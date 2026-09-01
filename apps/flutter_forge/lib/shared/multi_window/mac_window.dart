import '../../module_registry/module_category.dart';

class MacWindowRequest {
  const MacWindowRequest({required this.category});

  final ModuleCategory category;
}

class MacWindowHandle {
  const MacWindowHandle({required this.id, required this.category});

  final String id;
  final ModuleCategory category;
}

enum MacWindowLifecycle { created, firstFrameReady, shown, focused, closed }

class MacWindowEvent {
  const MacWindowEvent({
    required this.handle,
    required this.lifecycle,
    required this.elapsed,
  });

  final MacWindowHandle handle;
  final MacWindowLifecycle lifecycle;
  final Duration elapsed;
}

abstract interface class MacWindowBackend {
  Stream<MacWindowEvent> get events;

  Future<MacWindowHandle> open(MacWindowRequest request);

  Future<void> focus(MacWindowHandle handle);

  Future<void> close(MacWindowHandle handle);
}
