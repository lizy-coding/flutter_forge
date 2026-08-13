import 'package:go_router/go_router.dart';

import 'with_isolate_page.dart';
import 'without_isolate_page.dart';

/// Isolate 并发对比模块子路由
class IsolateTestRoutes {
  IsolateTestRoutes._();

  static const String withoutIsolate = '/without-isolate';
  static const String withIsolate = '/with-isolate';

  static List<GoRoute> get routes => [
    GoRoute(
      path: 'without-isolate',
      builder: (_, __) => const WithoutIsolatePage(),
    ),
    GoRoute(path: 'with-isolate', builder: (_, __) => const WithIsolatePage()),
  ];
}
