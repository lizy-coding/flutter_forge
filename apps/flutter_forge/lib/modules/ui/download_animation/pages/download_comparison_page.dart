import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'dart:math' as math;

import '../models/download_item.dart';
import '../models/animation_config.dart';
import '../services/overlay_download_service.dart';

/// 下载动画对比页面
class DownloadComparisonPage extends StatefulWidget {
  const DownloadComparisonPage({super.key});

  @override
  State<DownloadComparisonPage> createState() => _DownloadComparisonPageState();
}

class _DownloadComparisonPageState extends State<DownloadComparisonPage>
    with TickerProviderStateMixin {
  List<DownloadItem> downloadItems = [];
  final OverlayDownloadService _overlayService = OverlayDownloadService();

  final GlobalKey _downloadAreaKey = GlobalKey();
  Offset? _downloadAreaPosition;

  late AnimationConfig animationConfig;
  bool showControlPanel = false;

  @override
  void initState() {
    super.initState();
    animationConfig = const AnimationConfig();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getDownloadAreaPosition();
    });
  }

  void _getDownloadAreaPosition() {
    final RenderBox? renderBox =
        _downloadAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _downloadAreaPosition =
            position +
            Offset(renderBox.size.width / 2, renderBox.size.height / 2);
      });
    }
  }

  /// 使用自定义 View 方式开始下载
  void _startCustomViewDownload(
    String fileName,
    String fileSize,
    Offset startPosition,
  ) {
    final downloadItem = DownloadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      fileSize: fileSize,
      startPosition: startPosition,
      endPosition: _downloadAreaPosition ?? const Offset(200, 600),
    );

    setState(() {
      downloadItems.add(downloadItem);
    });

    _animateCustomViewDownload(downloadItem);
  }

  /// 使用 Overlay 方式开始下载
  void _startOverlayDownload(
    String fileName,
    String fileSize,
    Offset startPosition,
  ) {
    if (_downloadAreaPosition == null) return;

    _overlayService.startDownload(
      context: context,
      fileName: fileName,
      fileSize: fileSize,
      startPosition: startPosition,
      endPosition: _downloadAreaPosition!,
      animationConfig: animationConfig,
      onComplete: () {
        _showDownloadComplete(fileName, 'Overlay');
      },
    );
  }

  void _animateCustomViewDownload(DownloadItem item) {
    final animationController = AnimationController(
      duration: Duration(
        milliseconds:
            (animationConfig.animationDuration / animationConfig.flyingSpeed)
                .round(),
      ),
      vsync: this,
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

    item.positionAnimation = positionAnimation;
    item.scaleAnimation = scaleAnimation;
    item.opacityAnimation = opacityAnimation;
    item.animationController = animationController;

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          downloadItems.removeWhere((element) => element.id == item.id);
        });
        animationController.dispose();

        HapticFeedback.lightImpact();
        _showDownloadComplete(item.fileName, 'Custom View');
      }
    });

    animationController.forward();
  }

  void _showDownloadComplete(String fileName, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fileName 下载完成 ($type)'),
        duration: const Duration(seconds: 2),
        backgroundColor: type == 'Overlay' ? Colors.green : Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    for (var item in downloadItems) {
      item.animationController?.dispose();
    }
    _overlayService.clearAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LearningScaffold(
          title: '下载动画对比',
          interactiveDemo: SizedBox(
            height: 500,
            child: Column(
              children: [
                if (showControlPanel) _buildControlPanel(),
                _buildComparisonInfo(),
                Flexible(child: _buildFileList()),
                _buildDownloadArea(),
              ],
            ),
          ),
          sections: const [
            LearningObjectives(
              objectives: [
                '对比 Custom View（Stack + AnimatedBuilder）与 Overlay 两种动画实现方式的差异',
                '理解 OverlayEntry 的全局渲染机制——不受视图层级限制',
                '掌握 Tween 动画与 Interval 组合实现多阶段动画效果',
              ],
            ),
            ConceptChips(
              concepts: [
                'Stack',
                'Positioned',
                'Overlay',
                'OverlayEntry',
                'AnimatedBuilder',
                'Tween',
                'Interval',
              ],
            ),
            CodeSnippetCard(
              title: 'Custom View vs Overlay',
              code: '''// Custom View：使用 Stack + AnimatedBuilder
Stack(
  children: [
    // 主内容
    Column(children: [...]),
    // 飞入元素
    ...items.map((item) => Positioned(
      left: item.position.value.dx,
      top: item.position.value.dy,
      child: flyingWidget,
    )),
  ],
)

// Overlay：使用 Overlay.of(context).insert
final overlayEntry = OverlayEntry(builder: (_) => flyingWidget);
Overlay.of(context).insert(overlayEntry);''',
              explanation:
                  'Custom View 受父组件边界限制；Overlay 渲染在独立的 Overlay 层，不受任何父组件裁剪。',
            ),
            CommonPitfalls(
              pitfalls: [
                'OverlayEntry 必须在 dispose 中移除，否则会内存泄漏',
                'Positioned 必须在 Stack 中才能正确定位',
                'AnimationController 使用后必须 dispose',
                'globalPosition 在列表滚动时会偏移，注意使用 RenderBox.localToGlobal 转换',
              ],
            ),
            ExerciseCard(
              task:
                  '对比两种方式的下载动画：点击文件右侧的「View」和「Overlay」按钮，观察飞入动画的视觉差异。尝试调整动画参数面板中的持续时间与速度。',
              hint: 'Overlay 方式不受页面边界限制，可以覆盖在其他组件（如 AppBar）之上。',
            ),
          ],
        ),
        ...downloadItems.map((item) => _buildFlyingItem(item)),
      ],
    );
  }

  /// 构建对比说明
  Widget _buildComparisonInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '实现方式对比',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildComparisonCard(
                  title: 'Custom View',
                  color: Colors.blue,
                  description: '基于 Stack 的自定义视图实现\n受视图层级限制',
                  icon: Icons.layers,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComparisonCard(
                  title: 'Overlay',
                  color: Colors.green,
                  description: '基于 Overlay 的全局实现\n不受视图层级限制',
                  icon: Icons.open_in_full,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required Color color,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  /// 构建动画参数控制面板
  Widget _buildControlPanel() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '动画参数设置',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // 动画持续时间滑块
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('动画持续时间: ${animationConfig.animationDuration} 毫秒'),
                Slider(
                  value: animationConfig.animationDuration.toDouble(),
                  min: 500,
                  max: 3000,
                  divisions: 25,
                  onChanged: (value) {
                    setState(() {
                      animationConfig = animationConfig.copyWith(
                        animationDuration: value.toInt(),
                      );
                    });
                  },
                ),
              ],
            ),

            // 飞入速度滑块
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '飞入速度: ${animationConfig.flyingSpeed.toStringAsFixed(1)}x',
                ),
                Slider(
                  value: animationConfig.flyingSpeed,
                  min: 0.5,
                  max: 3.0,
                  divisions: 25,
                  onChanged: (value) {
                    setState(() {
                      animationConfig = animationConfig.copyWith(
                        flyingSpeed: value,
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList() {
    final files = [
      {
        'name': 'Flutter开发指南.pdf',
        'size': '15.2 MB',
        'icon': Icons.picture_as_pdf,
      },
      {'name': '项目源码.zip', 'size': '89.5 MB', 'icon': Icons.folder_zip},
      {'name': '设计稿.psd', 'size': '234.7 MB', 'icon': Icons.image},
      {'name': '演示视频.mp4', 'size': '156.3 MB', 'icon': Icons.video_file},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                file['icon'] as IconData,
                color: Colors.blue.shade600,
                size: 28,
              ),
            ),
            title: Text(
              file['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              file['size'] as String,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTapDown: (TapDownDetails details) {
                        _startCustomViewDownload(
                          file['name'] as String,
                          file['size'] as String,
                          details.globalPosition,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'View',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTapDown: (TapDownDetails details) {
                        _startOverlayDownload(
                          file['name'] as String,
                          file['size'] as String,
                          details.globalPosition,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_download,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Overlay',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadArea() {
    return Container(
      key: _downloadAreaKey,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.download_done,
              size: 40,
              color: Colors.purple.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '下载中心',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击不同按钮体验两种实现方式',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFlyingItem(DownloadItem item) {
    return AnimatedBuilder(
      animation: item.animationController!,
      builder: (context, child) {
        final position = item.positionAnimation!.value;
        final scale = item.scaleAnimation!.value;
        final opacity = item.opacityAnimation!.value;

        return Positioned(
          left: position.dx - animationConfig.flyingItemOffset,
          top: position.dy - animationConfig.flyingItemOffset,
          child: Transform.scale(
            scale: math.max(0.1, 1.0 - scale),
            child: Opacity(
              opacity: math.max(0.0, opacity),
              child: Container(
                padding: EdgeInsets.all(animationConfig.flyingItemPadding + 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(
                    animationConfig.flyingItemRadius + 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade300,
                      blurRadius: 12,
                      spreadRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.blue.shade600.withValues(alpha: 0.3),
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
}
