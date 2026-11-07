import 'package:flutter_forge_app/l10n/strings.dart';
import 'package:flutter/material.dart';

import 'app_theme_controller.dart';
import 'app_theme_selection.dart';
import 'forge_theme_tokens.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return MenuAnchor(
      builder: (context, menuController, child) => IconButton(
        key: const ValueKey('theme-mode-button'),
        tooltip: appStrings(context).appearance,
        onPressed: () => menuController.isOpen
            ? menuController.close()
            : menuController.open(),
        icon: Icon(controller.mode.icon),
      ),
      menuChildren: [
        ...[
          for (final palette in AppThemePalette.values)
            MenuItemButton(
              key: ValueKey('theme-palette:${palette.name}'),
              leadingIcon: Icon(
                palette == AppThemePalette.liquidGlass
                    ? Icons.blur_on_rounded
                    : Icons.palette_outlined,
              ),
              trailingIcon: controller.palette == palette
                  ? const Icon(Icons.check_rounded)
                  : null,
              onPressed: () => controller.setPalette(palette),
              child: Text(
                palette == AppThemePalette.graphiteForge
                    ? appStrings(context).solidAppearance
                    : context.forgeColors.desktop
                    ? appStrings(context).systemMaterial
                    : appStrings(context).glassAppearance,
              ),
            ),
          const Divider(),
        ],
        for (final mode in AppThemeModePreference.values)
          MenuItemButton(
            key: ValueKey('theme-mode:${mode.name}'),
            leadingIcon: Icon(mode.icon),
            trailingIcon: controller.mode == mode
                ? const Icon(Icons.check_rounded)
                : null,
            onPressed: () => controller.setMode(mode),
            child: Text(switch (mode) {
              AppThemeModePreference.system => appStrings(context).themeSystem,
              AppThemeModePreference.light => appStrings(context).themeLight,
              AppThemeModePreference.dark => appStrings(context).themeDark,
            }),
          ),
      ],
    );
  }
}
