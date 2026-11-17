import 'dart:ui';

/// Immutable stroke parameters shared by the GPU renderer and legend widgets.
class GcodeStroke {
  const GcodeStroke(this.color, this.width) : assert(width > 0);
  final Color color;
  final double width;
}

/// Drawing parameters, independent of Canvas Paint objects.
class GcodeStyle {
  const GcodeStyle({
    this.rapidMove = const GcodeStroke(Color(0xFFF44336), 1.5),
    this.rapidBackground = const GcodeStroke(Color(0x40F44336), 1),
    this.linearMove = const GcodeStroke(Color(0xFF4CAF50), 2.5),
    this.linearBackground = const GcodeStroke(Color(0x264CAF50), 1),
    this.grid = const GcodeStroke(Color(0x26000000), 0.5),
    this.origin = const GcodeStroke(Color(0x99FF9800), 1.5),
    this.originDotColor = const Color(0x99FF9800),
    this.toolHeadColor = const Color(0xFFF44336),
    this.toolHeadGlowColor = const Color(0x4DF44336),
  });

  final GcodeStroke rapidMove;
  final GcodeStroke rapidBackground;
  final GcodeStroke linearMove;
  final GcodeStroke linearBackground;
  final GcodeStroke grid;
  final GcodeStroke origin;
  final Color originDotColor;
  final Color toolHeadColor;
  final Color toolHeadGlowColor;

  factory GcodeStyle.light({
    Color rapidColor = const Color(0xFFF44336),
    Color linearColor = const Color(0xFF4CAF50),
    Color toolHeadColor = const Color(0xFFF44336),
    Color originColor = const Color(0x99FF9800),
    Color gridColor = const Color(0x26000000),
  }) =>
      GcodeStyle(
        rapidMove: GcodeStroke(rapidColor, 1.5),
        rapidBackground: GcodeStroke(rapidColor.withValues(alpha: 0.25), 1),
        linearMove: GcodeStroke(linearColor, 2.5),
        linearBackground: GcodeStroke(linearColor.withValues(alpha: 0.15), 1),
        grid: GcodeStroke(gridColor, 0.5),
        origin: GcodeStroke(originColor, 1.5),
        originDotColor: originColor,
        toolHeadColor: toolHeadColor,
        toolHeadGlowColor: toolHeadColor.withValues(alpha: 0.3),
      );
}
