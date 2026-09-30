import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:flutter_forge_app/shared/popup/popup_scope.dart';

class PopupPage extends StatefulWidget {
  const PopupPage({super.key});

  @override
  State<PopupPage> createState() => _PopupPageState();
}

class _PopupPageState extends State<PopupPage> {
  final PopupScope _popups = PopupScope();
  String _selection = '尚未选择';
  bool _busy = false;
  bool _cancelled = false;

  Future<void> _choose({required bool bottomSheet}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    Widget options(BuildContext context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final action in ['编辑', '收藏', '取消'])
          ListTile(
            title: Text(action),
            onTap: () =>
                Navigator.of(context).pop(action == '取消' ? null : action),
          ),
      ],
    );
    try {
      final Route<String> route = bottomSheet
          ? ModalBottomSheetRoute<String>(
              builder: (context) => SafeArea(child: options(context)),
              isScrollControlled: false,
              showDragHandle: true,
              capturedThemes: InheritedTheme.capture(
                from: context,
                to: navigator.context,
              ),
              barrierLabel: MaterialLocalizations.of(
                context,
              ).modalBarrierDismissLabel,
            )
          : DialogRoute<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('选择列表动作'),
                content: options(context),
              ),
            );
      final result = await _popups.push(navigator, route);
      if (!mounted) return;
      setState(() {
        _cancelled = result == null;
        if (result != null) _selection = '已选择：$result';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
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
      title: '弹窗组件',
      interactiveDemo: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_selection, key: const Key('popup-action-result')),
            if (_cancelled) const Text('已取消，保留原状态'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: _busy ? null : () => _choose(bottomSheet: false),
                  child: const Text('对话框选择动作'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _choose(bottomSheet: true),
                  child: const Text('底部弹窗选择动作'),
                ),
              ],
            ),
          ],
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: ['通过弹窗返回列表动作', '区分确认、取消与离页关闭', '让页面负责弹窗生命周期'],
        ),
        ConceptChips(
          concepts: [
            'DialogRoute',
            'ModalBottomSheetRoute',
            'Navigator.pop',
            '返回值',
          ],
        ),
        CodeSnippetCard(
          title: '接收弹窗结果',
          code:
              'final result = await popups.push(navigator, route);\nif (!mounted || result == null) return;\nsetState(() => selectedAction = result);',
          explanation: '等待返回值后检查页面生命周期；取消不应提交列表修改。',
        ),
        CommonPitfalls(
          pitfalls: ['不要重复打开同一个动作弹窗', '页面离开后不得写回结果；页面拥有的弹窗应随页面释放'],
        ),
      ],
    );
  }
}
