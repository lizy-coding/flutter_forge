import 'dart:async';

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
    FilePickerService? filePicker,
    Stream<GcodeLoadSnapshot> Function(GcodeLineReader)? loadSnapshots,
  }) : _filePicker = filePicker ?? createFilePickerService(),
       _loadSnapshots = loadSnapshots ?? _defaultLoadSnapshots {
    _animationController =
        AnimationController(vsync: vsync, duration: const Duration(seconds: 5))
          ..addListener(_onAnimationTick)
          ..addStatusListener(_onAnimationStatusChanged);
  }

  late final AnimationController _animationController;
  final FilePickerService _filePicker;
  final Stream<GcodeLoadSnapshot> Function(GcodeLineReader) _loadSnapshots;
  StreamSubscription<GcodeLoadSnapshot>? _loadSubscription;
  Completer<void>? _loadCompletion;
  bool _disposed = false;
  bool _picking = false;

  static Stream<GcodeLoadSnapshot> _defaultLoadSnapshots(
    GcodeLineReader reader,
  ) {
    final pipeline = GcodeReadlinePipeline(
      options: const GcodeReadlineOptions(
        snapshotBatchSize: 2000,
        previewLimit: 2000,
        minimumSnapshotInterval: Duration(milliseconds: 100),
      ),
    );
    if (reader is FileGcodeLineReader) {
      return pipeline.loadFileInBackground(reader.path);
    }
    if (reader is StringGcodeLineReader) {
      return pipeline.loadStringInBackground(reader.source);
    }
    return pipeline.load(reader);
  }

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
  final ValueNotifier<double> playback = ValueNotifier(0);
  GcodeBounds? bounds;
  bool _previewInstalled = false;
  Map<int, int> _commandIndices = {};
  List<GcodeCommand>? _indexedCommands;

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
    if (_disposed) return;
    _source = value;
    notifyListeners();
  }

  Future<void> parse() {
    return _loadFromReader(StringGcodeLineReader(_source));
  }

  Future<void> loadFilePath(String path) {
    if (_disposed) return Future.value();
    final normalizedPath = FileGcodeLineReader.normalizePath(path);
    if (normalizedPath.isEmpty) {
      ++_parseGeneration;
      _cancelLoad();
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
    if (_disposed || _picking) return null;
    _picking = true;
    final generation = _parseGeneration;
    _loadMessage = '打开文件选择器';
    _addLog(_loadMessage);
    notifyListeners();

    try {
      final pickedFile = await _filePicker.pickFile(
        allowedExtensions: _kGcodeFileExtensions,
        title: '选择 G-code 文件',
        message: '选择用于解析和绘制刀路的 G-code 文件',
      );
      if (_disposed || generation != _parseGeneration) return null;
      final path = pickedFile?.path;
      if (path == null || path.trim().isEmpty) {
        _loadMessage = '已取消选择文件';
        _addLog(_loadMessage);
        notifyListeners();
        return null;
      }

      final load = loadFilePath(path);
      final loadGeneration = _parseGeneration;
      await load;
      if (_disposed || loadGeneration != _parseGeneration) return null;
      return FileGcodeLineReader.normalizePath(path);
    } on PlatformException catch (error) {
      if (_disposed || generation != _parseGeneration) return null;
      _loadStage = GcodeLoadStage.failed;
      _loadMessage = '文件选择失败: ${error.message ?? error.code}';
      _addLog(_loadMessage);
      notifyListeners();
      return null;
    } on MissingPluginException {
      if (_disposed || generation != _parseGeneration) return null;
      _loadStage = GcodeLoadStage.failed;
      _loadMessage = '当前平台未实现文件选择器';
      _addLog(_loadMessage);
      notifyListeners();
      return null;
    } catch (error) {
      if (_disposed || generation != _parseGeneration) return null;
      _loadStage = GcodeLoadStage.failed;
      _loadMessage = '文件选择失败: $error';
      _addLog(_loadMessage);
      notifyListeners();
      return null;
    } finally {
      _picking = false;
    }
  }

  Future<void> _loadFromReader(GcodeLineReader reader) {
    if (_disposed) return Future.value();
    final generation = ++_parseGeneration;
    _cancelLoad();
    _previewInstalled = false;
    _segments = [];
    _parseResult = null;
    _indexedCommands = null;
    _commandIndices.clear();
    bounds = null;
    final completion = _loadCompletion = Completer<void>();
    _currentCommandIndex = -1;
    _progress = 0;
    _isPlaying = false;
    _animationController.stop();
    _animationController.value = 0;
    _loadStage = GcodeLoadStage.reading;
    _linesRead = 0;
    _loadMessage = '开始逐行读取';
    notifyListeners();

    bool isCurrent() => !_disposed && generation == _parseGeneration;
    void fail(Object error) {
      if (!isCurrent()) return;
      _loadStage = GcodeLoadStage.failed;
      _loadMessage = '读取失败: $error';
      _addLog(_loadMessage);
      notifyListeners();
    }

    void finish() {
      if (identical(_loadCompletion, completion)) {
        _loadCompletion = null;
        _loadSubscription = null;
      }
      if (!completion.isCompleted) completion.complete();
    }

    // A listener may synchronously start another load.
    if (!isCurrent()) return completion.future;
    try {
      final subscription = _loadSnapshots(reader).listen(
        (snapshot) {
          if (!isCurrent()) return;
          _loadStage = snapshot.stage;
          _linesRead = snapshot.linesRead;
          if (snapshot.stage != GcodeLoadStage.parsing || !_previewInstalled) {
            _previewInstalled =
                snapshot.stage == GcodeLoadStage.parsing &&
                snapshot.linesRead >= 2000;
            _parseResult = snapshot.toParseResult();
            _segments = snapshot.segments;
            bounds = snapshot.bounds;
            if (!identical(_indexedCommands, snapshot.commands)) {
              _indexedCommands = snapshot.commands;
              _commandIndices = {
                for (var i = 0; i < snapshot.commands.length; i++)
                  snapshot.commands[i].lineNumber: i,
              };
            }
          }
          _loadMessage =
              snapshot.stage == GcodeLoadStage.parsing &&
                  snapshot.linesRead >= 2000
              ? '${snapshot.message}（仅显示前 2000 条预览，完成后显示全部）'
              : snapshot.message;
          if (snapshot.stage == GcodeLoadStage.ready) {
            _addLog(
              '逐行解析完成: ${snapshot.commands.length} 条指令, '
              '${snapshot.errors.length} 个错误, ${snapshot.linesRead} 行',
            );
          } else if (snapshot.stage == GcodeLoadStage.failed) {
            _addLog(snapshot.message);
          }
          notifyListeners();
        },
        onError: (Object error) {
          fail(error);
          if (isCurrent()) _cancelLoad();
          finish();
        },
        onDone: finish,
      );
      if (isCurrent() && !completion.isCompleted) {
        _loadSubscription = subscription;
      } else {
        _releaseSubscription(subscription);
      }
    } catch (error) {
      fail(error);
      finish();
    }
    return completion.future;
  }

  void _cancelLoad() {
    final subscription = _loadSubscription;
    final completion = _loadCompletion;
    _loadSubscription = null;
    _loadCompletion = null;
    if (completion != null && !completion.isCompleted) completion.complete();
    if (subscription != null) _releaseSubscription(subscription);
  }

  void _releaseSubscription(
    StreamSubscription<GcodeLoadSnapshot> subscription,
  ) {
    unawaited(
      subscription.cancel().catchError((Object error) {
        debugPrint('G-code stream cleanup failed: $error');
      }),
    );
  }

  void play() {
    if (_disposed) return;
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
    if (_disposed) return;
    _isPlaying = false;
    _animationController.stop();
    _addLog('暂停播放 (进度: ${(_progress * 100).toStringAsFixed(1)}%)');
    notifyListeners();
  }

  void reset() {
    if (_disposed) return;
    _isPlaying = false;
    _progress = 0;
    _currentCommandIndex = -1;
    _animationController.stop();
    _animationController.value = 0;
    _loadStage = _parseResult == null
        ? GcodeLoadStage.idle
        : GcodeLoadStage.ready;
    _addLog('重置');
    notifyListeners();
  }

  void setSpeed(double value) {
    if (_disposed) return;
    _speedMultiplier = value;
    if (_isPlaying) {
      _animationController.stop();
      play();
    }
    notifyListeners();
  }

  void seek(double value) {
    if (_disposed) return;
    _progress = value.clamp(0.0, 1.0);
    _animationController.value = _progress;
    _updateCurrentCommandIndex();
    notifyListeners();
  }

  void loadSample() {
    if (_disposed) return;
    _source = _kDefaultSample.trim();
    _addLog('加载示例 G-code');
    notifyListeners();
  }

  void _onAnimationTick() {
    if (_disposed) return;
    _progress = _animationController.value;
    _updateCurrentCommandIndex();
    playback.value = _progress;
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (_disposed) return;
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
    final cmdIdx = _commandIndices[cmd.lineNumber] ?? -1;
    _currentCommandIndex = cmdIdx;
  }

  void _addLog(String message) {
    _logs.add(
      '[${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}] $message',
    );
    if (_logs.length > 50) {
      _logs.removeAt(0);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_parseGeneration;
    _cancelLoad();
    _animationController.dispose();
    playback.dispose();
    _previewInstalled = false;
    _segments = [];
    _parseResult = null;
    _indexedCommands = null;
    _commandIndices.clear();
    bounds = null;
    super.dispose();
  }
}
