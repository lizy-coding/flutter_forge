import 'package:material_ui/material_ui.dart';

import 'app_localizations.dart';

/// Localizes standalone widgets and dependencies still using the SDK widgets.
const forgeLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  ...GlobalMaterialLocalizations.delegates,
  ...AppLocalizations.localizationsDelegates,
];
