export 'package:flutter_forge_app/shared/table/scroll_table.dart';

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
