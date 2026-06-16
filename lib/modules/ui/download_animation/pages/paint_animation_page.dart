import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

import '../models/animation_config.dart';

/// Paint 绘制动画页面
class PaintAnimationPage extends StatefulWidget {
  final AnimationConfig? animationConfig;

  const PaintAnimationPage({super.key, this.animationConfig});

  @override
  State<PaintAnimationPage> createState() => _PaintAnimationPageState();
}

class _PaintAnimationPageState extends State<PaintAnimationPage>
    with TickerProviderStateMixin {
  final List<FlyingPaintItem> _flyingItems = [];

  final GlobalKey _downloadAreaKey = GlobalKey();
  Offset? _downloadAreaPosition;

  late AnimationConfig animationConfig;
  bool showControlPanel = false;

  @override
  void initState() {
    super.initState();
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
        _downloadAreaPosition = position +
            Offset(renderBox.size.width / 2, renderBox.size.height / 2);
      });
    }
  }

  void _startDownload(String fileName, String fileSize, Offset startPosition) {
    if (_downloadAreaPosition == null) {
      debugPrint('下载区域位置未初始化');
      return;
    }

    debugPrint(
        '开始下载动画: $fileName, 起点: $startPosition, 终点: $_downloadAreaPosition');

    final controller = AnimationController(
      duration: Duration(
          milliseconds:
              (animationConfig.animationDuration / animationConfig.flyingSpeed)
                  .round()),
      vsync: this,
    );

    final item = FlyingPaintItem(
      fileName: fileName,
      fileSize: fileSize,
      startPosition: startPosition,
      endPosition: _downloadAreaPosition!,
      controller: controller,
    );

    setState(() {
      _flyingItems.add(item);
    });

    controller.addListener(() {
      setState(() {});
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _flyingItems.remove(item);
        });
        controller.dispose();

        HapticFeedback.lightImpact();
        _showDownloadComplete(fileName);
      }
    });

    controller.forward();
  }

  void _showDownloadComplete(String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fileName 下载完成'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    for (var item in _flyingItems) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LearningScaffold(
          title: 'Paint 绘制动画',
          interactiveDemo: SizedBox(
            height: 460,
            child: Column(
              children: [
                if (showControlPanel) _buildControlPanel(),
                Flexible(child: _buildFileList()),
                _buildDownloadArea(),
              ],
            ),
          ),
          sections: const [
            LearningObjectives(
              objectives: [
                '掌握 CustomPainter 实现动画的方法——在 paint 中根据动画进度计算绘制位置',
                '理解 Canvas 绘制坐标系变换（translate / scale / rotate）',
                '掌握贝塞尔曲线轨迹与尾迹效果的绘制技巧',
              ],
            ),
            ConceptChips(
              concepts: [
                'CustomPaint',
                'CustomPainter',
                'Canvas',
                'Path',
                'MaskFilter',
                '贝塞尔曲线'
              ],
            ),
            CodeSnippetCard(
              title: 'CustomPainter 动画核心',
              code: '''// 在 CustomPainter.paint() 中驱动动画
class FlyingPainter extends CustomPainter {
  final List<FlyingItem> items;
  final AnimationConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    for (var item in items) {
      final progress = item.controller.value;
      final pos = _calculatePosition(item, progress);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.scale(_calculateScale(progress));
      // 绘制图形...
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(FlyingPainter old) => true;
}''',
              explanation:
                  '动画每帧触发 setState → parent rebuild → CustomPaint repaint，在 paint 中根据 AnimationController.value 实时计算绘制位置。',
            ),
            CommonPitfalls(
              pitfalls: [
                'CustomPainter.shouldRepaint 应返回 true 以确保持续驱动画帧重绘',
                'Canvas 绘制的坐标变换需要 save/restore 配对使用，否则会影响后续绘制',
                'MaskFilter 性能开销较大，不宜在循环中创建过多实例',
                '尾迹绘制涉及历史帧计算，注意性能优化',
              ],
            ),
            ExerciseCard(
              task:
                  '尝试调整动画参数（持续时间、飞入点大小、速度），观察 CustomPainter 绘制的飞入轨迹与尾迹效果的变化。对比与 Stack+Positioned 方式的视觉差异。',
              hint: 'CustomPainter 可以绘制更复杂的图形效果（渐变、光晕、尾迹），不受 Widget 层级限制。',
            ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: FlyingAnimationPainter(
                items: _flyingItems,
                animationConfig: animationConfig,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('飞入点大小: ${animationConfig.flyingItemOffset.toInt()}'),
                Slider(
                  value: animationConfig.flyingItemOffset,
                  min: 10,
                  max: 50,
                  divisions: 40,
                  onChanged: (value) {
                    setState(() {
                      animationConfig = animationConfig.copyWith(
                        flyingItemOffset: value,
                      );
                    });
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '飞入速度: ${animationConfig.flyingSpeed.toStringAsFixed(1)}x'),
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
        'color': Colors.red
      },
      {
        'name': '项目源码.zip',
        'size': '89.5 MB',
        'icon': Icons.folder_zip,
        'color': Colors.orange
      },
      {
        'name': '设计稿.psd',
        'size': '234.7 MB',
        'icon': Icons.image,
        'color': Colors.purple
      },
      {
        'name': '演示视频.mp4',
        'size': '156.3 MB',
        'icon': Icons.video_file,
        'color': Colors.blue
      },
      {
        'name': '技术文档.docx',
        'size': '3.8 MB',
        'icon': Icons.description,
        'color': Colors.green
      },
      {
        'name': '音频文件.mp3',
        'size': '12.4 MB',
        'icon': Icons.audiotrack,
        'color': Colors.pink
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final color = file['color'] as Color;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(file['icon'] as IconData, color: color, size: 28),
            ),
            title: Text(
              file['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              file['size'] as String,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.8), color],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTapDown: (TapDownDetails details) {
                    final itemPosition = details.globalPosition;
                    _startDownload(
                      file['name'] as String,
                      file['size'] as String,
                      itemPosition,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('下载',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      ],
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
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
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.download_done,
                size: 40, color: Colors.blue.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            '下载中心',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            '点击文件右侧下载按钮查看 Paint 动画效果',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// 飞行动画项数据模型
class FlyingPaintItem {
  final String fileName;
  final String fileSize;
  final Offset startPosition;
  final Offset endPosition;
  final AnimationController controller;

  FlyingPaintItem({
    required this.fileName,
    required this.fileSize,
    required this.startPosition,
    required this.endPosition,
    required this.controller,
  });

  void dispose() {
    controller.dispose();
  }
}

/// 自定义 Painter 绘制飞行动画
class FlyingAnimationPainter extends CustomPainter {
  final List<FlyingPaintItem> items;
  final AnimationConfig animationConfig;

  FlyingAnimationPainter({
    required this.items,
    required this.animationConfig,
  });

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('CustomPaint paint 被调用，items 数量: ${items.length}');
    for (var item in items) {
      _drawFlyingItem(canvas, item);
    }
  }

  void _drawFlyingItem(Canvas canvas, FlyingPaintItem item) {
    final progress = item.controller.value;

    final curveProgress = Curves.easeInOut.transform(progress);

    final dx = item.startPosition.dx +
        (item.endPosition.dx - item.startPosition.dx) * curveProgress;
    final dy = item.startPosition.dy +
        (item.endPosition.dy - item.startPosition.dy) * curveProgress;

    final controlPointOffset = -100.0 * math.sin(math.pi * curveProgress);
    final currentPosition = Offset(dx, dy + controlPointOffset);

    final scale = progress < 0.7 ? 1.2 : 1.2 - (progress - 0.7) / 0.3 * 1.0;

    final opacity = progress < 0.8 ? 1.0 : 1.0 - (progress - 0.8) / 0.2;

    if (opacity <= 0) return;

    canvas.save();
    canvas.translate(currentPosition.dx, currentPosition.dy);
    canvas.scale(math.max(0.1, scale));

    _drawGlow(canvas, opacity);
    _drawMainCircle(canvas, opacity);
    _drawIcon(canvas, opacity);
    _drawTrail(canvas, item, progress, opacity);

    canvas.restore();
  }

  void _drawGlow(Canvas canvas, double opacity) {
    final glowPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(Offset.zero, 40, glowPaint);

    glowPaint.color = Colors.blue.withValues(alpha: 0.2 * opacity);
    glowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, 30, glowPaint);
  }

  void _drawMainCircle(Canvas canvas, double opacity) {
    const rect = Rect.fromLTRB(-25, -25, 25, 25);
    final gradient = RadialGradient(
      colors: [
        Colors.blue.shade400.withValues(alpha: opacity),
        Colors.blue.shade700.withValues(alpha: opacity),
      ],
    );

    final circlePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, 25, circlePaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset.zero, 25, borderPaint);
  }

  void _drawIcon(Canvas canvas, double opacity) {
    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, -10);
    path.lineTo(0, 10);
    path.moveTo(-8, 3);
    path.lineTo(0, 10);
    path.lineTo(8, 3);

    path.moveTo(-10, 15);
    path.lineTo(10, 15);

    canvas.drawPath(path, iconPaint);
  }

  void _drawTrail(
      Canvas canvas, FlyingPaintItem item, double progress, double opacity) {
    if (progress < 0.1) return;

    final trailPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (int i = 1; i <= 5; i++) {
      final trailProgress = math.max(0.0, progress - i * 0.02);
      if (trailProgress <= 0) break;

      final curveTProgress = Curves.easeInOut.transform(trailProgress);
      final trailDx = item.startPosition.dx +
          (item.endPosition.dx - item.startPosition.dx) * curveTProgress;
      final trailDy = item.startPosition.dy +
          (item.endPosition.dy - item.startPosition.dy) * curveTProgress;
      final trailControlOffset = -100.0 * math.sin(math.pi * curveTProgress);
      final trailPosition = Offset(
        trailDx -
            item.startPosition.dx -
            (item.endPosition.dx - item.startPosition.dx) *
                Curves.easeInOut.transform(progress),
        trailDy +
            trailControlOffset -
            item.startPosition.dy -
            (item.endPosition.dy - item.startPosition.dy) *
                Curves.easeInOut.transform(progress) -
            (-100.0 * math.sin(math.pi * Curves.easeInOut.transform(progress))),
      );

      final trailOpacity = opacity * (1.0 - i / 5.0) * 0.5;
      final trailSize = 20.0 * (1.0 - i / 5.0);

      trailPaint.color = Colors.blue.shade300.withValues(alpha: trailOpacity);
      canvas.drawCircle(trailPosition, trailSize, trailPaint);
    }
  }

  @override
  bool shouldRepaint(FlyingAnimationPainter oldDelegate) {
    return true;
  }
}
