import 'package:flutter/material.dart';
import 'package:forge_localization/forge_localization.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(strings.language, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButton<String>(
          key: const ValueKey('language-selector'),
          value: controller.preference,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: 'system',
              child: Text(strings.systemLanguage),
            ),
            DropdownMenuItem(value: 'zh', child: Text(strings.chinese)),
            DropdownMenuItem(value: 'en', child: Text(strings.english)),
          ],
          onChanged: (value) async {
            if (value != null) await controller.setPreference(value);
          },
        ),
        if (controller.loadError != null) Text(strings.loadLanguageFailed),
        if (controller.saveError != null)
          TextButton(
            onPressed: () => controller.setPreference(controller.preference),
            child: Text(strings.saveLanguageFailed),
          ),
        if (controller.effectiveLocale.languageCode == 'en')
          Text(strings.chineseLessons),
      ],
    );
  }
}
