import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

import 'widgets/scroll_table.dart';

class ScrollTableDemo extends StatelessWidget {
  const ScrollTableDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '二维滚动表格演示',
      interactiveDemo: SizedBox(
        height: 400,
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
      sections: [
        LearningObjectives(
          objectives: [
            '掌握二维滚动表格的基本使用方式',
            '理解固定表头与行头的实现原理',
            '学会使用 TableView 处理大量数据展示',
          ],
        ),
        ConceptChips(
          concepts: [
            'TableView',
            '二维滚动',
            '固定表头',
            '行头',
            'two_dimensional_scrollables',
          ],
        ),
        CodeSnippetCard(
          title: 'ScrollTable 使用示例',
          code:
              'ScrollTable(\n'
              '  columnHeaders: columnHeaders,\n'
              '  rowHeaders: rowHeaders,\n'
              '  data: sampleData,\n'
              '  cellHeight: 56.0,\n'
              '  cellWidth: 140.0,\n'
              ')',
          explanation: 'ScrollTable 封装了 TableView 的常见配置，简化使用。',
        ),
        CommonPitfalls(
          pitfalls: [
            '数据量大时需注意性能 — TableView 本身支持懒加载，但 cellWidget 避免复杂构建',
            '宽高需明确指定 — TableView 的单元格宽高必须固定，不支持自适应',
          ],
        ),
        ExerciseCard(
          task: '在现有表格基础上增加一列"操作"，包含编辑和删除按钮。',
          hint: '在 columnHeaders 和 data 中同步增加列，TableData 数据类中增加对应字段。',
        ),
      ],
    );
  }
}
