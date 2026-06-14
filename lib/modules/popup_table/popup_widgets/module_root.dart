import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 固定链式弹窗代号，便于确认与复用（顺序可变，代号固定）
const List<String> kChainDialogIds = <String>['A', 'B', 'C'];

// 统一的数据管理：链式弹窗顺序
class ChainOrderStore {
  ChainOrderStore({List<String>? initial})
      : openOrder =
            ValueNotifier<List<String>>(List.of(initial ?? kChainDialogIds)),
        closeOrder = ValueNotifier<List<String>>(
            List.of((initial ?? kChainDialogIds).reversed));

  final ValueNotifier<List<String>> openOrder;
  final ValueNotifier<List<String>> closeOrder;

  void setOrders({required List<String> open, required List<String> close}) {
    openOrder.value = List.of(open);
    closeOrder.value = List.of(close);
  }

  void reset() {
    setOrders(open: kChainDialogIds, close: List.of(kChainDialogIds.reversed));
  }
}

class PopDemoHomePage extends StatefulWidget {
  const PopDemoHomePage({super.key, required this.title});

  final String title;

  @override
  State<PopDemoHomePage> createState() => _PopDemoHomePageState();
}

class _PopDemoHomePageState extends State<PopDemoHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PersistentBottomSheetController? _bottomSheetController;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldPop = await _showExitConfirmDialog(context);
        if ((shouldPop ?? false) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              tooltip: '显示 AboutDialog',
              onPressed: _showAbout,
              icon: const Icon(Icons.info_outline),
            ),
            PopupMenuButton<String>(
              tooltip: '选择更多弹窗',
              onSelected: (value) async {
                switch (value) {
                  case 'date':
                    await _showDatePicker();
                    break;
                  case 'time':
                    await _showTimePicker();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'date', child: Text('日期选择弹窗')),
                PopupMenuItem(value: 'time', child: Text('时间选择弹窗')),
              ],
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.deepPurple),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('弹窗演示菜单',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('显示 AboutDialog'),
                onTap: () {
                  Navigator.pop(context);
                  _showAbout();
                },
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: const Text('AlertDialog (普通对话框)'),
              subtitle: const Text('点击触发'),
              onTap: () => _showAlertDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('SimpleDialog (选项对话框)'),
              subtitle: const Text('点击右侧图标触发'),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: _showSimpleDialog,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.keyboard_double_arrow_up),
              title: const Text('Modal Bottom Sheet (模态底部弹窗)'),
              subtitle: const Text('长按触发'),
              onLongPress: _showModalBottomSheet,
            ),
            const Divider(height: 16),
            _CupertinoDoubleTapTile(onDoubleTap: _showCupertinoAlert),
            ListTile(
              leading: const Icon(Icons.design_services),
              title: const Text('自定义 Dialog'),
              subtitle: const Text('点击按钮触发'),
              trailing: ElevatedButton(
                onPressed: _showCustomDialog,
                child: const Text('打开'),
              ),
            ),
            _ContextMenuTile(onShowMenu: _showContextMenu),
            const Divider(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('顺序链式弹窗（自定义开关顺序）',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('示例：打开 A→B→C；关闭 B→A→C',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _demoOpenChain,
                        child: const Text('打开 A→B→C'),
                      ),
                      OutlinedButton(
                        onPressed: _demoCloseChain,
                        child: const Text('关闭 B→A→C'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overlay 链式弹窗（对比 Navigator）',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  ValueListenableBuilder<List<String>>(
                    valueListenable: _orderStore.openOrder,
                    builder: (_, open, __) =>
                        ValueListenableBuilder<List<String>>(
                      valueListenable: _orderStore.closeOrder,
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
                        valueListenable: _orderStore.openOrder,
                        builder: (_, open, __) => ElevatedButton(
                          onPressed: _demoOpenOverlayChain,
                          child: Text('Overlay 打开 ${open.join('→')}'),
                        ),
                      ),
                      ValueListenableBuilder<List<String>>(
                        valueListenable: _orderStore.closeOrder,
                        builder: (_, close, __) => OutlinedButton(
                          onPressed: _demoCloseOverlayChain,
                          child: Text('Overlay 关闭 ${close.join('→')}'),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _editOverlayOrders,
                        icon: const Icon(Icons.tune),
                        label: const Text('编辑 Overlay 顺序'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _togglePersistentBottomSheet,
          icon: const Icon(Icons.vertical_align_top),
          label: Text(_bottomSheetController == null ? '显示底部工具条' : '关闭底部工具条'),
        ),
      ),
    );
  }

  // 1) AlertDialog
  Future<void> _showAlertDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('这是一个 AlertDialog 示例。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context), child: const Text('确定')),
        ],
      ),
    );
  }

  // ---- 顺序链式弹窗：按指定顺序打开与关闭 ----
  final Map<String, Route<void>> _chainRoutes = <String, Route<void>>{};
  bool _chainOpening = false;
  bool _chainClosing = false;

  Widget _noBack(Widget child) => PopScope(
        canPop: false,
        child: child,
      );

  Route<void> _buildRawDialogRoute(Widget child) {
    return RawDialogRoute<void>(
      pageBuilder: (context, anim, secAnim) => child,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
    );
  }

  // 构建带右上角关闭按钮的链式对话框
  Widget _buildChainDialog({
    required String id,
    required String title,
    required String body,
    required VoidCallback onClose,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    tooltip: '关闭 $id',
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(body),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDialogsInOrder(List<MapEntry<String, Widget>> items) async {
    if (_chainOpening) return;
    _chainOpening = true;
    final nav = Navigator.of(context, rootNavigator: true);
    for (final e in items) {
      // 如果已存在则先移除，保证干净状态
      final existed = _chainRoutes.remove(e.key);
      if (existed != null) {
        nav.removeRoute(existed);
      }
      final route = _buildRawDialogRoute(_noBack(e.value));
      _chainRoutes[e.key] = route;
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
      if (route != null) {
        // 仅当仍在导航栈时再移除
        try {
          nav.removeRoute(route);
        } catch (_) {
          // 已被用户关闭或不存在，忽略
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }
    _chainClosing = false;
  }

  Future<void> _demoOpenChain() async {
    await _openDialogsInOrder([
      MapEntry(
          'A',
          _buildChainDialog(
            id: 'A',
            title: '弹窗 A',
            body: '链式对话框（Navigator）',
            onClose: () => _closeDialogById('A'),
          )),
      MapEntry(
          'B',
          _buildChainDialog(
            id: 'B',
            title: '弹窗 B',
            body: 'iOS 风格（Navigator）',
            onClose: () => _closeDialogById('B'),
          )),
      MapEntry(
          'C',
          _buildChainDialog(
            id: 'C',
            title: '弹窗 C',
            body: '自定义对话框（Navigator）',
            onClose: () => _closeDialogById('C'),
          )),
    ]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已按顺序打开：A → B → C')),
    );
  }

  Future<void> _demoCloseChain() async {
    await _closeDialogsInOrder(const ['B', 'A', 'C']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已按顺序关闭：B → A → C')),
    );
  }

  // ---- Overlay 版本：使用 OverlayEntry 管理多个弹窗 ----
  // 统一顺序存储
  final ChainOrderStore _orderStore = ChainOrderStore(initial: kChainDialogIds);
  final Map<String, List<OverlayEntry>> _overlayEntries =
      <String, List<OverlayEntry>>{};
  bool _overlayOpening = false;
  bool _overlayClosing = false;

  OverlayState _overlayOf() => Overlay.of(context, rootOverlay: true);

  List<OverlayEntry> _buildOverlayEntries(Widget dialog) {
    final barrier = OverlayEntry(
      builder: (_) =>
          const ModalBarrier(dismissible: false, color: Colors.black54),
    );
    final content = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: dialog,
        ),
      ),
    );
    return [barrier, content];
  }

  Future<void> _openOverlayInOrder(List<MapEntry<String, Widget>> items) async {
    if (_overlayOpening) return;
    _overlayOpening = true;
    final overlay = _overlayOf();
    for (final e in items) {
      final existed = _overlayEntries.remove(e.key);
      if (existed != null) {
        for (final entry in existed) {
          entry.remove();
        }
      }
      final entries = _buildOverlayEntries(_noBack(e.value));
      // 确保 barrier 在下，dialog 在上
      overlay.insert(entries[0]);
      overlay.insert(entries[1]);
      _overlayEntries[e.key] = entries;
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    _overlayOpening = false;
  }

  Future<void> _closeOverlayInOrder(List<String> order) async {
    if (_overlayClosing) return;
    _overlayClosing = true;
    for (final id in order) {
      final entries = _overlayEntries.remove(id);
      if (entries != null) {
        // 先移除对话框，再移除遮罩
        if (entries.length >= 2) {
          entries[1].remove();
          await Future<void>.delayed(const Duration(milliseconds: 80));
          entries[0].remove();
        } else {
          for (final e in entries) {
            e.remove();
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }
    _overlayClosing = false;
  }

  Future<void> _demoOpenOverlayChain() async {
    final order = List<String>.from(_orderStore.openOrder.value);
    final items = order.map((id) {
      return MapEntry(
          id,
          _buildChainDialog(
            id: id,
            title: 'Overlay 弹窗 $id',
            body: '通过 OverlayEntry 打开',
            onClose: () => _closeOverlayById(id),
          ));
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
        SnackBar(content: Text('Overlay 已按顺序关闭：${order.join(' → ')}')));
  }

  void _closeDialogById(String id) {
    final nav = Navigator.of(context, rootNavigator: true);
    final route = _chainRoutes.remove(id);
    if (route != null) {
      try {
        nav.removeRoute(route);
      } catch (_) {}
    }
  }

  void _closeOverlayById(String id) {
    final entries = _overlayEntries.remove(id);
    if (entries != null) {
      if (entries.length >= 2) {
        entries[1].remove();
        entries[0].remove();
      } else {
        for (final e in entries) {
          e.remove();
        }
      }
    }
  }

  // 编辑 Overlay 顺序
  Future<void> _editOverlayOrders() async {
    List<String> curOpen = List.of(_orderStore.openOrder.value);
    List<String> curClose = List.of(_orderStore.closeOrder.value);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheet) {
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = MediaQuery.of(context).size.height * 0.85;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('编辑 Overlay 打开顺序',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: true,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex--;
                            setSheet(() {
                              final item = curOpen.removeAt(oldIndex);
                              curOpen.insert(newIndex, item);
                            });
                          },
                          children: [
                            for (final id in curOpen)
                              ListTile(
                                key: ValueKey('open-$id'),
                                title: Text('代号 $id'),
                                trailing: const Icon(Icons.drag_handle),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('编辑 Overlay 关闭顺序',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: true,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex--;
                            setSheet(() {
                              final item = curClose.removeAt(oldIndex);
                              curClose.insert(newIndex, item);
                            });
                          },
                          children: [
                            for (final id in curClose)
                              ListTile(
                                key: ValueKey('close-$id'),
                                title: Text('代号 $id'),
                                trailing: const Icon(Icons.drag_handle),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('固定代号：${kChainDialogIds.join('、')}（仅顺序可调）',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setSheet(() {
                                  curOpen = List<String>.from(kChainDialogIds);
                                  curClose = List<String>.from(
                                      kChainDialogIds.reversed);
                                });
                              },
                              child: const Text('重置'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _orderStore.setOrders(
                                      open: curOpen, close: curClose);
                                  _overlayApplyVisibleOrder(curOpen);
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('保存'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        });
      },
    );
  }

  // 使用 Overlay.rearrange 对当前可见弹窗重排，避免维护持久顺序表
  void _overlayApplyVisibleOrder(List<String> order) {
    final overlay = _overlayOf();
    final newEntries = <OverlayEntry>[];
    for (final id in order) {
      final pair = _overlayEntries[id];
      if (pair != null) {
        newEntries.add(pair[0]); // barrier
        newEntries.add(pair[1]); // content
      }
    }
    if (newEntries.isNotEmpty) {
      overlay.rearrange(newEntries);
    }
  }

  // 2) SimpleDialog
  Future<void> _showSimpleDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择一个选项'),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'A'),
              child: const Text('选项 A')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'B'),
              child: const Text('选项 B')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'C'),
              child: const Text('选项 C')),
        ],
      ),
    );
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('选择了: $result')));
    }
  }

  // 3) Modal Bottom Sheet
  Future<void> _showModalBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('这是一个模态底部弹窗',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
      ),
    );
  }

  // 4) Cupertino 风格对话框（双击触发）
  Future<void> _showCupertinoAlert() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('iOS 风格弹窗'),
        content: const Text('通过双击手势触发。'),
        actions: [
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(context), child: const Text('好的')),
        ],
      ),
    );
  }

  // 5) 自定义 Dialog
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
                  const Text('自定义内容',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
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

  // 6) 持久化 BottomSheet（FAB 切换）
  void _togglePersistentBottomSheet() {
    if (_bottomSheetController != null) {
      _bottomSheetController!.close();
      _bottomSheetController = null;
      setState(() {});
      return;
    }
    _bottomSheetController =
        _scaffoldKey.currentState?.showBottomSheet((context) {
      return SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined),
              const SizedBox(width: 8),
              const Expanded(child: Text('这是一个持久化底部工具条，你可以手动关闭。')),
              TextButton(
                  onPressed: () => _bottomSheetController?.close(),
                  child: const Text('关闭')),
            ],
          ),
        ),
      );
    });
    _bottomSheetController?.closed.whenComplete(() {
      if (mounted) setState(() => _bottomSheetController = null);
    });
    setState(() {});
  }

  // 7) 日期/时间选择
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
    await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  // 8) About 对话框
  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Flutter 弹窗学习',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(),
      children: const [Text('展示多种弹窗类型与触发方式。')],
    );
  }

  // 9) 退出确认弹窗（返回键触发）
  Future<bool?> _showExitConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出应用吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('退出')),
        ],
      ),
    );
  }

  // 10) 上下文菜单（在点击位置弹出）
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
    if (!mounted) return;
    if (selected != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('选择了: $selected')));
    }
  }
}

// 专用条目：双击触发 Cupertino 对话框
class _CupertinoDoubleTapTile extends StatelessWidget {
  const _CupertinoDoubleTapTile({required this.onDoubleTap});
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: const ListTile(
        leading: Icon(Icons.phone_iphone),
        title: Text('Cupertino AlertDialog (iOS 风格)'),
        subtitle: Text('双击触发'),
      ),
    );
  }
}

// 专用条目：在点击处弹出上下文菜单
class _ContextMenuTile extends StatelessWidget {
  const _ContextMenuTile({required this.onShowMenu});
  final Future<void> Function(TapDownDetails) onShowMenu;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onShowMenu,
      child: const ListTile(
        leading: Icon(Icons.more_vert),
        title: Text('Context Menu (showMenu)'),
        subtitle: Text('轻触显示菜单（在手指位置）'),
      ),
    );
  }
}
