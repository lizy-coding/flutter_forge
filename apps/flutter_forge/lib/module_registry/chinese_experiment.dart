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
class ExperimentNavigatorLocale extends StatelessWidget {
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: router.routeInformationProvider,
    builder: (context, _) {
      final path = router.routeInformationProvider.value.uri.path;
      final experiment = modules.any(
        (module) => path == module.path || path.startsWith('${module.path}/'),
      );
      return Localizations.override(
        context: context,
        locale: experiment
            ? const Locale('zh')
            : (LocaleScope.maybeOf(context)?.effectiveLocale ??
                  const Locale('zh')),
        delegates: AppLocalizations.localizationsDelegates,
        child: child,
      );
    },
  );
}
