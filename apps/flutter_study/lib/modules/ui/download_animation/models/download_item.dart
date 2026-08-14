import 'package:flutter/material.dart';

/// 代表下载项的数据模型类
class DownloadItem {
  final String id;
  final String fileName;
  final String fileSize;
  final Offset startPosition;
  final Offset endPosition;

  Animation<Offset>? positionAnimation;
  Animation<double>? scaleAnimation;
  Animation<double>? opacityAnimation;
  AnimationController? animationController;

  DownloadItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.startPosition,
    required this.endPosition,
  });

  /// 转换为Map，用于序列化
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'fileSize': fileSize,
      'startPosition': startPosition,
      'endPosition': endPosition,
    };
  }

  /// 从Map创建实例，用于反序列化
  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      id: map['id'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      startPosition: map['startPosition'],
      endPosition: map['endPosition'],
    );
  }
}
