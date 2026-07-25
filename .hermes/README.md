# Hermes Agent 项目架构记录

> 本文档记录 flutter_study 项目的 Hermes Agent 托管架构，供 Agent 和人类开发者参考。
> 最后更新: 2026-07-25

## 项目概述

flutter_study 是一个 Flutter 模块化学习应用，涵盖基础机制、异步并发、状态管理、UI 动效、弹窗列表、网络平台六大分类共 17 个学习模块。

## Agent 文档体系

```
flutter_study/
├── AGENTS.md                          # Agent 行为契约（入口）
├── AI_ANALYSIS_SCHEMA.json            # 文档 schema 定义
├── AI_PROJECT_CONTEXT.md              # 项目架构上下文（JSON 机器契约）
├── REFACTOR_PLAN.md                   # 任务队列与里程碑
├── AI_ANALYSIS.md                     # 工作区根索引
├── lib/
│   ├── AI_ANALYSIS.md                 # lib 层索引
│   ├── AI_MODULE_INDEX.md             # 模块索引（生成物）
│   ├── app/AI_ANALYSIS.md             # 应用壳层
│   ├── app/router/AI_ANALYSIS.md      # 路由层
│   ├── module_registry/AI_ANALYSIS.md # 模块注册表
│   ├── shared/AI_ANALYSIS.md          # 共享层
│   ├── modules/AI_ANALYSIS.md         # 模块根索引
│   └── modules/{category}/{module}/AI_ANALYSIS.md  # 17个模块契约
├── packages/
│   ├── gcode_core/AI_ANALYSIS.md      # G-code 解析包
│   ├── flutter_study_learning/AI_ANALYSIS.md  # 教学模板包
│   ├── file_picker_bridge/AI_ANALYSIS.md      # 文件选择桥接
│   └── flutter_ioc_core/AI_ANALYSIS.md        # IoC 容器
├── tool/
│   ├── generate_agent_indexes.js      # 文档生成器
│   ├── validate_agent_docs.js         # 文档校验器
│   ├── generate_harness_ai_analysis.sh # 生成+校验入口
│   ├── quality_gate.sh               # 全量质量门禁
│   ├── bootstrap.sh                  # 环境自举
│   ├── check_environment.sh          # 环境检查
│   └── test_all.sh                   # 全量测试
└── .hermes/
    ├── README.md                      # 本文档
    └── plans/                         # Agent 执行计划
```

总计: 36 个 AI_ANALYSIS.md + 4 个 AI_ANALYSIS.md (packages) = 40 个验证通过。

## 分层架构

```
app/              ← 宿主引导 + 路由组装（禁止被 modules/ 依赖）
module_registry/  ← 模块元数据与分类（仅依赖 Flutter + go_router）
shared/           ← 业务无关能力（禁止依赖 app/ 和 modules/）
modules/          ← 学习模块叶子节点（禁止互相依赖）
packages/         ← 工作区共享包（Dart Pub Workspace）
```

## 依赖方向

```
app → module_registry, shared, modules
shared → 仅 Flutter SDK
modules → module_registry, flutter_study_learning, packages/*
packages/* → 仅 Flutter/Dart SDK（独立包）
```

## 质量门禁

本地执行:
```bash
bash tool/quality_gate.sh
```

CI 等效步骤:
1. `bash tool/generate_harness_ai_analysis.sh` + `git diff --exit-code` (文档不漂移)
2. `dart format .` + `git diff --exit-code -- '*.dart'` (格式不漂移)
3. `flutter analyze` (无 error)
4. `bash tool/test_all.sh` (测试通过)
5. `dart run flutterguard_cli:flutterguard scan . --fail-on high` (无高优问题)

## 当前状态

| 项目 | 状态 |
|------|------|
| Agent 文档 | ✅ 40 契约验证通过 |
| Pub Workspace | ✅ 4 包已迁入，依赖解析正常 |
| dart format | ✅ 0 changed (85 files formatted this session, pending commit) |
| flutter analyze | ✅ 0 errors, 194 info, 1 warning |
| flutterguard | ❌ 2 HIGH issues (pre-existing: DefaultTabController/FocusNode in build) |
| 测试 | ⚠️ 3/5 通过 (main_app 11, gcode_core 30, file_picker_bridge 2; flutter_study_learning 与 flutter_ioc_core 无 test/) |
| CI | ❌ 尚未配置 |
| 工具链锁定 | ✅ .fvmrc (Flutter 3.44.6), .nvmrc (Node 20.20.2) |
| 质量门禁脚本 | ✅ tool/quality_gate.sh, bootstrap.sh, test_all.sh, check_environment.sh |
| 人类文档 | ✅ CONTRIBUTING.md, docs/DEVELOPMENT.md, docs/TESTING.md |
| Agent 协议 | ✅ docs/agent/TASK_SCHEMA.json, CHANGE_REPORT_SCHEMA.json, COMMANDS.json |
| ADR | ✅ 0001-repository-layout, 0002-agent-contract-source-of-truth |

## 待推进（P1-P2）

| 项目 | 优先级 |
|------|--------|
| 修复 2 个 FlutterGuard HIGH 问题 | P1 |
| 配置 .github/workflows/ci.yml | P1 |
| flutter_study_learning / flutter_ioc_core 补测试 | P2 |
| Android 平台适配 | P2 |
| 教学页视觉证据（截图/golden） | P2 |

## Agent 执行约定

1. 修改代码前读取 AGENTS.md + 目标 AI_ANALYSIS.md
2. 改动后执行 `bash tool/generate_harness_ai_analysis.sh`
3. 提交前执行 `bash tool/quality_gate.sh`
4. 禁止修改生成物（AI_MODULE_INDEX.md 等）而不更新生成源
5. 禁止提交、推送、合并（除非用户明确授权）
