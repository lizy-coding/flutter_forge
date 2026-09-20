import 'package:go_router/go_router.dart';

import '../../module_registry/app_platform_snapshot.dart';
import 'app_route_table.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create(AppPlatformSnapshot platform) =>
      GoRouter(routes: AppRouteTable.routesFor(platform));
}
