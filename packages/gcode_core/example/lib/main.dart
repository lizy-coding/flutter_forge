import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:gcode_core/gcode_core.dart';

void main() {
  runApp(const GcodeCoreExampleApp());
}

class GcodeCoreExampleApp extends StatelessWidget {
  const GcodeCoreExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'G-code Core Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2563eb)),
        useMaterial3: true,
      ),
      home: const GcodeExamplePage(),
    );
  }
}

class GcodeExamplePage extends StatefulWidget {
  const GcodeExamplePage({super.key});

  @override
  State<GcodeExamplePage> createState() => _GcodeExamplePageState();
}

class _GcodeExamplePageState extends State<GcodeExamplePage> {
  static const _sampleSource = '''
G0 X0 Y0
G1 X30 Y0 F1200
G1 X30 Y18
G1 X12 Y18
G0 X6 Y8
G1 X22 Y8
G2 X40 Y40
''';

  final _pipeline = GcodeReadlinePipeline(
    options: const GcodeReadlineOptions(snapshotBatchSize: 1),
  );

  GcodeLoadSnapshot? _snapshot;
  String _sourceName = '未选择文件';
  String _status = '请选择本地 G-code 文件，或加载内置示例。';
  bool _loading = false;
  bool _isPlaying = false;
  double _playbackProgress = 1;
  double _speedMultiplier = 1;
  Timer? _playbackTimer;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickAndParseFile() async {
    const typeGroup = XTypeGroup(
      label: 'G-code',
      extensions: ['gcode', 'nc', 'tap', 'txt'],
    );

    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    await _parseReader(FileGcodeLineReader(file.path), sourceName: file.name);
  }

  Future<void> _loadSample() {
    return _parseReader(
      const StringGcodeLineReader(_sampleSource),
      sourceName: '内置示例',
    );
  }

  Future<void> _parseReader(
    GcodeLineReader reader, {
    required String sourceName,
  }) async {
    _playbackTimer?.cancel();
    setState(() {
      _loading = true;
      _isPlaying = false;
      _playbackProgress = 1;
      _sourceName = sourceName;
      _snapshot = null;
      _status = '正在读取 $sourceName';
    });

    await for (final snapshot in _pipeline.load(reader)) {
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _status = snapshot.message;
        _playbackProgress = 1;
      });
      if (snapshot.stage == GcodeLoadStage.parsing) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _play() {
    if ((_snapshot?.segments.isEmpty ?? true) || _loading) return;

    _playbackTimer?.cancel();
    setState(() => _isPlaying = true);
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      final next = _playbackProgress + 0.004 * _speedMultiplier;
      setState(() {
        _playbackProgress = next.clamp(0, 1);
        _isPlaying = _playbackProgress < 1;
      });
      if (_playbackProgress >= 1) {
        _playbackTimer?.cancel();
      }
    });
  }

  void _pause() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _resetPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _playbackProgress = 0;
    });
  }

  void _seekPlayback(double value) {
    setState(() => _playbackProgress = value);
  }

  void _setSpeed(double value) {
    setState(() => _speedMultiplier = value);
  }

  int _currentCommandIndex(GcodeLoadSnapshot? snapshot) {
    final commandCount = snapshot?.commands.length ?? 0;
    if (commandCount == 0) return -1;
    return (_playbackProgress * commandCount).ceil().clamp(1, commandCount) - 1;
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('G-code Core 绘制示例'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _loadSample,
            icon: const Icon(Icons.data_object),
            label: const Text('示例数据'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _loading ? null : _pickAndParseFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('选择 G-code'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusBar(
              sourceName: _sourceName,
              status: _status,
              loading: _loading,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: _CanvasPanel(
                      snapshot: snapshot,
                      parsing: _loading,
                      progress: _playbackProgress,
                      isPlaying: _isPlaying,
                      speedMultiplier: _speedMultiplier,
                      onPlay: _play,
                      onPause: _pause,
                      onReset: _resetPlayback,
                      onSeek: _seekPlayback,
                      onSpeedChange: _setSpeed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 360,
                    child: _ResultPanel(
                      snapshot: snapshot,
                      currentIndex: _currentCommandIndex(snapshot),
                      onCommandTap: (index) {
                        final total = snapshot?.commands.length ?? 0;
                        if (total == 0) return;
                        _pause();
                        setState(() => _playbackProgress = (index + 1) / total);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.sourceName,
    required this.status,
    required this.loading,
  });

  final String sourceName;
  final String status;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.route),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$sourceName - $status',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasPanel extends StatelessWidget {
  const _CanvasPanel({
    required this.snapshot,
    required this.parsing,
    required this.progress,
    required this.isPlaying,
    required this.speedMultiplier,
    required this.onPlay,
    required this.onPause,
    required this.onReset,
    required this.onSeek,
    required this.onSpeedChange,
  });

  final GcodeLoadSnapshot? snapshot;
  final bool parsing;
  final double progress;
  final bool isPlaying;
  final double speedMultiplier;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSpeedChange;

  @override
  Widget build(BuildContext context) {
    final segments = snapshot?.segments ?? const <ToolpathSegment>[];
    final errors = snapshot?.errors.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: GcodeCanvas(
                  segments: segments,
                  progress: parsing ? 1 : progress,
                  errorCount: errors,
                  bounds: snapshot?.bounds,
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: _CanvasLegend(
                  parsing: parsing,
                  segments: segments.length,
                  mainSegments: segments
                      .where(
                        (segment) => segment.type == GcodeSegmentType.linear,
                      )
                      .length,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PlaybackControls(
          isPlaying: isPlaying,
          progress: parsing ? 1 : progress,
          speedMultiplier: speedMultiplier,
          onPlay: onPlay,
          onPause: onPause,
          onReset: onReset,
          onSeek: onSeek,
          onSpeedChange: onSpeedChange,
        ),
      ],
    );
  }
}

class _CanvasLegend extends StatelessWidget {
  const _CanvasLegend({
    required this.parsing,
    required this.segments,
    required this.mainSegments,
  });

  final bool parsing;
  final int segments;
  final int mainSegments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: DefaultTextStyle(
          style: theme.textTheme.labelMedium!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(parsing ? '动态解析绘制中' : 'GcodeCanvas 绘制'),
              const SizedBox(height: 4),
              Text('主线段 G1: $mainSegments'),
              Text('移动段 G0/G1: $segments'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.snapshot,
    required this.currentIndex,
    required this.onCommandTap,
  });

  final GcodeLoadSnapshot? snapshot;
  final int currentIndex;
  final ValueChanged<int> onCommandTap;

  @override
  Widget build(BuildContext context) {
    final current = snapshot;

    if (current == null) {
      return const Center(child: Text('解析结果会显示在这里'));
    }

    return ListView(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Metric(label: '行数', value: current.linesRead.toString()),
            _Metric(label: '指令', value: current.commands.length.toString()),
            _Metric(label: '轨迹', value: current.segments.length.toString()),
            _Metric(label: '错误', value: current.errors.length.toString()),
          ],
        ),
        const SizedBox(height: 16),
        CommandTimeline(
          commands: current.commands,
          errors: current.errors,
          currentIndex: currentIndex,
          onTap: onCommandTap,
          maxHeight: 360,
        ),
        const SizedBox(height: 16),
        Text('解析错误', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (current.errors.isEmpty)
          const Text('无')
        else
          for (final error in current.errors)
            ListTile(
              dense: true,
              leading: const Icon(Icons.warning_amber),
              title: Text('第 ${error.lineNumber} 行'),
              subtitle: Text('${error.message}\n${error.rawLine}'),
            ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
