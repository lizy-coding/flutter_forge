# Hermes Agent 项目架构记录

> flutter_study 项目 Hermes Agent 托管架构 — 完全托管模式
> 里程碑: agent_takeover_ready | 阶段: agent_managed | 更新: 2026-07-25

## 项目概述

flutter_study 是一个 Flutter 模块化学习应用，涵盖基础机制、异步并发、状态管理、UI 动效、弹窗列表、网络平台六大分类共 17 个学习模块。通过 Dart Pub Workspace 管理 4 个内部共享包。

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
│   ├── generate_agent_indexes.js      # Agent 文档生成器（唯一生成源）
│   ├── validate_agent_docs.js         # Agent 文档校验器
│   ├── generate_harness_ai_analysis.sh # 生成+校验入口
│   ├── quality_gate.sh               # 全量质量门禁（统一入口）
│   ├── bootstrap.sh                  # 环境自举
│   ├── check_environment.sh          # 环境检查
│   └── test_all.sh                   # 全量测试
├── docs/
│   ├── DEVELOPMENT.md                 # 开发指南
│   ├── TESTING.md                     # 测试指南
│   ├── agent/
│   │   ├── TASK_SCHEMA.json           # Agent 任务输入格式
│   │   ├── CHANGE_REPORT_SCHEMA.json  # Agent 变更报告格式
│   │   └── COMMANDS.json             # 项目命令清单
│   └── adr/
│       ├── README.md                  # ADR 索引
│       ├── 0001-repository-layout.md  # 单仓布局决策
│       └── 0002-agent-contract-source-of-truth.md # 契约生成源决策
├── .fvmrc                             # Flutter 3.44.6
├── .nvmrc                             # Node 20.20.2
└── .hermes/
    ├── README.md                      # 本文档
    └── plans/                         # Agent 执行计划归档
```

总计: 36 个 lib AI_ANALYSIS.md + 4 个 packages AI_ANALYSIS.md = 40 个验证通过。

## 分层架构

```
app/              ← 宿主引导 + 路由组装（禁止被 modules/ 依赖）
module_registry/  ← 模块元数据与分类（仅依赖 Flutter + go_router）
shared/           ← 业务无关能力（禁止依赖 app/ 和 modules/）
modules/          ← 学习模块叶子节点（禁止互相依赖）
packages/         ← 工作区共享包（Dart Pub Workspace，独立可测）
```

## 依赖方向

```
app → module_registry, shared, modules
shared → 仅 Flutter SDK
modules → module_registry, flutter_study_learning, packages/*
packages/* → 仅 Flutter/Dart SDK（独立包，workspace 内互不可见）
```

## 质量门禁（单一入口）

```bash
bash tool/quality_gate.sh
```

内部 5 阶段:
1. Agent 文档生成 + 校验 + 漂移检测 (40 contracts)
2. dart format + git diff (格式不漂移)
3. flutter analyze (0 errors)
4. test_all.sh (5/5 packages)
5. flutterguard --fail-on high (0 HIGH)

## 当前基线 (2026-07-25 — agent_takeover_ready)

| 项目 | 状态 |
|------|------|
| Agent 文档 | ✅ 40 契约验证通过，生成源已修正 |
| Pub Workspace | ✅ 4 包，resolution_status=active |
| dart format | ✅ 0 changed (174 files) |
| flutter analyze | ✅ 0 errors, 198 info |
| flutterguard | ✅ 0 HIGH, 5 MEDIUM |
| 测试 | ✅ 5/5 通过, 85 tests (main_app 11, gcode_core 30, learning 11, file_picker 2, ioc 22 + 子测试) |
| CI | ⏳ 待配置 .github/workflows/ |
| 工具链锁定 | ✅ .fvmrc (Flutter 3.44.6), .nvmrc (Node 20.20.2) |
| 质量门禁脚本 | ✅ quality_gate.sh, bootstrap.sh, test_all.sh, check_environment.sh |
| 人类文档 | ✅ CONTRIBUTING.md, docs/DEVELOPMENT.md, docs/TESTING.md |
| Agent 协议 | ✅ TASK_SCHEMA.json, CHANGE_REPORT_SCHEMA.json, COMMANDS.json |
| ADR | ✅ 0001-repository-layout, 0002-agent-contract-source-of-truth |
| 托管模式 | ✅ agent_managed (REFACTOR_PLAN.active_phase) |

## 已完成的里程碑

1. directory_layers — 分层目录结构
2. shared_package_extraction — 共享包提取
3. module_analysis_coverage — 模块分析覆盖
4. app_navigation_boundary — 应用导航边界
5. host_bootstrap_boundary — 宿主引导边界
6. workspace_package_import — 工作区包导入
7. agent_takeover_ready — Agent 完全托管就绪 ← 当前

## 待推进 (P1-P2)

| 项目 | 优先级 |
|------|--------|
| .github/workflows/ci.yml | P1 |
| Android 平台适配 (module_platform_contract → android_host) | P1 |
| FlutterGuard MEDIUM 消减 (5 issues) | P2 |
| 教学页视觉证据（截图/golden） | P2 |

## Agent 执行约定

1. 修改代码前: read AGENTS.md + .hermes/README.md + 目标 AI_ANALYSIS.md
2. 修改生成源: 编辑 tool/generate_agent_indexes.js，不要手改生成物
3. 验证: bash tool/generate_harness_ai_analysis.sh
4. 门禁: bash tool/quality_gate.sh
5. 禁止: 提交/推送/合并（除非用户明确授权）
6. 禁止: 手改 AI_MODULE_INDEX.md / AI_PROJECT_CONTEXT.md / REFACTOR_PLAN.md / packages/*/AI_ANALYSIS.md
