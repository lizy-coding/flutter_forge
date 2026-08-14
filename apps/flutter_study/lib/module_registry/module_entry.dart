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
}
