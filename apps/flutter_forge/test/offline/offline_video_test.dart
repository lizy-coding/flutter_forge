import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_forge_app/modules/platform/online_video_player/state/video_player_adapter.dart';
import 'package:flutter_forge_app/shared/platform/build_features.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class AssetVideoPlatform extends VideoPlayerPlatform {
  DataSource? opened;
  @override
  Future<void> init() async {}
  @override
  Future<int> create(DataSource dataSource) async {
    opened = dataSource;
    return 0;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 8),
      size: const Size(640, 360),
    ),
  );
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'offline playback opens an installed asset and never probes a URL',
    () async {
      final original = VideoPlayerPlatform.instance;
      final platform = AssetVideoPlatform();
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = original);
      final adapter = VideoPlayerPluginAdapter(
        reachabilityProbe: (_) =>
            throw StateError('No network probe permitted'),
        startAutomatically: false,
      );
      await adapter.openAndPlay();
      expect(platform.opened!.sourceType, DataSourceType.asset);
      expect(platform.opened!.asset, offlineVideoAsset);
      expect(adapter.uiState.value, PlayerUiState.paused);
      adapter.dispose();
    },
    skip: !offlineEdition ? 'Requires offline edition' : false,
  );
}
