import 'package:flutter/material.dart';

import '../../../../shared/learning/learning_scaffold.dart';
import '../domain/gcode_load_stage.dart';
import '../state/gcode_player_controller.dart';
import '../widgets/command_timeline.dart';
import '../widgets/gcode_canvas.dart';
import '../widgets/gcode_editor_panel.dart';
import '../widgets/playback_controls.dart';

class GcodeVisualizerPage extends StatefulWidget {
  const GcodeVisualizerPage({super.key});

  @override
  State<GcodeVisualizerPage> createState() => _GcodeVisualizerPageState();
}

class _GcodeVisualizerPageState extends State<GcodeVisualizerPage>
    with TickerProviderStateMixin {
  late final GcodePlayerController _controller;
  final _editorKey = GlobalKey<GcodeEditorPanelState>();

  @override
  void initState() {
    super.initState();
    _controller = GcodePlayerController(vsync: this);
    _controller.parse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onParse() {
    _controller.updateSource(_editorKey.currentState!.text);
    _controller.parse();
  }

  void _onLoadFilePath(String path) {
    _controller.loadFilePath(path);
  }

  Future<String?> _onPickFilePath() {
    return _controller.pickFilePathAndLoad();
  }

  void _onResetSample() {
    _controller.loadSample();
    _editorKey.currentState!.text = _controller.source;
    _controller.parse();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return LearningScaffold(
          title: 'G-code 解析与轨迹动画',
          interactiveDemo: _buildInteractiveDemo(context),
          sections: _buildSections(context),
        );
      },
    );
  }

  Widget _buildInteractiveDemo(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '交互演示',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 320,
                  child: GcodeCanvas(
                    segments: _controller.segments,
                    progress: _controller.progress,
                    errorCount: _controller.errorCount,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRightPanel(context),
              ),
            ],
          )
        else
          Column(
            children: [
              SizedBox(
                height: 280,
                child: GcodeCanvas(
                  segments: _controller.segments,
                  progress: _controller.progress,
                  errorCount: _controller.errorCount,
                ),
              ),
              const SizedBox(height: 12),
              _buildRightPanel(context),
            ],
          ),
      ],
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    return Column(
      children: [
        GcodeEditorPanel(
          key: _editorKey,
          initialText: _controller.source,
          onParse: _onParse,
          onLoadFilePath: _onLoadFilePath,
          onPickFilePath: _onPickFilePath,
          onResetSample: _onResetSample,
          errorCount: _controller.errorCount,
          commandCount: _controller.totalCommands,
          hasParsed: _controller.parseResult != null,
          linesRead: _controller.linesRead,
          loadStageLabel: _loadStageLabel(_controller.loadStage),
          loadMessage: _controller.loadMessage,
        ),
        const SizedBox(height: 8),
        PlaybackControls(
          isPlaying: _controller.isPlaying,
          progress: _controller.progress,
          speedMultiplier: _controller.speedMultiplier,
          onPlay: _controller.play,
          onPause: _controller.pause,
          onReset: _controller.reset,
          onSeek: _controller.seek,
          onSpeedChange: _controller.setSpeed,
        ),
        if (_controller.totalCommands > 0) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: CommandTimeline(
              commands: _controller.parseResult?.commands ?? [],
              errors: _controller.parseResult?.errors ?? [],
              currentIndex: _controller.currentCommandIndex,
              maxHeight: 140,
            ),
          ),
        ],
      ],
    );
  }

  String _loadStageLabel(GcodeLoadStage stage) {
    return switch (stage) {
      GcodeLoadStage.idle => '未读取',
      GcodeLoadStage.reading => '读取中',
      GcodeLoadStage.parsing => '解析中',
      GcodeLoadStage.ready => '可播放',
      GcodeLoadStage.failed => '读取失败',
    };
  }

  List<Widget> _buildSections(BuildContext context) {
    return [
      const LearningObjectives(
        objectives: [
          '理解 G-code 文本如何转换为结构化指令',
          '理解运动指令如何生成可绘制的刀路轨迹段',
          '理解 CustomPaint 如何将机床坐标映射到屏幕坐标',
          '理解 AnimationController 如何随时间逐步揭示路径',
        ],
      ),
      const ConceptChips(
        concepts: [
          'G0 快速移动',
          'G1 线性插补',
          'Parser',
          'Toolpath',
          'CustomPaint',
          'AnimationController',
        ],
      ),
      const CodeSnippetCard(
        title: 'G-code 示例',
        code: '; 注释说明\n'
            'G0 X0 Y0    ; 快速移动到原点\n'
            'G1 X80 Y0 F1200  ; 以 F1200 进给率线性移动到 (80, 0)\n'
            'G1 X80 Y50       ; 继续移动到 (80, 50)\n'
            'G0 X0 Y0    ; 快速返回原点',
        explanation: 'G0 为快速定位（不切削），G1 为线性插补（切削进给）',
      ),
      StateLogView(
        logs: _controller.logs,
        maxLines: 6,
      ),
      const CommonPitfalls(
        pitfalls: [
          '不支持的 G-code 应明显报错，而不是静默绘制错误轨迹',
          '屏幕 Y 轴向下，机床坐标映射必须显式处理方向',
          '解析逻辑必须独立于 Flutter Widget，保持纯 Dart 可测试',
          '动画进度不应修改已解析的几何数据',
          '大文件不应在每帧都重新解析',
        ],
      ),
      const ExerciseCard(
        task: '修改示例 G-code 绘制一个矩形，然后添加一个 G0 移动，对比快速/线性轨迹的颜色差异。',
        hint: '矩形: G1 X80 Y0 -> G1 X80 Y50 -> G1 X0 Y50 -> G1 X0 Y0',
      ),
    ];
  }
}
