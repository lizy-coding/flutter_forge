import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'module_category.dart';

class ModuleEntry {
  ModuleEntry({
    required this.title,
    required this.path,
    required this.subtitle,
    required this.category,
    required this.difficulty,
    required this.concepts,
    required this.estimatedMinutes,
    required this.status,
    required this.builder,
    this.routes = const [],
    this.supportedPlatforms,
  });

  final String title;
  final String path;
  final String subtitle;
  final ModuleCategory category;
  final Difficulty difficulty;
  final List<String> concepts;
  final int estimatedMinutes;
  final ModuleStatus status;
  final WidgetBuilder builder;
  final List<GoRoute> routes;

  /// Null means the module is platform-neutral and supported by default.
  /// A non-null set restricts availability to the listed host platforms.
  final Set<TargetPlatform>? supportedPlatforms;

  bool isSupportedOn(TargetPlatform platform) {
    final platforms = supportedPlatforms;
    return platforms == null || platforms.contains(platform);
  }
}
