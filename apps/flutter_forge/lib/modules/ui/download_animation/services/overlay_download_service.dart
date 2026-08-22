import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../models/overlay_download_item.dart';
import '../models/animation_config.dart';

/// 简单的 TickerProvider 实现
class _OverlayTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// 基于 Overlay 的下载动效服务
class OverlayDownloadService {
  static final OverlayDownloadService _instance =
      OverlayDownloadService._internal();
  factory OverlayDownloadService() => _instance;
  OverlayDownloadService._internal();

  final List<OverlayDownloadItem> _activeItems = [];

  /// 开始下载动画
  void startDownload({
    required BuildContext context,
    required String fileName,
    required String fileSize,
    required Offset startPosition,
    required Offset endPosition,
    AnimationConfig? animationConfig,
    VoidCallback? onComplete,
  }) {
    final config = animationConfig ?? const AnimationConfig();
    final itemId = DateTime.now().millisecondsSinceEpoch.toString();

    // 创建 OverlayEntry
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _buildFlyingItem(
        fileName: fileName,
        fileSize: fileSize,
        startPosition: startPosition,
        endPosition: endPosition,
        config: config,
        itemId: itemId,
      ),
    );

    // 创建下载项
    final downloadItem = OverlayDownloadItem(
      id: itemId,
      fileName: fileName,
      fileSize: fileSize,
      startPosition: startPosition,
      endPosition: endPosition,
      overlayEntry: overlayEntry,
    );

    _activeItems.add(downloadItem);

    // 插入到 Overlay
    Overlay.of(context).insert(overlayEntry);

    // 开始动画
    _animateDownload(downloadItem, config, onComplete);
  }

  /// 执行下载动画
  void _animateDownload(
    OverlayDownloadItem item,
    AnimationConfig config,
    VoidCallback? onComplete,
  ) {
    // 使用单例 Ticker Provider
    final animationController = AnimationController(
      duration: Duration(
        milliseconds: (config.animationDuration / config.flyingSpeed).round(),
      ),
      vsync: _OverlayTickerProvider(),
    );

    final curveAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    final positionAnimation = Tween<Offset>(
      begin: item.startPosition,
      end: item.endPosition,
    ).animate(curveAnimation);

    final scaleAnimation = Tween<double>(begin: 1.2, end: 0.2).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    final opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    item.animationController = animationController;
    item.positionAnimation = positionAnimation;
    item.scaleAnimation = scaleAnimation;
    item.opacityAnimation = opacityAnimation;

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _removeItem(item.id);
        HapticFeedback.lightImpact();
        onComplete?.call();
      }
    });

    animationController.forward();
  }

  /// 构建飞行动画组件
  Widget _buildFlyingItem({
    required String fileName,
    required String fileSize,
    required Offset startPosition,
    required Offset endPosition,
    required AnimationConfig config,
    required String itemId,
  }) {
    final item = _activeItems.firstWhere((item) => item.id == itemId);

    return AnimatedBuilder(
      animation: item.animationController!,
      builder: (context, child) {
        final position = item.positionAnimation?.value ?? startPosition;
        final scale = item.scaleAnimation?.value ?? 1.0;
        final opacity = item.opacityAnimation?.value ?? 1.0;

        return Positioned(
          left: position.dx - config.flyingItemOffset,
          top: position.dy - config.flyingItemOffset,
          child: Transform.scale(
            scale: math.max(0.1, 1.0 - scale),
            child: Opacity(
              opacity: math.max(0.0, opacity),
              child: Container(
                padding: EdgeInsets.all(config.flyingItemPadding + 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(
                    config.flyingItemRadius + 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade300,
                      blurRadius: 12,
                      spreadRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.green.shade600.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/icons/paper_plane.svg',
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 移除动画项
  void _removeItem(String itemId) {
    final index = _activeItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _activeItems[index];
      item.dispose();
      _activeItems.removeAt(index);
    }
  }

  /// 清理所有动画
  void clearAll() {
    for (final item in _activeItems) {
      item.dispose();
    }
    _activeItems.clear();
  }

  /// 获取当前活跃的动画数量
  int get activeCount => _activeItems.length;
}
