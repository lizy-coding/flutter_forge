# 测试指南

## 测试分层

| 层级 | 目录 | 工具 | 覆盖范围 |
|------|------|------|------|
| 单元测试 | `test/` | flutter_test | 逻辑、模型、服务 |
| Widget 测试 | `test/` | flutter_test | UI 组件行为 |
| 集成测试 | `integration_test/` | integration_test | 端到端用户流程 |
| 包测试 | `packages/*/test/` | flutter_test / dart test | 各包独立测试 |

## 执行测试

```bash
# 全量测试（主应用 + workspace packages）
bash tool/test_all.sh

# 仅主应用
flutter test

# 指定文件
flutter test test/gcode_visualizer/gcode_visualizer_page_test.dart

# 纯 Dart 包
cd packages/flutter_ioc_core && dart test
```

## 基线冒烟

```bash
bash tool/smoke_baseline.sh                # 基线用例，零网络，目标 2 分钟内
bash tool/smoke_baseline.sh --ax-soak      # 追加 macOS AX 语义浸泡（默认 24 轮，需本机 macos 设备）
```

冒烟是全项目测试中固定的关键路径子集，用于本地改动后的快速预检与事故回归入口；不替代 `tool/quality_gate.sh` 完整门禁。AX 浸泡背景见 `docs/reports/MACOS_AX_BRIDGE_CRASH-20261025.md`。

基线用例与选型依据（新关键链路被验证后补充进本表，保持零网络与确定性）：

| 用例 | 入口 | 验证什么 | 来源 |
|------|------|----------|------|
| 模块测试存在性 | `tool/verify_test_layout.sh` | 全模块测试结构完整 | 门禁子集 |
| GenUI 桥接 | `tool/genui_codex_bridge_test.py` | SSE 事件模式、回退、心跳（fake codex，零网络） | 2026-10-24 夜跑流式化 |
| GenUI 双会话管线 | `test/shared/genui_session_core_test.dart` | 取消保留前缀、流中错误、dispose 冻结、明文端点拒绝 | 夜跑加固 |
| GenUI 流式渲染 | `test/shared/module_discovery_streaming_test.dart` | 真实回环 SSE 分片+心跳渲染完整面 | 夜跑加固 |
| GenUI 工作台 + AX 语义边界 | `test/modules/ui/genui_workbench/genui_workbench_test.dart` | 工作台渲染与观测；快照 JSON 不进语义树、转写单节点 | 2026-10-25 AX 崩溃修复 |
| 多窗口生命周期 | `test/shared/multi_window_manager_test.dart` | 分类窗口创建、启动失败、重试 | 2026-10-21 多窗口崩溃修复 |
| 桌面工作台壳 | `test/shared/desktop_workbench_test.dart` | 导航壳结构与语义 | 既有基线 |
| 导航磁贴 | `test/shared/forge_nav_tile_test.dart` | 磁贴语义与交互 | 既有基线 |
| 工作流文章管线 | `packages/forge_articles/test/article_workflow_test.dart` | 文章工作流取消与转换 | 既有基线 |
| macOS AX 语义浸泡（可选） | `integration_test/genui_ax_soak_test.dart` | 语义开启下流式重建不触发引擎 AX 桥崩溃 | 2026-10-25 AX 崩溃修复 |

## 何时必须补测试

| 变更类型 | 要求 |
|------|------|
| 新增逻辑代码 | 补充单元测试 |
| 修改公共 API | 更新已有测试 |
| 新增模块 | 至少补入口 smoke test |
| 修复 bug | 补回归测试 |
| 平台特定功能 | 补平台分支测试 |

## 新模块验收

新模块必须通过：
1. 模块入口 smoke test（widget 可渲染）
2. 教学模板验证（使用 `shared/learning` 的教学组件，如 `LearningScaffold`）
3. 平台支持声明（ModuleEntry.platform_support）

## 测试环境

- 测试运行不依赖真实网络（使用 mock）
- 平台特定测试需在目标平台执行
- Golden 测试仅用于稳定组件
