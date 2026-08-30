import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/platform/online_video_player/state/video_player_adapter.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeVideoPlayerPlatform platform;

  setUp(() {
    platform = _FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = platform;
  });

  tearDown(() {
    VideoPlayerPlatform.instance = _RestoringVideoPlayerPlatform();
  });

  test('probe failure reaches error without creating any controller', () async {
    final adapter = VideoPlayerPluginAdapter(
      reachabilityProbe: (_) async => false,
      initializeTimeout: const Duration(milliseconds: 100),
    );

    await adapter.openAndPlay();

    expect(adapter.uiState.value, PlayerUiState.error);
    expect(adapter.videoController, isNull);
    expect(platform.createdIds, isEmpty);
    expect(platform.disposedIds, isEmpty);
    adapter.dispose();
  });

  test(
    'default probe uses a ranged GET compatible with media servers',
    () async {
      final httpAdapter = _RecordingHttpClientAdapter();
      final dio = Dio()..httpClientAdapter = httpAdapter;
      final adapter = VideoPlayerPluginAdapter(
        dio: dio,
        initializeTimeout: const Duration(seconds: 1),
      );

      await adapter.openAndPlay();

      expect(httpAdapter.method, 'GET');
      expect(httpAdapter.range, 'bytes=0-0');
      expect(adapter.uiState.value, PlayerUiState.playing);
      adapter.dispose();
    },
  );

  test('default probe rejects an unreadable response stream', () async {
    final httpAdapter = _RecordingHttpClientAdapter(streamError: true);
    final dio = Dio()..httpClientAdapter = httpAdapter;
    final adapter = VideoPlayerPluginAdapter(dio: dio);

    await adapter.openAndPlay();

    expect(adapter.uiState.value, PlayerUiState.error);
    expect(platform.createdIds, isEmpty);
    adapter.dispose();
  });

  test(
    'no-frame monitor disposes the controller and enters error state',
    () async {
      final adapter = VideoPlayerPluginAdapter(
        reachabilityProbe: (_) async => true,
        noFrameTimeout: const Duration(milliseconds: 40),
        noFrameCheckInterval: const Duration(milliseconds: 10),
      );

      await adapter.openAndPlay();
      await _waitUntil(
        () => adapter.uiState.value == PlayerUiState.error,
        timeout: const Duration(seconds: 1),
      );

      expect(adapter.videoController, isNull);
      expect(platform.disposedIds, isNotEmpty);
      adapter.dispose();
    },
  );

  test('global loading watchdog releases a stalled initialization', () async {
    platform.haltInitializedEvents = true;
    final adapter = VideoPlayerPluginAdapter(
      reachabilityProbe: (_) async => true,
      loadingTimeout: const Duration(milliseconds: 40),
      initializeTimeout: const Duration(seconds: 1),
    );

    final opening = adapter.openAndPlay();
    await _waitUntil(
      () => adapter.uiState.value == PlayerUiState.error,
      timeout: const Duration(seconds: 1),
    );

    expect(adapter.videoController, isNull);
    expect(platform.disposedIds, isNotEmpty);
    await opening.timeout(const Duration(seconds: 1));
    adapter.dispose();
  });

  test('Windows uses the shorter default initialize timeout', () {
    final windowsAdapter = VideoPlayerPluginAdapter(
      targetPlatform: TargetPlatform.windows,
    );
    final otherAdapter = VideoPlayerPluginAdapter(
      targetPlatform: TargetPlatform.macOS,
    );

    expect(windowsAdapter.initializeTimeout, const Duration(seconds: 12));
    expect(otherAdapter.initializeTimeout, const Duration(seconds: 15));
    windowsAdapter.dispose();
    otherAdapter.dispose();
  });

  test(
    'initialize failure releases the previous controller and errors',
    () async {
      final adapter = VideoPlayerPluginAdapter(
        reachabilityProbe: (_) async => true,
        initializeTimeout: const Duration(milliseconds: 100),
      );

      await adapter.openAndPlay();
      expect(adapter.uiState.value, isNot(PlayerUiState.loading));
      final first = adapter.videoController;
      expect(first, isNotNull);

      platform.haltInitializedEvents = true;
      await adapter.openAndPlay();

      expect(adapter.uiState.value, PlayerUiState.error);
      expect(adapter.videoController, isNull);
      expect(platform.disposedIds, isNotEmpty);
      adapter.dispose();
    },
  );

  test('initialize timeout can be rebuilt on the next open', () async {
    final adapter = VideoPlayerPluginAdapter(
      reachabilityProbe: (_) async => true,
      initializeTimeout: const Duration(milliseconds: 80),
    );

    platform.haltInitializedEvents = true;
    await adapter.openAndPlay();
    expect(adapter.uiState.value, PlayerUiState.error);
    expect(adapter.videoController, isNull);

    platform.haltInitializedEvents = false;
    await adapter.openAndPlay();

    expect(adapter.uiState.value, PlayerUiState.playing);
    expect(adapter.videoController, isNotNull);
    expect(platform.disposedIds, isNotEmpty);
    adapter.dispose();
  });

  test('dispose releases a live controller without hanging', () async {
    final adapter = VideoPlayerPluginAdapter(
      reachabilityProbe: (_) async => true,
      initializeTimeout: const Duration(seconds: 1),
    );

    await adapter.openAndPlay();
    expect(adapter.videoController, isNotNull);
    final created = platform.createdIds.toSet();
    expect(created, isNotEmpty);

    final stopwatch = Stopwatch()..start();
    adapter.dispose();
    await _waitUntil(
      () => platform.disposedIds.any(created.contains),
      timeout: const Duration(seconds: 5),
    );
    stopwatch.stop();
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    expect(platform.disposedIds.toSet(), containsAll(created));
  });

  test('concurrent open discards the superseded generation', () async {
    var probeCalls = 0;
    final adapter = VideoPlayerPluginAdapter(
      reachabilityProbe: (url) async {
        probeCalls++;
        if (probeCalls == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
        return true;
      },
      initializeTimeout: const Duration(seconds: 5),
    );

    final first = adapter.openAndPlay();
    final second = adapter.openAndPlay();
    await Future.wait([first, second]);

    expect(probeCalls, 2);
    expect(adapter.uiState.value, PlayerUiState.playing);
    expect(adapter.videoController, isNotNull);
    // Only the winning generation keeps a live controller.
    expect(platform.createdIds, hasLength(1));
    expect(platform.disposedIds, isEmpty);
    adapter.dispose();
  });
}

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter({this.streamError = false});

  final bool streamError;
  String? method;
  String? range;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    range = options.headers['Range'] as String?;
    if (streamError) {
      return ResponseBody(
        Stream<Uint8List>.error(StateError('unreadable stream')),
        206,
        headers: const {
          Headers.contentTypeHeader: ['video/mp4'],
          'content-range': ['bytes 0-0/1'],
        },
      );
    }
    return ResponseBody.fromBytes(
      const [0],
      206,
      headers: const {
        Headers.contentTypeHeader: ['video/mp4'],
        'content-range': ['bytes 0-0/1'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A minimal [VideoPlayerPlatform] double that records lifecycle calls.
class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  bool haltInitializedEvents = false;

  final List<int> createdIds = [];
  final Set<int> disposedIds = {};
  int _nextId = 0;
  final Map<int, StreamController<VideoEvent>> _events = {};

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) => _doCreate();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) => _doCreate();

  Future<int?> _doCreate() async {
    final id = _nextId++;
    createdIds.add(id);
    final controller = StreamController<VideoEvent>();
    _events[id] = controller;
    if (!haltInitializedEvents) {
      // Emit after the controller has subscribed to videoEventsFor so the
      // single-subscription initialized event is not lost.
      Future<void>.delayed(const Duration(milliseconds: 20), () {
        controller.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(minutes: 2),
            size: const Size(640, 360),
          ),
        );
      });
    }
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) =>
      _events[textureId]!.stream;

  @override
  Future<void> dispose(int textureId) async {
    disposedIds.add(textureId);
    final controller = _events.remove(textureId);
    await controller?.close();
  }

  @override
  Future<void> play(int textureId) async {
    _events[textureId]?.add(
      VideoEvent(eventType: VideoEventType.isPlayingStateUpdate),
    );
  }

  @override
  Future<void> pause(int textureId) async {}

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<Duration> getPosition(int textureId) async => Duration.zero;

  @override
  Future<void> seekTo(int textureId, Duration position) async {}

  @override
  Widget buildView(int textureId) => const SizedBox.shrink();
}

/// Restores a neutral platform double so per-test instance is reset.
class _RestoringVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> pause(int textureId) async {}

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<Duration> getPosition(int textureId) async => Duration.zero;

  @override
  Future<void> seekTo(int textureId, Duration position) async {}

  @override
  Widget buildView(int textureId) => const SizedBox.shrink();
}

Future<void> _waitUntil(
  bool Function() predicate, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
