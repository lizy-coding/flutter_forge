import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'widgets/bottom_sheet_demo.dart';
import 'widgets/demo_section.dart';
import 'widgets/dialog_demo_tile.dart';
import 'widgets/learning_content.dart';

class PopDemoHomePage extends StatefulWidget {
  const PopDemoHomePage({super.key, required this.title});

  final String title;

  @override
  State<PopDemoHomePage> createState() => _PopDemoHomePageState();
}

class _PopDemoHomePageState extends State<PopDemoHomePage> {
  final ChainOrderStore _orderStore = ChainOrderStore(initial: kChainDialogIds);
  final Map<String, Route<void>> _chainRoutes = <String, Route<void>>{};
  final Map<String, List<OverlayEntry>> _overlayEntries =
      <String, List<OverlayEntry>>{};

  bool _showBottomSheet = false;
  bool _chainOpening = false;
  bool _chainClosing = false;
  bool _overlayOpening = false;
  bool _overlayClosing = false;

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: widget.title,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _togglePersistentBottomSheet,
        icon: const Icon(Icons.vertical_align_top),
        label: Text(_showBottomSheet ? '关闭底部条' : '显示底部条'),
      ),
      interactiveDemo: PopupDemoInteractiveDemo(
        showBottomSheet: _showBottomSheet,
        orderStore: _orderStore,
        onTogglePersistentBottomSheet: _togglePersistentBottomSheet,
        onShowAbout: _showAbout,
        onShowDatePicker: _showDatePicker,
        onShowTimePicker: _showTimePicker,
        onShowAlertDialog: _showAlertDialog,
        onShowSimpleDialog: _showSimpleDialog,
        onShowModalBottomSheet: _showModalBottomSheet,
        onShowCupertinoAlert: _showCupertinoAlert,
        onShowCustomDialog: _showCustomDialog,
        onShowContextMenu: _showContextMenu,
        onDemoOpenChain: _demoOpenChain,
        onDemoCloseChain: _demoCloseChain,
        onDemoOpenOverlayChain: _demoOpenOverlayChain,
        onDemoCloseOverlayChain: _demoCloseOverlayChain,
        onEditOverlayOrders: _editOverlayOrders,
      ),
      sections: buildPopupLearningSections(),
    );
  }

  @override
  void dispose() {
    _chainRoutes.clear();
    for (final entries in _overlayEntries.values) {
      for (final entry in entries) {
        entry.remove();
      }
    }
    _overlayEntries.clear();
    _orderStore.dispose();
    super.dispose();
  }

  Future<void> _showAlertDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('这是一个 AlertDialog 示例。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSimpleDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择一个选项'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'A'),
            child: const Text('选项 A'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'B'),
            child: const Text('选项 B'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'C'),
            child: const Text('选项 C'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('选择了: $result')));
  }

  Future<void> _showModalBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const ModalBottomSheetContent(),
    );
  }

  Future<void> _showCupertinoAlert() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('iOS 风格弹窗'),
        content: const Text('通过双击手势触发。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  const Text(
                    '自定义内容',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text('这里可以放置任意自定义 Widget，例如输入框、进度等。'),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: '输入一些内容')),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('提交'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _togglePersistentBottomSheet() {
    setState(() {
      _showBottomSheet = !_showBottomSheet;
    });
  }

  void _saveOverlayOrders(List<String> open, List<String> close) {
    setState(() {
      _orderStore.setOrders(open: open, close: close);
      _overlayApplyVisibleOrder(open);
    });
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
  }

  Future<void> _showTimePicker() async {
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Flutter 弹窗学习',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(),
      children: const [Text('展示多种弹窗类型与触发方式。')],
    );
  }

  Future<void> _showContextMenu(TapDownDetails details) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(value: 'edit', child: Text('编辑')),
        PopupMenuItem(value: 'share', child: Text('分享')),
        PopupMenuItem(value: 'delete', child: Text('删除')),
      ],
    );
    if (!mounted || selected == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('选择了: $selected')));
  }
}

extension _PopupDialogRoutes on _PopDemoHomePageState {
  Widget _noBack(Widget child) => PopScope(canPop: false, child: child);

  Route<void> _buildRawDialogRoute(Widget child) {
    return RawDialogRoute<void>(
      pageBuilder: (context, anim, secAnim) => child,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
    );
  }

  Future<void> _openDialogsInOrder(List<MapEntry<String, Widget>> items) async {
    if (_chainOpening) return;
    _chainOpening = true;
    final nav = Navigator.of(context, rootNavigator: true);
    for (final item in items) {
      final existed = _chainRoutes.remove(item.key);
      if (existed != null) nav.removeRoute(existed);
      final route = _buildRawDialogRoute(_noBack(item.value));
      _chainRoutes[item.key] = route;
      nav.push(route);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    _chainOpening = false;
  }

  Future<void> _closeDialogsInOrder(List<String> order) async {
    if (_chainClosing) return;
    _chainClosing = true;
    final nav = Navigator.of(context, rootNavigator: true);
    for (final id in order) {
      final route = _chainRoutes.remove(id);
      if (route == null) continue;
      try {
        nav.removeRoute(route);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    _chainClosing = false;
  }

  Future<void> _demoOpenChain() async {
    await _openDialogsInOrder([
      MapEntry(
        'A',
        ChainDialog(
          id: 'A',
          title: '弹窗 A',
          body: '链式对话框（Navigator）',
          onClose: () => _closeDialogById('A'),
        ),
      ),
      MapEntry(
        'B',
        ChainDialog(
          id: 'B',
          title: '弹窗 B',
          body: 'iOS 风格（Navigator）',
          onClose: () => _closeDialogById('B'),
        ),
      ),
      MapEntry(
        'C',
        ChainDialog(
          id: 'C',
          title: '弹窗 C',
          body: '自定义对话框（Navigator）',
          onClose: () => _closeDialogById('C'),
        ),
      ),
    ]);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已按顺序打开：A → B → C')));
  }

  Future<void> _demoCloseChain() async {
    await _closeDialogsInOrder(const ['B', 'A', 'C']);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已按顺序关闭：B → A → C')));
  }

  void _closeDialogById(String id) {
    final nav = Navigator.of(context, rootNavigator: true);
    final route = _chainRoutes.remove(id);
    if (route == null) return;
    try {
      nav.removeRoute(route);
    } catch (_) {}
  }
}

extension _PopupOverlayDialogs on _PopDemoHomePageState {
  OverlayState _overlayOf() => Overlay.of(context, rootOverlay: true);

  List<OverlayEntry> _buildOverlayEntries(Widget dialog) {
    final barrier = OverlayEntry(
      builder: (_) =>
          const ModalBarrier(dismissible: false, color: Colors.black54),
    );
    final content = OverlayEntry(
      builder: (context) => Center(
        child: Material(type: MaterialType.transparency, child: dialog),
      ),
    );
    return [barrier, content];
  }

  Future<void> _openOverlayInOrder(List<MapEntry<String, Widget>> items) async {
    if (_overlayOpening) return;
    _overlayOpening = true;
    final overlay = _overlayOf();
    for (final item in items) {
      final existed = _overlayEntries.remove(item.key);
      if (existed != null) {
        for (final entry in existed) {
          entry.remove();
        }
      }
      final entries = _buildOverlayEntries(_noBack(item.value));
      overlay.insert(entries[0]);
      overlay.insert(entries[1]);
      _overlayEntries[item.key] = entries;
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    _overlayOpening = false;
  }

  Future<void> _closeOverlayInOrder(List<String> order) async {
    if (_overlayClosing) return;
    _overlayClosing = true;
    for (final id in order) {
      final entries = _overlayEntries.remove(id);
      if (entries == null) continue;
      if (entries.length >= 2) {
        entries[1].remove();
        await Future<void>.delayed(const Duration(milliseconds: 80));
        entries[0].remove();
      } else {
        for (final entry in entries) {
          entry.remove();
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    _overlayClosing = false;
  }

  Future<void> _demoOpenOverlayChain() async {
    final order = List<String>.from(_orderStore.openOrder.value);
    final items = order.map((id) {
      return MapEntry(
        id,
        ChainDialog(
          id: id,
          title: 'Overlay 弹窗 $id',
          body: '通过 OverlayEntry 打开',
          onClose: () => _closeOverlayById(id),
        ),
      );
    }).toList();
    await _openOverlayInOrder(items);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Overlay 已按顺序打开：${order.join(' → ')}')),
    );
  }

  Future<void> _demoCloseOverlayChain() async {
    final order = List<String>.from(_orderStore.closeOrder.value);
    await _closeOverlayInOrder(order);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Overlay 已按顺序关闭：${order.join(' → ')}')),
    );
  }

  void _closeOverlayById(String id) {
    final entries = _overlayEntries.remove(id);
    if (entries == null) return;
    if (entries.length >= 2) {
      entries[1].remove();
      entries[0].remove();
    } else {
      for (final entry in entries) {
        entry.remove();
      }
    }
  }

  Future<void> _editOverlayOrders() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => OverlayOrderEditor(
        fixedIds: kChainDialogIds,
        initialOpen: List<String>.of(_orderStore.openOrder.value),
        initialClose: List<String>.of(_orderStore.closeOrder.value),
        onSave: _saveOverlayOrders,
      ),
    );
  }

  void _overlayApplyVisibleOrder(List<String> order) {
    final overlay = _overlayOf();
    final newEntries = <OverlayEntry>[];
    for (final id in order) {
      final pair = _overlayEntries[id];
      if (pair == null) continue;
      newEntries
        ..add(pair[0])
        ..add(pair[1]);
    }
    if (newEntries.isNotEmpty) overlay.rearrange(newEntries);
  }
}
