# G-code Visualizer 模块分析

> G-code 解析与轨迹动画演示模块。纯解析与轨迹构建逻辑已迁移到同级包 `../gcode_core`，本模块只保留 Flutter 教学 UI、状态编排和绘制交互。

## 功能目标

调用 `gcode_core` 将 G-code 文本或文件解析为轨迹段，并通过 CustomPaint、AnimationController 和教学模板展示 G0/G1 刀路执行过程。

## 文件结构

```
modules/ui/gcode_visualizer/
├── module_entry.dart              # 入口: 返回 GcodeVisualizerPage
├── AI_ANALYSIS.md                 # 模块分析文档
├── gcode_readline.dart            # 兼容导出: export package:gcode_core/gcode_core.dart
├── pages/
│   └── gcode_visualizer_page.dart # 教学页面，依赖 flutter_study_learning
├── state/
│   └── gcode_player_controller.dart # ChangeNotifier + AnimationController，编排解析、文件选择和播放
└── widgets/
    ├── command_timeline.dart      # 指令列表，高亮当前执行行
    ├── gcode_canvas.dart          # CustomPaint 轨迹画布
    ├── gcode_editor_panel.dart    # 编辑器 + 文件路径输入/选择/提取按钮
    └── playback_controls.dart     # 播放/暂停/重置/进度/速度控制
```

## 外部包依赖

| 包 | 用途 |
|---|---|
| `gcode_core` | G-code 读取、解析、错误收集、轨迹构建 |
| `flutter_study_learning` | 教学页面模板组件 |
| `flutter_study_platform_file_picker` | 文件选择 Dart API，macOS 原生通道仍由宿主应用注册 |

## 数据流

```
source text / path input / file picker
  -> gcode_core GcodeLineReader
  -> gcode_core GcodeReadlinePipeline
  -> GcodePlayerController
  -> GcodeCanvas / CommandTimeline / PlaybackControls
```

## 修改注意事项

1. 新增 G-code 语法、reader 或 toolpath 规则时修改 `../gcode_core`。
2. 本模块只处理 Flutter UI、播放状态和教学表达。
3. 文件选择能力来自 `flutter_study_platform_file_picker`，模块只传入 G-code 扩展名和弹窗文案。
4. 教学页面组件来自 `flutter_study_learning`。
