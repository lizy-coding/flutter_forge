import 'package:flutter/material.dart';

import 'bottom_sheet_demo.dart';
import 'context_menu_demo.dart';
import 'dialog_demo_tile.dart';

const List<String> kChainDialogIds = <String>['A', 'B', 'C'];

class ChainOrderStore {
  ChainOrderStore({List<String>? initial})
    : openOrder = ValueNotifier<List<String>>(
        List.of(initial ?? kChainDialogIds),
      ),
      closeOrder = ValueNotifier<List<String>>(
        List.of((initial ?? kChainDialogIds).reversed),
      );

  final ValueNotifier<List<String>> openOrder;
  final ValueNotifier<List<String>> closeOrder;

  void setOrders({required List<String> open, required List<String> close}) {
    openOrder.value = List.of(open);
    closeOrder.value = List.of(close);
  }

  void reset() {
    setOrders(open: kChainDialogIds, close: List.of(kChainDialogIds.reversed));
  }

  void dispose() {
    openOrder.dispose();
    closeOrder.dispose();
  }
}

class PopupDemoInteractiveDemo extends StatelessWidget {
  const PopupDemoInteractiveDemo({
    super.key,
    required this.showBottomSheet,
    required this.orderStore,
    required this.onTogglePersistentBottomSheet,
    required this.onShowAbout,
    required this.onShowDatePicker,
    required this.onShowTimePicker,
    required this.onShowAlertDialog,
    required this.onShowSimpleDialog,
    required this.onShowModalBottomSheet,
    required this.onShowCupertinoAlert,
    required this.onShowCustomDialog,
    required this.onShowContextMenu,
    required this.onDemoOpenChain,
    required this.onDemoCloseChain,
    required this.onDemoOpenOverlayChain,
    required this.onDemoCloseOverlayChain,
    required this.onEditOverlayOrders,
  });

  final bool showBottomSheet;
  final ChainOrderStore orderStore;
  final VoidCallback onTogglePersistentBottomSheet;
  final VoidCallback onShowAbout;
  final Future<void> Function() onShowDatePicker;
  final Future<void> Function() onShowTimePicker;
  final Future<void> Function() onShowAlertDialog;
  final Future<void> Function() onShowSimpleDialog;
  final Future<void> Function() onShowModalBottomSheet;
  final Future<void> Function() onShowCupertinoAlert;
  final Future<void> Function() onShowCustomDialog;
  final Future<void> Function(TapDownDetails) onShowContextMenu;
  final Future<void> Function() onDemoOpenChain;
  final Future<void> Function() onDemoCloseChain;
  final Future<void> Function() onDemoOpenOverlayChain;
  final Future<void> Function() onDemoCloseOverlayChain;
  final Future<void> Function() onEditOverlayOrders;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Column(
        children: [
          _PopupDemoToolbar(
            onShowAbout: onShowAbout,
            onShowDatePicker: onShowDatePicker,
            onShowTimePicker: onShowTimePicker,
          ),
          Expanded(
            child: _PopupDemoList(
              orderStore: orderStore,
              onShowAbout: onShowAbout,
              onShowAlertDialog: onShowAlertDialog,
              onShowSimpleDialog: onShowSimpleDialog,
              onShowModalBottomSheet: onShowModalBottomSheet,
              onShowCupertinoAlert: onShowCupertinoAlert,
              onShowCustomDialog: onShowCustomDialog,
              onShowContextMenu: onShowContextMenu,
              onDemoOpenChain: onDemoOpenChain,
              onDemoCloseChain: onDemoCloseChain,
              onDemoOpenOverlayChain: onDemoOpenOverlayChain,
              onDemoCloseOverlayChain: onDemoCloseOverlayChain,
              onEditOverlayOrders: onEditOverlayOrders,
            ),
          ),
          if (showBottomSheet)
            PersistentBottomSheetBar(onClose: onTogglePersistentBottomSheet),
        ],
      ),
    );
  }
}

class _PopupDemoToolbar extends StatelessWidget {
  const _PopupDemoToolbar({
    required this.onShowAbout,
    required this.onShowDatePicker,
    required this.onShowTimePicker,
  });

  final VoidCallback onShowAbout;
  final Future<void> Function() onShowDatePicker;
  final Future<void> Function() onShowTimePicker;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '显示 AboutDialog',
            onPressed: onShowAbout,
            icon: const Icon(Icons.info_outline),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: '选择更多弹窗',
            onSelected: (value) async {
              switch (value) {
                case 'date':
                  await onShowDatePicker();
                  break;
                case 'time':
                  await onShowTimePicker();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'date', child: Text('日期选择弹窗')),
              PopupMenuItem(value: 'time', child: Text('时间选择弹窗')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 20),
                  SizedBox(width: 4),
                  Text('日期/时间', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupDemoList extends StatelessWidget {
  const _PopupDemoList({
    required this.orderStore,
    required this.onShowAbout,
    required this.onShowAlertDialog,
    required this.onShowSimpleDialog,
    required this.onShowModalBottomSheet,
    required this.onShowCupertinoAlert,
    required this.onShowCustomDialog,
    required this.onShowContextMenu,
    required this.onDemoOpenChain,
    required this.onDemoCloseChain,
    required this.onDemoOpenOverlayChain,
    required this.onDemoCloseOverlayChain,
    required this.onEditOverlayOrders,
  });

  final ChainOrderStore orderStore;
  final VoidCallback onShowAbout;
  final Future<void> Function() onShowAlertDialog;
  final Future<void> Function() onShowSimpleDialog;
  final Future<void> Function() onShowModalBottomSheet;
  final Future<void> Function() onShowCupertinoAlert;
  final Future<void> Function() onShowCustomDialog;
  final Future<void> Function(TapDownDetails) onShowContextMenu;
  final Future<void> Function() onDemoOpenChain;
  final Future<void> Function() onDemoCloseChain;
  final Future<void> Function() onDemoOpenOverlayChain;
  final Future<void> Function() onDemoCloseOverlayChain;
  final Future<void> Function() onEditOverlayOrders;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        DialogDemoTile(
          leading: const Icon(Icons.warning_amber_rounded),
          title: 'AlertDialog (普通对话框)',
          subtitle: '点击触发',
          onTap: onShowAlertDialog,
        ),
        DialogDemoTile(
          leading: const Icon(Icons.list_alt),
          title: 'SimpleDialog (选项对话框)',
          subtitle: '点击右侧图标触发',
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: onShowSimpleDialog,
          ),
        ),
        DialogDemoTile(
          leading: const Icon(Icons.keyboard_double_arrow_up),
          title: 'Modal Bottom Sheet (模态底部弹窗)',
          subtitle: '长按触发',
          onLongPress: onShowModalBottomSheet,
        ),
        const Divider(height: 16),
        CupertinoDoubleTapTile(onDoubleTap: onShowCupertinoAlert),
        DialogDemoTile(
          leading: const Icon(Icons.design_services),
          title: '自定义 Dialog',
          subtitle: '点击按钮触发',
          trailing: ElevatedButton(
            onPressed: onShowCustomDialog,
            child: const Text('打开'),
          ),
        ),
        ContextMenuTile(onShowMenu: onShowContextMenu),
        const Divider(height: 16),
        DialogDemoTile(
          leading: const Icon(Icons.info_outline),
          title: '显示 AboutDialog',
          subtitle: '系统自带"关于"对话框',
          onTap: onShowAbout,
        ),
        const Divider(height: 16),
        _NavigatorChainSection(
          onDemoOpenChain: onDemoOpenChain,
          onDemoCloseChain: onDemoCloseChain,
        ),
        _OverlayChainSection(
          orderStore: orderStore,
          onDemoOpenOverlayChain: onDemoOpenOverlayChain,
          onDemoCloseOverlayChain: onDemoCloseOverlayChain,
          onEditOverlayOrders: onEditOverlayOrders,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _NavigatorChainSection extends StatelessWidget {
  const _NavigatorChainSection({
    required this.onDemoOpenChain,
    required this.onDemoCloseChain,
  });

  final Future<void> Function() onDemoOpenChain;
  final Future<void> Function() onDemoCloseChain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '顺序链式弹窗（自定义开关顺序）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '示例：打开 A→B→C；关闭 B→A→C',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: onDemoOpenChain,
                child: const Text('打开 A→B→C'),
              ),
              OutlinedButton(
                onPressed: onDemoCloseChain,
                child: const Text('关闭 B→A→C'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverlayChainSection extends StatelessWidget {
  const _OverlayChainSection({
    required this.orderStore,
    required this.onDemoOpenOverlayChain,
    required this.onDemoCloseOverlayChain,
    required this.onEditOverlayOrders,
  });

  final ChainOrderStore orderStore;
  final Future<void> Function() onDemoOpenOverlayChain;
  final Future<void> Function() onDemoCloseOverlayChain;
  final Future<void> Function() onEditOverlayOrders;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overlay 链式弹窗（对比 Navigator）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<List<String>>(
            valueListenable: orderStore.openOrder,
            builder: (_, open, __) => ValueListenableBuilder<List<String>>(
              valueListenable: orderStore.closeOrder,
              builder: (_, close, __) => Text(
                '示例：打开 ${open.join('→')}；关闭 ${close.join('→')}（使用 OverlayEntry）',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ValueListenableBuilder<List<String>>(
                valueListenable: orderStore.openOrder,
                builder: (_, open, __) => ElevatedButton(
                  onPressed: onDemoOpenOverlayChain,
                  child: Text('Overlay 打开 ${open.join('→')}'),
                ),
              ),
              ValueListenableBuilder<List<String>>(
                valueListenable: orderStore.closeOrder,
                builder: (_, close, __) => OutlinedButton(
                  onPressed: onDemoCloseOverlayChain,
                  child: Text('Overlay 关闭 ${close.join('→')}'),
                ),
              ),
              TextButton.icon(
                onPressed: onEditOverlayOrders,
                icon: const Icon(Icons.tune),
                label: const Text('编辑 Overlay 顺序'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
