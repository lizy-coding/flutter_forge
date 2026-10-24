import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'forge_interaction_tokens.dart';
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

/// Window chrome surface (titlebar, sidebar, floating panels).
///
/// Under native window material it lays a light tint over the system blur;
/// without one it falls back to a Flutter backdrop blur. [edgeHighlight] adds
/// a 1px specular cap so glass reads as a pane instead of a flat tint.
/// Teaching and floating surfaces stay highlight-free per ADR 0018.
class ForgeShellSurface extends StatelessWidget {
  const ForgeShellSurface({
    super.key,
    required this.child,
    this.radius = 0,
    this.titlebar = false,
    this.floating = false,
    this.edgeHighlight = false,
  });
  final Widget child;
  final double radius;
  final bool titlebar;
  final bool floating;
  final bool edgeHighlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scope = ForgeSurfaceScope.maybeOf(context);
    final teaching = scope?.teaching == true;
    if (scope?.nativeMaterial == true) {
      final surface = Material(
        color: colors.surface.withValues(
          alpha: floating
              ? 0.97
              : teaching
              ? (titlebar ? 0.94 : 1)
              : 0.18,
        ),
        child: child,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _withEdgeHighlight(context, surface, glassy: !teaching),
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
      child: _withEdgeHighlight(
        context,
        glass
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: surface,
              )
            : surface,
        glassy: glass,
      ),
    );
  }

  Widget _withEdgeHighlight(
    BuildContext context,
    Widget child, {
    required bool glassy,
  }) {
    // Non-uniform borders cannot carry a radius, so chrome keeps square edges.
    if (!edgeHighlight || floating || !glassy || radius != 0) return child;
    return Container(
      foregroundDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.forgeInteraction.chromeHighlightColor),
        ),
      ),
      child: child,
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

/// Fixed navigation surfaces only (mobile sidebar, rail, compact app bar).
/// Content cards use [ForgePressableCard] instead — glass is reserved for
/// window chrome and transient overlays, never for scrollable content.
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
    // Refraction belongs to fixed navigation surfaces only. Skia/Web uses the
    // library's frosted fallback; no full-screen background capture is needed.
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
