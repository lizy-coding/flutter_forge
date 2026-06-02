import 'dart:math';

import 'package:flutter/material.dart';

import 'package:gcode_core/gcode_core.dart';

class GcodeCanvas extends StatelessWidget {
  const GcodeCanvas({
    super.key,
    required this.segments,
    required this.progress,
    this.errorCount = 0,
  });

  final List<ToolpathSegment> segments;
  final double progress;
  final int errorCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (segments.isEmpty) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.draw_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorCount > 0
                          ? '存在 $errorCount 个解析错误，无有效轨迹'
                          : '输入并解析 G-code 后显示轨迹',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _ToolpathPainter(
              segments: segments,
              progress: progress,
            ),
          );
        },
      ),
    );
  }
}

class _ToolpathPainter extends CustomPainter {
  _ToolpathPainter({
    required this.segments,
    required this.progress,
  });

  final List<ToolpathSegment> segments;
  final double progress;

  static const _padding = 30.0;
  static const _gridSpacing = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final bounds = _calculateBounds();
    final machineRangeX = bounds.maxX - bounds.minX;
    final machineRangeY = bounds.maxY - bounds.minY;
    final scaleX = (size.width - _padding * 2) / max(machineRangeX, 1);
    final scaleY = (size.height - _padding * 2) / max(machineRangeY, 1);
    final scale = min(scaleX, scaleY);

    final offsetX =
        _padding + (size.width - _padding * 2 - machineRangeX * scale) / 2;
    final offsetY =
        _padding + (size.height - _padding * 2 - machineRangeY * scale) / 2;

    _drawGrid(canvas, size, bounds, scale, offsetX, offsetY);
    _drawFullPath(canvas, bounds, scale, offsetX, offsetY);
    _drawAnimatedPath(canvas, bounds, scale, offsetX, offsetY);
    _drawToolHead(canvas, bounds, scale, offsetX, offsetY);
    _drawOrigin(canvas, bounds, scale, offsetX, offsetY);
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    _Bounds bounds,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    final gridStep = _gridSpacing / scale;

    var x = (bounds.minX / gridStep).floor() * gridStep;
    while (x <= bounds.maxX) {
      final sx = offsetX + (x - bounds.minX) * scale;
      canvas.drawLine(Offset(sx, offsetY),
          Offset(sx, offsetY + (bounds.maxY - bounds.minY) * scale), gridPaint);
      x += gridStep;
    }

    var y = (bounds.minY / gridStep).floor() * gridStep;
    while (y <= bounds.maxY) {
      final sy = offsetY + (bounds.maxY - y - bounds.minY) * scale;
      canvas.drawLine(Offset(offsetX, sy),
          Offset(offsetX + (bounds.maxX - bounds.minX) * scale, sy), gridPaint);
      y += gridStep;
    }
  }

  void _drawFullPath(
    Canvas canvas,
    _Bounds bounds,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    for (final seg in segments) {
      final sx = offsetX + (seg.start.x - bounds.minX) * scale;
      final sy = offsetY + (bounds.maxY - seg.start.y - bounds.minY) * scale;
      final ex = offsetX + (seg.end.x - bounds.minX) * scale;
      final ey = offsetY + (bounds.maxY - seg.end.y - bounds.minY) * scale;

      final paint = Paint()
        ..color = seg.type == GcodeSegmentType.rapid
            ? Colors.blue.withValues(alpha: 0.15)
            : Colors.green.withValues(alpha: 0.15)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      if (seg.type == GcodeSegmentType.rapid) {
        paint.strokeWidth = 0.5;
      }

      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paint);
    }
  }

  void _drawAnimatedPath(
    Canvas canvas,
    _Bounds bounds,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    if (progress <= 0 || segments.isEmpty) return;

    final totalSegments = segments.length;
    final currentSegFloat = progress * totalSegments;
    final currentSegIndex = currentSegFloat.floor().clamp(0, totalSegments - 1);
    final localProgress = (currentSegFloat - currentSegIndex).clamp(0.0, 1.0);

    for (var i = 0; i <= currentSegIndex && i < totalSegments; i++) {
      final seg = segments[i];
      final isCurrent = i == currentSegIndex;

      var endX = seg.end.x;
      var endY = seg.end.y;

      if (isCurrent) {
        endX = seg.start.x + (seg.end.x - seg.start.x) * localProgress;
        endY = seg.start.y + (seg.end.y - seg.start.y) * localProgress;
      }

      final sx = offsetX + (seg.start.x - bounds.minX) * scale;
      final sy = offsetY + (bounds.maxY - seg.start.y - bounds.minY) * scale;
      final ex = offsetX + (endX - bounds.minX) * scale;
      final ey = offsetY + (bounds.maxY - endY - bounds.minY) * scale;

      final paint = Paint()
        ..color =
            seg.type == GcodeSegmentType.rapid ? Colors.blue : Colors.green
        ..strokeWidth = seg.type == GcodeSegmentType.rapid ? 1.5 : 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (seg.type == GcodeSegmentType.rapid) {
        paint.strokeWidth = 1.5;
      }

      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paint);
    }
  }

  void _drawToolHead(
    Canvas canvas,
    _Bounds bounds,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    if (progress <= 0 || segments.isEmpty) return;

    final totalSegments = segments.length;
    final currentSegFloat = progress * totalSegments;
    final currentSegIndex = currentSegFloat.floor().clamp(0, totalSegments - 1);
    final localProgress = (currentSegFloat - currentSegIndex).clamp(0.0, 1.0);
    final seg = segments[currentSegIndex];

    final toolX = seg.start.x + (seg.end.x - seg.start.x) * localProgress;
    final toolY = seg.start.y + (seg.end.y - seg.start.y) * localProgress;

    final sx = offsetX + (toolX - bounds.minX) * scale;
    final sy = offsetY + (bounds.maxY - toolY - bounds.minY) * scale;

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(sx, sy), 5, paint);

    final outerPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sx, sy), 10, outerPaint);
  }

  void _drawOrigin(
    Canvas canvas,
    _Bounds bounds,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final ox = offsetX + (0 - bounds.minX) * scale;
    final oy = offsetY + (bounds.maxY - 0 - bounds.minY) * scale;

    final paint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const size = 6;
    canvas.drawLine(Offset(ox - size, oy), Offset(ox + size, oy), paint);
    canvas.drawLine(Offset(ox, oy - size), Offset(ox, oy + size), paint);
    canvas.drawCircle(Offset(ox, oy), 2, paint..style = PaintingStyle.fill);
  }

  _Bounds _calculateBounds() {
    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;

    for (final seg in segments) {
      minX = min(minX, min(seg.start.x, seg.end.x));
      maxX = max(maxX, max(seg.start.x, seg.end.x));
      minY = min(minY, min(seg.start.y, seg.end.y));
      maxY = max(maxY, max(seg.start.y, seg.end.y));
    }

    return _Bounds(minX, maxX, minY, maxY);
  }

  @override
  bool shouldRepaint(covariant _ToolpathPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.segments != segments;
  }
}

class _Bounds {
  const _Bounds(this.minX, this.maxX, this.minY, this.maxY);

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
}
