import 'package:flutter/material.dart';

import '../../scroll_table/module_root.dart' as scroll_table;

class ListPage extends StatelessWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const scroll_table.ScrollTableDemo();
  }
}
