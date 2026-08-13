# Phase Summary — gcode_core

> 2026-06-14 · 当前版本 0.1.0 · 基于 xgimi_gcode2d 对比分析后的首轮优化完成

## 当前架构

```
lib/src/
├── application/                          ── 编排层
│   └── gcode_readline_pipeline.dart       Stream<Snapshot> 流式管道 + isolate 后台解析
├── core/                                 ── 核心抽象（本次新增）
│   ├── gcode_bounds.dart                 包围盒，增量合并，供 painter 复用
│   └── gcode_style.dart                  绘制样式，预创建 Paint，light/dark 工厂
├── data/readers/                         ── 输入/IO层
│   ├── gcode_line_reader.dart            抽象接口 Stream<GcodeLineRecord>
│   ├── string_gcode_line_reader.dart     内存字符串读取
│   └── file_gcode_line_reader.dart       流式文件读取（openRead + LineSplitter）
├── domain/                               ── 领域类型
│   ├── gcode_load_stage.dart             idle/reading/parsing/ready/failed 枚举
│   ├── gcode_line_record.dart            原始行元数据
│   ├── gcode_load_snapshot.dart          不可变进度快照（含 bounds）
│   └── parsed_gcode_line.dart            sealed class: command/error/skipped
├── models/                               ── 数据模型
│   ├── gcode_command.dart                G0/G1 + 参数 + 注释
│   ├── machine_position.dart             X/Y/F 位置状态
│   └── toolpath_segment.dart             起止点 + 类型（rapid/linear）
├── parser/                               ── 解析
│   ├── gcode_parser.dart                 词法/语法解析，支持流式 parseRecord
│   └── gcode_parse_result.dart           批量解析结果 + 错误 DTO
├── services/                             ── 业务逻辑
│   └── toolpath_builder.dart             批量/增量 toolpath 构建 + bounds 增量跟踪
└── widgets/                              ── Flutter 控件
    ├── gcode_canvas.dart                 CustomPaint 可视化（支持 Bounds + Style）
    ├── command_timeline.dart             指令/错误时间线列表
    └── playback_controls.dart            播放/暂停/进度/速度控件
```

## 首轮优化完成项 (2026-06-14)

### 1. GcodeBounds — 边界预计算
- **问题**：`_ToolpathPainter.paint()` 每帧 O(n) 遍历 segments 计算 bounds
- **方案**：`IncrementalToolpathBuilder.accept()` 增量维护 `GcodeBounds`，经由 `GcodeLoadSnapshot.bounds` 透传至 painter
- **效果**：painter 直接接收预计算 bounds，删除内部 `_calculateBounds()` 遍历

### 2. GcodeStyle — 样式抽离
- **问题**：painter 内每帧 `new Paint()` + 颜色硬编码
- **方案**：`GcodeStyle` 类预创建所有 Paint（rapidMoveBg/rapidMove/linearMoveBg/linearMove/toolHead/toolHeadGlow/origin/originDot/grid），`GcodeStyle.light()` 工厂
- **效果**：零帧内开销 + 外部可自定义配色

### 3. Isolate 后台流式解析
- **问题**：大文件解析阻塞 UI 线程
- **方案**：`loadFileInBackground(path)` / `loadStringInBackground(source)` 使用 `Isolate.spawn` + `SendPort`/`ReceivePort` 流式返回 `Stream<GcodeLoadSnapshot>`
- **效果**：与 `load()` 完全一致的 `await for` 消费方式，仅调用入口不同

### 不采纳的优化（已评估排除）

| 项 | 排除原因 |
|---|---|
| SoA 数据模型 (Float32List) | gcode_core 面向中小规模 G-code，Dart 对象开销可忽略；SoA 增加维护负担 |
| Viewport/Transform 两层分离 | 当前无 pan/zoom 交互需求，引入两层会增加不必要的复杂度 |
| Picture 缓存 / Checkpoint 缓存 | 当前 segment 量级下收益有限，后续如需要可作为第二轮专项 |
| G25/G102/G103 指令支持 | 业务领域不同，gcode_core 聚焦 G0/G1 |
| SceneClassifier（矢量/光栅分类） | 仅处理矢量路径，无分类需求 |
| GCodeMemoryTrace 调试日志 | 面向生产环境，教学级项目暂不需要 |

## 后续规划

### 优先级 A — 近期可做

| 任务 | 预估工作量 | 说明 |
|---|---|---|
| **Picture 缓存** | 中 | 已完成路径录制成 `ui.Picture`，播放时只画 tail，避免全量重绘 |
| **GcodeController** | 中 | ChangeNotifier 控制器，封装 play/pause/seek/speed 逻辑，替代示例 app 中手写 Timer |
| **错误统计增强** | 小 | `scannedLineCount` / `skippedLineCount` 透传至 snapshot |

### 优先级 B — 按需启动

| 任务 | 预估工作量 | 说明 |
|---|---|---|
| **G2 圆弧支持** | 大 | 新增 `GcodeSegmentType.arc`，painter 实现弧线绘制 |
| **多层绘制** | 大 | 背景网格/辅助线/路径分层，独立 togglable |
| **撤销/重做** | 中 | 编辑场景下的状态回退能力 |

### 优先级 C — 远期探索

| 任务 | 说明 |
|---|---|
| **SVG/Bitmap → G-code 生成** | 当前包只做解析+预览，生成是反向需求 |
| **3D 预览** | 需要整体架构升级 |

## 测试覆盖

```
flutter test     → 22 tests passed (parser × 11, toolpath × 3, pipeline × 3, widget × 1)
flutter analyze  → 0 issues
```
