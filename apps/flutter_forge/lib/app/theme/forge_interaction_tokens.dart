import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// App-wide interaction and surface-stroke tuning shared by every shell
/// surface.
///
/// Hover, selection, keyboard-cursor and card-stroke feedback form one
/// contract across platforms and materials; only the material backend
/// differs. Values derive from the active [ColorScheme] so both palettes stay
/// consistent without per-palette tables.
@immutable
class ForgeInteractionTokens extends ThemeExtension<ForgeInteractionTokens> {
  const ForgeInteractionTokens({
    required this.hoverDuration,
    required this.selectedColor,
    required this.hoverOverlayColor,
    required this.focusColor,
    required this.cardStrokeColor,
    required this.chromeHighlightColor,
    required this.cardSurfaceAlpha,
  });

  factory ForgeInteractionTokens.fromScheme(ColorScheme colors) {
    final dark = colors.brightness == Brightness.dark;
    return ForgeInteractionTokens(
      hoverDuration: const Duration(milliseconds: 120),
      selectedColor: colors.primary.withValues(alpha: dark ? 0.2 : 0.12),
      hoverOverlayColor: colors.onSurface.withValues(alpha: dark ? 0.08 : 0.05),
      focusColor: colors.primary.withValues(alpha: 0.6),
      // Shadows barely read on dark themes; strokes carry hierarchy there.
      cardStrokeColor: dark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.08),
      chromeHighlightColor: Colors.white.withValues(alpha: dark ? 0.12 : 0.45),
      cardSurfaceAlpha: dark ? 0.86 : 0.9,
    );
  }

  /// Hover/selection transition speed; reduce-motion callers snap to zero.
  final Duration hoverDuration;
  final Color selectedColor;
  final Color hoverOverlayColor;
  final Color focusColor;
  final Color cardStrokeColor;
  final Color chromeHighlightColor;

  /// Opacity of content cards sitting on native window material. Cards stay
  /// near-solid so hierarchy reads as "more opaque = higher".
  final double cardSurfaceAlpha;

  @override
  ForgeInteractionTokens copyWith({
    Duration? hoverDuration,
    Color? selectedColor,
    Color? hoverOverlayColor,
    Color? focusColor,
    Color? cardStrokeColor,
    Color? chromeHighlightColor,
    double? cardSurfaceAlpha,
  }) => ForgeInteractionTokens(
    hoverDuration: hoverDuration ?? this.hoverDuration,
    selectedColor: selectedColor ?? this.selectedColor,
    hoverOverlayColor: hoverOverlayColor ?? this.hoverOverlayColor,
    focusColor: focusColor ?? this.focusColor,
    cardStrokeColor: cardStrokeColor ?? this.cardStrokeColor,
    chromeHighlightColor: chromeHighlightColor ?? this.chromeHighlightColor,
    cardSurfaceAlpha: cardSurfaceAlpha ?? this.cardSurfaceAlpha,
  );

  @override
  ForgeInteractionTokens lerp(ForgeInteractionTokens? other, double t) {
    if (other == null) return this;
    return ForgeInteractionTokens(
      hoverDuration: Duration(
        milliseconds: lerpDouble(
          hoverDuration.inMilliseconds,
          other.hoverDuration.inMilliseconds,
          t,
        )!.round(),
      ),
      selectedColor: Color.lerp(selectedColor, other.selectedColor, t)!,
      hoverOverlayColor: Color.lerp(
        hoverOverlayColor,
        other.hoverOverlayColor,
        t,
      )!,
      focusColor: Color.lerp(focusColor, other.focusColor, t)!,
      cardStrokeColor: Color.lerp(cardStrokeColor, other.cardStrokeColor, t)!,
      chromeHighlightColor: Color.lerp(
        chromeHighlightColor,
        other.chromeHighlightColor,
        t,
      )!,
      cardSurfaceAlpha: lerpDouble(
        cardSurfaceAlpha,
        other.cardSurfaceAlpha,
        t,
      )!,
    );
  }
}

extension ForgeInteractionContext on BuildContext {
  ForgeInteractionTokens get forgeInteraction {
    final theme = Theme.of(this);
    return theme.extension<ForgeInteractionTokens>() ??
        ForgeInteractionTokens.fromScheme(theme.colorScheme);
  }
}
