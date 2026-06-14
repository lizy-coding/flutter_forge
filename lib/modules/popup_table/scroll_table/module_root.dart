import 'package:flutter/material.dart';

import 'widgets/scroll_table.dart';

class ScrollTableDemo extends StatefulWidget {
  const ScrollTableDemo({super.key});

  @override
  State<ScrollTableDemo> createState() => _ScrollTableDemoState();
}

class _ScrollTableDemoState extends State<ScrollTableDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('二维滚动表格演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '员工信息表格',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '支持横向和纵向滚动，固定表头和行头',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ScrollTable(
                columnHeaders: TableData.getColumnHeaders(),
                rowHeaders: TableData.getRowHeaders(),
                data: TableData.getSampleData(),
                cellHeight: 56.0,
                cellWidth: 140.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
