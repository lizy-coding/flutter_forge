import 'package:flutter/material.dart';

import 'module_root.dart' as isolate_basic;

class IsolateTestEntry extends StatelessWidget {
  const IsolateTestEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const isolate_basic.HomePage();
  }
}
