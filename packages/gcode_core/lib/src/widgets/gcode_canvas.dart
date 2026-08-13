import 'dart:math';

import 'package:flutter/material.dart';

import '../core/gcode_bounds.dart';
import '../core/gcode_style.dart';
import '../models/gcode_command.dart';
import '../models/toolpath_segment.dart';

class GcodeCanvas extends StatelessWidget {
  const GcodeCanvas({
    super.key,
    required this.segments,
    required this.progress,
    this.errorCount = 0,
    this.commandCount = 0,
    this.bounds,
    this.style,
    this.showLegend = true,
  });

  final List<ToolpathSegment> segments;
  final double progress;
  final int errorCount;
  final int commandCount;
  final GcodeBounds? bounds;
  final GcodeStyle? style;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? GcodeStyle.light();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget content;

          if (segments.isEmpty && commandCount == 0) {
            content = _buildEmptyState();
          } else if (segments.isEmpty && commandCount > 0) {
            content = _buildNoMovementState(commandCount);
          } else if (segments.isNotEmpty && errorCount > 0) {
            content = _buildPartialErrorState(constraints, effectiveStyle);
          } else {
            content = Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _ToolpathPainter(
                    segments: segments,
                    progress: progress,
                    bounds: bounds,
                    style: effectiveStyle,
                  ),
                ),
                if (showLegend)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _CanvasLegend(style: effectiveStyle),
                  ),
              ],
            );
          }

          return content;
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.draw_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            '输入并解析 G-code 后显示轨迹',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMovementState(int cmds) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.orange.shade300),
          const SizedBox(height: 12),
          Text(
            '已解析 $cmds 条指令，但未产生运动轨迹',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '提示：G1 F1200 仅设置进给率，需配合 X/Y 坐标',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialErrorState(BoxConstraints constraints, GcodeStyle style) {
    return Stack(
      children: [
        CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _ToolpathPainter(
            segments: segments,
            progress: progress,
            bounds: bounds,
            style: style,
          ),
        ),
        if (showLegend)
          Positioned(
            left: 8,
            bottom: 8,
            child: _CanvasLegend(style: style),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$errorCount 个解析错误',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CanvasLegend extends StatelessWidget {
  const _CanvasLegend({required this.style});

  final GcodeStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendRow(style.rapidMovePaint, 'G0 快速移动', isDashed: true),
          const SizedBox(height: 4),
          _legendRow(style.linearMovePaint, 'G1 线性移动'),
          const SizedBox(height: 4),
          _legendRow(style.toolHeadPaint, '当前刀头', isCircle: true),
          const SizedBox(height: 4),
          _legendRow(
              Paint()
                ..color = const Color(0x99FF9800)
                ..strokeWidth = 1.5,
              '原点',
              isCross: true),
        ],
      ),
    );
  }

  Widget _legendRow(Paint paint, String label,
      {bool isDashed = false, bool isCircle = false, bool isCross = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 12,
          child: CustomPaint(
            painter: _LegendIconPainter(
              iconPaint: paint,
              isDashed: isDashed,
              isCircle: isCircle,
              isCross: isCross,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _LegendIconPainter extends CustomPainter {
  _LegendIconPainter({
    required Paint iconPaint,
    this.isDashed = false,
    this.isCircle = false,
    this.isCross = false,
  }) : _iconPaint = iconPaint;

  final Paint _iconPaint;
  final bool isDashed;
  final bool isCircle;
  final bool isCross;

  @override
  void paint(Canvas canvas, Size size) {
    if (isCircle) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4, _iconPaint);
    } else if (isCross) {
      final cx = size.width / 2;
      final cy = size.height / 2;
      canvas.drawLine(Offset(cx - 4, cy), Offset(cx + 4, cy), _iconPaint);
      canvas.drawLine(Offset(cx, cy - 4), Offset(cx, cy + 4), _iconPaint);
    } else if (isDashed) {
      const dash = 4.0;
      const gap = 3.0;
      var dx = 0.0;
      while (dx < size.width) {
        final end = (dx + dash).clamp(0.0, size.width);
        canvas.drawLine(Offset(dx, size.height / 2),
            Offset(end, size.height / 2), _iconPaint);
        dx = end + gap;
      }
    } else {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        _iconPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ToolpathPainter extends CustomPainter {
  _ToolpathPainter({
    required this.segments,
    required this.progress,
    required this.bounds,
    required this.style,
  });

  final List<ToolpathSegment> segments;
  final double progress;
  final GcodeBounds? bounds;
  final GcodeStyle style;

  static const _padding = 30.0;
  static const _gridSpacing = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final b = bounds ?? _computeBounds();
    final machineRangeX = max(b.maxX - b.minX, 1.0);
    final machineRangeY = max(b.maxY - b.minY, 1.0);
    final scaleX = (size.width - _padding * 2) / machineRangeX;
    final scaleY = (size.height - _padding * 2) / machineRangeY;
    final scale = min(scaleX, scaleY);

    final offsetX =
        _padding + (size.width - _padding * 2 - machineRangeX * scale) / 2;
    final offsetY =
        _padding + (size.height - _padding * 2 - machineRangeY * scale) / 2;

    _drawGrid(canvas, size, b, scale, offsetX, offsetY);
    _drawFullPath(canvas, b, scale, offsetX, offsetY);
    _drawAnimatedPath(canvas, b, scale, offsetX, offsetY);
    _drawToolHead(canvas, b, scale, offsetX, offsetY);
    _drawOrigin(canvas, b, scale, offsetX, offsetY);
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    GcodeBounds bounds,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final gridStep = _gridSpacing / scale;

    var x = (bounds.minX / gridStep).floor() * gridStep;
    while (x <= bounds.maxX) {
      final sx = offsetX + (x - bounds.minX) * scale;
      canvas.drawLine(
        Offset(sx, offsetY),
        Offset(sx, offsetY + (bounds.maxY - bounds.minY) * scale),
        style.gridPaint,
      );
      x += gridStep;
    }

    var y = (bounds.minY / gridStep).floor() * gridStep;
    while (y <= bounds.maxY) {
      final sy = offsetY + (bounds.maxY - y - bounds.minY) * scale;
      canvas.drawLine(
        Offset(offsetX, sy),
        Offset(offsetX + (bounds.maxX - bounds.minX) * scale, sy),
        style.gridPaint,
      );
      y += gridStep;
    }
  }

  void _drawFullPath(
    Canvas canvas,
    GcodeBounds bounds,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    for (final seg in segments) {
      final sx = offsetX + (seg.start.x - bounds.minX) * scale;
      final sy = offsetY + (bounds.maxY - seg.start.y - bounds.minY) * scale;
      final ex = offsetX + (seg.end.x - bounds.minX) * scale;
      final ey = offsetY + (bounds.maxY - seg.end.y - bounds.minY) * scale;

      if (seg.type == GcodeSegmentType.rapid) {
        _drawDashedLine(
          canvas,
          Offset(sx, sy),
          Offset(ex, ey),
          style.rapidMoveBgPaint,
        );
      } else {
        canvas.drawLine(
          Offset(sx, sy),
          Offset(ex, ey),
          style.linearMoveBgPaint,
        );
      }
    }
  }

  void _drawAnimatedPath(
    Canvas canvas,
    GcodeBounds bounds,
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

      if (seg.type == GcodeSegmentType.rapid) {
        _drawDashedLine(
          canvas,
          Offset(sx, sy),
          Offset(ex, ey),
          style.rapidMovePaint,
        );
      } else {
        canvas.drawLine(
          Offset(sx, sy),
          Offset(ex, ey),
          style.linearMovePaint,
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 7.0;
    const gapLength = 5.0;
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) return;

    final direction = delta / distance;
    var current = 0.0;
    while (current < distance) {
      final next = min(current + dashLength, distance);
      canvas.drawLine(
        start + direction * current,
        start + direction * next,
        paint,
      );
      current = next + gapLength;
    }
  }

  void _drawToolHead(
    Canvas canvas,
    GcodeBounds bounds,
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

    canvas.drawCircle(Offset(sx, sy), 10, style.toolHeadGlowPaint);
    canvas.drawCircle(Offset(sx, sy), 5, style.toolHeadPaint);
  }

  void _drawOrigin(
    Canvas canvas,
    GcodeBounds bounds,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final ox = offsetX + (0 - bounds.minX) * scale;
    final oy = offsetY + (bounds.maxY - 0 - bounds.minY) * scale;

    const size = 6;
    canvas.drawLine(
        Offset(ox - size, oy), Offset(ox + size, oy), style.originPaint);
    canvas.drawLine(
        Offset(ox, oy - size), Offset(ox, oy + size), style.originPaint);
    canvas.drawCircle(Offset(ox, oy), 2, style.originDotPaint);
  }

  GcodeBounds _computeBounds() {
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

    return GcodeBounds(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  @override
  bool shouldRepaint(covariant _ToolpathPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.segments != segments ||
        oldDelegate.bounds != bounds ||
        oldDelegate.style != style;
  }
}
