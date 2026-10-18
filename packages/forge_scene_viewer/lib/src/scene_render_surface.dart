import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'scene_render_controller.dart';

typedef SceneSurfaceRenderer =
    void Function(Canvas canvas, Size size, double pixelRatio);

/// A repaint-isolated scene surface with a lifecycle-aware frame driver.
class SceneRenderSurface extends StatefulWidget {
  const SceneRenderSurface({
    super.key,
    required this.controller,
    required this.render,
  });

  final SceneRenderController controller;
  final SceneSurfaceRenderer render;

  @override
  State<SceneRenderSurface> createState() => _SceneRenderSurfaceState();
}

class _SceneRenderSurfaceState extends State<SceneRenderSurface>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(widget.controller.onTick);
  bool _routeActive = true;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appActive =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    widget.controller.ticking.addListener(_syncTicker);
    widget.controller.attachDriver();
    _syncTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeActive = TickerMode.valuesOf(context).enabled;
    final refreshRate = View.of(context).display.refreshRate;
    widget.controller.refreshRate = refreshRate > 0 ? refreshRate : 60;
    widget.controller.setVisible(_routeActive && _appActive);
  }

  @override
  void didUpdateWidget(covariant SceneRenderSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      throw StateError(
        'Use a new key when replacing the scene render controller.',
      );
    }
  }

  void _syncTicker() {
    if (widget.controller.ticking.value) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    widget.controller.setVisible(_routeActive && _appActive);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!widget.controller.isDisposed) {
      widget.controller.ticking.removeListener(_syncTicker);
      widget.controller.detachDriver();
    }
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _ScenePainter(
        widget.controller,
        widget.render,
        View.of(context).devicePixelRatio,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.controller, this.render, this.pixelRatio)
    : super(repaint: controller.repaint);

  final SceneRenderController controller;
  final SceneSurfaceRenderer render;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.isEmpty && !controller.isDisposed) {
      render(canvas, size, pixelRatio);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      controller != oldDelegate.controller ||
      render != oldDelegate.render ||
      pixelRatio != oldDelegate.pixelRatio;
}
