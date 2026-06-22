import 'package:flutter/material.dart';

import 'pages/home_page.dart' as microtask;

class MicrotaskEntry extends StatelessWidget {
  const MicrotaskEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const microtask.HomePage();
  }
}
