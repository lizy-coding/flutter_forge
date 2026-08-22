import 'package:flutter/material.dart';

import 'status_info.dart';

class ComparePanel extends StatelessWidget {
  const ComparePanel({
    super.key,
    required this.title,
    required this.color,
    required this.followMethod,
    required this.scrollListener,
    required this.rebuildLevel,
    required this.demo,
  });

  final String title;
  final Color color;
  final String followMethod;
  final String scrollListener;
  final String rebuildLevel;
  final Widget demo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: color,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StatusInfo(
          followMethod: followMethod,
          scrollListener: scrollListener,
          rebuildLevel: rebuildLevel,
        ),
        Expanded(child: demo),
      ],
    );
  }
}
