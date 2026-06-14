import 'package:go_router/go_router.dart';

import 'pages/list_page.dart';
import 'pages/popup_page.dart';

class PopupListInteractionRoutes {
  PopupListInteractionRoutes._();

  static const String popup = '/popup';
  static const String list = '/list';

  static List<GoRoute> get routes => [
        GoRoute(
          path: 'popup',
          builder: (_, __) => const PopupPage(),
        ),
        GoRoute(
          path: 'list',
          builder: (_, __) => const ListPage(),
        ),
      ];
}
