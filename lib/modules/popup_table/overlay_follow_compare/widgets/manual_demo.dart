import 'package:flutter/material.dart';

import 'dropdown_surface.dart';

class ManualRebuildDemo extends StatefulWidget {
  const ManualRebuildDemo({super.key});

  @override
  State<ManualRebuildDemo> createState() => _ManualRebuildDemoState();
}

class _ManualRebuildDemoState extends State<ManualRebuildDemo> {
  final GlobalKey _buttonKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _overlayEntry;
  int _rebuildCount = 0;
  bool _colorToggle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    _overlayEntry?.markNeedsBuild();
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _rebuildCount = 0;
      _colorToggle = false;
      setState(() {});
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        _rebuildCount++;
        _colorToggle = !_colorToggle;

        final buttonContext = _buttonKey.currentContext;
        if (buttonContext == null) return const SizedBox.shrink();

        final box = buttonContext.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return const SizedBox.shrink();

        final position = box.localToGlobal(Offset.zero);

        return Positioned(
          left: position.dx,
          top: position.dy + 48,
          child: DropdownSurface(
            schemeName: 'Manual',
            description: 'markNeedsBuild 刷新',
            rebuildCount: _rebuildCount,
            color: _colorToggle ? Colors.blue.shade600 : Colors.blue.shade800,
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          itemCount: 50,
          itemBuilder: (context, index) {
            if (index == 8) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  key: _buttonKey,
                  onPressed: _toggleOverlay,
                  child: const Text('手动刷新下拉菜单'),
                ),
              );
            }
            return ListTile(title: Text('Item $index'));
          },
        ),
        if (_overlayEntry != null)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _toggleOverlay,
          ),
      ],
    );
  }
}
