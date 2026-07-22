import 'package:flutter/material.dart';

class GcodeStyle {
  const GcodeStyle({
    required this.rapidMovePaint,
    required this.rapidMoveBgPaint,
    required this.linearMovePaint,
    required this.linearMoveBgPaint,
    required this.toolHeadPaint,
    required this.toolHeadGlowPaint,
    required this.originPaint,
    required this.originDotPaint,
    required this.gridPaint,
  });

  final Paint rapidMovePaint;
  final Paint rapidMoveBgPaint;
  final Paint linearMovePaint;
  final Paint linearMoveBgPaint;
  final Paint toolHeadPaint;
  final Paint toolHeadGlowPaint;
  final Paint originPaint;
  final Paint originDotPaint;
  final Paint gridPaint;

  factory GcodeStyle.light({
    Color rapidColor = Colors.red,
    Color linearColor = Colors.green,
    Color toolHeadColor = Colors.red,
    Color originColor = const Color(0x99FF9800),
    Color gridColor = const Color(0x26000000),
  }) {
    return GcodeStyle(
      rapidMovePaint: Paint()
        ..color = rapidColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
      rapidMoveBgPaint: Paint()
        ..color = rapidColor.withValues(alpha: 0.25)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
      linearMovePaint: Paint()
        ..color = linearColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
      linearMoveBgPaint: Paint()
        ..color = linearColor.withValues(alpha: 0.15)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
      toolHeadPaint: Paint()
        ..color = toolHeadColor
        ..style = PaintingStyle.fill,
      toolHeadGlowPaint: Paint()
        ..color = toolHeadColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
      originPaint: Paint()
        ..color = originColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
      originDotPaint: Paint()
        ..color = originColor
        ..style = PaintingStyle.fill,
      gridPaint: Paint()
        ..color = gridColor
        ..strokeWidth = 0.5,
    );
  }
}
