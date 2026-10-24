import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard navigation wrapper for shell lists.
///
/// Manages a keyboard cursor (arrow keys, Home/End) that items render via
/// [itemBuilder]'s `keyboardActive` flag, and activates it with Enter/Space.
/// Pointer interaction and tab focus stay with the tiles themselves; the
/// cursor starts at [selectedIndex] and re-syncs when the route selection
/// changes. Any pointer-down inside the list moves focus here, so keyboard
/// navigation arms immediately after the first click in the sidebar.
class ForgeSelectableList extends StatefulWidget {
  const ForgeSelectableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onActivate,
    this.selectedIndex = 0,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index, bool keyboardActive)
  itemBuilder;
  final ValueChanged<int> onActivate;
  final int selectedIndex;

  @override
  State<ForgeSelectableList> createState() => _ForgeSelectableListState();
}

class _ForgeSelectableListState extends State<ForgeSelectableList> {
  final _focusNode = FocusNode();
  final _itemContexts = <int, BuildContext>{};
  int _active = 0;
  bool _keyboardNavigating = false;

  @override
  void initState() {
    super.initState();
    _syncActive();
  }

  @override
  void didUpdateWidget(ForgeSelectableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) _itemContexts.clear();
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _syncActive();
      _keyboardNavigating = false;
    }
  }

  void _syncActive() {
    _active = widget.itemCount == 0
        ? 0
        : widget.selectedIndex.clamp(0, widget.itemCount - 1);
  }

  @override
  void dispose() {
    _itemContexts.clear();
    _focusNode.dispose();
    super.dispose();
  }

  void _moveTo(int index) {
    if (widget.itemCount == 0 ||
        index < 0 ||
        index >= widget.itemCount ||
        index == _active) {
      return;
    }
    setState(() {
      _active = index;
      _keyboardNavigating = true;
    });
    final itemContext = _itemContexts[index];
    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 120),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveTo(_active - 1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveTo(_active + 1),
        const SingleActivator(LogicalKeyboardKey.home): () => _moveTo(0),
        const SingleActivator(LogicalKeyboardKey.end): () =>
            _moveTo(widget.itemCount - 1),
        const SingleActivator(LogicalKeyboardKey.enter): _activate,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _activate,
        const SingleActivator(LogicalKeyboardKey.space): _activate,
      },
      child: Focus(
        focusNode: _focusNode,
        child: Listener(
          onPointerDown: (_) => _focusNode.requestFocus(),
          child: ListView.builder(
            itemCount: widget.itemCount,
            itemBuilder: (context, index) => Builder(
              builder: (itemContext) {
                _itemContexts[index] = itemContext;
                return widget.itemBuilder(
                  context,
                  index,
                  _keyboardNavigating && index == _active,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _activate() {
    if (widget.itemCount > 0) widget.onActivate(_active);
  }
}
