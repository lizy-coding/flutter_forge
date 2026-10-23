import 'package:flutter/material.dart';
import 'theme/forge_glass.dart';
import 'theme/forge_theme_tokens.dart';

/// Lightweight interactive surface; follows solid and accessibility preferences.
class DiscoverySurface extends StatefulWidget {
  const DiscoverySurface({
    super.key,
    required this.child,
    this.highlighted = false,
    this.radius = 20,
  });
  final Widget child;
  final bool highlighted;
  final double radius;
  @override
  State<DiscoverySurface> createState() => _DiscoverySurfaceState();
}

class _DiscoverySurfaceState extends State<DiscoverySurface> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highContrast = MediaQuery.highContrastOf(context);
    final glass = context.forgeColors.glass && !highContrast;
    final active = hovered || widget.highlighted;
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final content = glass
        ? ForgeGlassSurface(radius: widget.radius, child: widget.child)
        : Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(widget.radius),
            clipBehavior: Clip.antiAlias,
            child: widget.child,
          );
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: active
                ? colors.primary.withValues(alpha: 0.65)
                : colors.outlineVariant.withValues(
                    alpha: highContrast ? 1 : 0.5,
                  ),
          ),
          boxShadow: glass && active
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.07),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: content,
      ),
    );
  }
}
