import 'package:go_router/go_router.dart';

import 'pages/login_page.dart';

/// Dio 拦截器链路模块子路由
class InterceptorTestRoutes {
  InterceptorTestRoutes._();

  static const String login = '/login';

  static List<GoRoute> get routes => [
    GoRoute(path: 'login', builder: (_, __) => const LoginPage()),
  ];
}
