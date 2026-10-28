import 'dart:async';
import '../../../shared/platform/build_features.dart';
import 'core/offline_documents.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/learning/learning_scaffold.dart';
import 'core/webview_backend.dart';
import 'core/webview_session.dart';
import 'platforms/webview_flutter_backend.dart';
import 'platforms/webview2_backend.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key, this.backend});
  final WebViewBackend? backend;
  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewSession? _session;
  final _address = TextEditingController(text: 'https://example.com');
  @override
  void initState() {
    super.initState();
    final backend =
        widget.backend ??
        (kIsWeb
            ? null
            : switch (defaultTargetPlatform) {
                TargetPlatform.android ||
                TargetPlatform.macOS => WebViewFlutterBackend(),
                TargetPlatform.windows => WebView2Backend(),
                _ => null,
              });
    if (backend != null) {
      _session = WebViewSession(backend);
      unawaited(_session!.start());
    }
  }

  @override
  void dispose() {
    _session?.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LearningScaffold(
    title: '网页容器与跨平台导航',
    interactiveDemo: _session == null
        ? const Text('当前平台不可用：仅支持 Android、macOS 和 Windows')
        : AnimatedBuilder(
            animation: _session!,
            builder: (context, child) {
              final session = _session!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (offlineEdition)
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: session.initialized
                              ? () => session.navigate(offlineOverviewUrl)
                              : null,
                          child: const Text('本地内容'),
                        ),
                        TextButton(
                          onPressed: session.initialized
                              ? () => session.navigate(offlineCounterUrl)
                              : null,
                          child: const Text('页面交互'),
                        ),
                      ],
                    )
                  else
                    TextField(
                      controller: _address,
                      key: const ValueKey('webview-url'),
                      decoration: const InputDecoration(
                        labelText: '网页地址（http / https）',
                      ),
                      onSubmitted: session.initialized
                          ? session.navigate
                          : null,
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (!offlineEdition)
                        TextButton(
                          onPressed: session.initialized
                              ? () => session.navigate(_address.text)
                              : null,
                          child: const Text('打开'),
                        ),
                      IconButton(
                        tooltip: '网页后退',
                        onPressed: session.canBack ? session.back : null,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      IconButton(
                        tooltip: '网页前进',
                        onPressed: session.canForward ? session.forward : null,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                      IconButton(
                        tooltip: '刷新网页',
                        onPressed: session.initialized ? session.reload : null,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  Text(
                    offlineEdition ? '内置教学页 · 无需联网' : session.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (session.loading)
                    LinearProgressIndicator(
                      value: session.progress > 0 ? session.progress : null,
                    ),
                  if (session.error != null) ...[
                    Text(session.error!, key: const ValueKey('webview-error')),
                    TextButton(
                      onPressed: session.busy
                          ? null
                          : (session.initialized
                                ? session.reload
                                : session.start),
                      child: const Text('重试'),
                    ),
                  ],
                  SizedBox(
                    height: 320,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (session.initialized)
                          AnimatedOpacity(
                            opacity: session.contentVisible ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: session.backend.buildView(),
                          ),
                        if (!session.contentVisible && session.error == null)
                          const ColoredBox(
                            color: Color(0xffeeeeee),
                            child: Center(child: Text('正在加载网页…')),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
    sections: const [
      LearningObjectives(
        objectives: [
          '比较 Android WebView、macOS WKWebView 与 Windows WebView2',
          '掌握网页前进、后退与加载状态管理',
          '退出页面时释放控制器、订阅和计时器',
        ],
      ),
      ConceptChips(concepts: ['Platform View', 'WebView2', '异步生命周期', '导航安全']),
      CodeSnippetCard(
        title: '统一网页导航',
        code:
            'await backend.loadUrl(url);\nawait backend.goBack();\nawait backend.reload();',
        explanation: 'Forge 管理模块入口和平台可用性；模块使用统一接口隔离原生 WebView。',
      ),
      CommonPitfalls(
        pitfalls: [
          'Windows 需要安装 WebView2 Runtime。',
          'Windows 进度为估算；30% 或 3 秒只控制内容显示，不代表加载成功。',
          '模块始终在现有页面中运行，不创建业务窗口。',
        ],
      ),
      ExerciseCard(task: '打开两个网页，观察后退、前进、刷新和无效地址提示，再退出并重新进入。'),
    ],
  );
}
