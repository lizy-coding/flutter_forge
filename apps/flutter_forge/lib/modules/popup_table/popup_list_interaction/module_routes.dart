import 'package:go_router/go_router.dart';

import 'pages/list_page.dart';
import 'pages/popup_page.dart';

class PopupListInteractionRoutes {
  PopupListInteractionRoutes._();

  // The declarations below are nested routes, while these constants are
  // absolute locations for callers using BuildContext.push.
  static const String popup = '/popup-list-interaction/popup';
  static const String list = '/popup-list-interaction/list';

  static List<GoRoute> get routes => [
    GoRoute(path: 'popup', builder: (_, __) => const PopupPage()),
    GoRoute(path: 'list', builder: (_, __) => const ListPage()),
  ];
}
