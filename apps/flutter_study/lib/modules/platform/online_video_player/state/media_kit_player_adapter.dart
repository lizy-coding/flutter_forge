import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

const sampleStreamUrl = 'https://media.w3.org/2010/05/sintel/trailer.mp4';

enum PlayerUiState { idle, loading, playing, paused, error }

abstract interface class VideoPlayerAdapter {
  ValueNotifier<PlayerUiState> get uiState;
  ValueNotifier<Duration> get position;
  ValueNotifier<Duration> get duration;
  ValueNotifier<double> get volume;
  ValueNotifier<double> get rate;
  VideoController? get videoController;

  Future<void> openAndPlay();
  Future<void> play();
  Future<void> pause();
  Future<void> togglePlayPause();
  Future<void> seek(Duration value);
  Future<void> setVolume(double value);
  Future<void> setRate(double value);
  void dispose();
}

class MediaKitPlayerAdapter implements VideoPlayerAdapter {
  MediaKitPlayerAdapter({Player? player}) : _player = player ?? Player() {
    videoController = VideoController(_player);
    _subscriptions.addAll([
      _player.stream.position.listen((value) => position.value = value),
      _player.stream.duration.listen((value) => duration.value = value),
      _player.stream.playing.listen((isPlaying) {
        if (uiState.value == PlayerUiState.loading ||
            uiState.value == PlayerUiState.error) {
          if (!isPlaying) return;
        }
        uiState.value = isPlaying
            ? PlayerUiState.playing
            : PlayerUiState.paused;
      }),
      _player.stream.error.listen((_) => uiState.value = PlayerUiState.error),
    ]);
  }

  final Player _player;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  late final VideoController videoController;

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
      await _player.open(Media(sampleStreamUrl), play: true);
    } on Object {
      uiState.value = PlayerUiState.error;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> togglePlayPause() => _player.playOrPause();

  @override
  Future<void> seek(Duration value) => _player.seek(value);

  @override
  Future<void> setVolume(double value) async {
    final normalized = value.clamp(0.0, 1.0);
    volume.value = normalized;
    await _player.setVolume(normalized * 100);
  }

  @override
  Future<void> setRate(double value) async {
    rate.value = value;
    await _player.setRate(value);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    uiState.dispose();
    position.dispose();
    duration.dispose();
    volume.dispose();
    rate.dispose();
  }
}
