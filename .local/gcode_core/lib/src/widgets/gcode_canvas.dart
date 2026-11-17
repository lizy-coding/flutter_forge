import 'package:flutter/material.dart';
import '../core/gcode_bounds.dart';
import '../core/gcode_style.dart';
import '../models/toolpath_segment.dart';
import '../rendering/gpu_toolpath_layer.dart';

/// GPU-only G-code drawing area. The host must enable Flutter GPU and Impeller.
class GcodeCanvas extends StatelessWidget {
  const GcodeCanvas(
      {super.key,
      required this.segments,
      required this.progress,
      this.errorCount = 0,
      this.commandCount = 0,
      this.bounds,
      this.style,
      this.showLegend = true,
      this.onReady,
      this.onError});
  final List<ToolpathSegment> segments;
  final double progress;
  final int errorCount;
  final int commandCount;
  final GcodeBounds? bounds;
  final GcodeStyle? style;
  final bool showLegend;

  /// The callback invoked after this mounted scene presents its first GPU frame.
  ///
  /// Called once per segment-list version, after frame composition. Empty scenes
  /// and scenes too small to draw do not report readiness.
  final VoidCallback? onReady;

  /// The callback reporting GPU initialization or drawing failures.
  ///
  /// Initialization failures prevent [onReady]. Drawing may fail after the
  /// first frame has been presented. Disposed scenes emit no events.
  final ValueChanged<Object>? onError;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? const GcodeStyle();
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300)),
      child: segments.isEmpty
          ? Center(
              child: Text(
                  commandCount == 0
                      ? '输入并解析 G-code 后显示轨迹'
                      : '已解析 $commandCount 条指令，但未产生运动轨迹',
                  textAlign: TextAlign.center))
          : ClipRect(
              child: Stack(fit: StackFit.expand, children: [
              GpuToolpathLayer(
                  segments: segments,
                  bounds: bounds,
                  progress: progress.isFinite
                      ? progress.clamp(0.0, 1.0).toDouble()
                      : 0.0,
                  style: effectiveStyle,
                  onReady: onReady,
                  onError: onError),
              if (showLegend)
                Positioned(
                    left: 8, bottom: 8, child: _Legend(style: effectiveStyle)),
              if (errorCount > 0)
                Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('$errorCount 个解析错误',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    )),
            ])),
    );
  }
}

// Legends are ordinary UI widgets, not a second graphics renderer.
class _Legend extends StatelessWidget {
  const _Legend({required this.style});
  final GcodeStyle style;
  Widget row(Widget symbol, String text) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 24, height: 12, child: Center(child: symbol)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11)),
      ]);
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6)),
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  row(
                      Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                              3,
                              (_) => Container(
                                  width: 5,
                                  height: style.rapidMove.width,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  color: style.rapidMove.color))),
                      'G0 快速移动'),
                  const SizedBox(height: 4),
                  row(
                      Container(
                          width: 24,
                          height: style.linearMove.width,
                          color: style.linearMove.color),
                      'G1 线性移动'),
                  const SizedBox(height: 4),
                  row(
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: style.toolHeadColor,
                              shape: BoxShape.circle)),
                      '当前刀头'),
                  const SizedBox(height: 4),
                  row(
                      Text('+',
                          style: TextStyle(
                              color: style.origin.color,
                              fontSize: 14,
                              height: 1)),
                      '原点'),
                ])),
      );
}
