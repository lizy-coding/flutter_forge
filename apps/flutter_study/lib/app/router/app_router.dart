import 'package:go_router/go_router.dart';

import 'app_route_table.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(routes: AppRouteTable.routes);
}
