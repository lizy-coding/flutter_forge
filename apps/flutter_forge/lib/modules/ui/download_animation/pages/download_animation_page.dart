import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import '../models/animation_config.dart';
import '../models/download_item.dart';

/// 下载动画页面组件
class DownloadAnimationPage extends StatefulWidget {
  final AnimationConfig? animationConfig;

  const DownloadAnimationPage({super.key, this.animationConfig});

  @override
  State<DownloadAnimationPage> createState() => _DownloadAnimationPageState();
}

class _DownloadAnimationPageState extends State<DownloadAnimationPage>
    with TickerProviderStateMixin {
  List<DownloadItem> downloadItems = [];
  late AnimationController _animationController;

  final GlobalKey _downloadAreaKey = GlobalKey();
  Offset? _downloadAreaPosition;

  late AnimationConfig animationConfig;

  bool showControlPanel = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    animationConfig = widget.animationConfig ?? const AnimationConfig();

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

  void _startDownload(String fileName, String fileSize, Offset startPosition) {
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

    _animateDownload(downloadItem);
  }

  void _animateDownload(DownloadItem item) {
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
        _showDownloadComplete(item);
      }
    });

    animationController.forward();
  }

  void _showDownloadComplete(DownloadItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.fileName} 下载完成'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var item in downloadItems) {
      item.animationController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LearningScaffold(
          title: '下载飞入动画',
          interactiveDemo: SizedBox(
            height: 480,
            child: Column(
              children: [
                _buildSettingsToggle(),
                if (showControlPanel) _buildControlPanel(),
                Flexible(child: _buildFileList()),
                _buildDownloadArea(),
              ],
            ),
          ),
          sections: const [
            LearningObjectives(
              objectives: [
                '理解 AnimationController 的生命周期管理——创建、forward、dispose。',
                '掌握 Tween 与 CurvedAnimation 的组合使用来控制动画轨迹。',
                '理解 AnimatedBuilder 的刷新机制——监听动画值变化重建 widget。',
                '掌握 Stack + Positioned 实现元素飞入效果。',
                '理解 Offset 动画与缩放、透明度动画的协同调度。',
              ],
            ),
            ConceptChips(
              concepts: [
                'AnimationController',
                'Tween',
                'CurvedAnimation',
                'AnimatedBuilder',
                'Stack',
                'Positioned',
                'Interval',
              ],
            ),
            CodeSnippetCard(
              title: '飞入动画核心模式',
              code: '''// 创建动画控制器
final controller = AnimationController(
  duration: Duration(seconds: 2),
  vsync: this,
);

// 位置动画
final positionAnim = Tween<Offset>(
  begin: startPos,
  end: endPos,
).animate(CurvedAnimation(
  parent: controller,
  curve: Curves.easeInOut,
));

// 使用 AnimatedBuilder 驱动 widget
AnimatedBuilder(
  animation: controller,
  builder: (context, child) {
    return Positioned(
      left: positionAnim.value.dx,
      top: positionAnim.value.dy,
      child: child!,
    );
  },
  child: flyingWidget,
);''',
              explanation:
                  'AnimationController 驱动 Tween 输出插值，AnimatedBuilder 监听动画变化并重建 widget 树，实现流畅的飞入效果。',
            ),
            CommonPitfalls(
              pitfalls: [
                'AnimationController 必须在使用后 dispose()，否则会造成内存泄漏。',
                '在 State 中混入 TickerProviderStateMixin 才能创建 AnimationController。',
                'AnimationController 的 duration 过短会导致动画卡顿，建议 800ms 以上。',
                '多个动画组合时（位置+缩放+透明度），注意 Interval 的时间重叠，避免视觉冲突。',
                'Positioned 必须在 Stack 中才能正确定位，否则会抛出布局异常。',
              ],
            ),
            ExerciseCard(
              task:
                  '为每个文件添加不同的飞入颜色（如 PDF 蓝色、ZIP 橙色、视频红色），在 _buildFlyingItem 中根据 file type 设置不同的 Container 颜色。',
              hint: '在 DownloadItem 中添加 color 字段，或在 _startDownload 时传入文件类型标记。',
            ),
          ],
        ),
        ...downloadItems.map((item) => _buildFlyingItem(item)),
      ],
    );
  }

  Widget _buildSettingsToggle() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.tune,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '下载演示',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                showControlPanel ? Icons.close : Icons.settings,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  showControlPanel = !showControlPanel;
                });
              },
              tooltip: '动画设置',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '动画参数设置',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              label: '持续时间',
              value: animationConfig.animationDuration.toDouble(),
              min: 500,
              max: 3000,
              divisions: 25,
              display: '${animationConfig.animationDuration} 毫秒',
              onChanged: (v) {
                setState(() {
                  animationConfig = animationConfig.copyWith(
                    animationDuration: v.toInt(),
                  );
                });
              },
            ),
            _buildSliderRow(
              label: '偏移量',
              value: animationConfig.flyingItemOffset,
              min: 10,
              max: 50,
              divisions: 40,
              display: animationConfig.flyingItemOffset.toInt().toString(),
              onChanged: (v) {
                setState(() {
                  animationConfig = animationConfig.copyWith(
                    flyingItemOffset: v,
                  );
                });
              },
            ),
            _buildSliderRow(
              label: '内边距',
              value: animationConfig.flyingItemPadding,
              min: 4,
              max: 16,
              divisions: 12,
              display: animationConfig.flyingItemPadding.toInt().toString(),
              onChanged: (v) {
                setState(() {
                  animationConfig = animationConfig.copyWith(
                    flyingItemPadding: v,
                  );
                });
              },
            ),
            _buildSliderRow(
              label: '圆角',
              value: animationConfig.flyingItemRadius,
              min: 4,
              max: 16,
              divisions: 12,
              display: animationConfig.flyingItemRadius.toInt().toString(),
              onChanged: (v) {
                setState(() {
                  animationConfig = animationConfig.copyWith(
                    flyingItemRadius: v,
                  );
                });
              },
            ),
            _buildSliderRow(
              label: '速度',
              value: animationConfig.flyingSpeed,
              min: 0.5,
              max: 3.0,
              divisions: 25,
              display: '${animationConfig.flyingSpeed.toStringAsFixed(1)}x',
              onChanged: (v) {
                setState(() {
                  animationConfig = animationConfig.copyWith(flyingSpeed: v);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const Spacer(),
              Text(
                display,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          SizedBox(
            height: 28,
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
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
      {'name': '技术文档.docx', 'size': '3.8 MB', 'icon': Icons.description},
      {'name': '音频文件.mp3', 'size': '12.4 MB', 'icon': Icons.audiotrack},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            height: 52,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  file['icon'] as IconData,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              title: Text(
                file['name'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                file['size'] as String,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTapDown: (TapDownDetails details) {
                      final itemPosition = details.globalPosition;

                      _startDownload(
                        file['name'] as String,
                        file['size'] as String,
                        itemPosition,
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
                            '下载',
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadArea() {
    return Container(
      key: _downloadAreaKey,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.download_done,
              size: 24,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '下载中心',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '点击文件右侧下载按钮查看飞入效果',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
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
                  width: 24,
                  height: 24,
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
