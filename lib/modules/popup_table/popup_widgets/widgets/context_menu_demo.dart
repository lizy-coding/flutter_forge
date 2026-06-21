import 'package:flutter/material.dart';

class ContextMenuTile extends StatelessWidget {
  const ContextMenuTile({super.key, required this.onShowMenu});

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
