import 'package:go_router/go_router.dart';

import 'pages/stream_demo_page.dart';
import 'pages/broadcast_demo_page.dart';

/// Stream 订阅机制模块子路由
class StreamSubscriptionRoutes {
  StreamSubscriptionRoutes._();

  static const String streamDemo = '/stream-demo';
  static const String broadcastDemo = '/broadcast-demo';

  static List<GoRoute> get routes => [
        GoRoute(
          path: 'stream-demo',
          builder: (_, __) => const StreamDemoPage(),
        ),
        GoRoute(
          path: 'broadcast-demo',
          builder: (_, __) => const BroadcastDemoPage(),
        ),
      ];
}
