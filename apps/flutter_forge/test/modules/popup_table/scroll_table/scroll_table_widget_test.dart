import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/popup_table/scroll_table/module_root.dart';
import 'package:flutter_forge_app/modules/popup_table/scroll_table/widgets/scroll_table.dart';
import 'package:flutter_forge_app/shared/table/scroll_table.dart'
    as shared_table;
import 'package:flutter_test/flutter_test.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

void main() {
  testWidgets('module page renders table with pinned headers and sections', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScrollTableDemo()));
    await tester.pumpAndSettle();

    expect(find.text('二维滚动表格演示'), findsOneWidget);
    expect(find.text('员工信息表格'), findsOneWidget);
    // Pinned header row and row headers render with the first data cells.
    expect(find.text('姓名'), findsOneWidget);
    expect(find.text('第1行'), findsOneWidget);
    // Names cycle across the 20 rows, so more than one instance can be built.
    expect(find.text('张三'), findsAtLeastNWidgets(1));
    expect(find.text('掌握二维滚动表格的基本使用方式'), findsOneWidget);
  });

  testWidgets('vertical scroll keeps the pinned column header visible', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScrollTableDemo()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(TableView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('姓名'), findsOneWidget, reason: '表头行必须保持钉住');
    expect(find.text('第10行'), findsOneWidget);
  });

  testWidgets('horizontal scroll keeps the pinned row header visible', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScrollTableDemo()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(TableView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('第1行'), findsOneWidget, reason: '行头列必须保持钉住');
    expect(find.text('薪资'), findsOneWidget);
  });

  testWidgets('cell tap reports the tapped row and column', (tester) async {
    final tapped = <({int row, int column})>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: shared_table.ScrollTable(
            columnHeaders: TableData.getColumnHeaders(),
            rowHeaders: TableData.getRowHeaders(),
            data: TableData.getSampleData(),
            cellHeight: 56,
            cellWidth: 140,
            onCellTap: (row, column) => tapped.add((row: row, column: column)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('张三').first);
    await tester.pump();
    expect(tapped, [(row: 0, column: 0)]);

    await tester.tap(find.text('第2行').first);
    await tester.pump();
    // Row header taps open no cell callback: only data cells report.
    expect(tapped.length, 1, reason: '行头不是数据单元格');
  });

  test('sample data matches the declared header shape', () {
    final columns = TableData.getColumnHeaders();
    final rows = TableData.getRowHeaders();
    final data = TableData.getSampleData();
    expect(columns.length, 8);
    expect(rows.length, 20);
    expect(data.length, 20);
    for (final row in data) {
      expect(row.length, columns.length);
    }
    expect(data.first.first, '张三');
    expect(data.last.last, isNotEmpty);
  });

  testWidgets('compact 360 width does not overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ScrollTableDemo()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
