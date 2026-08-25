import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

const sampleStreamUrl = 'https://media.w3.org/2010/05/sintel/trailer.mp4';

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
    this.initializeTimeout = const Duration(seconds: 15),
    this.reachabilityProbe,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    if (controller != null) {
      _controller = controller;
      _controller!.addListener(_synchronizeState);
    }
  }

  final Duration initializeTimeout;
  final Future<bool> Function(Uri url)? reachabilityProbe;
  final Dio _dio;

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
      return response.statusCode != null && response.statusCode! < 400;
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
    final current = _controller;
    _controller = null;
    await _disposeQuietly(current);
  }

  @override
  Future<void> openAndPlay() async {
    final generation = ++_openGeneration;
    if (_disposed) return;

    uiState.value = PlayerUiState.loading;
    position.value = Duration.zero;
    duration.value = Duration.zero;

    final url = Uri.parse(sampleStreamUrl);
    final probe = reachabilityProbe ?? _defaultReachabilityProbe;
    final reachable = await probe(url);
    if (_disposed || generation != _openGeneration) return;
    if (!reachable) {
      uiState.value = PlayerUiState.error;
      return;
    }

    await _releaseCurrent();

    final controller = VideoPlayerController.networkUrl(url);
    controller.addListener(_synchronizeState);
    _controller = controller;
    try {
      await controller.initialize().timeout(initializeTimeout);
      if (_disposed || generation != _openGeneration) {
        await _disposeQuietly(controller);
        return;
      }
      await controller.play();
    } on Object {
      await _disposeQuietly(controller);
      if (_controller == controller) {
        _controller = null;
      }
      if (!_disposed && generation == _openGeneration) {
        uiState.value = PlayerUiState.error;
      }
    }
  }

  @override
  Future<void> play() {
    final controller = _controller;
    if (controller == null) return Future.value();
    return controller.play();
  }

  @override
  Future<void> pause() {
    final controller = _controller;
    if (controller == null) return Future.value();
    return controller.pause();
  }

  @override
  Future<void> togglePlayPause() {
    final controller = _controller;
    if (controller == null) return Future.value();
    return controller.value.isPlaying ? controller.pause() : controller.play();
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
    unawaited(_releaseCurrent());
    uiState.dispose();
    position.dispose();
    duration.dispose();
    volume.dispose();
    rate.dispose();
  }
}
