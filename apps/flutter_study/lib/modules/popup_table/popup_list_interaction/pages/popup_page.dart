import 'package:flutter/material.dart';

import '../../popup_widgets/module_root.dart' as pop_widget;

class PopupPage extends StatelessWidget {
  const PopupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const pop_widget.PopDemoHomePage(title: '弹窗组件');
  }
}
