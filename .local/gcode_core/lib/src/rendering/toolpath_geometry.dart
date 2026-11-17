import 'dart:typed_data';
import 'dart:ui';

import '../core/gcode_bounds.dart';
import '../models/gcode_command.dart';
import '../models/toolpath_segment.dart';
import 'toolpath_viewport.dart';

/// Screen-space geometry rebuilt only when the path, viewport or width changes.
class ToolpathGeometry {
  ToolpathGeometry(this.vertices, this.prefixVertexCounts);
  final Float32List vertices;

  /// Vertex count through each original segment, including degenerate ones.
  final List<int> prefixVertexCounts;
  int get vertexCount => vertices.length ~/ 7;

  static int foregroundVertexCount(
      List<int> prefixVertexCounts, double progress) {
    if (!progress.isFinite || progress <= 0) return 0;
    final segmentCount = prefixVertexCounts.length - 1;
    final visibleSegments = (progress.clamp(0.0, 1.0) * segmentCount).ceil();
    return prefixVertexCounts[visibleSegments];
  }

  static ToolpathGeometry build(List<ToolpathSegment> segments,
      GcodeBounds bounds, Size size, double maximumWidth) {
    if (size.width <= 60 || size.height <= 60) {
      return ToolpathGeometry(
          Float32List(0), List.filled(segments.length + 1, 0));
    }
    final viewport = ToolpathViewport(bounds, size);
    final radius = maximumWidth / 2 + 1;
    final data = Float32List(segments.length * 6 * 7);
    final prefixVertexCounts = List<int>.filled(segments.length + 1, 0);
    var cursor = 0;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final start = viewport.project(segment.start.x, segment.start.y);
      final end = viewport.project(segment.end.x, segment.end.y);
      final delta = end - start;
      final length = delta.distance;
      if (!length.isFinite || length <= 0) {
        prefixVertexCounts[i + 1] = cursor ~/ 7;
        continue;
      }
      final tangent = delta / length;
      final normal = Offset(-tangent.dy, tangent.dx);
      for (final corner in const [0, 1, 2, 2, 1, 3]) {
        final along = corner.isOdd ? length + radius : -radius;
        final across = corner < 2 ? -radius : radius;
        final point = start + tangent * along + normal * across;
        data[cursor++] = point.dx;
        data[cursor++] = point.dy;
        data[cursor++] = along;
        data[cursor++] = across;
        data[cursor++] = length;
        data[cursor++] = i.toDouble();
        data[cursor++] = segment.type == GcodeSegmentType.rapid ? 1 : 0;
      }
      prefixVertexCounts[i + 1] = cursor ~/ 7;
    }
    return ToolpathGeometry(
        Float32List.sublistView(data, 0, cursor), prefixVertexCounts);
  }
}
