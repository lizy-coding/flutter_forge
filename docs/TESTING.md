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
2. 教学模板验证（使用了 flutter_study_learning 组件）
3. 平台支持声明（ModuleEntry.platform_support）

## 测试环境

- 测试运行不依赖真实网络（使用 mock）
- 平台特定测试需在目标平台执行
- Golden 测试仅用于稳定组件
