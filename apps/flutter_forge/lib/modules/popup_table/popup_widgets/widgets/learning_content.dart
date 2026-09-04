import 'package:flutter/widgets.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

List<Widget> buildPopupLearningSections() {
  return const [
    LearningObjectives(
      objectives: [
        '掌握 Flutter 中多种弹窗的创建方式',
        '理解 AlertDialog、SimpleDialog、BottomSheet 的区别与适用场景',
        '掌握通过 Navigator 管理链式对话框',
        '学习使用 OverlayEntry 自定义弹窗',
        '理解 ContextMenu（showMenu）的触发方式',
      ],
    ),
    ConceptChips(
      concepts: [
        'showDialog',
        'AlertDialog',
        'SimpleDialog',
        'BottomSheet',
        'showMenu',
        'OverlayEntry',
        'Navigator',
        'showDatePicker',
        'showTimePicker',
      ],
    ),
    CodeSnippetCard(
      title: 'AlertDialog 基础用法',
      code:
          'Future<void> showAlertDialog() async {\n'
          '  await showDialog<void>(\n'
          '    context: context,\n'
          '    builder: (context) => AlertDialog(\n'
          '      title: Text(\'提示\'),\n'
          '      content: Text(\'这是 AlertDialog\'),\n'
          '      actions: [\n'
          '        TextButton(\n'
          '          onPressed: () => Navigator.pop(context),\n'
          '          child: Text(\'确定\'),\n'
          '        ),\n'
          '      ],\n'
          '    ),\n'
          '  );\n'
          '}',
      explanation: 'showDialog + AlertDialog 是最常用的弹窗组合。',
    ),
    CodeSnippetCard(
      title: 'Modal Bottom Sheet',
      code:
          'Future<void> showBottomSheetDemo() async {\n'
          '  await showModalBottomSheet<void>(\n'
          '    context: context,\n'
          '    showDragHandle: true,\n'
          '    builder: (context) => SafeArea(\n'
          '      child: Padding(\n'
          '        padding: EdgeInsets.all(16),\n'
          '        child: Column(\n'
          '          mainAxisSize: MainAxisSize.min,\n'
          '          children: [\n'
          '            Text(\'底部弹窗\'),\n'
          '            ElevatedButton(\n'
          '              onPressed: () => Navigator.pop(context),\n'
          '              child: Text(\'关闭\'),\n'
          '            ),\n'
          '          ],\n'
          '        ),\n'
          '      ),\n'
          '    ),\n'
          '  );\n'
          '}',
      explanation: 'showModalBottomSheet 从屏幕底部滑入，支持拖动关闭。',
    ),
    CommonPitfalls(
      pitfalls: [
        '忘记 Navigator.pop(context) — 对话框不会自动关闭，需要在按钮回调中显式调用 Navigator.pop(context)',
        'context 生命周期 — 异步操作后需检查 mounted，否则调用 Navigator.pop(context) 可能抛异常',
        'showDialog 与 showCupertinoDialog 使用不同的主题上下文，不可混用',
        'OverlayEntry 需手动管理 — 不会自动释放，必须在 dispose 时清理所有 entry',
      ],
    ),
    ExerciseCard(
      task: '创建一个包含输入框的自定义对话框，用户输入文字后点击"提交"，在 SnackBar 中显示输入内容。',
      hint:
          '使用 showDialog + AlertDialog，在 builder 中使用 TextField，通过 Navigator.pop(context, inputValue) 返回结果。',
    ),
  ];
}
