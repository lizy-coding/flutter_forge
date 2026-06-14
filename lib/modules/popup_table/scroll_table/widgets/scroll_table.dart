import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class ScrollTable extends StatelessWidget {
  final List<String> columnHeaders;
  final List<String> rowHeaders;
  final List<List<String>> data;
  final double cellHeight;
  final double cellWidth;

  const ScrollTable({
    super.key,
    required this.columnHeaders,
    required this.rowHeaders,
    required this.data,
    this.cellHeight = 50.0,
    this.cellWidth = 120.0,
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
      backgroundColor =
          vicinity.row % 2 == 0 ? Colors.white : Colors.grey.shade50;
      text = data[vicinity.row - 1][vicinity.column - 1];
      textStyle = const TextStyle();
    }

    return TableViewCell(
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
    );
  }

  TableSpan _buildColumn(int index) {
    return TableSpan(
      extent: FixedTableSpanExtent(cellWidth),
    );
  }

  TableSpan _buildRow(int index) {
    return TableSpan(
      extent: FixedTableSpanExtent(cellHeight),
    );
  }
}

// 演示用的数据模型
class TableData {
  static List<String> getColumnHeaders() {
    return ['姓名', '年龄', '部门', '职位', '薪资', '入职日期', '绩效', '状态'];
  }

  static List<String> getRowHeaders() {
    return List.generate(20, (index) => '第${index + 1}行');
  }

  static List<List<String>> getSampleData() {
    final List<String> names = ['张三', '李四', '王五', '赵六', '钱七', '孙八', '周九', '吴十'];
    final List<String> departments = ['技术部', '销售部', '市场部', '人事部', '财务部'];
    final List<String> positions = ['工程师', '经理', '专员', '主管', '总监'];
    final List<String> performance = ['优秀', '良好', '一般', '待改进'];
    final List<String> status = ['在职', '休假', '出差', '培训'];

    return List.generate(20, (rowIndex) {
      return [
        names[rowIndex % names.length],
        '${25 + rowIndex % 15}',
        departments[rowIndex % departments.length],
        positions[rowIndex % positions.length],
        '${(8 + rowIndex % 20) * 1000}',
        '2023-0${(rowIndex % 9) + 1}-${(rowIndex % 28) + 1}',
        performance[rowIndex % performance.length],
        status[rowIndex % status.length],
      ];
    });
  }
}
