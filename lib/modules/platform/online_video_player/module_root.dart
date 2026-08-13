import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'state/media_kit_player_adapter.dart';
import 'widgets/video_player_controls.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.adapter});

  final String title;
  final VideoPlayerAdapter? adapter;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final VideoPlayerAdapter _adapter =
      widget.adapter ?? MediaKitPlayerAdapter();

  @override
  void initState() {
    super.initState();
    _adapter.openAndPlay();
  }

  @override
  void dispose() {
    _adapter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: widget.title,
      floatingActionButton: FloatingActionButton(
        tooltip: '重新加载视频',
        onPressed: _adapter.openAndPlay,
        child: const Icon(Icons.refresh),
      ),
      interactiveDemo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: Colors.black,
                child: ValueListenableBuilder<PlayerUiState>(
                  valueListenable: _adapter.uiState,
                  builder: (context, state, child) {
                    if (state == PlayerUiState.error) {
                      return const _VideoPlaceholder(
                        key: Key('video-error-placeholder'),
                        icon: Icons.error_outline,
                        message: '视频加载失败，请检查网络后重试',
                      );
                    }
                    if (state == PlayerUiState.idle) {
                      return const _VideoPlaceholder(
                        icon: Icons.ondemand_video,
                        message: '等待加载在线视频',
                      );
                    }
                    final controller = _adapter.videoController;
                    if (controller == null) {
                      return const _VideoPlaceholder(
                        icon: Icons.videocam_off_outlined,
                        message: '视频渲染器不可用',
                      );
                    }
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Video(
                          controller: controller,
                          controls: NoVideoControls,
                        ),
                        if (state == PlayerUiState.loading)
                          const ColoredBox(
                            color: Color(0x66000000),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          VideoPlayerControls(adapter: _adapter),
          const SizedBox(height: 8),
          const SelectableText(
            '示例地址：$sampleStreamUrl',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解 media_kit、VideoController 与原生 libmpv 的职责边界',
            '掌握在线媒体打开、播放、暂停、跳转、音量和倍速控制',
            '正确管理 Player、流订阅和 ValueNotifier 的生命周期',
          ],
        ),
        ConceptChips(
          concepts: [
            'media_kit',
            'libmpv',
            'HTTP 流',
            '播放控制',
            '倍速',
            'Player 生命周期',
          ],
        ),
        CodeSnippetCard(
          title: '打开并播放在线媒体',
          code:
              "final player = Player();\n"
              "final controller = VideoController(player);\n"
              "await player.open(\n"
              "  Media('https://example.com/video.mp4'),\n"
              "  play: true,\n"
              ");",
          explanation: 'Player 负责媒体状态，VideoController 将视频画面连接到 Flutter Widget。',
        ),
        CommonPitfalls(
          pitfalls: [
            'macOS 沙箱默认禁止外部网络访问，需要同时配置 DebugProfile 与 Release 的 network.client 权限',
            'media_kit 必须在 runApp 前完成全局初始化，否则原生后端可能无法正确加载',
            'Player、流订阅和监听器必须在页面销毁时释放，避免原生资源与回调泄漏',
          ],
        ),
        ExerciseCard(
          task: '增加一个 URL 输入框，让使用者加载自己的 HTTPS 视频，并保留最近一次成功播放的地址。',
          hint: '先校验 Uri 的 scheme 与 host，再把媒体地址作为适配器 open 方法的参数。',
        ),
      ],
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 52),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
