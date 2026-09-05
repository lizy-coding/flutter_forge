import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:video_player/video_player.dart';

import 'state/video_player_adapter.dart';
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
      widget.adapter ?? VideoPlayerPluginAdapter();

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
                      return _VideoPlaceholder(
                        key: const Key('video-error-placeholder'),
                        icon: Icons.error_outline,
                        message: '视频加载失败，请检查网络后重试',
                        onRetry: _adapter.openAndPlay,
                      );
                    }
                    if (state == PlayerUiState.idle ||
                        state == PlayerUiState.loading) {
                      return const _VideoPlaceholder(
                        icon: Icons.ondemand_video,
                        message: '正在连接视频源…',
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
                      children: [VideoPlayer(controller)],
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
            '理解 video_player、VideoPlayerController 与平台播放器的职责边界',
            '掌握在线媒体打开、播放、暂停、跳转、音量和倍速控制',
            '正确管理 VideoPlayerController、监听器和 ValueNotifier 的生命周期',
          ],
        ),
        ConceptChips(
          concepts: [
            'video_player',
            '平台播放器',
            'HTTP 流',
            '播放控制',
            '倍速',
            'Controller 生命周期',
          ],
        ),
        CodeSnippetCard(
          title: '打开并播放在线媒体',
          code:
              "final controller = VideoPlayerController.networkUrl(\n"
              "  Uri.parse('https://example.com/video.mp4'),\n"
              ");\n"
              "await controller.initialize();\n"
              "await controller.play();",
          explanation:
              'VideoPlayerController 负责媒体状态，并把平台播放器画面连接到 Flutter Widget。',
        ),
        CommonPitfalls(
          pitfalls: [
            'macOS 沙箱默认禁止外部网络访问，需要同时配置 DebugProfile 与 Release 的 network.client 权限',
            'VideoPlayerController 必须先完成 initialize，才能可靠读取时长并渲染画面',
            'VideoPlayerController 和监听器必须在页面销毁时释放，避免原生资源与回调泄漏',
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
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 52),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('video-retry-button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }
}
