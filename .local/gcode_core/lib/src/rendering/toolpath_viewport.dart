import 'dart:math' as math;
import 'dart:ui';
import '../core/gcode_bounds.dart';
import '../models/toolpath_segment.dart';

/// One coordinate transform for paths, grid and moving markers.
class ToolpathViewport {
  ToolpathViewport(this.bounds, Size size) {
    final x = math.max(bounds.maxX - bounds.minX, 1.0);
    final y = math.max(bounds.maxY - bounds.minY, 1.0);
    scale = math.min((size.width - 60) / x, (size.height - 60) / y);
    offset = Offset(30 + (size.width - 60 - x * scale) / 2,
        30 + (size.height - 60 - y * scale) / 2);
  }
  final GcodeBounds bounds;
  late final double scale;
  late final Offset offset;
  Offset project(double x, double y) => Offset(
      offset.dx + (x - bounds.minX) * scale,
      offset.dy + (bounds.maxY - y) * scale);
  Rect get plot => Rect.fromLTRB(
      offset.dx,
      offset.dy,
      offset.dx + (bounds.maxX - bounds.minX) * scale,
      offset.dy + (bounds.maxY - bounds.minY) * scale);
  Offset get gridOrigin {
    final step = 20 / scale;
    return project((bounds.minX / step).floor() * step,
        (bounds.maxY / step).ceil() * step);
  }

  Offset toolHead(List<ToolpathSegment> segments, double progress) {
    final position = progress.clamp(0.0, 1.0) * segments.length;
    final index = position.floor().clamp(0, segments.length - 1);
    final t = (position - index).clamp(0.0, 1.0);
    final segment = segments[index];
    return project(segment.start.x + (segment.end.x - segment.start.x) * t,
        segment.start.y + (segment.end.y - segment.start.y) * t);
  }

  static GcodeBounds measure(List<ToolpathSegment> segments) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final s in segments) {
      minX = math.min(minX, math.min(s.start.x, s.end.x));
      minY = math.min(minY, math.min(s.start.y, s.end.y));
      maxX = math.max(maxX, math.max(s.start.x, s.end.x));
      maxY = math.max(maxY, math.max(s.start.y, s.end.y));
    }
    return segments.isEmpty
        ? GcodeBounds.zero
        : GcodeBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }
}
