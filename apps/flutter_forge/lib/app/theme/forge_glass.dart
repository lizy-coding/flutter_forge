import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'forge_theme_tokens.dart';

class ForgeSurfaceScope extends InheritedWidget {
  const ForgeSurfaceScope({
    super.key,
    required this.nativeMaterial,
    required this.teaching,
    required super.child,
  });
  final bool nativeMaterial;
  final bool teaching;

  static ForgeSurfaceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ForgeSurfaceScope>();

  @override
  bool updateShouldNotify(ForgeSurfaceScope oldWidget) =>
      nativeMaterial != oldWidget.nativeMaterial ||
      teaching != oldWidget.teaching;
}

class ForgeShellSurface extends StatelessWidget {
  const ForgeShellSurface({
    super.key,
    required this.child,
    this.radius = 0,
    this.titlebar = false,
    this.floating = false,
  });
  final Widget child;
  final double radius;
  final bool titlebar;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scope = ForgeSurfaceScope.maybeOf(context);
    if (scope?.nativeMaterial == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: colors.surface.withValues(
            alpha: floating
                ? 0.97
                : scope!.teaching
                ? (titlebar ? 0.94 : 1)
                : 0.18,
          ),
          child: child,
        ),
      );
    }
    final glass =
        context.forgeColors.glass && !MediaQuery.highContrastOf(context);
    final surface = Material(
      color: glass ? colors.surface.withValues(alpha: 0.72) : colors.surface,
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: glass
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: surface,
            )
          : surface,
    );
  }
}

class ForgeThemeBackdrop extends StatelessWidget {
  const ForgeThemeBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.forgeColors;
    final scope = ForgeSurfaceScope.maybeOf(context);
    if (scope?.nativeMaterial == true) {
      return ColoredBox(
        key: const ValueKey('native-material-backdrop'),
        color: Colors.transparent,
        child: child,
      );
    }
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
    if (ForgeSurfaceScope.maybeOf(context)?.nativeMaterial == true) {
      return Material(
        color: colors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }
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
