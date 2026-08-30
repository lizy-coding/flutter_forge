import 'dart:async';
import 'package:flutter/material.dart';
import '../models/drawing_element.dart';

class SnapLine {
  final Offset start;
  final Offset end;
  final SnapType type;

  const SnapLine({required this.start, required this.end, required this.type});
}

enum SnapType { horizontal, vertical, center }

class AdsorptionManager {
  static const double snapThreshold = 25.0;

  /// 延迟隐藏时间（毫秒）
  static const int hideDelayMs = 500;

  /// 当前是否处于吸附状态
  static bool _isSnapped = false;

  /// 延迟隐藏计时器
  static Timer? _hideTimer;

  /// 最后一次吸附的线条
  static List<SnapLine> _lastSnapLines = [];

  /// 获取可见的吸附线（带延迟隐藏机制）
  static List<SnapLine> getVisibleSnapLines(
    List<DrawingElement> elements,
    DrawingElement? currentElement,
  ) {
    if (currentElement == null) return [];

    final allSnapLines = calculateSnapLines(elements, currentElement);
    final visibleLines = <SnapLine>[];
    final currentSnapPoints = currentElement.getSnapPoints();
    bool hasActiveSnap = false;

    for (final snapLine in allSnapLines) {
      bool shouldShow = false;

      for (final point in currentSnapPoints) {
        if (snapLine.type == SnapType.vertical) {
          if ((point.dx - snapLine.start.dx).abs() < snapThreshold) {
            shouldShow = true;
            hasActiveSnap = true;
            break;
          }
        } else if (snapLine.type == SnapType.horizontal) {
          if ((point.dy - snapLine.start.dy).abs() < snapThreshold) {
            shouldShow = true;
            hasActiveSnap = true;
            break;
          }
        }
      }

      if (shouldShow) {
        visibleLines.add(snapLine);
      }
    }

    // 更新吸附状态和延迟隐藏逻辑
    if (hasActiveSnap) {
      // 有活跃的吸附，立即显示辅助线并启动延迟隐藏
      if (!_isSnapped) {
        // 刚进入吸附状态，启动延迟隐藏计时器
        _isSnapped = true;
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(milliseconds: hideDelayMs), () {
          _lastSnapLines.clear();
          _isSnapped = false;
        });
      }
      _lastSnapLines = visibleLines;
      return visibleLines;
    } else {
      // 没有活跃吸附，返回缓存的线条（如果在延迟期间）
      return _lastSnapLines;
    }
  }

  static List<SnapLine> calculateSnapLines(
    List<DrawingElement> elements,
    DrawingElement? currentElement,
  ) {
    if (currentElement == null || elements.isEmpty) return [];

    final snapLines = <SnapLine>[];
    final currentSnapPoints = currentElement.getSnapPoints();

    for (final element in elements) {
      if (element.id == currentElement.id) continue;

      final elementSnapPoints = element.getSnapPoints();

      for (final currentPoint in currentSnapPoints) {
        if (!currentPoint.dx.isFinite || !currentPoint.dy.isFinite) continue;
        for (final elementPoint in elementSnapPoints) {
          if (!elementPoint.dx.isFinite || !elementPoint.dy.isFinite) continue;
          if ((currentPoint.dx - elementPoint.dx).abs() < snapThreshold) {
            snapLines.add(
              SnapLine(
                start: Offset(elementPoint.dx, 0),
                end: Offset(elementPoint.dx, double.infinity),
                type: SnapType.vertical,
              ),
            );
          }

          if ((currentPoint.dy - elementPoint.dy).abs() < snapThreshold) {
            snapLines.add(
              SnapLine(
                start: Offset(0, elementPoint.dy),
                end: Offset(double.infinity, elementPoint.dy),
                type: SnapType.horizontal,
              ),
            );
          }
        }
      }
    }

    return snapLines;
  }

  static Offset snapPosition(
    Offset position,
    List<DrawingElement> elements,
    DrawingElement currentElement,
  ) {
    if (!position.dx.isFinite || !position.dy.isFinite) return position;
    final snapLines = calculateSnapLines(elements, currentElement);
    double newX = position.dx;
    double newY = position.dy;

    // 查找最近的吸附线
    double minXDistance = double.infinity;
    double minYDistance = double.infinity;
    double snapX = position.dx;
    double snapY = position.dy;

    for (final snapLine in snapLines) {
      if (snapLine.type == SnapType.vertical) {
        final distance = position.dx - snapLine.start.dx;
        if (distance.abs() < snapThreshold &&
            distance.abs() < minXDistance.abs()) {
          minXDistance = distance;
          snapX = snapLine.start.dx;
        }
      } else if (snapLine.type == SnapType.horizontal) {
        final distance = position.dy - snapLine.start.dy;
        if (distance.abs() < snapThreshold &&
            distance.abs() < minYDistance.abs()) {
          minYDistance = distance;
          snapY = snapLine.start.dy;
        }
      }
    }

    // 简化的吸附逻辑：在阈值范围内直接吸附
    if (minXDistance != double.infinity) {
      newX = snapX;
    }

    if (minYDistance != double.infinity) {
      newY = snapY;
    }

    return Offset(newX, newY);
  }

  /// 应用磁吸效果的拖拽方法
  /// 简化的磁吸逻辑，减少晃动
  static Offset applyMagneticEffect(
    Offset currentPosition,
    List<DrawingElement> elements,
    DrawingElement currentElement, {
    Function(DrawingElement)? onElementSnapped,
  }) {
    // 简化逻辑：直接使用snapPosition方法
    return snapPosition(currentPosition, elements, currentElement);
  }

  /// 清理延迟隐藏计时器（在页面销毁时调用）
  static void dispose() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _lastSnapLines.clear();
    _isSnapped = false;
  }
}
