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
        tooltip: '切换外观',
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
                    ? '实色外观'
                    : context.forgeColors.desktop
                    ? '系统材质'
                    : '玻璃外观',
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
            child: Text(mode.label),
          ),
      ],
    );
  }
}
