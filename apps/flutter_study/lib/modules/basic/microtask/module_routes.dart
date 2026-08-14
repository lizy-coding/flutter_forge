import 'package:go_router/go_router.dart';

import 'pages/event_queue_page.dart';
import 'pages/microtask_queue_page.dart';
import 'pages/advanced_examples_page.dart';

class MicrotaskRoutes {
  MicrotaskRoutes._();

  static const String eventQueue = '/event-queue';
  static const String microtaskQueue = '/microtask-queue';
  static const String advanced = '/advanced';

  static List<GoRoute> get routes => [
    GoRoute(path: 'event-queue', builder: (_, __) => const EventQueuePage()),
    GoRoute(
      path: 'microtask-queue',
      builder: (_, __) => const MicrotaskQueuePage(),
    ),
    GoRoute(path: 'advanced', builder: (_, __) => const AdvancedExamplesPage()),
  ];
}
