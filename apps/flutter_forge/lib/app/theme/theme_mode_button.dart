import 'package:flutter/material.dart';

import 'app_theme_controller.dart';
import 'app_theme_selection.dart';

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
