import 'dart:async';

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
  VideoPlayerPluginAdapter({VideoPlayerController? controller})
    : videoController =
          controller ??
          VideoPlayerController.networkUrl(Uri.parse(sampleStreamUrl)) {
    videoController.addListener(_synchronizeState);
  }

  @override
  final VideoPlayerController videoController;

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

  @override
  Future<void> openAndPlay() async {
    uiState.value = PlayerUiState.loading;
    position.value = Duration.zero;
    try {
      await videoController.initialize();
      await videoController.play();
    } on Object {
      uiState.value = PlayerUiState.error;
    }
  }

  @override
  Future<void> play() => videoController.play();

  @override
  Future<void> pause() => videoController.pause();

  @override
  Future<void> togglePlayPause() =>
      videoController.value.isPlaying ? pause() : play();

  @override
  Future<void> seek(Duration value) => videoController.seekTo(value);

  @override
  Future<void> setVolume(double value) async {
    final normalized = value.clamp(0.0, 1.0);
    volume.value = normalized;
    await videoController.setVolume(normalized);
  }

  @override
  Future<void> setRate(double value) async {
    rate.value = value;
    await videoController.setPlaybackSpeed(value);
  }

  void _synchronizeState() {
    final value = videoController.value;
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
    videoController.removeListener(_synchronizeState);
    unawaited(videoController.dispose());
    uiState.dispose();
    position.dispose();
    duration.dispose();
    volume.dispose();
    rate.dispose();
  }
}
