import 'package:flutter/material.dart';

class PersistentBottomSheetBar extends StatelessWidget {
  const PersistentBottomSheetBar({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined),
          const SizedBox(width: 8),
          const Expanded(child: Text('这是一个持久化底部工具条，你可以手动关闭。')),
          TextButton(onPressed: onClose, child: const Text('关闭')),
        ],
      ),
    );
  }
}

class ModalBottomSheetContent extends StatelessWidget {
  const ModalBottomSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '这是一个模态底部弹窗',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('确定'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OverlayOrderEditor extends StatefulWidget {
  const OverlayOrderEditor({
    super.key,
    required this.fixedIds,
    required this.initialOpen,
    required this.initialClose,
    required this.onSave,
  });

  final List<String> fixedIds;
  final List<String> initialOpen;
  final List<String> initialClose;
  final void Function(List<String> open, List<String> close) onSave;

  @override
  State<OverlayOrderEditor> createState() => _OverlayOrderEditorState();
}

class _OverlayOrderEditorState extends State<OverlayOrderEditor> {
  late List<String> _openOrder;
  late List<String> _closeOrder;

  @override
  void initState() {
    super.initState();
    _openOrder = List<String>.of(widget.initialOpen);
    _closeOrder = List<String>.of(widget.initialClose);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '编辑 Overlay 打开顺序',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _OrderList(
                keyPrefix: 'open',
                ids: _openOrder,
                onReorder: _reorderOpen,
              ),
              const SizedBox(height: 12),
              Text(
                '编辑 Overlay 关闭顺序',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _OrderList(
                keyPrefix: 'close',
                ids: _closeOrder,
                onReorder: _reorderClose,
              ),
              const SizedBox(height: 12),
              Text(
                '固定代号：${widget.fixedIds.join('、')}（仅顺序可调）',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _EditorActions(
                onReset: _reset,
                onSave: () {
                  widget.onSave(_openOrder, _closeOrder);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reorderOpen(int oldIndex, int newIndex) {
    setState(() => _reorder(_openOrder, oldIndex, newIndex));
  }

  void _reorderClose(int oldIndex, int newIndex) {
    setState(() => _reorder(_closeOrder, oldIndex, newIndex));
  }

  void _reset() {
    setState(() {
      _openOrder = List<String>.of(widget.fixedIds);
      _closeOrder = List<String>.of(widget.fixedIds.reversed);
    });
  }

  void _reorder(List<String> ids, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.keyPrefix,
    required this.ids,
    required this.onReorder,
  });

  final String keyPrefix;
  final List<String> ids;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: true,
      onReorder: onReorder,
      children: [
        for (final id in ids)
          ListTile(
            key: ValueKey('$keyPrefix-$id'),
            title: Text('代号 $id'),
            trailing: const Icon(Icons.drag_handle),
          ),
      ],
    );
  }
}

class _EditorActions extends StatelessWidget {
  const _EditorActions({required this.onReset, required this.onSave});

  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: onReset, child: const Text('重置')),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: onSave, child: const Text('保存')),
      ],
    );
  }
}
