# AI 模块分析: tree_state

> Flutter 三棵树（Widget/Element/RenderObject）与生命周期演示。

## 功能

展示 Flutter 的 Widget 树、Element 树、RenderObject 树的关系，以及 StatefulWidget 生命周期和渲染行为。

## 文件结构

```
modules/basic/tree_state/
├── module_entry.dart              # 入口: 跳转到 DemoHomePage
├── module_routes.dart             # 子路由定义 + 路由常量
├── routes.dart                    # 兼容旧导入，导出 module_routes.dart
└── pages/
    ├── demo_home_page.dart        # 仪表盘: 四个演示页面入口
    ├── basic_widgets_page.dart    # ★ 标准教学页: StatelessWidget vs StatefulWidget 重建行为
    ├── state_lifecycle_page.dart  # StatefulWidget 生命周期钩子
    ├── painter_demo_page.dart     # CustomPainter 渲染阶段日志
    └── repaint_boundary_demo_page.dart # 局部重绘与 RenderObject 隔离
```

## 演示内容

| 页面 | 核心概念 | 状态 |
|------|---------|------|
| BasicWidgets | Widget 重建时机，const 优化，State 持久性 | ★ 标准教学页 |
| StateLifecycle | initState, didChangeDependencies, build, dispose | 待改造 |
| PainterDemo | CustomPainter 的 paint 和 shouldRepaint 调用时机 | 待改造 |
| RepaintBoundary | RenderObject 层级的重绘隔离 | 待改造 |

## BasicWidgetsPage 教学页结构

`basic_widgets_page.dart` 是第一个使用 `package:flutter_study_learning` 的标准教学页：

- **学习目标**: Widget vs State 角色差异、父组件 setState 对子组件的影响、State 持久性
- **交互演示**: 触发重建按钮 + 闪烁边框动画（_RebuildAwareBox）直观展示 rebuild
- **代码片段**: setState 与数据传递的标准写法
- **状态日志**: 页面内可见的重建日志（替代 debugPrint）
- **常见误区**: Widget 不是界面对象、StatelessWidget 也会 rebuild、可变状态不应放在 Widget 字段
- **练习任务**: 观察 StatelessBox 每次 build 但 StatefulBox initState 只执行一次

### 关键类

| 类 | 作用 |
|---|------|
| `BasicWidgetsPage` | 教学页主 Widget，使用 LearningScaffold |
| `_RebuildAwareBox` | 重建时闪烁边框的包装器，直观展示 rebuild 行为 |
| `StatelessBox` | StatelessWidget 示例 |
| `StatefulBox` | StatefulWidget 示例，含 didUpdateWidget 日志 |

## 关键知识点

1. **Widget**: 不可变的配置对象，每次 build 重新创建
2. **Element**: Widget 的实例，持有状态，类型/key 不变时复用
3. **RenderObject**: 实际渲染和布局的对象
4. **const Widget**: 编译时常量，跳过重建
5. **RepaintBoundary**: 创建独立的 RenderObject，限制重绘范围
6. **didUpdateWidget**: StatefulWidget 接收新配置时的回调

## 修改建议

- 添加 Element 树可视化: 展示 Widget -> Element 的映射关系
- 扩展教学模板: 将其他 3 个页面也改造为 LearningScaffold 格式
- 性能分析: 添加 rebuild 次数统计
