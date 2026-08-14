import 'package:go_router/go_router.dart';

import 'pages/basic_widgets_page.dart';
import 'pages/state_lifecycle_page.dart';
import 'pages/painter_demo_page.dart';
import 'pages/repaint_boundary_demo_page.dart';

/// 三棵树与生命周期模块子路由
class TreeStateRoutes {
  TreeStateRoutes._();

  static const String basicWidgets = '/basic_widgets';
  static const String stateLifecycle = '/state_lifecycle';
  static const String painterDemo = '/painter_demo';
  static const String repaintBoundary = '/repaint_boundary_demo';

  static List<GoRoute> get routes => [
    GoRoute(
      path: 'basic_widgets',
      builder: (_, __) => const BasicWidgetsPage(),
    ),
    GoRoute(
      path: 'state_lifecycle',
      builder: (_, __) => const StateLifecyclePage(),
    ),
    GoRoute(path: 'painter_demo', builder: (_, __) => const PainterDemoPage()),
    GoRoute(
      path: 'repaint_boundary_demo',
      builder: (_, __) => const RepaintBoundaryDemoPage(),
    ),
  ];
}
