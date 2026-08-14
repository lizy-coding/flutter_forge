import 'package:flutter/material.dart';

/// Overlay 下载动画项的数据模型
class OverlayDownloadItem {
  final String id;
  final String fileName;
  final String fileSize;
  final Offset startPosition;
  final Offset endPosition;
  final OverlayEntry overlayEntry;

  AnimationController? animationController;
  Animation<Offset>? positionAnimation;
  Animation<double>? scaleAnimation;
  Animation<double>? opacityAnimation;

  OverlayDownloadItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.startPosition,
    required this.endPosition,
    required this.overlayEntry,
  });

  /// 清理资源
  void dispose() {
    animationController?.dispose();
    overlayEntry.remove();
  }
}
