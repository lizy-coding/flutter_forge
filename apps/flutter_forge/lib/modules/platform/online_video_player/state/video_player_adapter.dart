import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../../shared/platform/build_features.dart';

const offlineVideoAsset = 'assets/offline/motion-study.mp4';

const sampleStreamUrl = 'https://media.w3.org/2010/05/sintel/trailer.mp4';
const webSampleStreamPath = 'media/flutter-forge-sample.mp4';

Uri get defaultSampleStreamUri =>
    kIsWeb ? Uri.base.resolve(webSampleStreamPath) : Uri.parse(sampleStreamUrl);

enum PlayerUiState { idle, loading, playing, paused, error }

abstract interface class VideoPlayerAdapter {
  ValueNotifier<PlayerUiState> get uiState;
  ValueNotifier<Duration> get position;
  ValueNotifier<Duration> get duration;
  ValueNotifier<double> get volume;
  ValueNotifier<double> get rate;
  VideoPlayerController? get videoController;

  Future<void> openAndPlay();
  Future<void> play();
  Future<void> pause();
  Future<void> togglePlayPause();
  Future<void> seek(Duration value);
  Future<void> setVolume(double value);
  Future<void> setRate(double value);
  void dispose();
}

class VideoPlayerPluginAdapter implements VideoPlayerAdapter {
  VideoPlayerPluginAdapter({
    VideoPlayerController? controller,
    Duration? initializeTimeout,
    this.reachabilityProbe,
    bool? probeBeforeOpen,
    bool? startAutomatically,
    Uri? mediaUri,
    Dio? dio,
    TargetPlatform? targetPlatform,
    this.noFrameTimeout = const Duration(seconds: 10),
    this.noFrameCheckInterval = const Duration(seconds: 1),
    this.loadingTimeout = const Duration(seconds: 25),
  }) : probeBeforeOpen = probeBeforeOpen ?? !kIsWeb,
       startAutomatically = startAutomatically ?? !kIsWeb,
       targetPlatform = targetPlatform ?? defaultTargetPlatform,
       initializeTimeout =
           initializeTimeout ??
           ((targetPlatform ?? defaultTargetPlatform) == TargetPlatform.windows
               ? const Duration(seconds: 12)
               : const Duration(seconds: 15)),
       _dio = dio ?? Dio(),
       _mediaUri = mediaUri {
    if (controller != null) {
      _controller = controller;
      _controller!.addListener(_synchronizeState);
    }
  }

  final Duration initializeTimeout;
  final Future<bool> Function(Uri url)? reachabilityProbe;
  final bool probeBeforeOpen;
  final bool startAutomatically;
  final TargetPlatform targetPlatform;
  final Duration noFrameTimeout;
  final Duration noFrameCheckInterval;
  final Duration loadingTimeout;
  final Dio _dio;
  final Uri? _mediaUri;

  VideoPlayerController? _controller;

  @override
  VideoPlayerController? get videoController => _controller;

  @override
  final ValueNotifier<PlayerUiState> uiState = ValueNotifier(
    PlayerUiState.idle,
  );

  @override
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  @override
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);

  @override
  final ValueNotifier<double> volume = ValueNotifier(1);

  @override
  final ValueNotifier<double> rate = ValueNotifier(1);

  int _openGeneration = 0;
  bool _disposed = false;
  Timer? _noFrameTimer;
  Timer? _loadingWatchdog;

  void _logDiagnostic(String stage, Stopwatch stopwatch, String result) {
    debugPrint(
      '[video-diag] $stage ${stopwatch.elapsedMilliseconds}ms $result',
    );
  }

  void _cancelLoadingWatchdog() {
    _loadingWatchdog?.cancel();
    _loadingWatchdog = null;
  }

  void _startLoadingWatchdog(int generation) {
    _cancelLoadingWatchdog();
    _loadingWatchdog = Timer(loadingTimeout, () {
      if (_disposed ||
          generation != _openGeneration ||
          uiState.value != PlayerUiState.loading) {
        return;
      }
      debugPrint(
        '[video-diag] loading-watchdog '
        '${loadingTimeout.inMilliseconds}ms timeout',
      );
      final controller = _controller;
      _controller = null;
      _openGeneration++;
      unawaited(_disposeQuietly(controller));
      if (!_disposed) uiState.value = PlayerUiState.error;
    });
  }

  Future<bool> _defaultReachabilityProbe(Uri url) async {
    final cancelToken = CancelToken();
    try {
      final response = await _dio
          .get<ResponseBody>(
            url.toString(),
            options: Options(
              headers: const {'Range': 'bytes=0-0'},
              responseType: ResponseType.stream,
              validateStatus: (status) => status != null && status < 400,
            ),
            cancelToken: cancelToken,
          )
          .timeout(const Duration(seconds: 5));
      final responseBody = response.data;
      if (response.statusCode == null ||
          response.statusCode! >= 400 ||
          responseBody == null) {
        return false;
      }
      final bytesRead = await responseBody.stream
          .take(4096)
          .fold<int>(0, (count, chunk) => count + chunk.length)
          .timeout(const Duration(seconds: 3));
      return bytesRead > 0;
    } on Object {
      return false;
    } finally {
      cancelToken.cancel('reachability probe completed');
    }
  }

  Future<void> _disposeQuietly(VideoPlayerController? controller) async {
    if (controller == null) return;
    controller.removeListener(_synchronizeState);
    try {
      await controller.dispose().timeout(const Duration(seconds: 5));
    } on Object catch (e) {
      debugPrint('video_player dispose failed: $e');
    }
  }

  Future<void> _releaseCurrent() async {
    _cancelNoFrameMonitor();
    final current = _controller;
    _controller = null;
    await _disposeQuietly(current);
  }

  void _cancelNoFrameMonitor() {
    _noFrameTimer?.cancel();
    _noFrameTimer = null;
  }

  void _startNoFrameMonitor(VideoPlayerController controller, int generation) {
    _cancelNoFrameMonitor();
    var elapsed = Duration.zero;
    var lastPosition = controller.value.position;
    _noFrameTimer = Timer.periodic(noFrameCheckInterval, (timer) {
      if (_disposed ||
          generation != _openGeneration ||
          _controller != controller) {
        timer.cancel();
        return;
      }
      final value = controller.value;
      if (value.hasError) {
        timer.cancel();
        unawaited(_failNoFrame(controller, generation));
        return;
      }
      if (value.position > lastPosition) {
        timer.cancel();
        _noFrameTimer = null;
        return;
      }
      lastPosition = value.position;
      elapsed += noFrameCheckInterval;
      if (elapsed >= noFrameTimeout) {
        timer.cancel();
        _noFrameTimer = null;
        unawaited(_failNoFrame(controller, generation));
      }
    });
  }

  Future<void> _failNoFrame(
    VideoPlayerController controller,
    int generation,
  ) async {
    if (_disposed ||
        generation != _openGeneration ||
        _controller != controller) {
      return;
    }
    final failureGeneration = ++_openGeneration;
    _controller = null;
    await _disposeQuietly(controller);
    if (!_disposed && failureGeneration == _openGeneration) {
      uiState.value = PlayerUiState.error;
    }
  }

  @override
  Future<void> openAndPlay() async {
    final generation = ++_openGeneration;
    if (_disposed) return;

    uiState.value = PlayerUiState.loading;
    _startLoadingWatchdog(generation);
    position.value = Duration.zero;
    duration.value = Duration.zero;

    final url = _mediaUri ?? defaultSampleStreamUri;
    if (probeBeforeOpen && !offlineEdition) {
      final probe = reachabilityProbe ?? _defaultReachabilityProbe;
      final probeStopwatch = Stopwatch()..start();
      debugPrint('[video-diag] probe-start 0ms started');
      bool reachable;
      try {
        reachable = await probe(url);
        _logDiagnostic(
          'probe-complete',
          probeStopwatch,
          'reachable=$reachable',
        );
      } on Object catch (error) {
        _logDiagnostic('probe-complete', probeStopwatch, 'error=$error');
        reachable = false;
      }
      if (_disposed || generation != _openGeneration) return;
      if (!reachable) {
        _cancelLoadingWatchdog();
        await _releaseCurrent();
        if (!_disposed && generation == _openGeneration) {
          uiState.value = PlayerUiState.error;
        }
        return;
      }
    }

    await _releaseCurrent();
    if (_disposed || generation != _openGeneration) return;

    final controller = offlineEdition
        ? VideoPlayerController.asset(offlineVideoAsset)
        : VideoPlayerController.networkUrl(url);
    controller.addListener(_synchronizeState);
    _controller = controller;
    final initializeStopwatch = Stopwatch()..start();
    debugPrint('[video-diag] initialize-start 0ms started');
    try {
      await controller.initialize().timeout(initializeTimeout);
      _logDiagnostic('initialize-complete', initializeStopwatch, 'success');
      if (_disposed || generation != _openGeneration) {
        await _disposeQuietly(controller);
        if (_controller == controller) _controller = null;
        return;
      }
      _cancelLoadingWatchdog();
      if (startAutomatically) {
        await controller.play();
        if (_disposed || generation != _openGeneration) return;
        _startNoFrameMonitor(controller, generation);
      } else {
        uiState.value = PlayerUiState.paused;
      }
    } on TimeoutException catch (error) {
      _logDiagnostic(
        'initialize-complete',
        initializeStopwatch,
        'timeout=$error',
      );
      await _disposeQuietly(controller);
      if (_controller == controller) {
        _controller = null;
      }
      if (!_disposed && generation == _openGeneration) {
        _cancelLoadingWatchdog();
        uiState.value = PlayerUiState.error;
      }
    } on Object catch (error) {
      _logDiagnostic(
        'initialize-complete',
        initializeStopwatch,
        'error=$error',
      );
      await _disposeQuietly(controller);
      if (_controller == controller) {
        _controller = null;
      }
      if (!_disposed && generation == _openGeneration) {
        _cancelLoadingWatchdog();
        uiState.value = PlayerUiState.error;
      }
    }
  }

  @override
  Future<void> play() async {
    final controller = _controller;
    if (controller == null) return;
    final generation = _openGeneration;
    await controller.play();
    if (_disposed ||
        generation != _openGeneration ||
        _controller != controller) {
      return;
    }
    _startNoFrameMonitor(controller, generation);
  }

  @override
  Future<void> pause() async {
    final controller = _controller;
    if (controller == null) return;
    _cancelNoFrameMonitor();
    await controller.pause();
  }

  @override
  Future<void> togglePlayPause() {
    final controller = _controller;
    if (controller == null) return Future.value();
    return controller.value.isPlaying ? pause() : play();
  }

  @override
  Future<void> seek(Duration value) {
    final controller = _controller;
    if (controller == null) return Future.value();
    return controller.seekTo(value);
  }

  @override
  Future<void> setVolume(double value) async {
    final normalized = value.clamp(0.0, 1.0);
    volume.value = normalized;
    final controller = _controller;
    if (controller == null) return;
    await controller.setVolume(normalized);
  }

  @override
  Future<void> setRate(double value) async {
    rate.value = value;
    final controller = _controller;
    if (controller == null) return;
    await controller.setPlaybackSpeed(value);
  }

  void _synchronizeState() {
    if (_disposed) return;
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    if (value.hasError) {
      _cancelLoadingWatchdog();
      uiState.value = PlayerUiState.error;
      return;
    }
    position.value = value.position;
    duration.value = value.duration;
    volume.value = value.volume;
    rate.value = value.playbackSpeed;
    if (value.isInitialized) {
      uiState.value = value.isPlaying
          ? PlayerUiState.playing
          : PlayerUiState.paused;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _openGeneration++;
    _cancelNoFrameMonitor();
    _cancelLoadingWatchdog();
    unawaited(_releaseCurrent());
    uiState.dispose();
    position.dispose();
    duration.dispose();
    volume.dispose();
    rate.dispose();
  }
}
