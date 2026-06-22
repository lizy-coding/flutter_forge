import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker_bridge/file_picker_bridge.dart';
import 'package:gcode_core/gcode_core.dart';

const _kDefaultSample = '''
; Flutter G-code visualizer sample
G0 X0 Y0
G1 X80 Y0 F1200
G1 X80 Y50
G1 X20 Y50
G1 X20 Y20
G1 X60 Y20
G0 X0 Y0
''';

const _kGcodeFileExtensions = [
  'gcode',
  'gco',
  'nc',
  'ngc',
  'tap',
  'cnc',
  'txt',
];

class GcodePlayerController extends ChangeNotifier {
  GcodePlayerController({
    required TickerProvider vsync,
    FilePickerService filePicker = const MethodChannelFilePicker(),
  }) : _filePicker = filePicker {
    _animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 5),
    )
      ..addListener(_onAnimationTick)
      ..addStatusListener(_onAnimationStatusChanged);
  }

  late final AnimationController _animationController;
  final FilePickerService _filePicker;
  final _readlinePipeline = GcodeReadlinePipeline();

  String _source = _kDefaultSample.trim();
  GcodeParseResult? _parseResult;
  List<ToolpathSegment> _segments = [];
  int _currentCommandIndex = -1;
  bool _isPlaying = false;
  GcodeLoadStage _loadStage = GcodeLoadStage.idle;
  double _progress = 0;
  double _speedMultiplier = 1.0;
  int _linesRead = 0;
  int _parseGeneration = 0;
  String _loadMessage = '';
  final List<String> _logs = [];

  String get source => _source;
  GcodeParseResult? get parseResult => _parseResult;
  List<ToolpathSegment> get segments => _segments;
  int get currentCommandIndex => _currentCommandIndex;
  bool get isPlaying => _isPlaying;
  GcodeLoadStage get loadStage => _loadStage;
  double get progress => _progress;
  double get speedMultiplier => _speedMultiplier;
  int get linesRead => _linesRead;
  String get loadMessage => _loadMessage;
  List<String> get logs => List.unmodifiable(_logs);

  int get totalCommands => _parseResult?.commands.length ?? 0;
  int get errorCount => _parseResult?.errors.length ?? 0;

  ToolpathSegment? get currentSegment {
    if (_segments.isEmpty) return null;
    final totalSegments = _segments.length;
    final idx = (_progress * totalSegments).floor().clamp(0, totalSegments - 1);
    return _segments[idx];
  }

  double get currentSegmentProgress {
    if (_segments.isEmpty) return 0;
    final totalSegments = _segments.length;
    final currentSegFloat = _progress * totalSegments;
    final currentSegIndex = currentSegFloat.floor().clamp(0, totalSegments - 1);
    return (currentSegFloat - currentSegIndex).clamp(0.0, 1.0);
  }

  void updateSource(String value) {
    _source = value;
    notifyListeners();
  }

  Future<void> parse() {
    return _loadFromReader(StringGcodeLineReader(_source));
  }

  Future<void> loadFilePath(String path) {
    final normalizedPath = FileGcodeLineReader.normalizePath(path);
    if (normalizedPath.isEmpty) {
      _loadStage = GcodeLoadStage.failed;
      _loadMessage = '文件路径为空';
      _addLog(_loadMessage);
      notifyListeners();
      return Future.value();
    }
    _loadMessage = '准备读取: $normalizedPath';
    _addLog(_loadMessage);
    return _loadFromReader(FileGcodeLineReader(normalizedPath));
  }

  Future<String?> pickFilePathAndLoad() async {
    _loadMessage = '打开文件选择器';
    _addLog(_loadMessage);
    notifyListeners();

    try {
      final pickedFile = await _filePicker.pickFile(
        allowedExtensions: _kGcodeFileExtensions,
        title: '选择 G-code 文件',
        message: '选择用于解析和绘制刀路的 G-code 文件',
      );
      final path = pickedFile?.path;
      if (path == null || path.trim().isEmpty) {
        _loadMessage = '已取消选择文件';
        _addLog(_loadMessage);
        notifyListeners();
        return null;
      }

      await loadFilePath(path);
      return FileGcodeLineReader.normalizePath(path);
    } on PlatformException catch (error) {
      _loadStage = GcodeLoadStage.failed;
      _loadMessage = '文件选择失败: ${error.message ?? error.code}';
      _addLog(_loadMessage);
      notifyListeners();
      return null;
    } on MissingPluginException {
      _loadStage = GcodeLoadStage.failed;
      _loadMessage = '当前平台未实现文件选择器';
      _addLog(_loadMessage);
      notifyListeners();
      return null;
    }
  }

  Future<void> _loadFromReader(GcodeLineReader reader) async {
    final generation = ++_parseGeneration;
    _currentCommandIndex = -1;
    _progress = 0;
    _isPlaying = false;
    _animationController.stop();
    _animationController.value = 0;
    _loadStage = GcodeLoadStage.reading;
    _linesRead = 0;
    _loadMessage = '开始逐行读取';
    notifyListeners();

    await for (final snapshot in _readlinePipeline.load(reader)) {
      if (generation != _parseGeneration) return;

      _loadStage = snapshot.stage;
      _linesRead = snapshot.linesRead;
      _parseResult = snapshot.toParseResult();
      _segments = snapshot.segments;
      _loadMessage = snapshot.message;

      if (snapshot.stage == GcodeLoadStage.ready) {
        _addLog(
          '逐行解析完成: ${snapshot.commands.length} 条指令, '
          '${snapshot.errors.length} 个错误, ${snapshot.linesRead} 行',
        );
      } else if (snapshot.stage == GcodeLoadStage.failed) {
        _addLog(snapshot.message);
      }

      notifyListeners();
    }
  }

  void play() {
    if (_segments.isEmpty) return;
    if (_progress >= 1.0) {
      _progress = 0;
      _animationController.value = 0;
    }
    _isPlaying = true;
    _animationController.duration = Duration(
      milliseconds: (5000 / _speedMultiplier).round(),
    );
    _animationController.forward(from: _progress);
    _addLog('开始播放');
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    _animationController.stop();
    _addLog('暂停播放 (进度: ${(_progress * 100).toStringAsFixed(1)}%)');
    notifyListeners();
  }

  void reset() {
    _isPlaying = false;
    _progress = 0;
    _currentCommandIndex = -1;
    _animationController.stop();
    _animationController.value = 0;
    _loadStage =
        _parseResult == null ? GcodeLoadStage.idle : GcodeLoadStage.ready;
    _addLog('重置');
    notifyListeners();
  }

  void setSpeed(double value) {
    _speedMultiplier = value;
    if (_isPlaying) {
      _animationController.stop();
      play();
    }
    notifyListeners();
  }

  void seek(double value) {
    _progress = value.clamp(0.0, 1.0);
    _animationController.value = _progress;
    _updateCurrentCommandIndex();
    notifyListeners();
  }

  void loadSample() {
    _source = _kDefaultSample.trim();
    _addLog('加载示例 G-code');
    notifyListeners();
  }

  void _onAnimationTick() {
    _progress = _animationController.value;
    _updateCurrentCommandIndex();
    notifyListeners();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _isPlaying = false;
    _progress = 1.0;
    _updateCurrentCommandIndex();
    _addLog('播放完成');
    notifyListeners();
  }

  void _updateCurrentCommandIndex() {
    if (_segments.isEmpty) {
      _currentCommandIndex = -1;
      return;
    }
    final totalSegments = _segments.length;
    final idx = (_progress * totalSegments).floor().clamp(0, totalSegments - 1);
    final cmd = _segments[idx].command;
    final cmdIdx = _parseResult?.commands.indexWhere(
          (c) => c.lineNumber == cmd.lineNumber,
        ) ??
        -1;
    _currentCommandIndex = cmdIdx;
  }

  void _addLog(String message) {
    _logs.add(
        '[${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}] $message');
    if (_logs.length > 50) {
      _logs.removeAt(0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
