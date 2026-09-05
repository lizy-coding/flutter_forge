import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:video_player_win/video_player_win.dart';
import 'package:video_player_win/video_player_win_platform_interface.dart';
import 'package:video_player_win/video_player_win_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVideoPlayerWinPlatform
    with MockPlatformInterfaceMixin
    implements VideoPlayerWinPlatform {
  @override
  Future<WinVideoPlayerValue?> openVideo(
    WinVideoPlayerController player,
    int playerId,
    String path,
    Map<String, String> httpHeaders,
  ) {
    throw UnimplementedError();
  }

  @override
  WinVideoPlayerController? getPlayerByTextureId(int textureId) {
    throw UnimplementedError();
  }

  @override
  Future<int> getCurrentPosition(int textureId) {
    throw UnimplementedError();
  }

  @override
  Future<int?> getDuration(int textureId) {
    throw UnimplementedError();
  }

  @override
  Future<void> setVolume(int textureId, double volume) {
    throw UnimplementedError();
  }

  @override
  Future<void> dispose(int textureId) {
    throw UnimplementedError();
  }

  @override
  Future<void> pause(int playerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> play(int playerId) {
    throw UnimplementedError();
  }

  @override
  void registerPlayer(int playerId, WinVideoPlayerController player) {}

  @override
  Future<void> seekTo(int playerId, int ms) {
    throw UnimplementedError();
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double rate) {
    throw UnimplementedError();
  }

  @override
  void unregisterPlayer(int playerId) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('video_player_win'),
        (call) async => null,
      );
  final VideoPlayerWinPlatform initialPlatform =
      VideoPlayerWinPlatform.instance;

  test('$MethodChannelVideoPlayerWin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVideoPlayerWin>());
  });

  test('getPlatformVersion', () async {
    //VideoPlayerWin videoPlayerWinPlugin = VideoPlayerWin();
    MockVideoPlayerWinPlatform fakePlatform = MockVideoPlayerWinPlatform();
    VideoPlayerWinPlatform.instance = fakePlatform;

    //expect(await videoPlayerWinPlugin.getPlatformVersion(), '42');
  });
}
