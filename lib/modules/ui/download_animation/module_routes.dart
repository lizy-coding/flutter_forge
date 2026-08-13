import 'package:go_router/go_router.dart';

import 'models/animation_config.dart';
import 'pages/download_animation_page.dart';
import 'pages/download_comparison_page.dart';
import 'pages/paint_animation_page.dart';

/// 下载飞入动效模块子路由
class DownloadAnimationRoutes {
  DownloadAnimationRoutes._();

  static const String customView = '/custom-view';
  static const String paint = '/paint';
  static const String comparison = '/comparison';

  static const AnimationConfig defaultConfig = AnimationConfig(
    animationDuration: 2000,
    flyingItemOffset: 30,
    flyingItemPadding: 8,
    flyingItemRadius: 8,
  );

  static List<GoRoute> get routes => [
    GoRoute(
      path: 'custom-view',
      builder: (_, __) =>
          const DownloadAnimationPage(animationConfig: defaultConfig),
    ),
    GoRoute(
      path: 'paint',
      builder: (_, __) =>
          const PaintAnimationPage(animationConfig: defaultConfig),
    ),
    GoRoute(
      path: 'comparison',
      builder: (_, __) => const DownloadComparisonPage(),
    ),
  ];
}
