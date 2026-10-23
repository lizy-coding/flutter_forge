import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:go_router/go_router.dart';

import 'lesson_steps.dart';
import 'shader_preview.dart';

class ShaderPlaygroundPage extends StatefulWidget {
  const ShaderPlaygroundPage({super.key, this.loadLesson = ShaderLesson.load});

  final Future<ShaderLesson> Function() loadLesson;

  @override
  State<ShaderPlaygroundPage> createState() => _ShaderPlaygroundPageState();
}

class _ShaderPlaygroundPageState extends State<ShaderPlaygroundPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ShaderLesson? _lesson;
  ShaderParameters _parameters = shaderSteps.first.parameters;
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
    value: 0.5,
  );
  final _stepAnchor = GlobalKey();
  final _previewAnchor = GlobalKey();
  int _step = 0;
  Offset _uv = const Offset(0.25, 0.5);
  bool _reveal = false;
  bool _loading = true;
  bool _failed = false;
  double _seconds = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _motion.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      setState(_motion.stop);
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    _lesson?.dispose();
    super.dispose();
  }

  void _selectStep(int step) {
    _motion.stop();
    _motion.value = 0.5;
    setState(() {
      _step = step;
      _parameters = shaderSteps[step].parameters;
      _uv = const Offset(0.25, 0.5);
      _reveal = false;
      _seconds = 4;
      _motion.duration = const Duration(seconds: 4);
    });
    final anchor = _stepAnchor.currentContext;
    if (anchor != null) unawaited(Scrollable.ensureVisible(anchor));
  }

  bool _pauseOffscreen(ScrollNotification notification) {
    if (_motion.isAnimating && notification.depth == 0) {
      final box =
          _previewAnchor.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final top = box.localToGlobal(Offset.zero).dy;
        if (top + box.size.height < 0 ||
            top > MediaQuery.sizeOf(context).height) {
          setState(_motion.stop);
        }
      }
    }
    return false;
  }

  Widget _preview(ShaderLesson lesson) => AnimatedBuilder(
    animation: _motion,
    builder: (context, _) {
      final values = _parameters.copyWith(phase: _motion.value);
      final color = values.colorAt(_uv);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                (constraints.maxWidth / 1.6).clamp(80.0, 220.0),
              );
              void select(Offset point) => setState(() {
                _uv = Offset(
                  (point.dx / size.width).clamp(0.0, 1.0),
                  (point.dy / size.height).clamp(0.0, 1.0),
                );
              });
              return Semantics(
                label: 'Shader 画面，点击或拖动查看位置对应的颜色',
                child: GestureDetector(
                  onTapDown: (event) => select(event.localPosition),
                  onPanUpdate: (event) => select(event.localPosition),
                  child: SizedBox(
                    key: _previewAnchor,
                    height: size.height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CustomPaint(
                              key: const Key('shader-preview'),
                              painter: ShaderPreviewPainter(
                                shader: lesson.shader,
                                parameters: values,
                              ),
                            ),
                          ),
                        ),
                        if (values.effect == ShaderEffect.sweep)
                          const Center(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    '探索会员权益 →',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: (_uv.dx * size.width - 7).clamp(
                            0.0,
                            size.width - 14,
                          ),
                          top: (_uv.dy * size.height - 7).clamp(
                            0.0,
                            size.height - 14,
                          ),
                          child: IgnorePointer(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text('点击或拖动选点；圆环是位置标记，不参与 Shader 计算。'),
          if (values.effect == ShaderEffect.sweep)
            const Text('场景示例：卡片背景扫光；文字仍由普通 Flutter Widget 绘制。'),
          Wrap(
            spacing: 8,
            children: [
              for (final u in [0.25, 0.5, 0.75])
                TextButton(
                  onPressed: () => setState(() => _uv = Offset(u, 0.5)),
                  child: Text('选点 U=$u'),
                ),
            ],
          ),
          Text(
            '选中位置：横向 ${(100 * _uv.dx).toStringAsFixed(0)}%，纵向 ${(100 * _uv.dy).toStringAsFixed(0)}% → UV (${_uv.dx.toStringAsFixed(2)}, ${_uv.dy.toStringAsFixed(2)})',
            key: const Key('shader-sample-position'),
          ),
          if (!values.showUv)
            Text(switch (values.effect) {
              ShaderEffect.solid => '规则：t = 0，不依赖位置。',
              ShaderEffect.split =>
                '规则：${_uv.dx.toStringAsFixed(2)} < 0.5 为${_uv.dx < 0.5 ? '真' : '假'} → t = ${values.blendAt(_uv).toInt()}',
              ShaderEffect.gradient =>
                '规则：clamp(${(values.vertical ? _uv.dy : _uv.dx).toStringAsFixed(2)} + ${values.offset.toStringAsFixed(2)}, 0, 1) = ${values.blendAt(_uv).toStringAsFixed(2)}',
              ShaderEffect.sweep =>
                '规则：距离 = |${_uv.dx.toStringAsFixed(2)} − ${(-values.bandWidth + (1 + 2 * values.bandWidth) * _motion.value).toStringAsFixed(2)}|；距离越接近中心，越接近结束色。',
            }, key: const Key('shader-calculation')),
          Text(
            values.showUv
                ? '输出 (U, V, 0, 1)；渐变参数暂不参与绘制。'
                : '混合比例 t = ${values.blendAt(_uv).toStringAsFixed(2)} → 起始色 ${(100 * (1 - values.blendAt(_uv))).toStringAsFixed(0)}%，结束色 ${(100 * values.blendAt(_uv)).toStringAsFixed(0)}%',
            key: const Key('shader-sample-blend'),
          ),
          Row(
            children: [
              Container(width: 24, height: 24, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '颜色 RGBA (${color.r.toStringAsFixed(2)}, ${color.g.toStringAsFixed(2)}, ${color.b.toStringAsFixed(2)}, ${color.a.toStringAsFixed(2)})',
                ),
              ),
            ],
          ),
          if (values.effect == ShaderEffect.sweep)
            Text(
              '亮带位置：${_motion.value.toStringAsFixed(2)}；中心 U = ${(-values.bandWidth + (1 + 2 * values.bandWidth) * _motion.value).toStringAsFixed(2)}',
              key: const Key('shader-phase-value'),
            ),
        ],
      );
    },
  );

  Widget _slider(
    String label,
    String key,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label：${value.toStringAsFixed(2)}'),
      Slider(
        key: Key(key),
        label: value.toStringAsFixed(2),
        value: value,
        min: min,
        max: max,
        divisions: 20,
        onChanged: onChanged,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final step = shaderSteps[_step];
    final lesson = _lesson;
    final sweep = _parameters.effect == ShaderEffect.sweep;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return NotificationListener<ScrollNotification>(
      onNotification: _pauseOffscreen,
      child: LearningScaffold(
        title: 'Shader 像素绘制与交互动效',
        interactiveDemo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '第 ${_step + 1} 步 / 共 ${shaderSteps.length} 步',
              key: _stepAnchor,
            ),
            Text(step.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('学习顺序：绘制入门 → 真实 Shader → 渐变 → 卡片扫光。每步可直接查看解释，无需答题。'),
            TextButton(
              onPressed: () {
                _motion.stop();
                unawaited(context.push('/pixel-shader-intro'));
              },
              child: const Text('返回基础：从画形状到算颜色'),
            ),
            Text('先想一想：${step.prediction}'),
            TextButton(
              key: const Key('shader-reveal'),
              onPressed: () => setState(() => _reveal = !_reveal),
              child: Text(_reveal ? '收起解释' : '查看解释'),
            ),
            if (_reveal) Text(step.answer, key: const Key('shader-answer')),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Column(
                  children: [CircularProgressIndicator(), Text('正在加载 Shader…')],
                ),
              )
            else if (_failed)
              Column(
                children: [
                  const Text('无法加载 Shader，请重试。'),
                  FilledButton(
                    onPressed: () => unawaited(_load()),
                    child: const Text('重试加载'),
                  ),
                ],
              )
            else if (lesson != null) ...[
              if (sweep) ...[
                FilledButton.tonal(
                  key: const Key('shader-play'),
                  onPressed: reducedMotion
                      ? null
                      : () => setState(() {
                          if (_motion.isAnimating) {
                            _motion.stop();
                          } else {
                            _motion.repeat();
                          }
                        }),
                  child: Text(_motion.isAnimating ? '暂停扫光' : '播放扫光'),
                ),
              ],
              _preview(lesson),
              if (_step >= 2 && !sweep)
                SwitchListTile(
                  key: const Key('shader-uv-toggle'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('显示 UV 坐标'),
                  subtitle: const Text('红色表示 U，绿色表示 V；左上角 (0, 0)，右下角 (1, 1)'),
                  value: _parameters.showUv,
                  onChanged: (value) => setState(
                    () => _parameters = _parameters.copyWith(showUv: value),
                  ),
                ),
              if (_step == 3)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final vertical in [false, true])
                      ChoiceChip(
                        label: Text(vertical ? '纵向渐变' : '横向渐变'),
                        selected: _parameters.vertical == vertical,
                        onSelected: _parameters.showUv
                            ? null
                            : (_) => setState(
                                () => _parameters = _parameters.copyWith(
                                  vertical: vertical,
                                ),
                              ),
                      ),
                  ],
                ),
              if (_step == 4) ...[
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
                      : (value) => setState(
                          () =>
                              _parameters = _parameters.copyWith(offset: value),
                        ),
                ),
              ],
              if (sweep) ...[
                AnimatedBuilder(
                  animation: _motion,
                  builder: (context, _) => _slider(
                    '亮带位置（暂停后拖动）',
                    'shader-phase',
                    _motion.value,
                    0,
                    1,
                    (value) {
                      _motion.stop();
                      setState(() => _motion.value = value);
                    },
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final subtle in [true, false])
                      OutlinedButton(
                        onPressed: () {
                          _motion.stop();
                          _motion.value = 0.5;
                          setState(() {
                            _parameters = shaderSteps.last.parameters.copyWith(
                              bandWidth: subtle ? 0.15 : 0.4,
                              softness: subtle ? 0.9 : 0.25,
                            );
                          });
                        },
                        child: Text(subtle ? '对照：窄而柔和' : '对照：宽而清晰'),
                      ),
                  ],
                ),
                _slider(
                  '亮带半宽（画布比例）',
                  'shader-width',
                  _parameters.bandWidth,
                  0.05,
                  0.5,
                  (value) => setState(
                    () => _parameters = _parameters.copyWith(bandWidth: value),
                  ),
                ),
                _slider(
                  '边缘柔和度',
                  'shader-softness',
                  _parameters.softness,
                  0.05,
                  1,
                  (value) => setState(
                    () => _parameters = _parameters.copyWith(softness: value),
                  ),
                ),
                _slider(
                  '单次扫过秒数',
                  'shader-speed',
                  _seconds,
                  1,
                  8,
                  (value) => setState(() {
                    _seconds = value;
                    _motion.duration = Duration(
                      milliseconds: (value * 1000).round(),
                    );
                    if (_motion.isAnimating) _motion.repeat();
                  }),
                ),
                TextButton(
                  onPressed: () {
                    final anchor = _previewAnchor.currentContext;
                    if (anchor != null) {
                      unawaited(Scrollable.ensureVisible(anchor));
                    }
                  },
                  child: const Text('回到画面查看调参结果'),
                ),
                Text(
                  reducedMotion
                      ? '系统已开启减少动态效果：保持静态，可手动调整亮带位置。'
                      : '默认暂停。离开页面、切换步骤、滚出预览或应用进入后台时停止播放。',
                ),
              ],
              Wrap(
                spacing: 8,
                children: [
                  if (_step >= 2)
                    OutlinedButton(
                      onPressed: _parameters.showUv
                          ? null
                          : () => setState(
                              () => _parameters = _parameters.copyWith(
                                startColor: _parameters.endColor,
                                endColor: _parameters.startColor,
                              ),
                            ),
                      child: const Text('交换颜色'),
                    ),
                  TextButton(
                    onPressed: () => _selectStep(_step),
                    child: const Text('复位本步'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('shader-previous'),
                  onPressed: _step == 0 ? null : () => _selectStep(_step - 1),
                  child: const Text('上一步'),
                ),
                FilledButton(
                  key: const Key('shader-next'),
                  onPressed: _step == shaderSteps.length - 1
                      ? null
                      : () => _selectStep(_step + 1),
                  child: const Text('下一步'),
                ),
              ],
            ),
          ],
        ),
        sections: [
          CodeSnippetCard(
            title: 'Dart 思路对照（不在 CPU 上逐像素运行）',
            code: step.dart,
            explanation: 'GLSL 的 vec2 是两个分量，vec4 是四个颜色分量；此处先对应规则，再看下面真正运行的代码。',
          ),
          if (lesson != null)
            _FocusedSource(source: lesson.source, patterns: step.lines),
          const LearningObjectives(
            objectives: [
              '跟随操作，理解位置、颜色比例与 Shader 代码的对应关系',
              '从纯色、分界和渐变过渡到真实卡片扫光',
              '认识适用场景，并通过对照调整视觉方案',
            ],
          ),
          const _ScenarioGuide(),
          const CodeSnippetCard(
            title: 'Flutter 怎样把参数送进 Shader',
            code:
                '// 初始化时加载一次，创建本页使用的实例\nfinal program = await FragmentProgram.fromAsset(asset);\nfinal shader = program.fragmentShader();\n\n// 在 paint 中，尺寸与控件参数送入 uniform\nshader.setFloat(0, size.width);\nshader.setFloat(1, size.height);\nshader.setFloat(4, offset);\ncanvas.drawRect(Offset.zero & size, Paint()..shader = shader);\n\n// 页面退出时释放本页实例\nshader.dispose();',
            explanation:
                'uniform 是 Flutter 传给一次绘制的参数，本次绘制的片元共用这些值。本课先用 Canvas 矩形承载规则；后续图片处理需要另外引入图片采样。',
          ),
          const CommonPitfalls(
            pitfalls: [
              '只要标准渐变就能满足需求，优先使用 LinearGradient；使用 Shader 本身不代表更快。',
              '亮带更窄或移动更慢，不代表每帧处理的区域更小。本示例始终绘制整个卡片矩形。',
              '视觉调优先暂停并固定位置，再逐个比较宽度、柔和度和速度；不要同时改多个参数。',
              '性能判断要在目标设备的 Profile 模式下比较相同尺寸和动画时长，观察帧耗时；当前页面没有测量 GPU 时间。',
            ],
          ),
          const ExerciseCard(
            task:
                '基础：完成六步操作并查看解释。进阶：想一个真实界面需求，比较标准渐变、Canvas 与 Shader 的适合程度，再选一个参数做前后对照。',
            hint: '无需独立写题；重点是能把画面变化与规则、场景和调优选择联系起来。',
          ),
        ],
      ),
    );
  }
}

class _FocusedSource extends StatelessWidget {
  const _FocusedSource({required this.source, required this.patterns});
  final String source;
  final List<String> patterns;

  @override
  Widget build(BuildContext context) {
    final lines = source.split('\n');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('本步关注的 GLSL 行', style: Theme.of(context).textTheme.titleMedium),
          const Text('摘自正在运行的源码；行号对应下方完整文件。选点后的数值按这些规则计算。'),
          for (var i = 0; i < lines.length; i++)
            if (patterns.any((pattern) => lines[i].contains(pattern)))
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(10),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: SelectableText(
                  '${i + 1}  ${lines[i].trim()}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
          ExpansionTile(
            title: const Text('展开完整 GLSL 源码'),
            children: [CodeSnippetCard(title: '正在运行的 GLSL 核心代码', code: source)],
          ),
        ],
      ),
    );
  }
}

class _ScenarioGuide extends StatelessWidget {
  const _ScenarioGuide();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('什么时候用？怎样调？', style: Theme.of(context).textTheme.titleMedium),
        const Text(
          '普通背景渐变 → LinearGradient：颜色与方向即可表达需求。\n图表、路径、标记 → Canvas：重点是形状与几何布局。\n自定义逐位置颜色、组合距离规则 → Shader：本课扫光展示这条路线，也可先评估标准渐变动画。\n图片变色、波纹扭曲 → 后续课程：还需要取图与采样，本课未实现。',
        ),
        const SizedBox(height: 12),
        const Text(
          '卡片扫光调优：先暂停并保持亮带居中 → 比较扫光控制区的两个预设 → 再调一个参数。窄亮带更集中，宽亮带覆盖更多；柔和度越大，边缘过渡越宽；扫过秒数越大，移动越慢。',
        ),
        const SizedBox(height: 8),
        const Text(
          '性能调优：先确认是否需要持续动画，再比较绘制区域和更新范围。加载资源放在初始化，退出时释放。最终效果与帧耗时应分别验证，不能从视觉参数推断性能收益。',
        ),
      ],
    ),
  );
}
