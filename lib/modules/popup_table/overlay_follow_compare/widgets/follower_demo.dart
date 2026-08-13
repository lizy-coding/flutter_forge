import 'package:flutter/material.dart';

import 'dropdown_surface.dart';

class FollowerDemo extends StatefulWidget {
  const FollowerDemo({super.key});

  @override
  State<FollowerDemo> createState() => _FollowerDemoState();
}

class _FollowerDemoState extends State<FollowerDemo> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  int _rebuildCount = 0;

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      setState(() {});
      return;
    }

    _rebuildCount = 0;
    _overlayEntry = OverlayEntry(
      builder: (context) {
        _rebuildCount++;
        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: DropdownSurface(
            schemeName: 'Follower',
            description: 'Layer 自动同步',
            rebuildCount: _rebuildCount,
            color: Colors.orange.shade700,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          itemCount: 50,
          itemBuilder: (context, index) {
            if (index == 8) {
              return CompositedTransformTarget(
                link: _layerLink,
                child: _buildButton('Follower 下拉菜单'),
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

  Widget _buildButton(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(onPressed: _toggleOverlay, child: Text(label)),
    );
  }
}
