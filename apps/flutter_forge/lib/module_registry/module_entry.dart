import 'concept_localizations.dart';
import '../l10n/strings.dart';
import 'module_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_platform_snapshot.dart';
import 'module_category.dart';
import 'module_platform_support.dart';

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
    required this.platformSupport,
  });

  String titleFor(BuildContext context) =>
      localizedModuleTitle(this, appStrings(context));
  String subtitleFor(BuildContext context) =>
      localizedModuleSubtitle(this, appStrings(context));

  List<String> conceptsFor(BuildContext context) => concepts
      .map((value) => localizedConcept(value, appStrings(context)))
      .toList(growable: false);

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

  final ModulePlatformSupport platformSupport;

  bool isSupportedOn(AppPlatformSnapshot snapshot) =>
      platformSupport.supports(snapshot);
}
