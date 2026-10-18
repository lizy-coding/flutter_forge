import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'shader_preview.dart';

class ShaderPlaygroundPage extends StatefulWidget {
  const ShaderPlaygroundPage({super.key, this.loadLesson = ShaderLesson.load});

  final Future<ShaderLesson> Function() loadLesson;

  @override
  State<ShaderPlaygroundPage> createState() => _ShaderPlaygroundPageState();
}

class _ShaderPlaygroundPageState extends State<ShaderPlaygroundPage> {
  ShaderLesson? _lesson;
  ShaderParameters _parameters = const ShaderParameters();
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final lesson = await widget.loadLesson();
      if (!mounted) {
        lesson.dispose();
        return;
      }
      setState(() {
        _lesson = lesson;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _lesson?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    return LearningScaffold(
      title: 'Shader 像素绘制与交互动效',
      interactiveDemo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('UV 坐标与双色渐变', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('调节参数，观察每个像素如何从坐标得到颜色。本节按操作重绘，不持续播放动画。'),
          const SizedBox(height: 16),
          if (_loading)
            const SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('正在加载 Shader…'),
                  ],
                ),
              ),
            )
          else if (_failed)
            Column(
              children: [
                const Text('无法加载 Shader，请重试。'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => unawaited(_load()),
                  child: const Text('重试加载'),
                ),
              ],
            )
          else if (lesson != null) ...[
            Semantics(
              label: _parameters.showUv ? 'UV 坐标预览：红色表示横坐标，绿色表示纵坐标' : '双色渐变预览',
              image: true,
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  height: (constraints.maxWidth / 1.6).clamp(0.0, 240.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomPaint(
                      key: const Key('shader-preview'),
                      painter: ShaderPreviewPainter(
                        shader: lesson.shader,
                        parameters: _parameters,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              key: const Key('shader-uv-toggle'),
              contentPadding: EdgeInsets.zero,
              title: const Text('显示 UV 坐标'),
              subtitle: const Text('左上角为 (0, 0)，右下角为 (1, 1)'),
              value: _parameters.showUv,
              onChanged: (value) => setState(() {
                _parameters = _parameters.copyWith(showUv: value);
              }),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final vertical in [false, true])
                  ChoiceChip(
                    label: Text(vertical ? '纵向渐变' : '横向渐变'),
                    selected: _parameters.vertical == vertical,
                    onSelected: _parameters.showUv
                        ? null
                        : (_) => setState(() {
                            _parameters = _parameters.copyWith(
                              vertical: vertical,
                            );
                          }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('渐变偏移：${_parameters.offset.toStringAsFixed(2)}'),
            Slider(
              key: const Key('shader-offset'),
              value: _parameters.offset,
              min: -0.5,
              max: 0.5,
              divisions: 20,
              label: _parameters.offset.toStringAsFixed(2),
              onChanged: _parameters.showUv
                  ? null
                  : (value) => setState(() {
                      _parameters = _parameters.copyWith(offset: value);
                    }),
            ),
            Text(
              _parameters.showUv
                  ? '当前输出 (U, V, 0, 1)，渐变参数暂不参与绘制。'
                  : '当前使用 ${_parameters.vertical ? 'V' : 'U'} + ${_parameters.offset.toStringAsFixed(2)}，限制在 0～1 后混合两端颜色。',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _parameters.showUv
                      ? null
                      : () => setState(() {
                          _parameters = _parameters.copyWith(
                            startColor: _parameters.endColor,
                            endColor: _parameters.startColor,
                          );
                        }),
                  child: const Text('交换颜色'),
                ),
                FilledButton.tonal(
                  onPressed: () => setState(() {
                    _parameters = const ShaderParameters();
                  }),
                  child: const Text('复位参数'),
                ),
              ],
            ),
          ],
        ],
      ),
      sections: [
        const LearningObjectives(
          objectives: [
            '理解片元着色器如何把局部坐标转换成像素颜色',
            '通过 uniform 将 Flutter 控件参数传入 GLSL',
            '区分 UV 可视化与双色渐变，观察方向和偏移的影响',
          ],
        ),
        const ConceptChips(
          concepts: [
            'FragmentProgram',
            'FragmentShader',
            'UV',
            'uniform',
            'CustomPainter',
          ],
        ),
        if (lesson != null)
          CodeSnippetCard(
            title: '正在运行的 GLSL 核心代码',
            code: lesson.source,
            explanation:
                '此代码直接来自编译时包含的源文件。入口 .frag 声明 GLSL 版本，并引入 Flutter 坐标函数。',
          ),
        const CommonPitfalls(
          pitfalls: [
            'Shader 文件需要声明在 flutter.shaders 中，由 Flutter 编译后加载。',
            'vec2 占两个 float 槽，vec4 占四个；Dart 绑定顺序必须与 uniform 声明一致。',
            '使用 FlutterFragCoord() 获取局部坐标，并用当前画布宽高归一化。',
            '透明颜色使用预乘 alpha；页面退出释放 Shader，不能在每次重绘时重新加载。',
          ],
        ),
        const ExerciseCard(
          task: '先观察 UV 的四个角，再切换纵向渐变、交换颜色并改变偏移；最后复位，解释每一步画面变化。',
          hint: '红色通道对应 U，绿色通道对应 V；渐变混合比例来自选定的坐标轴。',
        ),
      ],
    );
  }
}
