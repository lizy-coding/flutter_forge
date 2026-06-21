import 'package:flutter/material.dart';

class DialogDemoTile extends StatelessWidget {
  const DialogDemoTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class CupertinoDoubleTapTile extends StatelessWidget {
  const CupertinoDoubleTapTile({super.key, required this.onDoubleTap});

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

class ChainDialog extends StatelessWidget {
  const ChainDialog({
    super.key,
    required this.id,
    required this.title,
    required this.body,
    required this.onClose,
  });

  final String id;
  final String title;
  final String body;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
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
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
}
