import 'package:flutter/material.dart';

import 'theme/forge_glass.dart';
import 'theme/forge_interaction_tokens.dart';
import 'theme/forge_theme_tokens.dart';

/// Unified tappable card surface.
///
/// Cards are content carriers, never glass: they render near-solid over any
/// backdrop (native window material, glass fallback or solid theme) and
/// express hierarchy with a 1px stroke plus a hover elevation shadow. The
/// interaction feedback is identical across materials; only the resolved
/// surface color differs.
class ForgePressableCard extends StatefulWidget {
  const ForgePressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 12,
    this.highlighted = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;

  /// External highlight (e.g. a parent selection) — behaves like hover.
  final bool highlighted;

  @override
  State<ForgePressableCard> createState() => _ForgePressableCardState();
}

class _ForgePressableCardState extends State<ForgePressableCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.forgeInteraction;
    final native = ForgeSurfaceScope.maybeOf(context)?.nativeMaterial == true;
    final glass = context.forgeColors.glass && !native;
    final active = widget.highlighted || _hovered;
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final surface = native
        ? colors.surface.withValues(alpha: tokens.cardSurfaceAlpha)
        : glass
        ? colors.surface.withValues(alpha: 0.92)
        : colors.surface;
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : tokens.hoverDuration,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: widget.onTap != null && active
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.07),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        // The stroke paints above the opaque surface, so it survives the
        // native-material tint and the glass fallback alike.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: active
                ? colors.primary.withValues(alpha: 0.65)
                : tokens.cardStrokeColor,
          ),
        ),
        child: Material(
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          clipBehavior: Clip.antiAlias,
          child: widget.onTap == null
              ? widget.child
              : InkWell(onTap: widget.onTap, child: widget.child),
        ),
      ),
    );
  }
}
