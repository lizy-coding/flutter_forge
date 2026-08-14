import 'package:flutter/material.dart';

class StatusInfo extends StatelessWidget {
  const StatusInfo({
    super.key,
    required this.followMethod,
    required this.scrollListener,
    required this.rebuildLevel,
  });

  final String followMethod;
  final String scrollListener;
  final String rebuildLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(child: _chip('跟随: $followMethod')),
          Flexible(child: _chip('监听: $scrollListener')),
          Flexible(child: _chip('重绘: $rebuildLevel')),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11, color: Colors.black54),
    );
  }
}
