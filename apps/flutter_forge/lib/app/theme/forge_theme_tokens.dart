import 'package:flutter/material.dart';

@immutable
class ForgeThemeTokens extends ThemeExtension<ForgeThemeTokens> {
  const ForgeThemeTokens({
    required this.canvas,
    required this.sidebar,
    required this.codeSurface,
    required this.success,
    required this.warning,
    required this.aiAccent,
    required this.textMuted,
  });

  final Color canvas;
  final Color sidebar;
  final Color codeSurface;
  final Color success;
  final Color warning;
  final Color aiAccent;
  final Color textMuted;

  static const light = ForgeThemeTokens(
    canvas: Color(0xFFF3F6F9),
    sidebar: Color(0xFFFFFFFF),
    codeSurface: Color(0xFF10161D),
    success: Color(0xFF16875D),
    warning: Color(0xFFA96800),
    aiAccent: Color(0xFF7157C8),
    textMuted: Color(0xFF7A8997),
  );

  static const dark = ForgeThemeTokens(
    canvas: Color(0xFF0B0F14),
    sidebar: Color(0xFF131B24),
    codeSurface: Color(0xFF0D131A),
    success: Color(0xFF45C486),
    warning: Color(0xFFE6B450),
    aiAccent: Color(0xFFA78BFA),
    textMuted: Color(0xFF71808F),
  );

  @override
  ForgeThemeTokens copyWith({
    Color? canvas,
    Color? sidebar,
    Color? codeSurface,
    Color? success,
    Color? warning,
    Color? aiAccent,
    Color? textMuted,
  }) => ForgeThemeTokens(
    canvas: canvas ?? this.canvas,
    sidebar: sidebar ?? this.sidebar,
    codeSurface: codeSurface ?? this.codeSurface,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    aiAccent: aiAccent ?? this.aiAccent,
    textMuted: textMuted ?? this.textMuted,
  );

  @override
  ForgeThemeTokens lerp(ForgeThemeTokens? other, double t) {
    if (other == null) return this;
    return ForgeThemeTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      codeSurface: Color.lerp(codeSurface, other.codeSurface, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      aiAccent: Color.lerp(aiAccent, other.aiAccent, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

extension ForgeThemeContext on BuildContext {
  ForgeThemeTokens get forgeColors {
    final theme = Theme.of(this);
    return theme.extension<ForgeThemeTokens>() ??
        (theme.brightness == Brightness.dark
            ? ForgeThemeTokens.dark
            : ForgeThemeTokens.light);
  }
}
