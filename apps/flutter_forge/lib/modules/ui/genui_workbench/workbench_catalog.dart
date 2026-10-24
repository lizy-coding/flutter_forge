import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'genui_session.dart';
import 'workbench_protocol.dart';

Catalog buildWorkbenchCatalog(GenuiSession session) {
  CatalogItem item(
    String name,
    Widget Function(CatalogItemContext) builder, {
    Map<String, Schema> properties = const {},
    List<String> required = const [],
  }) => CatalogItem(
    name: name,
    dataSchema: S.object(properties: properties, required: required),
    widgetBuilder: builder,
  );

  return Catalog([
    item(
      'LabColumn',
      (context) {
        final children = (context.data as Map)['children'] as List;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final id in children)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: context.buildChild(id as String),
              ),
          ],
        );
      },
      properties: {'children': S.list(items: S.string())},
      required: ['children'],
    ),
    item(
      'Note',
      (context) => Text((context.data as Map)['text'] as String),
      properties: {'text': S.string(maxLength: 2000)},
      required: ['text'],
    ),
    item(
      'NumberControl',
      (context) {
        final field = (context.data as Map)['field'] as String;
        final value = (session.value(field) as num).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${field == 'parentWidth' ? '父容器最大宽度' : '子组件期望宽度'}：${value.round()} dp',
            ),
            Slider(
              key: ValueKey('genui-$field'),
              min: 60,
              max: 300,
              divisions: 24,
              value: value,
              label: '${value.round()} dp',
              onChanged: session.busy
                  ? null
                  : (value) => session.updateParameter(field, value),
            ),
          ],
        );
      },
      properties: {
        'field': S.string(enumValues: ['parentWidth', 'requestedWidth']),
      },
      required: ['field'],
    ),
    item(
      'ModeControl',
      (context) => Wrap(
        spacing: 8,
        children: [
          for (final tight in [false, true])
            ChoiceChip(
              label: Text(tight ? '紧约束' : '松约束'),
              selected: session.value('tight') == tight,
              onSelected: session.busy
                  ? null
                  : (_) => session.updateParameter('tight', tight),
            ),
        ],
      ),
    ),
    item('ConstraintPreview', (context) => ConstraintPreview(session: session)),
    item(
      'Observation',
      (context) => Text(
        session.observationReady
            ? 'Flutter 实际尺寸：${session.actualWidth!.toStringAsFixed(0)} × '
                  '${session.actualHeight!.toStringAsFixed(0)} dp · 状态 v${session.revision}'
            : '正在等待 Flutter 布局结果…',
        key: const ValueKey('genui-observation'),
      ),
    ),
    item(
      'ExplainAction',
      (context) => Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          onPressed: session.busy || !session.observationReady
              ? null
              : () => session.explain(context),
          icon: const Icon(Icons.psychology_outlined),
          label: const Text('解释当前结果'),
        ),
      ),
    ),
  ], catalogId: workbenchCatalogId);
}

class ConstraintPreview extends StatefulWidget {
  const ConstraintPreview({super.key, required this.session});
  final GenuiSession session;

  @override
  State<ConstraintPreview> createState() => _ConstraintPreviewState();
}

class _ConstraintPreviewState extends State<ConstraintPreview> {
  final _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final parent = (session.value('parentWidth') as num).toDouble();
    final requested = (session.value('requestedWidth') as num).toDouble();
    final tight = session.value('tight') as bool;
    final revision = session.revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _childKey.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        session.observe(revision, box.size.width, box.size.height);
      }
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('橙色为父容器，蓝色为子组件。窄窗口按比例显示，尺寸单位仍为逻辑 dp。'),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 320,
              height: 110,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: parent,
                  height: 90,
                  color: Colors.orange.withValues(alpha: 0.2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: tight
                          ? BoxConstraints.tightFor(width: parent, height: 60)
                          : BoxConstraints(maxWidth: parent, maxHeight: 60),
                      child: SizedBox(
                        key: _childKey,
                        width: requested,
                        height: 60,
                        child: const ColoredBox(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
