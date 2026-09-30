import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class ScrollTable extends StatelessWidget {
  final List<String> columnHeaders;
  final List<String> rowHeaders;
  final List<List<String>> data;
  final double cellHeight;
  final double cellWidth;
  final double? rowHeaderWidth;
  final void Function(int row, int column)? onCellTap;

  const ScrollTable({
    super.key,
    required this.columnHeaders,
    required this.rowHeaders,
    required this.data,
    this.cellHeight = 50.0,
    this.cellWidth = 120.0,
    this.rowHeaderWidth,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TableView.builder(
        diagonalDragBehavior: DiagonalDragBehavior.weightedEvent,
        cellBuilder: _buildCell,
        pinnedColumnCount: 1,
        pinnedRowCount: 1,
        columnCount: columnHeaders.length + 1, // +1 for row headers
        rowCount: data.length + 1, // +1 for column headers
        columnBuilder: _buildColumn,
        rowBuilder: _buildRow,
      ),
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    final bool isColumnHeader = vicinity.row == 0;
    final bool isRowHeader = vicinity.column == 0;
    final bool isCornerCell = vicinity.row == 0 && vicinity.column == 0;

    Color backgroundColor;
    String text;
    TextStyle textStyle;

    if (isCornerCell) {
      // 左上角空单元格
      backgroundColor = Colors.grey.shade200;
      text = '';
      textStyle = const TextStyle(fontWeight: FontWeight.bold);
    } else if (isColumnHeader) {
      // 列头
      backgroundColor = Colors.blue.shade100;
      text = columnHeaders[vicinity.column - 1];
      textStyle = const TextStyle(fontWeight: FontWeight.bold);
    } else if (isRowHeader) {
      // 行头
      backgroundColor = Colors.blue.shade50;
      text = rowHeaders[vicinity.row - 1];
      textStyle = const TextStyle(fontWeight: FontWeight.bold);
    } else {
      // 数据单元格
      backgroundColor = vicinity.row % 2 == 0
          ? Colors.white
          : Colors.grey.shade50;
      text = data[vicinity.row - 1][vicinity.column - 1];
      textStyle = const TextStyle();
    }

    return TableViewCell(
      child: GestureDetector(
        onTap: isColumnHeader || isRowHeader || onCellTap == null
            ? null
            : () => onCellTap!(vicinity.row - 1, vicinity.column - 1),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300, width: 0.5),
              bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                text,
                style: textStyle,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  TableSpan _buildColumn(int index) {
    return TableSpan(
      extent: FixedTableSpanExtent(
        index == 0 ? rowHeaderWidth ?? cellWidth : cellWidth,
      ),
    );
  }

  TableSpan _buildRow(int index) {
    return TableSpan(extent: FixedTableSpanExtent(cellHeight));
  }
}
