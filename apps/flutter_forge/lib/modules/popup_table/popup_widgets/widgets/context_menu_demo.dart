import 'package:flutter/material.dart';

class ContextMenuTile extends StatelessWidget {
  const ContextMenuTile({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final item in const {
          'edit': '编辑',
          'share': '分享',
          'delete': '删除',
        }.entries)
          MenuItemButton(
            onPressed: () => onSelected(item.key),
            child: Text(item.value),
          ),
      ],
      builder: (context, controller, child) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) =>
            controller.open(position: details.localPosition),
        child: const ListTile(
          leading: Icon(Icons.more_vert),
          title: Text('Context Menu (MenuAnchor)'),
          subtitle: Text('轻触显示菜单（在手指位置）'),
        ),
      ),
    );
  }
}
