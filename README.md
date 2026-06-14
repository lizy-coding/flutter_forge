# Flutter 学习实验室

本项目是面向 Flutter 初学者的学习项目集合，所有学习模块位于 `lib/modules/` 目录下，按主题分类，通过路由切换进入不同模块。项目同时维护 `app/` 应用壳、`module_registry/` 模块元数据和 `shared/` 共享能力，让示例既能独立学习，也能按真实工程方式演进。
![demo](https://raw.githubusercontent.com/lizy-coding/flutter_study/master/assets/demo.gif)

Full video: https://github.com/user-attachments/assets/6af279c0-7d82-42bc-81b1-624071b0e2ea

## 推荐学习顺序

1. **三棵树与生命周期** - 理解 Flutter 渲染基础
2. **事件循环与微任务** - 掌握异步执行顺序
3. **Stream 订阅机制** - 学习流式数据处理
4. **Isolate 并发** - 理解多线程与性能优化
5. **状态管理演进** - 对比 Provider/Riverpod/Bloc
6. **UI 动效与绘制** - 学习动画与自定义绘制
7. **网络与平台能力** - 实战拦截器、USB 设备等

## 支持平台

- macOS
- Windows
- 移动端（iOS / Android）

## 环境与快速开始

- Flutter 3.x / Dart 3.x
- 根目录执行：
  ```bash
  flutter pub get
  flutter run [-d <device>]
  ```
- 代码检查与格式化：
  ```bash
  flutter analyze
  dart format .
  ```
- 标准验收：
  ```bash
  dart format .
  flutter analyze
  dart run flutterguard_cli:flutterguard scan --path . --fail-on high
  ```

## 项目结构

```
lib/
├── main.dart                     # 入口
├── app/                          # 应用壳
│   ├── app.dart                  # MaterialApp.router
│   └── router/                   # go_router 路由配置
├── module_registry/              # 模块元数据（入口模型、枚举）
├── shared/                       # 共享能力迁移后的边界文档与过渡层
│   ├── AI_ANALYSIS.md
│   └── platform/AI_ANALYSIS.md
└── modules/                      # 学习模块分区
    ├── basic/                    # 基础机制
    ├── async/                    # 异步并发
    ├── state/                    # 状态管理
    ├── ui/                       # UI 与动效
    ├── popup_table/              # 弹窗与列表
    └── platform/                 # 网络与平台
```

同级能力包：

```
../gcode_core                         # 纯 Dart G-code 解析、读取、轨迹构建
../flutter_study_learning             # 教学模板组件
../file_picker_bridge                 # 文件选择 Dart API / MethodChannel client
../flutter_ioc_core                   # 纯 Dart IoC 容器核心
```

## 维护文档

修改代码前先读根目录的：

- `AI_PROJECT_CONTEXT.md`：项目整体上下文与目录约定
- `REFACTOR_PLAN.md`：阶段性归拢重构计划
- `PLUGIN_DECOMPOSITION_PLAN.md`：后续能力包/插件化拆解路线
- 目标模块或共享能力的 `AI_ANALYSIS.md`

新增或迁移能力时需要同步更新对应层级的 `AI_ANALYSIS.md`。例如本轮同级包迁移后，相关文档为：

- `lib/shared/AI_ANALYSIS.md`
- `lib/shared/platform/AI_ANALYSIS.md`
- `../file_picker_bridge/AI_ANALYSIS.md`
- `../gcode_core/AI_ANALYSIS.md`
- `../flutter_study_learning/AI_ANALYSIS.md`
- `../flutter_ioc_core/AI_ANALYSIS.md`
- `lib/modules/ui/gcode_visualizer/AI_ANALYSIS.md`

## 共享能力

### 教学模板

`package:flutter_study_learning` 提供统一教学页面骨架，模块可以用学习目标、概念标签、代码片段、常见坑和练习卡片组织内容。

### 平台文件选择

`../file_picker_bridge` 提供业务无关的文件选择接口：

- Dart 接口：`FilePickerService`
- 默认实现：`MethodChannelFilePicker`
- macOS 通道：`file_picker_bridge/file_picker`
- 当前使用方：`modules/ui/gcode_visualizer`

模块只传入允许的扩展名、标题和提示文案；文件读取、解析和错误展示仍由模块自己负责。

### G-code 核心

`../gcode_core` 提供纯 Dart G-code 能力：

- 逐行读取抽象
- G0/G1 解析
- 错误收集
- 轨迹段构建

Flutter UI、播放动画和 Canvas 绘制保留在 `modules/ui/gcode_visualizer`。

## 示例索引（按主题）

### UI 与动效
- `modules/ui/adsorption_line`：智能吸附线画板，矩形/圆形/线条创建与拖拽，对齐辅助线、工具栏和快捷键。
- `modules/ui/download_animation`：下载飞入动效三种实现（自定义 View / CustomPaint / Overlay），带参数调节面板。
- `modules/ui/gcode_visualizer`：G-code 解析与轨迹动画，支持 G0/G1 指令解析、路径输入和系统文件选择、刀路轨迹绘制、播放进度控制与指令高亮，使用 `LearningScaffold` 教学模板。

### 弹窗与列表
- `modules/popup_table/popup_widgets`：常见弹窗合集，包含顺序链式 Overlay 演示与多种触发方式。
- `modules/popup_table/popup_list_interaction`：弹窗与列表交互组合入口，集成弹窗演示与二维表格。
- `modules/popup_table/scroll_table`：二维滚动表格，固定表头/行头，基于 `two_dimensional_scrollables`。
- `modules/popup_table/overlay_follow_compare`：Overlay 跟随方案对照组，对比 `CompositedTransformFollower` 与 `markNeedsBuild` 两种浮层跟随机制。

### 基础机制
- `modules/basic/tree_state`：Widget/Element/RenderObject 三棵树与生命周期、CustomPainter、RepaintBoundary 重绘范围示例。
- `modules/basic/microtask`：事件循环演示，微任务队列与事件队列的执行顺序可视化。
- `modules/basic/debounce_throttle`：防抖与节流执行时序对比。

### 异步与并发
- `modules/async/isolate_basic`：主线程 vs Isolate 执行耗时计算的 UI 流畅度对比。
- `modules/async/isolate_task_manager`：多任务 Isolate 管理器，支持进度上报、暂停/恢复/停止。
- `modules/async/stream_subscription`：单订阅/广播流示例，包含暂停/恢复/取消与变换工具。

### 架构与状态
- `modules/state/status_management`：状态管理演进链路，串联 setState、Provider、Riverpod、Bloc，附时间轴动画与测试用例。
- `modules/state/flutter_ioc`：Provider + 自研 IoC 容器示例，支持注册/作用域/属性注入，含 `test/ioc_container_test.dart`。

### 网络与平台
- `modules/platform/dio_interceptor`：Dio 拦截器链路（Auth/Error/Retry/Log）+ 内置本地 Mock Server，覆盖登录/列表/Token 刷新。
- `modules/platform/usb_detector`：跨平台 USB 设备检测，周期扫描与手动刷新，使用 Stream 推送设备与状态消息。
