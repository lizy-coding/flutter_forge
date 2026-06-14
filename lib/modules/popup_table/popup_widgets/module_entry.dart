import 'package:flutter/material.dart';

import 'module_root.dart' as pop_widget;

class PopWidgetEntry extends StatelessWidget {
  const PopWidgetEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const pop_widget.PopDemoHomePage(title: 'Flutter 弹窗学习');
  }
}
