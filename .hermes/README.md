# Hermes Agent 项目架构记录

> flutter_forge 项目 Hermes Agent 托管架构 — 完全托管模式
> 里程碑: online_video_player_landed | 阶段: agent_managed | 更新: 2026-08-02

## 项目概述

flutter_forge 是一个 Flutter 模块化学习应用，涵盖基础机制、异步并发、状态管理、UI 动效、弹窗列表、网络平台六大分类共 18 个学习模块。通过 Dart Pub Workspace 管理 4 个内部共享包。

## Agent 文档体系

```
flutter_forge/
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
│   └── modules/{category}/{module}/AI_ANALYSIS.md  # 18个模块契约
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
├── .github/workflows/ci.yml           # CI 流水线（FlutterGuard 固定版本）
├── .fvmrc                             # Flutter 3.44.6
├── .nvmrc                             # Node 20.20.2
└── .hermes/
    ├── README.md                      # 本文档
    ├── <task>.codex.json              # 单次任务 JSON 提词（Codex 执行依据）
    └── plans/                         # Agent 执行计划归档
```

总计: 37 个 lib AI_ANALYSIS.md + 4 个 packages AI_ANALYSIS.md = 41 个验证通过。

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
1. Agent 文档生成 + 校验 + 漂移检测 (41 contracts)
2. dart format + git diff (格式不漂移)
3. flutter analyze (0 errors)
4. test_all.sh (5/5 packages)
5. flutterguard --fail-on high (0 HIGH)

## 当前基线 (2026-08-02 — online_video_player_landed)

| 项目 | 状态 |
|------|------|
| Agent 文档 | ✅ 41 契约验证通过，生成源已修正 |
| Pub Workspace | ✅ 4 包，resolution_status=active |
| dart format | ✅ 0 changed |
| flutter analyze | ✅ 0 errors, 198 info |
| flutterguard | ✅ 0 HIGH, 5 MEDIUM（既有） |
| 测试 | ✅ 5/5 通过（含 online_video_player 3 用例） |
| CI | ✅ .github/workflows/ci.yml 已配置（FlutterGuard 固定版本） |
| 工具链锁定 | ✅ .fvmrc (Flutter 3.44.6), .nvmrc (Node 20.20.2) |
| 质量门禁脚本 | ✅ quality_gate.sh, bootstrap.sh, test_all.sh, check_environment.sh |
| 人类文档 | ✅ CONTRIBUTING.md, docs/DEVELOPMENT.md, docs/TESTING.md |
| Agent 协议 | ✅ TASK_SCHEMA.json, CHANGE_REPORT_SCHEMA.json, COMMANDS.json |
| ADR | ✅ 0001-repository-layout, 0002-agent-contract-source-of-truth |
| 托管模式 | ✅ agent_managed (REFACTOR_PLAN.active_phase) |
| 在线视频播放模块 | ✅ lib/modules/platform/online_video_player（media_kit，3 测试全过） |

## 已完成的里程碑

1. directory_layers — 分层目录结构
2. shared_package_extraction — 共享包提取
3. module_analysis_coverage — 模块分析覆盖
4. app_navigation_boundary — 应用导航边界
5. host_bootstrap_boundary — 宿主引导边界
6. workspace_package_import — 工作区包导入
7. agent_takeover_ready — Agent 完全托管就绪
8. online_video_player_landed — 在线视频播放模块落地（media_kit，macOS 优先）← 当前

## 最近进度（2026-07-25 → 2026-08-02）

| 日期 | 事项 |
|------|------|
| 2026-07-25 | quality_gate 5/5 通过，agent_takeover_ready 达成 |
| 2026-08-02 | 修复 tool/test_agent_tools.sh 用例（19/19 全绿） |
| 2026-08-02 | 新增「在线视频播放」模块：JSON 提词 → Codex 落地 → Hermes 验收 |
| 2026-08-02 | media_kit macOS 集成：entitlements 补 network.client、ensureInitialized 时序 |
| 2026-08-02 | 解决 libmpv xcframework 下载不可达（ghfast 镜像 + SHA256 校验） |
| 2026-08-02 | flutter build macos --debug 成功，quality_gate 5/5 通过 |
| 2026-08-02 | Notion 指导文档审查修正 + 配套实操示例页 |

## 待推进 (P1-P2)

| 项目 | 优先级 | 备注 |
|------|--------|------|
| Android 平台适配 (module_platform_contract → android_host) | P1 | REFACTOR_PLAN 中 blocked_by_dependencies |
| mobile_layout_baseline（移动端布局基线） | P1 | REFACTOR_PLAN 中 pending |
| platform_plugin_audit（平台插件审计） | P2 | REFACTOR_PLAN 中 pending |
| FlutterGuard MEDIUM 消减 (5 issues) | P2 | 既有问题，非本模块引入 |
| 教学页视觉证据（截图/golden） | P2 | 人工验收依赖 |

## 后续演进方向

1. **平台扩展**：在线视频播放模块当前 macOS 优先；后续按 REFACTOR_PLAN 推进 android_host，media_kit 三件套已支持 Android，预计补充网络权限声明与真机验证即可复用。
2. **多模块模式沉淀**：online_video_player 已验证「JSON 提词 → Codex → 独立验收」闭环，可作为新平台/新模块的标准执行范式。
3. **CI 强化**：ci.yml 已固定 FlutterGuard 版本；后续可补充 macOS 构建 job（media_kit 原生依赖需可下载的 CI 环境）。
4. **构建环境注意项**：libmpv 依赖 GitHub releases 下载；若网络受限需走镜像（ghfast.top），SHA256 校验 84d2ad98... 已固化在 pub-cache 缓存。
5. **Notion 文档体系**：指导文档 + 实操示例页已关联，后续每个新模块可在实操页追加一节约 1 屏的落地记录。

## Agent 执行约定

1. 修改代码前: read AGENTS.md + .hermes/README.md + 目标 AI_ANALYSIS.md
2. 修改生成源: 编辑 tool/generate_agent_indexes.js，不要手改生成物
3. 验证: bash tool/generate_harness_ai_analysis.sh
4. 门禁: bash tool/quality_gate.sh
5. 禁止: 提交/推送/合并（除非用户明确授权）
6. 禁止: 手改 AI_MODULE_INDEX.md / AI_PROJECT_CONTEXT.md / REFACTOR_PLAN.md / packages/*/AI_ANALYSIS.md
7. 任务提词: 写入 .hermes/<task>.codex.json（schema: flutter_forge.agent_task.v1），Codex 只执行提词，Hermes 独立验收
