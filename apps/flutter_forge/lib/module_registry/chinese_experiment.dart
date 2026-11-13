import 'package:flutter/scheduler.dart';
import '../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:forge_localization/forge_localization.dart';
import 'module_entry.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// Keeps lesson pages and their overlays in Chinese without changing app state.
class ChineseExperiment extends StatelessWidget {
  const ChineseExperiment({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = frameworkStrings(context).chineseExperiment;
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.translate, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(label)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Localizations.override(
              context: context,
              locale: const Locale('zh'),
              delegates: [
                _ChineseNavigationDelegate(frameworkStrings(context).back),
                ...AppLocalizations.localizationsDelegates,
              ],
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

// The experiment owns Chinese stock dialogs; the host still names navigation.
class _ChineseNavigationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _ChineseNavigationDelegate(this.backLabel);
  final String backLabel;
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'zh';
  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    await GlobalMaterialLocalizations.delegate.load(const Locale('zh'));
    return _ChineseNavigation(backLabel);
  }

  @override
  bool shouldReload(_ChineseNavigationDelegate old) =>
      backLabel != old.backLabel;
}

class _ChineseNavigation extends MaterialLocalizationZh {
  _ChineseNavigation(this.backLabel)
    : super(
        fullYearFormat: intl.DateFormat.y('zh'),
        compactDateFormat: intl.DateFormat.yMd('zh'),
        shortDateFormat: intl.DateFormat.yMMMd('zh'),
        mediumDateFormat: intl.DateFormat.MMMEd('zh'),
        longDateFormat: intl.DateFormat.yMMMMEEEEd('zh'),
        yearMonthFormat: intl.DateFormat.yMMMM('zh'),
        shortMonthDayFormat: intl.DateFormat.MMMd('zh'),
        decimalFormat: intl.NumberFormat.decimalPattern('zh'),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', 'zh'),
      );
  final String backLabel;
  @override
  String get backButtonTooltip => backLabel;
}

Widget frameworkLanguage(BuildContext context, Widget child) {
  final controller = LocaleScope.maybeOf(context);
  if (controller == null) return child;
  return Localizations.override(
    context: context,
    locale: controller.effectiveLocale,
    delegates: AppLocalizations.localizationsDelegates,
    child: child,
  );
}

/// Places root-navigator overlays in the experiment language, including dialogs.
class ExperimentNavigatorLocale extends StatefulWidget {
  const ExperimentNavigatorLocale({
    super.key,
    required this.router,
    required this.modules,
    required this.child,
  });
  final GoRouter router;
  final List<ModuleEntry> modules;
  final Widget child;
  @override
  State<ExperimentNavigatorLocale> createState() =>
      _ExperimentNavigatorLocaleState();
}

class _ExperimentNavigatorLocaleState extends State<ExperimentNavigatorLocale> {
  late String _path;
  bool _framePending = false;
  String get _visiblePath =>
      widget
          .router
          .routerDelegate
          .currentConfiguration
          .lastOrNull
          ?.matchedLocation ??
      '/';
  @override
  void initState() {
    super.initState();
    _path = _visiblePath;
    widget.router.routerDelegate.addListener(_routeChanged);
  }

  @override
  void didUpdateWidget(ExperimentNavigatorLocale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_routeChanged);
      widget.router.routerDelegate.addListener(_routeChanged);
      _path = _visiblePath;
    }
  }

  void _updatePath() {
    if (!mounted) return;
    final next = _visiblePath;
    if (next != _path) setState(() => _path = next);
  }

  void _routeChanged() {
    // Pop notifications can occur while Navigator is building its children.
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      _updatePath();
    } else if (!_framePending) {
      _framePending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _framePending = false;
        _updatePath();
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_routeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final experiment = widget.modules.any(
      (module) => _path == module.path || _path.startsWith('${module.path}/'),
    );
    return Localizations.override(
      context: context,
      locale: experiment
          ? const Locale('zh')
          : (LocaleScope.maybeOf(context)?.effectiveLocale ??
                const Locale('zh')),
      delegates: AppLocalizations.localizationsDelegates,
      child: widget.child,
    );
  }
}
