import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'forge_theme_tokens.dart';

class ForgeThemeBackdrop extends StatelessWidget {
  const ForgeThemeBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.forgeColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Keep the navigator at the same position when the palette changes.
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            key: const ValueKey('theme-backdrop'),
            decoration: BoxDecoration(
              color: tokens.canvas,
              gradient: tokens.glass
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? const [
                              Color(0xFF182C42),
                              Color(0xFF25203F),
                              Color(0xFF102F35),
                            ]
                          : const [
                              Color(0xFFD8EBFF),
                              Color(0xFFEAE0FF),
                              Color(0xFFD4F3ED),
                            ],
                    )
                  : null,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class ForgeGlassSurface extends StatelessWidget {
  const ForgeGlassSurface({
    super.key,
    required this.child,
    this.radius = 16,
    this.refract = false,
  });

  final Widget child;
  final double radius;
  final bool refract;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: colors.outlineVariant),
    );
    if (MediaQuery.highContrastOf(context)) {
      return Material(color: colors.surface, shape: shape, child: child);
    }
    // Only fixed navigation surfaces use refraction. Scrolling cards use
    // shader-free glass. Skia/Web uses the library's frosted fallback;
    // no full-screen background capture is needed for this theme.
    return LiquidGlassLens(
      style: LiquidGlassStyle(
        shape: LiquidGlassShape.roundedRectangle(cornerRadius: radius),
        color: colors.surface.withValues(alpha: dark ? 0.7 : 0.58),
        blur: 8,
        refractionIndex: 1.02,
        refractionWidth: 16,
        liteGlass: !refract,
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class ForgeCard extends StatelessWidget {
  const ForgeCard({super.key, required this.child, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    if (!context.forgeColors.glass) {
      return Card(margin: margin, clipBehavior: Clip.antiAlias, child: child);
    }
    return Padding(
      padding: margin ?? const EdgeInsets.all(4),
      child: ForgeGlassSurface(child: child),
    );
  }
}
