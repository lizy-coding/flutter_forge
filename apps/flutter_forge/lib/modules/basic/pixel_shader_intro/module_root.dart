import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'drawing_canvas.dart';
import 'drawing_model.dart';

class PixelShaderIntroPage extends StatefulWidget {
  const PixelShaderIntroPage({super.key});

  @override
  State<PixelShaderIntroPage> createState() => _PixelShaderIntroPageState();
}

class _PixelShaderIntroPageState extends State<PixelShaderIntroPage> {
  final _stepAnchor = GlobalKey();
  int _step = 0;
  double _width = 200;
  bool _proportional = false;
  DrawingMethod _method = DrawingMethod.rectangle;
  Offset _position = const Offset(50, 50);

  DrawingRule get _rule =>
      DrawingRule(width: _width, proportional: _proportional);

  void _startStep(int step) {
    setState(() {
      _step = step;
      _width = 200;
      _proportional = step == 2;
      _method = step == 0 ? DrawingMethod.rectangle : DrawingMethod.samples;
      _position = const Offset(50, 50);
    });
    final anchor = _stepAnchor.currentContext;
    if (anchor != null) unawaited(Scrollable.ensureVisible(anchor));
  }

  @override
  Widget build(BuildContext context) {
    final rule = _rule;
    final sample = rule.sample(_position);
    const titles = ['先画一个形状', '换成逐位置算颜色', '用比例描述位置：UV'];
    const explanations = [
      '目标：让画布左半边变蓝。画布宽 200、高 100，直接画一个宽 100、高 100 的蓝色矩形即可。',
      '换一种描述：对每个位置问“x 小于 100 吗？”是就给蓝色，否则给白色。把各个位置的结果放在一起，也能得到同样的蓝色区域。',
      '把画布加宽到 400。固定 x < 100 只占四分之一；U = x ÷ 宽度，判断 U < 0.5 才能始终得到左半边。V 同样表示纵向位置的比例。',
    ];
    return LearningScaffold(
      title: '绘制入门：从画形状到算颜色',
      interactiveDemo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyedSubtree(
            key: _stepAnchor,
            child: Text(
              '第 ${_step + 1} 步 / 共 3 步',
              key: const Key('intro-step'),
            ),
          ),
          const SizedBox(height: 8),
          Text(titles[_step], style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(explanations[_step]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('intro-previous'),
                onPressed: _step == 0 ? null : () => _startStep(_step - 1),
                child: const Text('上一步'),
              ),
              FilledButton(
                key: const Key('intro-next'),
                onPressed: _step == 2 ? null : () => _startStep(_step + 1),
                child: const Text('下一步'),
              ),
              TextButton(
                onPressed: () => _startStep(_step),
                child: const Text('复位本步'),
              ),
            ],
          ),
          if (_step >= 1) ...[
            const SizedBox(height: 12),
            const Text('同一个目标，两种描述方式：'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in DrawingMethod.values)
                  ChoiceChip(
                    label: Text(
                      method == DrawingMethod.rectangle ? '直接画矩形' : '逐位置算颜色',
                    ),
                    selected: _method == method,
                    onSelected: (_) => setState(() => _method = method),
                  ),
              ],
            ),
          ],
          if (_step == 2) ...[
            const SizedBox(height: 12),
            const Text('先加宽画布，再比较两条规则：'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final width in [200.0, 400.0])
                  ChoiceChip(
                    label: Text('宽 ${width.toInt()}'),
                    selected: _width == width,
                    onSelected: (_) => setState(() {
                      _width = width;
                      _position = _rule.sample(_position).position;
                    }),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final proportional in [false, true])
                  ChoiceChip(
                    label: Text(proportional ? '宽度比例 U < 0.5' : '固定坐标 x < 100'),
                    selected: _proportional == proportional,
                    onSelected: (_) =>
                        setState(() => _proportional = proportional),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('画布：${_width.toInt()} × 100；蓝色区域宽 ${rule.blueBoundary.toInt()}'),
          const SizedBox(height: 8),
          DrawingCanvas(
            rule: rule,
            method: _method,
            position: sample.position,
            onPositionChanged: (position) => setState(() {
              _position = Offset(
                position.dx.roundToDouble(),
                position.dy.roundToDouble(),
              );
            }),
          ),
          const SizedBox(height: 8),
          const Text('左上角是 (0, 0)，x 向右增加，y 向下增加。点击或拖动圆点查看一个位置。'),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () =>
                    setState(() => _position = Offset(_width / 4, 50)),
                child: const Text('选择左侧位置'),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _position = Offset(_width * 3 / 4, 50)),
                child: const Text('选择右侧位置'),
              ),
            ],
          ),
          Text(
            '选中位置：x = ${sample.position.dx.toStringAsFixed(0)}，y = ${sample.position.dy.toStringAsFixed(0)}',
            key: const Key('intro-position'),
          ),
          if (_step == 2)
            Text(
              'U = ${sample.position.dx.toStringAsFixed(0)} ÷ ${_width.toInt()} = ${sample.uv.dx}\n'
              'V = ${sample.position.dy.toStringAsFixed(0)} ÷ 100 = ${sample.uv.dy}',
              key: const Key('intro-uv'),
            ),
          const SizedBox(height: 8),
          Text(
            _step == 0
                ? '这个位置${sample.blue ? '在' : '不在'}蓝色矩形内 → ${sample.blue ? '蓝色' : '白色'}'
                : '${_proportional ? 'U < 0.5' : 'x < 100'}：${sample.blue ? '成立' : '不成立'} → 输出${sample.blue ? '蓝色' : '白色'}',
            key: const Key('intro-result'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            _method == DrawingMethod.rectangle
                ? '当前描述：从左上角画一个宽 ${rule.blueBoundary.toInt()}、高 100 的蓝色矩形。'
                : '当前描述：给每一格的中心计算颜色，再填满网格。每格是放大的采样示意，不是一个真实屏幕像素。',
          ),
          if (_step == 2) ...[
            const SizedBox(height: 12),
            const Text('UV 没有改变绘制方式，它只是把位置换成比例。Canvas 画矩形也能使用这个比例。'),
            const SizedBox(height: 8),
            const Text(
              '片元 Shader 会为绘制区域中的片元计算颜色；入门时可以先把片元近似理解为待绘制的像素。本页用 Dart 和 Canvas 演示这条思路，后续课程再把规则写成真正的 Shader。',
            ),
            TextButton(
              onPressed: () => _startStep(0),
              child: const Text('从第一步重新学习'),
            ),
          ],
        ],
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '区分“指定形状”与“按位置计算颜色”两种描述画面的思路',
            '通过加宽同一张画布，理解固定坐标和 UV 比例的区别',
          ],
        ),
        CommonPitfalls(
          pitfalls: [
            '画布坐标与屏幕物理像素不是同一回事；示意画布会整体缩放以适应窗口。',
            'UV 是坐标比例，Shader 是计算颜色的程序，两者不能画等号。',
            'Canvas 绘制也可能由 GPU 执行；这里比较的是描述方式，不是 CPU 与 GPU 的性能。',
          ],
        ),
        ExerciseCard(
          task: '到第三步把画布加宽到 400，比较两条规则：哪一条仍然能让左半边变蓝？',
          hint: '固定 100 占 400 的四分之一；0.5 表示当前宽度的一半。',
        ),
      ],
    );
  }
}
