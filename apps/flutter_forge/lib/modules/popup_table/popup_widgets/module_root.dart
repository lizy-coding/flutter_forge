import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:flutter_forge_app/shared/popup/popup_scope.dart';

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
  final PopupScope _popups = PopupScope();
  bool _showBottomSheet = false;

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
        onContextMenuSelected: _onContextMenuSelected,
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
    _popups.dispose();
    _orderStore.dispose();
    super.dispose();
  }

  Future<T?> _showOwnedDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    return _popups.push<T>(
      navigator,
      DialogRoute<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        themes: InheritedTheme.capture(from: context, to: navigator.context),
      ),
    );
  }

  Future<T?> _showOwnedSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
  }) {
    final navigator = Navigator.of(context);
    return _popups.push<T>(
      navigator,
      ModalBottomSheetRoute<T>(
        builder: builder,
        isScrollControlled: isScrollControlled,
        showDragHandle: true,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
      ),
    );
  }

  Future<void> _showAlertDialog() async {
    await _showOwnedDialog<void>(
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
    final result = await _showOwnedDialog<String>(
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
    await _showOwnedSheet<void>(
      builder: (context) => const ModalBottomSheetContent(),
    );
  }

  Future<void> _showCupertinoAlert() async {
    await _popups.push<void>(
      Navigator.of(context, rootNavigator: true),
      CupertinoDialogRoute<void>(
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
      ),
    );
  }

  Future<void> _showCustomDialog() async {
    await _showOwnedDialog<void>(
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
    await _showOwnedDialog<DateTime>(
      builder: (_) => DatePickerDialog(
        initialDate: now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 2),
      ),
    );
  }

  Future<void> _showTimePicker() async {
    await _showOwnedDialog<TimeOfDay>(
      builder: (_) => TimePickerDialog(initialTime: TimeOfDay.now()),
    );
  }

  void _showAbout() {
    unawaited(
      _showOwnedDialog<void>(
        builder: (_) => const AboutDialog(
          applicationName: 'Flutter 弹窗学习',
          applicationVersion: '1.0.0',
          applicationIcon: FlutterLogo(),
          children: [Text('展示多种弹窗类型与触发方式。')],
        ),
      ),
    );
  }

  void _onContextMenuSelected(String selected) {
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
    final nav = Navigator.of(context, rootNavigator: true);
    await _popups.sequence('dialog', items, (item) {
      final route = _buildRawDialogRoute(_noBack(item.value));
      unawaited(_popups.push<void>(nav, route, id: item.key));
    });
  }

  Future<void> _closeDialogsInOrder(List<String> order) =>
      _popups.sequence('dialog', order, _popups.closeRoute);

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
    _popups.closeRoute(id);
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
    final overlay = _overlayOf();
    await _popups.sequence('overlay', items, (item) {
      _popups.insertOverlay(
        item.key,
        overlay,
        _buildOverlayEntries(_noBack(item.value)),
      );
    });
  }

  Future<void> _closeOverlayInOrder(List<String> order) =>
      _popups.sequence('overlay', order, _popups.closeOverlay);

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
    _popups.closeOverlay(id);
  }

  Future<void> _editOverlayOrders() async {
    await _showOwnedSheet<void>(
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
    _popups.rearrange(_overlayOf(), order);
  }
}
