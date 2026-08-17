import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_study_app/modules/platform/online_video_player/module_root.dart';
import 'package:flutter_study_app/modules/platform/online_video_player/state/video_player_adapter.dart';
import 'package:flutter_study_app/modules/platform/online_video_player/widgets/video_player_controls.dart';
import 'package:video_player/video_player.dart';

void main() {
  testWidgets('controls render playback, seek, rate and volume controls', (
    tester,
  ) async {
    final adapter = FakeVideoPlayerAdapter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VideoPlayerControls(adapter: adapter)),
      ),
    );

    expect(find.byKey(const Key('video-play-pause')), findsOneWidget);
    expect(find.byKey(const Key('video-seek')), findsOneWidget);
    expect(find.byKey(const Key('video-rate')), findsOneWidget);
    expect(find.byKey(const Key('video-volume')), findsOneWidget);
    expect(find.text('00:00 / 02:00'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('play pause button follows adapter state', (tester) async {
    final adapter = FakeVideoPlayerAdapter();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VideoPlayerControls(adapter: adapter)),
      ),
    );

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    await tester.tap(find.byKey(const Key('video-play-pause')));
    await tester.pump();
    expect(find.byIcon(Icons.pause), findsOneWidget);

    await tester.tap(find.byKey(const Key('video-play-pause')));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('module shows error placeholder without network access', (
    tester,
  ) async {
    final adapter = FakeVideoPlayerAdapter(failOnOpen: true);

    await tester.pumpWidget(
      MaterialApp(
        home: MyHomePage(title: '在线视频播放', adapter: adapter),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('video-error-placeholder')), findsOneWidget);
    expect(find.text('视频加载失败，请检查网络后重试'), findsOneWidget);
    expect(adapter.openCount, 1);
  });
}

class FakeVideoPlayerAdapter implements VideoPlayerAdapter {
  FakeVideoPlayerAdapter({this.failOnOpen = false});

  final bool failOnOpen;
  int openCount = 0;

  @override
  final ValueNotifier<PlayerUiState> uiState = ValueNotifier(
    PlayerUiState.paused,
  );

  @override
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  @override
  final ValueNotifier<Duration> duration = ValueNotifier(
    const Duration(minutes: 2),
  );

  @override
  final ValueNotifier<double> volume = ValueNotifier(1);

  @override
  final ValueNotifier<double> rate = ValueNotifier(1);

  @override
  VideoPlayerController? get videoController => null;

  @override
  Future<void> openAndPlay() async {
    openCount++;
    uiState.value = failOnOpen ? PlayerUiState.error : PlayerUiState.playing;
  }

  @override
  Future<void> pause() async => uiState.value = PlayerUiState.paused;

  @override
  Future<void> play() async => uiState.value = PlayerUiState.playing;

  @override
  Future<void> togglePlayPause() async {
    uiState.value = uiState.value == PlayerUiState.playing
        ? PlayerUiState.paused
        : PlayerUiState.playing;
  }

  @override
  Future<void> seek(Duration value) async => position.value = value;

  @override
  Future<void> setRate(double value) async => rate.value = value;

  @override
  Future<void> setVolume(double value) async => volume.value = value;

  @override
  void dispose() {
    uiState.dispose();
    position.dispose();
    duration.dispose();
    volume.dispose();
    rate.dispose();
  }
}
