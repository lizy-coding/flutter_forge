import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

enum _LayoutMode { row, column, wrap }

class ConstraintLayoutPage extends StatefulWidget {
  const ConstraintLayoutPage({super.key});

  @override
  State<ConstraintLayoutPage> createState() => _ConstraintLayoutPageState();
}

class _ConstraintLayoutPageState extends State<ConstraintLayoutPage> {
  double _widthFactor = 1;
  double _parentHeight = 160;
  bool _resizing = false;
  Offset _resizeOrigin = Offset.zero;
  Size _resizeStartSize = Size.zero;
  double _requestedWidth = 120;
  double _requestedHeight = 80;
  bool _tight = false;
  _LayoutMode _mode = _LayoutMode.row;

  void _reset() {
    setState(() {
      _widthFactor = 1;
      _parentHeight = 160;
      _resizing = false;
      _requestedWidth = 120;
      _requestedHeight = 80;
      _tight = false;
      _mode = _LayoutMode.row;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '约束与声明式布局',
      interactiveDemo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '拖动橙色手柄改变父约束，观察蓝色子组件如何响应。',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          _slider(
            label: '父容器宽度',
            value: _widthFactor,
            min: 0.4,
            max: 1,
            valueLabel: '${(_widthFactor * 100).round()}% 可用宽度',
            sliderKey: 'parent-width',
            onChanged: (value) => setState(() => _widthFactor = value),
          ),
          _slider(
            label: '父容器高度',
            value: _parentHeight,
            min: 80,
            max: 240,
            valueLabel: '${_parentHeight.round()} dp',
            sliderKey: 'parent-height',
            onChanged: (value) => setState(() => _parentHeight = value),
          ),
          _slider(
            label: '子组件期望宽度',
            value: _requestedWidth,
            min: 60,
            max: 360,
            valueLabel: '${_requestedWidth.round()} dp',
            sliderKey: 'requested-width',
            onChanged: (value) => setState(() => _requestedWidth = value),
          ),
          _slider(
            label: '子组件期望高度',
            value: _requestedHeight,
            min: 40,
            max: 200,
            valueLabel: '${_requestedHeight.round()} dp',
            sliderKey: 'requested-height',
            onChanged: (value) => setState(() => _requestedHeight = value),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('松约束'),
                selected: !_tight,
                onSelected: (_) => setState(() => _tight = false),
              ),
              ChoiceChip(
                label: const Text('紧约束'),
                selected: _tight,
                onSelected: (_) => setState(() => _tight = true),
              ),
              OutlinedButton.icon(
                key: const ValueKey('reset-layout'),
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('重置实验'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('实验一：约束向下传递，尺寸向上返回'),
          const SizedBox(height: 8),
          _boundaryLegend(),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, available) {
              final parentSize = Size(
                available.maxWidth * _widthFactor,
                _parentHeight,
              );
              final childConstraints = _tight
                  ? BoxConstraints.tight(parentSize)
                  : BoxConstraints.loose(parentSize);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('父容器：${_sizeLabel(parentSize)}'),
                  Text(
                    '传给子组件：宽 ${childConstraints.minWidth.round()}'
                    '～${childConstraints.maxWidth.round()}，'
                    '高 ${childConstraints.minHeight.round()}'
                    '～${childConstraints.maxHeight.round()} dp',
                    key: const ValueKey('constraint-readout'),
                  ),
                  const SizedBox(height: 8),
                  _resizableParent(
                    parentSize,
                    available.maxWidth,
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _parentColor,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      position: DecorationPosition.foreground,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _parentColor.withValues(alpha: 0.08),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: childConstraints,
                            child: SizedBox(
                              width: _requestedWidth,
                              height: _requestedHeight,
                              child: LayoutBuilder(
                                builder: (context, actual) {
                                  return DecoratedBox(
                                    key: const ValueKey('constrained-child'),
                                    decoration: BoxDecoration(
                                      color: _childColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      border: Border.all(
                                        color: _childColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(
                                            '子组件实际尺寸\n${_sizeLabel(actual.biggest)}',
                                            key: const ValueKey('actual-size'),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _childColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    _resizing
                        ? '拖动中：父约束 → 子组件尺寸 → 布局更新'
                        : '拖动右下角橙色手柄调整宽高；也可使用上方滑杆。',
                    key: const ValueKey('resize-feedback'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tight
                        ? '紧约束下父子边界重合：橙色外边线与蓝色内边线同时显示，期望尺寸必须服从父约束。'
                        : '橙色框限定父容器范围，蓝色框显示子组件实际尺寸；浅橙色区域是剩余空间。',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('实验二：同一份数据，用状态声明布局'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in _LayoutMode.values)
                ChoiceChip(
                  label: Text(_modeLabel(mode)),
                  selected: _mode == mode,
                  onSelected: (_) => setState(() => _mode = mode),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('拖动下方横向手柄缩放父宽，观察均分、纵向排列与自动换行。'),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, available) {
              final width = available.maxWidth * _widthFactor;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '当前父宽：${width.round()} dp',
                        key: const ValueKey('layout-width-readout'),
                      ),
                      const SizedBox(height: 8),
                      _layoutTransition(),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _resizeHandle(
                          parentSize: Size(width, _parentHeight),
                          availableWidth: available.maxWidth,
                          widthOnly: true,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(switch (_mode) {
            _LayoutMode.row => 'Row + Expanded：三个组件均分横向空间。',
            _LayoutMode.column => 'Column：三个组件沿纵向排列。',
            _LayoutMode.wrap => 'Wrap：组件期望宽度为 96 dp，空间不足时自动换行。',
          }),
        ],
      ),
      sections: [
        const LearningObjectives(
          objectives: [
            '理解父组件传递约束、子组件返回尺寸、父组件决定位置的布局过程',
            '对比松约束与紧约束，解释期望尺寸与实际尺寸为何不同',
            '拖动父约束，观察实时布局；通过状态声明 Row、Column 与 Wrap 的空间分配',
          ],
        ),
        const ConceptChips(
          concepts: [
            'BoxConstraints',
            'LayoutBuilder',
            'SizedBox',
            'Row',
            'Column',
            'Wrap',
            '声明式 UI',
          ],
        ),
        CodeSnippetCard(
          title: '当前约束声明',
          code:
              '''// Align 为子组件提供松约束，ConstrainedBox 再限定范围。
Align(
  alignment: Alignment.topLeft,
  child: ConstrainedBox(
    constraints: BoxConstraints.${_tight ? 'tight' : 'loose'}(parentSize),
    child: SizedBox(
      width: ${_requestedWidth.round()},
      height: ${_requestedHeight.round()},
      child: LayoutBuilder(builder: (context, constraints) {
        // 此处读取的是 SizedBox 布局后的紧约束。
        return YourChild();
      }),
    ),
  ),
)''',
          explanation: 'SizedBox 表达期望尺寸，并不能突破父组件给出的约束。尺寸单位为逻辑像素。',
        ),
        CodeSnippetCard(
          title: '当前布局声明：${_modeLabel(_mode)}',
          code: switch (_mode) {
            _LayoutMode.row =>
              '''Row(
  children: [
    for (final item in items)
      Expanded(child: ItemCard(item)),
  ],
)''',
            _LayoutMode.column =>
              '''Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [for (final item in items) ItemCard(item)],
)''',
            _LayoutMode.wrap =>
              '''Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    for (final item in items)
      SizedBox(width: 96, child: ItemCard(item)),
  ],
)''',
          },
          explanation:
              '点击选项只更新布局状态；build 根据状态返回对应的 Widget 树，框架负责重新布局。代码省略卡片样式与间距。',
        ),
        const CommonPitfalls(
          pitfalls: [
            '把 width 当成最终尺寸：父组件的约束仍然优先。',
            '把 LayoutBuilder 的约束当成屏幕尺寸：它读取的是当前位置的父约束。',
            '在无界的主轴上使用 Expanded：例如垂直滚动容器中的 Column，需要先提供有限高度。',
            '声明式布局仍需约束：setState 更新状态，不会自动解决布局溢出。',
          ],
        ),
        const ExerciseCard(
          task:
              '将期望尺寸设为 360×200dp，拖动橙色手柄缩小父框，再切换紧约束重复拖动。选择 Wrap，拖动横向手柄找到 A、B、C 的换行临界点。',
          hint: '松约束下期望尺寸被上限限制；紧约束下实际尺寸始终等于父容器尺寸。',
        ),
      ],
    );
  }

  Duration get _motionDuration =>
      MediaQuery.of(context).disableAnimations || _resizing
      ? Duration.zero
      : const Duration(milliseconds: 250);

  Widget _layoutTransition() {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: _parentColor,
          width: 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      position: DecorationPosition.foreground,
      child: ColoredBox(
        color: _parentColor.withValues(alpha: 0.08),
        child: _motionDuration == Duration.zero
            ? _declaredLayout()
            : AnimatedSwitcher(
                duration: _motionDuration,
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                ),
                child: KeyedSubtree(
                  key: ValueKey(_mode),
                  child: _declaredLayout(),
                ),
              ),
      ),
    );
    // 零时长直接布局，避免拖拽时动画追赶手势，也兼容减少动态效果。
    if (_motionDuration == Duration.zero) {
      return SizedBox(
        key: const ValueKey('layout-size-transition'),
        child: content,
      );
    }
    return AnimatedSize(
      key: const ValueKey('layout-size-transition'),
      duration: _motionDuration,
      alignment: Alignment.topLeft,
      curve: Curves.easeInOut,
      clipBehavior: Clip.none,
      child: content,
    );
  }

  Widget _resizableParent(Size size, double availableWidth, Widget child) {
    // 固定操作区域，拖拽时后面的说明和手柄不会因内容流动而跳动。
    return SizedBox(
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: SizedBox.fromSize(
              key: const ValueKey('constraint-parent'),
              size: size,
              child: child,
            ),
          ),
          Positioned(
            left: size.width - 40,
            top: size.height - 40,
            child: _resizeHandle(
              parentSize: size,
              availableWidth: availableWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resizeHandle({
    required Size parentSize,
    required double availableWidth,
    bool widthOnly = false,
  }) {
    final label = widthOnly ? '拖动调整父容器宽度' : '拖动调整父容器宽高';
    return Semantics(
      label: label,
      child: Tooltip(
        message: label,
        child: MouseRegion(
          cursor: widthOnly
              ? SystemMouseCursors.resizeLeftRight
              : SystemMouseCursors.resizeDownRight,
          child: GestureDetector(
            key: ValueKey(
              widthOnly ? 'layout-width-handle' : 'parent-resize-handle',
            ),
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onPanDown: (details) {
              _resizeOrigin = details.globalPosition;
              _resizeStartSize = parentSize;
            },
            onPanStart: (_) => setState(() => _resizing = true),
            onPanUpdate: (details) {
              final delta = details.globalPosition - _resizeOrigin;
              setState(() {
                _widthFactor =
                    ((_resizeStartSize.width + delta.dx) / availableWidth)
                        .clamp(0.4, 1.0);
                if (!widthOnly) {
                  _parentHeight = (_resizeStartSize.height + delta.dy).clamp(
                    80.0,
                    240.0,
                  );
                }
              });
            },
            onPanEnd: (_) => setState(() => _resizing = false),
            onPanCancel: () => setState(() => _resizing = false),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                widthOnly ? Icons.swap_horiz : Icons.open_in_full,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _parentColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.orange.shade300
      : Colors.deepOrange.shade700;

  Color get _childColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.lightBlue.shade300
      : Colors.blue.shade800;

  Widget _boundaryLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final entry in [
          (_parentColor, '父容器 · 约束范围'),
          (_childColor, '子组件 · 实际尺寸'),
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: entry.$1.withValues(alpha: 0.12),
                  border: Border.all(color: entry.$1, width: 2),
                ),
              ),
              const SizedBox(width: 6),
              Text(entry.$2),
            ],
          ),
      ],
    );
  }

  Widget _declaredLayout() {
    final children = [
      for (final label in ['A', 'B', 'C'])
        Container(
          key: ValueKey('layout-item-$label'),
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _childColor.withValues(alpha: 0.12),
            border: Border.all(color: _childColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: TextStyle(color: _childColor)),
        ),
    ];
    return switch (_mode) {
      _LayoutMode.row => Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: children[i]),
          ],
        ],
      ),
      _LayoutMode.column => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            children[i],
          ],
        ],
      ),
      _LayoutMode.wrap => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final child in children) SizedBox(width: 96, child: child),
        ],
      ),
    };
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String valueLabel,
    required String sliderKey,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label：$valueLabel'),
        Slider(
          key: ValueKey(sliderKey),
          value: value,
          min: min,
          max: max,
          divisions: 30,
          label: valueLabel,
          semanticFormatterCallback: (_) => '$label：$valueLabel',
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _sizeLabel(Size size) =>
      '${size.width.round()} × ${size.height.round()} dp';

  String _modeLabel(_LayoutMode mode) => switch (mode) {
    _LayoutMode.row => 'Row',
    _LayoutMode.column => 'Column',
    _LayoutMode.wrap => 'Wrap',
  };
}
