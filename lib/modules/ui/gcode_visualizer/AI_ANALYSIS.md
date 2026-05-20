# G-code Visualizer 模块分析

> G-code 解析与轨迹动画演示模块。

## 功能目标

将 G-code 文本指令解析为结构化命令，生成刀路轨迹数据，并通过 CustomPaint 和 AnimationController 在 Canvas 上以动画形式展示执行过程。

## 文件结构

```
modules/ui/gcode_visualizer/
├── module_entry.dart              # 入口: 返回 GcodeVisualizerPage
├── AI_ANALYSIS.md                 # 模块分析文档
├── gcode_readline.dart            # readline 相关能力的模块级导出
├── application/
│   └── gcode_readline_pipeline.dart # 单行读取 -> 单行解析 -> 增量构建轨迹的应用管线
├── data/
│   └── readers/
│       ├── gcode_line_reader.dart        # 按行读取接口
│       ├── string_gcode_line_reader.dart # 编辑器文本的 readline 适配
│       └── file_gcode_line_reader.dart   # 文件 openRead + LineSplitter 按行读取
├── domain/
│   ├── gcode_line_record.dart     # 单行读取记录 (行号、原始文本、偏移)
│   ├── gcode_load_snapshot.dart   # 读取/解析阶段快照
│   ├── gcode_load_stage.dart      # idle/reading/parsing/ready/failed
│   └── parsed_gcode_line.dart     # 单行解析结果 (command/error/skipped)
├── models/
│   ├── gcode_command.dart         # 解析后的指令模型 (G0/G1, X, Y, F)
│   ├── machine_position.dart      # 机床位置模型 (x, y, feedRate)
│   └── toolpath_segment.dart      # 轨迹段模型 (start, end, type)
├── parser/
│   ├── gcode_parse_result.dart    # 解析结果 (commands + errors)
│   └── gcode_parser.dart          # 纯 Dart 解析器
├── services/
│   └── toolpath_builder.dart      # 一次性/增量地将指令转换为轨迹段列表
├── state/
│   └── gcode_player_controller.dart  # ChangeNotifier + AnimationController
├── widgets/
│   ├── command_timeline.dart      # 指令列表，高亮当前执行行
│   ├── gcode_canvas.dart          # CustomPaint 轨迹画布
│   ├── gcode_editor_panel.dart    # 多行文本编辑器 + 解析/示例按钮 (StatefulWidget, _HoverGestureWrapper 封装悬浮+按压+长按手势识别)
│   └── playback_controls.dart     # 播放/暂停/重置/进度/速度控制
└── pages/
    └── gcode_visualizer_page.dart # 教学页面 (LearningScaffold)
```

## 数据流

```
source text / file path
  -> GcodeLineReader.readLines()
  -> Stream<GcodeLineRecord>
  -> GcodeParser.parseRecord(record)
  -> ParsedGcodeLine(command/error/skipped)
  -> IncrementalToolpathBuilder.accept(command)
  -> GcodeLoadSnapshot(commands, errors, segments, linesRead, stage)
  -> GcodePlayerController.progress (AnimationController)
  -> GcodeCanvas (CustomPaint repaint)
```

兼容路径仍保留 `GcodeParser.parse(source)` 和 `ToolpathBuilder.build(commands)`，用于测试或小文本一次性解析。

## 关键类

| 类 | 作用 |
|---|------|
| `GcodeLineReader` | data 层读取接口，屏蔽文本来源或文件来源 |
| `StringGcodeLineReader` | 将编辑器文本按 `readLine` 语义输出为 `GcodeLineRecord` |
| `FileGcodeLineReader` | 使用 `File.openRead()` + `LineSplitter` 对文件单行读取 |
| `GcodeParser` | 纯 Dart 文本解析器，支持整段 `parse` 与单行 `parseRecord` |
| `GcodeReadlinePipeline` | application 层管线，聚合逐行读取、单行解析、增量轨迹构建和阶段快照 |
| `ToolpathBuilder` | 一次性将指令序列转换为轨迹段列表，跟踪机床当前位置 |
| `IncrementalToolpathBuilder` | 有状态增量构建器，每接收一条 `GcodeCommand` 生成 0/1 条运动段 |
| `GcodePlayerController` | ChangeNotifier 状态管理，整合 readline 管线、轨迹快照、动画播放 |
| `_ToolpathPainter` | CustomPainter，负责坐标映射、网格、路径分层绘制 |
| `GcodeVisualizerPage` | 教学页面，使用 LearningScaffold 组织交互演示和教学内容 |

## 解析范围

### 支持 (v1)
- G0 / G00: 快速定位
- G1 / G01: 线性插补
- X / Y: 绝对坐标
- F: 进给率（存储但不模拟物理时间）
- `;` 行尾注释
- `()` 括号注释
- 大小写不敏感
- 文本/文件统一按行读取，每行保留 `lineNumber` 和 `byteOffset`

### 延期
- G2/G3: 圆弧插补
- G20/G21: 英制/公制切换
- G90/G91: 绝对/增量模式切换
- Z 轴支持
- 刀具半径补偿
- 真实进给率计时
- Isolate 解析

## 绘制范围

| 图层 | 内容 | 样式 |
|------|------|------|
| 1 | 背景网格 | 浅灰 0.15 alpha |
| 2 | 完整路径 | 低透明度 |
| 3 | 快速段 (G0) | 蓝色，细线 |
| 4 | 线性段 (G1) | 绿色，粗线 |
| 5 | 已完成动画路径 | 高亮色 |
| 6 | 当前刀头标记 | 红色圆点 + 光晕 |
| 7 | 原点标记 | 橙色十字 |

### 坐标映射
- 计算 minX/maxX/minY/maxY
- 添加 padding
- fit scale = min(width/rangeX, height/rangeY)
- screenX = left + (machineX - minX) * scale
- screenY = bottom - (machineY - minY) * scale (Y 轴翻转)

## 状态管理

`GcodePlayerController` 使用 ChangeNotifier + AnimationController:
- `updateSource(String)` -> 更新编辑器内容
- `parse()` -> 使用 `StringGcodeLineReader` 逐行解析编辑器文本，重置播放状态
- `loadFilePath(String)` -> 使用 `FileGcodeLineReader` 逐行读取文件，作为文件选择器接入点
- `play()` / `pause()` / `reset()` -> 播放控制
- `seek(double)` -> 跳转进度
- `setSpeed(double)` -> 调整速度倍率
- `loadStage` / `linesRead` -> 暴露当前读取阶段和已读取行数

动画进度 0..1 映射到整个轨迹段列表，通过 `floor(progress * N)` 确定当前段索引。

## 修改注意事项

1. 解析器保持纯 Dart，不要引入 Flutter 依赖
2. 新增 G-code 指令支持时，同步更新 `_supportedCodes` 和 `ToolpathBuilder`
3. `CustomPainter.shouldRepaint` 仅依赖 progress 和 segments，避免不必要的重绘
4. 动画进度计算不应修改 segments 数据
5. 教学页面使用 LearningScaffold 组件，保持一致性
6. 文件读取能力只放在 `data/readers/`，controller 不直接处理 `dart:io`
7. 大文件解析应通过 `GcodeReadlinePipeline` 批量发布快照，避免每行刷新 UI

## 后续扩展计划

- 支持 G2/G3 圆弧插补（需要 Path.arcTo 或分段逼近）
- 支持多轴（Z 轴可视化，如颜色深浅表示 Z 高度）
- 真实进给率时间模拟（根据段长度和 F 值计算各段时间）
- 文件选择器 UI 与导入/导出功能
- 绘制点数抽离和抽稀缓存
- 播放帧率控制与抽帧策略
- Isolate 解析（大文件不阻塞 UI）
- 3D 视角切换
- 刀具路径仿真（显示刀具形状）
