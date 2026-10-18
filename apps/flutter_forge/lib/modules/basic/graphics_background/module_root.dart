import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:go_router/go_router.dart';

import 'texture_sample.dart';

const _chapters = [
  (
    title: '先理解画面：把照片放进一个矩形',
    question: '应用想显示一张照片，需要决定什么？',
    terms: [
      (
        '像素 Pixel',
        '可以先把图像看成许多小格子，每格有一种颜色。所有格子的颜色合起来，形成你看到的图像。',
        '这里说的是图像构成；Flutter 的布局坐标并不直接等于屏幕物理像素。',
      ),
      (
        '矩形与 Canvas',
        '矩形确定画面的显示范围。Canvas 是 Flutter 提供的绘制接口，可以提交画矩形、线条、图片等命令。',
        '先确定“画到哪里”，再确定“这些位置呈现什么颜色”。Canvas 不是一块硬件。',
      ),
    ],
    takeaway: '显示照片，需要有显示区域，也需要有图像内容。',
  ),
  (
    title: '认识 GPU 与纹理：谁执行，内容从哪里来',
    question: '图片内容怎样参与绘制？计算由谁执行？',
    terms: [
      (
        'GPU：图形处理器',
        'GPU 是一种处理器，擅长并行处理大量图形计算。应用和 CPU 准备数据、提交绘制工作，GPU 参与把它们变成画面。',
        'Flutter 的渲染引擎负责衔接这些工作，所以平时写 Widget 不必直接操作 GPU。不能据此认为 Canvas 一定只在 CPU 上绘制。',
      ),
      (
        '纹理 Texture',
        '常见纹理就是供绘制读取颜色的图片。显示照片时，照片可以作为纹理，给矩形里的位置提供颜色。',
        '纹理是数据，不是负责执行计算的程序。为看清取色位置，本课用四块颜色代替照片细节。',
      ),
    ],
    takeaway: 'GPU 是执行计算的硬件；纹理是提供颜色的数据。',
  ),
  (
    title: '认识 UV：从图片的哪里取颜色',
    question: '矩形中的一个位置，应该使用图片的哪一处颜色？',
    terms: [
      (
        'UV：纹理位置的坐标',
        'U 和 V 是两条坐标轴的名字。本课用 U 描述横向比例、V 描述纵向比例，约定左上角是 (0,0)，右下角是 (1,1)，中心是 (0.5,0.5)。',
        '选择图片四个色块的中心，观察 UV 如何指定取色位置。其他图形接口的方向约定可能不同，UV 也不总被限制在 0～1。',
      ),
      (
        '显示位置与取色位置',
        '屏幕或画布坐标描述“画面显示在哪里”；UV 描述“从图片哪里取颜色”。这里讨论的是两个不同空间中的位置。',
        '把示意图片显示得更大，同一个 UV 仍能指向同一块颜色。下一课再用 x ÷ 宽度推导它。',
      ),
    ],
    takeaway: 'UV 是位置数据，不是一种处理器，也不是一种绘制程序。',
  ),
  (
    title: '认识 Shader：决定怎样得到颜色',
    question: '知道取色位置之后，这个位置最终输出什么颜色？',
    terms: [
      (
        'Shader：着色器程序',
        'Shader 是参与图形渲染的小程序，通常在 GPU 上执行。图形管线中有不同种类：顶点着色器处理顶点位置等数据，片元着色器计算绘制区域中片元的输出颜色。',
        '本系列关注 Flutter 的自定义片元着色器。入门时可把片元近似理解为待着色的像素；Flutter 这里的接口不提供自定义顶点着色器。',
      ),
      (
        '片元着色器与取色规则',
        '显示照片时，可以按 UV 读取纹理颜色再输出；做灰度效果时，可以把读到的颜色转换后输出。也可以不读取图片，直接计算渐变颜色。',
        'UV 是输入位置，纹理是输入数据，Shader 是处理规则，GPU 是执行硬件。它们各自承担不同职责。',
      ),
    ],
    takeaway: '本课先认清角色；下一课观察颜色规则，再到 Shader 模块学习真正的 GLSL 程序。',
  ),
];

class GraphicsBackgroundPage extends StatefulWidget {
  const GraphicsBackgroundPage({super.key});

  @override
  State<GraphicsBackgroundPage> createState() => _GraphicsBackgroundPageState();
}

class _GraphicsBackgroundPageState extends State<GraphicsBackgroundPage> {
  final _anchor = GlobalKey();
  int _chapter = 0;
  TextureSample _sample = TextureSample.topLeft;
  bool _large = false;
  bool _grayscale = false;

  void _openChapter(int chapter) {
    setState(() {
      _chapter = chapter;
      _sample = TextureSample.topLeft;
      _large = false;
      _grayscale = false;
    });
    final anchor = _anchor.currentContext;
    if (anchor != null) unawaited(Scrollable.ensureVisible(anchor));
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _chapters[_chapter];
    final output = _sample.outputColor(grayscale: _grayscale);
    return LearningScaffold(
      title: '图形绘制背景：认识 GPU、纹理与 Shader',
      interactiveDemo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyedSubtree(
            key: _anchor,
            child: Text(
              '第 ${_chapter + 1} 节 / 共 4 节',
              key: const Key('background-chapter'),
            ),
          ),
          const SizedBox(height: 8),
          Text(chapter.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            chapter.question,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('background-previous'),
                onPressed: _chapter == 0
                    ? null
                    : () => _openChapter(_chapter - 1),
                child: const Text('上一节'),
              ),
              FilledButton(
                key: const Key('background-next'),
                onPressed: _chapter == 3
                    ? null
                    : () => _openChapter(_chapter + 1),
                child: const Text('下一节'),
              ),
              TextButton(
                onPressed: () => _openChapter(_chapter),
                child: const Text('复位本节'),
              ),
            ],
          ),
          for (final term in chapter.terms) ...[
            const SizedBox(height: 20),
            Text(term.$1, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(term.$2),
            const SizedBox(height: 8),
            Text(term.$3),
          ],
          const SizedBox(height: 20),
          const Text('示意图片：四块颜色组成一张图'),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (_large ? 300.0 : 200.0).clamp(
                0.0,
                constraints.maxWidth,
              );
              return SizedBox(
                width: width,
                height: width / 2,
                child: Column(
                  children: [
                    for (var row = 0; row < 2; row++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var column = 0; column < 2; column++)
                              Expanded(
                                child: _TextureCell(
                                  sample:
                                      TextureSample.values[row * 2 + column],
                                  selectable: _chapter >= 2,
                                  onSelected: (sample) =>
                                      setState(() => _sample = sample),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (_chapter >= 2) ...[
            const SizedBox(height: 8),
            const Text('点击色块，取它中心位置的颜色。坐标方向以本课左上角为原点。'),
            TextButton(
              onPressed: () => setState(() => _large = !_large),
              child: Text(_large ? '缩小显示' : '放大显示'),
            ),
            Text(
              '取色位置：${_sample.location}；UV = (${_sample.uv.dx}, ${_sample.uv.dy})',
              key: const Key('background-uv'),
            ),
            Text('读到的纹理颜色：${_sample.colorName}'),
            if (_chapter == 3)
              SwitchListTile(
                key: const Key('background-grayscale'),
                contentPadding: EdgeInsets.zero,
                title: const Text('把读到的颜色变成灰度再输出'),
                value: _grayscale,
                onChanged: (value) => setState(() => _grayscale = value),
              ),
            const SizedBox(height: 8),
            Text(_grayscale ? '规则：读取纹理颜色 → 转换为灰度 → 输出' : '规则：读取纹理颜色 → 原样输出'),
            const SizedBox(height: 8),
            Semantics(
              label: _grayscale ? '选中位置的输出为灰色' : '选中位置的输出为${_sample.colorName}',
              child: Container(
                key: const Key('background-output'),
                width: 100,
                height: 48,
                decoration: BoxDecoration(
                  color: output,
                  border: Border.all(color: Colors.black54),
                ),
              ),
            ),
            Text(
              _grayscale
                  ? '选中位置输出：灰色（${(output.r * 255).round()} / 255）'
                  : '选中位置输出：${_sample.colorName}',
              key: const Key('background-output-label'),
            ),
            const SizedBox(height: 8),
            const Text(
              '上方仍是原始示意图片，下方色块只展示选中位置的输出。本页使用 Canvas 和 Dart 计算来说明职责，不执行自定义 GPU Shader。',
            ),
          ],
          const SizedBox(height: 20),
          Text(
            '这一节记住：${chapter.takeaway}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_chapter == 3) ...[
            const SizedBox(height: 12),
            const Text('理解顺序：本课技术背景 → 绘制入门的颜色规则 → UV 位置与颜色 → 真正的 Shader 程序。'),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () =>
                      unawaited(context.push<void>('/pixel-shader-intro')),
                  child: const Text('继续学习：从画形状到算颜色'),
                ),
                TextButton(
                  onPressed: () => _openChapter(0),
                  child: const Text('从第一节重新学习'),
                ),
              ],
            ),
          ],
        ],
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '先用一句话解释 GPU、纹理、UV 和 Shader 各是什么',
            '能说出显示范围、图片取色位置与颜色处理规则的区别',
            '带着技术背景进入后续坐标与 Shader 课程',
          ],
        ),
        ExerciseCard(
          task: '试着解释：把图片显示得更大，为什么 UV 指向的颜色可以不变？切换灰度规则后，纹理本身是否被改变？',
          hint: 'UV 描述图片上的相对位置；读取颜色后还可以用不同规则处理。',
        ),
      ],
    );
  }
}

class _TextureCell extends StatelessWidget {
  const _TextureCell({
    required this.sample,
    required this.selectable,
    required this.onSelected,
  });

  final TextureSample sample;
  final bool selectable;
  final ValueChanged<TextureSample> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${sample.location}${sample.colorName}色块',
    button: selectable,
    child: Material(
      color: sample.color,
      child: InkWell(
        key: Key('texture-${sample.name}'),
        onTap: selectable ? () => onSelected(sample) : null,
        child: Center(
          child: Text(
            sample.location,
            style: TextStyle(
              color: sample.color.computeLuminance() > 0.179
                  ? Colors.black
                  : Colors.white,
            ),
          ),
        ),
      ),
    ),
  );
}
