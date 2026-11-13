import 'package:forge_localization/forge_localization.dart';
import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

AppLocalizations appStrings(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('zh'));

AppLocalizations frameworkStrings(BuildContext context) =>
    lookupAppLocalizations(
      LocaleScope.maybeOf(context)?.effectiveLocale ?? const Locale('zh'),
    );
