import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:flutter_forge_app/shared/popup/popup_scope.dart';
import 'package:flutter_forge_app/shared/table/scroll_table.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final PopupScope _popups = PopupScope();
  final List<List<String>> _rows = List.generate(
    12,
    (index) => ['学习任务 ${index + 1}', '待完成', '点击单元格编辑'],
  );
  bool _editing = false;

  Future<void> _edit(int row, int column) async {
    if (_editing) return;
    _editing = true;
    var draft = _rows[row][column];
    try {
      final result = await _popups.push<String>(
        Navigator.of(context),
        DialogRoute<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('编辑单元格'),
            content: TextFormField(
              key: const Key('cell-edit-input'),
              initialValue: draft,
              autofocus: true,
              onChanged: (value) => draft = value,
              onFieldSubmitted: (value) => Navigator.pop(context, value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, draft),
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || result == null) return;
      setState(() => _rows[row][column] = result);
    } finally {
      _editing = false;
    }
  }

  @override
  void dispose() {
    _popups.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '二维滚动表格演示',
      interactiveDemo: SizedBox(
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('点击数据单元格，确认后写回；取消保留原值。'),
            const SizedBox(height: 12),
            Expanded(
              child: ScrollTable(
                columnHeaders: const ['任务', '状态', '备注'],
                rowHeaders: List.generate(
                  _rows.length,
                  (index) => '${index + 1}',
                ),
                data: _rows,
                cellWidth: 160,
                rowHeaderWidth: 56,
                cellHeight: 56,
                onCellTap: _edit,
              ),
            ),
          ],
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: ['观察二维滚动与固定表头', '用弹窗编辑单元格并提交返回值', '取消编辑时保留列表状态'],
        ),
        ConceptChips(concepts: ['TableView', '二维滚动', 'DialogRoute', '草稿与提交']),
        CodeSnippetCard(
          title: '确认后更新单元格',
          code:
              'final result = await popups.push<String>(navigator, dialog);\nif (!mounted || result == null) return;\nsetState(() => rows[row][column] = result);',
          explanation: '弹窗只修改草稿，页面在收到确认结果后更新数据。',
        ),
        CommonPitfalls(pitfalls: ['直接修改列表会使取消操作失效', '销毁页面时要清理仍打开的弹窗']),
        ExerciseCard(
          task: '为单元格编辑增加输入校验，并在空值时保留弹窗。',
          hint: '在提交前检查草稿，验证通过后再 Navigator.pop。',
        ),
      ],
    );
  }
}
