# Agent-Driven Development Foundation Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** 将 `flutter_study` 从“有部分 Agent 文档”升级为可复现、可验证、可审计、可由 Agent 独立闭环执行的工程。

**Architecture:** 保留现有 `AGENTS.md + JSON 机器契约 + 分层 AI_ANALYSIS.md` 体系，将环境、命令、质量门禁、任务输入和变更输出全部标准化。优先解决单仓无法自举和质量门禁不可运行，再补 CI、文档漂移检测、任务模板和平台验收。

**Tech Stack:** Flutter 3.44.6、Dart 3.12.2、Node.js 20.20.2、GitHub Actions、FlutterGuard、JSON Schema、Shell/Node.js automation。

---

## 1. 当前基线与关键结论

### 已具备

- `AGENTS.md` 已定义修改协议、新模块规则、验收规则和禁止事项。
- `AI_ANALYSIS_SCHEMA.json`、`AI_PROJECT_CONTEXT.md`、`REFACTOR_PLAN.md` 已采用 JSON 机器契约。
- 根、分层、分类和模块级共有 32 个 `AI_ANALYSIS.md`；`node tool/validate_agent_docs.js` 当前通过，输出 `agent_docs_valid:36`。
- `tool/generate_agent_indexes.js` 可生成 Agent 索引，`tool/validate_agent_docs.js` 可做基础一致性校验。
- `.githooks/pre-commit` 已存在且 `core.hooksPath=.githooks` 已启用。
- 本机 Flutter Doctor 全绿：Flutter 3.44.6、Dart 3.12.2、Android SDK 36.1、JDK 21（Android Studio 内置）、Xcode 26.6、CocoaPods 1.16.2。

### 阻塞问题

1. **单仓无法自举。** `pubspec.yaml` 依赖 5 个仓库外相对路径；其中 `flutterguard_cli` 仍指向已不存在的 `../flutterguard/packages/flutterguard_cli`，实际包已在 `../flutterguard` 根目录。
2. **质量门禁当前不可执行。** `flutter analyze`、`flutter test`、FlutterGuard 都在依赖解析阶段因上述路径失败。
3. **格式基线未收敛。** `dart format` 检测到 138 个 Dart 文件中的 85 个会变化。
4. **无 CI。** 仓库没有 `.github/workflows/`，规则仅依赖开发者本机钩子，Agent 可在未启用钩子的环境中绕过。
5. **工具链未精确锁定。** README 只写 Flutter 3.x / Dart 3.x；项目没有 `.fvmrc`、`.nvmrc` 或统一版本检查脚本。
6. **文档存在漂移。** `README.md` 引用了不存在的 `PLUGIN_DECOMPOSITION_PLAN.md`；`GCODE_VISUALIZER_EVOLUTION_PLAN.md` 仍使用迁移前的 `lib/gcode_visualizer/...` 路径，并记录了不可作为当前事实使用的历史测试结果。
7. **生成源是手写清单。** `tool/generate_agent_indexes.js` 的模块、状态、依赖和分类清单与路由表重复维护，存在双源漂移。
8. **预提交门禁不完整。** 当前只运行 FlutterGuard，没有生成文档校验、格式化、分析和测试。
9. **FlutterGuard 配置重复。** `flutterguard.yaml` 中 `shared_purity` boundary 定义了两次。
10. **缺少 Agent 任务/交付协议。** 没有统一任务输入模板、变更报告模板、风险等级、允许修改范围和可机读验收结果。

---

## 2. 基础文档最小集合

文档应分为“人类入口”“Agent 契约”“决策记录”三层，避免同一事实重复维护。

### 人类入口

- `README.md`：项目定位、快速开始、支持平台、唯一权威命令入口。
- `CONTRIBUTING.md`：分支策略、提交规范、PR 流程、Definition of Done。
- `docs/DEVELOPMENT.md`：环境安装、自举、常用命令、故障排查。
- `docs/TESTING.md`：单元/Widget/Golden/集成/平台测试分层及何时必须补测试。
- `docs/RELEASE.md`：版本号、构建产物、平台发布与回滚。
- `SECURITY.md`：密钥处理、漏洞上报、依赖和平台权限审计。

### Agent 权威契约

- `AGENTS.md`：只保留全局行为规则、读取顺序、修改边界和统一门禁入口。
- `AI_PROJECT_CONTEXT.md`：架构边界、平台矩阵、入口和依赖方向。
- `REFACTOR_PLAN.md`：当前阶段、原子任务队列、依赖、状态和验收条件。
- `AI_ANALYSIS_SCHEMA.json`：所有机器文档的 schema 与约束。
- `lib/AI_MODULE_INDEX.md`：生成的模块索引，不手工编辑。
- `**/AI_ANALYSIS.md`：局部契约，只描述 ownership、依赖、入口、状态和验证。
- `docs/agent/TASK_SCHEMA.json`：Agent 任务输入格式。
- `docs/agent/CHANGE_REPORT_SCHEMA.json`：Agent 完成报告格式。
- `docs/agent/COMMANDS.json`：命令名、用途、是否修改文件、超时、产物和成功条件。

建议的任务字段：

- `id`
- `goal`
- `scope.allow`
- `scope.deny`
- `pre_read`
- `dependencies`
- `acceptance`
- `validation`
- `risk`
- `manual_review`
- `status`

建议的变更报告字段：

- `task_id`
- `changed_files`
- `tests_added`
- `commands`
- `results`
- `generated_artifacts`
- `known_risks`
- `manual_verification`
- `followups`

### 决策记录

- `docs/adr/README.md`：ADR 索引与状态定义。
- `docs/adr/0001-repository-layout.md`：单仓/多仓决策。
- `docs/adr/0002-agent-contract-source-of-truth.md`：哪些文档生成、哪些手写。
- `docs/adr/0003-platform-capability-boundary.md`：平台 API 和 fallback 规则。
- `docs/adr/0004-quality-gate.md`：必过检查、允许例外和例外期限。

ADR 只记录不可从代码直接推导的“为什么”，不要复制目录和 API 清单。

---

## 3. 推荐环境形态

### 首选：单仓工作区

将当前同级包迁入当前仓库：

- `packages/gcode_core`
- `packages/flutter_study_learning`
- `packages/file_picker_bridge`
- `packages/flutter_ioc_core`
- `tools/flutterguard_cli`，或改用已发布且锁版本的 FlutterGuard

同步调整：

- `pubspec.yaml`
- `pubspec.lock`
- `tool/migrate_sibling_packages.sh`（迁移完成后删除或归档）
- `AI_PROJECT_CONTEXT.md` 的生成源
- 所有依赖路径和相关 AI 契约

理由：Agent 在一个 clone 中即可获取源码、运行测试和提交原子变更；不会依赖开发机目录布局。

如果必须维持多仓，则将 path dependencies 改为带固定 tag/commit 的 Git dependencies，并提供 `tool/bootstrap.sh` 克隆脚本；不建议继续使用未声明的 `../` 相对目录约定。

### 工具链锁定

新增：

- `.fvmrc`：精确锁定 Flutter `3.44.6`。
- `.nvmrc`：锁定 Node.js `20.20.2`，供 Agent 文档生成器使用。
- `tool/check_environment.sh`：检查 Flutter、Dart、Node、Java、Xcode/CocoaPods、Android SDK 和必要平台目录。
- `tool/bootstrap.sh`：安装/校验工具、获取所有包依赖、启用 hooks、执行最小 smoke check。

不要用 Docker 作为唯一开发环境：Flutter 的 iOS/macOS 构建仍要求 macOS/Xcode。Docker 可作为纯 Dart、Web 和静态检查的补充环境。

---

## 4. 分阶段实施

### Task 1: 修复依赖布局并恢复可执行基线

**Objective:** 任意新 clone 不依赖未声明的父目录即可完成依赖解析。

**Files:**

- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create/Move: `packages/*` 或创建外部依赖 bootstrap 配置
- Modify: `tool/generate_agent_indexes.js`
- Modify: `AI_PROJECT_CONTEXT.md`（通过生成器）
- Modify/Delete: `tool/migrate_sibling_packages.sh`

**Steps:**

1. 为“单仓工作区”与“固定 Git 依赖”做一次 ADR 决策，默认选择单仓。
2. 先修正 FlutterGuard 的失效路径，不覆盖当前未提交的 `pubspec.yaml`/`pubspec.lock` 修改。
3. 迁入四个共享包和 FlutterGuard，逐包执行原有测试。
4. 执行 `flutter pub get`，确认不再访问仓库外路径。
5. 执行 `flutter analyze`、`flutter test`、FlutterGuard，记录真实基线。
6. 单独提交依赖布局变更，避免与格式化混在一起。

**Acceptance:**

- 新 clone 只需仓库内容和标准 SDK 即可 `flutter pub get`。
- 不存在 `path: ../...`。
- 所有包均有明确 owner、测试入口和 Agent 契约。

### Task 2: 建立唯一命令入口

**Objective:** 人和 Agent 使用同一组脚本，不再从多份文档拼接命令。

**Files:**

- Create: `tool/bootstrap.sh`
- Create: `tool/check_environment.sh`
- Create: `tool/quality_gate.sh`
- Create: `tool/test_all.sh`
- Create: `docs/agent/COMMANDS.json`
- Modify: `AGENTS.md`
- Modify: `README.md`

**Steps:**

1. `check_environment.sh` 输出版本、缺失组件和明确修复建议。
2. `bootstrap.sh` 校验环境、执行依赖获取、设置 hooks，不修改业务代码。
3. `test_all.sh` 遍历主应用与 workspace packages，逐包执行测试并保留失败码。
4. `quality_gate.sh` 按固定顺序执行：生成文档、检测生成差异、格式化、分析、测试、FlutterGuard。
5. 命令输出至少包含稳定的阶段标识和最终 exit code，便于 Agent 解析。
6. `AGENTS.md` 的验收规则改为唯一命令 `bash tool/quality_gate.sh`，详细步骤只在 `COMMANDS.json` 维护。

**Acceptance:**

- Agent 只需运行 bootstrap 与 quality gate 两个入口。
- 任一步失败都返回非零状态并指明失败阶段。
- 本地与 CI 调用完全相同的脚本。

### Task 3: 收敛格式和静态检查基线

**Objective:** 消除 85 个待格式化文件，使格式门禁具有信号价值。

**Files:**

- Modify: 当前 formatter 报告的 Dart 文件
- Modify: `analysis_options.yaml`
- Modify: `flutterguard.yaml`

**Steps:**

1. 在独立提交中执行 `dart format .`，不混入逻辑改动。
2. 删除 `flutterguard.yaml` 重复的 `shared_purity` 配置。
3. 评估并启用更严格但可渐进落地的 analyzer 规则；不要一次引入大量无关告警。
4. 运行全量质量门禁并建立当前 FlutterGuard medium 级基线。

**Acceptance:**

- 再次运行 formatter 不产生 diff。
- `flutter analyze` 无 error。
- FlutterGuard 无 high。

### Task 4: 强化机器文档生成与漂移检测

**Objective:** 模块清单、路由和契约不再靠重复手工维护。

**Files:**

- Modify: `tool/generate_agent_indexes.js`
- Modify: `tool/validate_agent_docs.js`
- Modify: `tool/generate_harness_ai_analysis.sh`
- Create: `tool/check_generated_docs.sh`
- Modify: `lib/app/router/app_route_table.dart` 或增加可解析的 registry source

**Steps:**

1. 明确单一源：推荐由结构化 registry manifest 生成 Dart 路由元数据和 AI 模块索引。
2. 验证器补充：模块目录注册覆盖、`module_entry.dart` 存在、元数据完整、route 唯一、目录/route 命名风格、教学模板依赖、父子索引一致。
3. 生成后执行 `git diff --exit-code`，CI 中发现未提交生成物即失败。
4. 验证所有 `.md` 机器文档确实为合法 JSON，并与 schema 版本一致。
5. 给生成器和验证器添加 Node 单元测试或 fixture 测试。

**Acceptance:**

- 新增未注册模块会失败。
- 修改路由而不更新契约会失败。
- 手工修改生成文件会失败。
- 生成器连续运行两次结果完全一致。

### Task 5: 清理和补齐基础文档

**Objective:** 消除失效链接、历史事实冒充当前事实和多源命令说明。

**Files:**

- Modify: `README.md`
- Create: `CONTRIBUTING.md`
- Create: `docs/DEVELOPMENT.md`
- Create: `docs/TESTING.md`
- Create: `docs/RELEASE.md`
- Create: `SECURITY.md`
- Move/Rewrite: `GCODE_VISUALIZER_EVOLUTION_PLAN.md`
- Create: `docs/adr/*.md`

**Steps:**

1. 删除或补回 README 中不存在的 `PLUGIN_DECOMPOSITION_PLAN.md` 引用。
2. 将 G-code 演进计划中的旧路径更新到 `lib/modules/ui/gcode_visualizer` 和 `packages/gcode_core`；历史测试数字标记时间与 commit，或移出权威文档。
3. README 只保留最短上手路径并链接详细文档。
4. 在 `CONTRIBUTING.md` 定义 Definition of Done：契约更新、测试、质量门禁、UI 证据、平台影响说明。
5. 文档增加 owner、last_verified 或 generated 标识，避免 Agent 不知道是否可编辑。

**Acceptance:**

- 仓库内文档链接检查通过。
- README 不引用不存在文件或迁移前路径。
- 命令、版本和平台支持状态只有一个权威来源。

### Task 6: 建立 CI 强制门禁

**Objective:** 无论提交来自人还是 Agent，远端都执行同一质量门禁。

**Files:**

- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/platform-smoke.yml`
- Create: `.github/dependabot.yml`
- Create: `.github/CODEOWNERS`
- Create: `.github/pull_request_template.md`
- Create: `.github/ISSUE_TEMPLATE/agent-task.yml`

**Steps:**

1. Linux job：文档校验、格式、analyze、全部纯 Dart/Flutter tests、FlutterGuard SARIF。
2. macOS job：macOS build、iOS simulator smoke（阶段开启）。
3. Windows job：Windows build 和关键插件 smoke。
4. Android job：debug APK 与 emulator smoke；在 `REFACTOR_PLAN.md` 阻塞任务完成后设为 required。
5. 上传 test、coverage、SARIF 和截图产物；失败时保留日志。
6. PR 模板强制填写任务 ID、修改范围、测试结果、平台影响、截图/人工验收和剩余风险。
7. 配置 protected branch required checks；本地 pre-commit 仅作快速反馈，CI 才是最终权威。

**Acceptance:**

- 未格式化、文档漂移、analyze error、test failure、FlutterGuard high 均阻止合并。
- Agent PR 能从 CI 产物还原验证过程。

### Task 7: 定义 Agent 任务与交付协议

**Objective:** Agent 获得边界明确、可验证、可恢复的原子任务。

**Files:**

- Create: `docs/agent/TASK_SCHEMA.json`
- Create: `docs/agent/CHANGE_REPORT_SCHEMA.json`
- Create: `docs/agent/examples/*.json`
- Modify: `REFACTOR_PLAN.md` generator source
- Modify: `AGENTS.md`

**Steps:**

1. 每个任务声明 allow/deny paths，避免越界重构。
2. 每个验收条件映射到真实命令或人工证据，不接受“应该可用”。
3. 高风险任务声明 `manual_review=true`：依赖升级、平台权限、原生配置、安全、数据迁移、发布。
4. Agent 输出结构化变更报告，并由 CI 校验 schema。
5. 任务状态只在质量门禁通过和人工条件满足后变为 completed。

**Acceptance:**

- 任一任务可在新会话中仅凭任务 JSON 和仓库契约执行。
- 完成报告能回答改了什么、如何验证、还有什么风险。

### Task 8: 补齐测试与平台证据

**Objective:** 让“通过”不仅代表静态检查通过，还代表主要行为和目标平台可用。

**Files:**

- Modify/Create: `test/**`
- Create: `integration_test/**`
- Create: `tool/capture_learning_pages.sh` 或等价 screenshot harness
- Modify: `REFACTOR_PLAN.md` generator source

**Steps:**

1. 为 registry/route contract、模块 entry smoke、平台 fallback 增加测试。
2. 每个 module 至少有入口 smoke test；逻辑模块覆盖正常、边界和错误分支。
3. 教学 UI 建立 360dp 窄屏、桌面宽屏和 text scale 基线。
4. 对 recommended 模块保存可审计截图或 golden；避免只写“人工看过”。
5. 对 Android/iOS/macOS/Windows 建立支持矩阵，并将 unsupported 状态呈现在模块元数据和 UI。

**Acceptance:**

- 新模块没有 smoke test 或教学模板验证时 CI 失败。
- 平台特定模块有明确支持/降级行为和测试证据。

---

## 5. 建议执行顺序

### P0：先恢复工程可运行

1. Task 1 依赖布局。
2. Task 2 唯一命令入口。
3. Task 3 格式与静态基线。

### P1：让规则不可绕过

4. Task 4 文档生成与漂移检测。
5. Task 6 CI 强制门禁。
6. Task 5 文档清理与 ADR。

### P2：提高 Agent 自主闭环能力

7. Task 7 任务/报告 schema。
8. Task 8 测试、平台和视觉证据。

---

## 6. 验证命令

实施完成后的目标入口：

```bash
bash tool/check_environment.sh
bash tool/bootstrap.sh
bash tool/quality_gate.sh
```

`tool/quality_gate.sh` 内部至少执行：

```bash
bash tool/generate_harness_ai_analysis.sh
git diff --exit-code -- AI_ANALYSIS_SCHEMA.json AI_PROJECT_CONTEXT.md REFACTOR_PLAN.md lib/**/AI_ANALYSIS.md lib/AI_MODULE_INDEX.md
dart format .
git diff --exit-code -- '*.dart'
flutter analyze
bash tool/test_all.sh
dart run flutterguard_cli:flutterguard scan --path . --fail-on high
```

平台阶段再执行：

```bash
flutter build macos
flutter build windows
flutter build apk --debug
flutter test integration_test
```

Windows build 必须在 Windows runner 执行；Android/iOS smoke 必须使用对应 emulator/simulator。

---

## 7. 风险与边界

- 当前 `pubspec.yaml` 和 `pubspec.lock` 有用户未提交修改；实施时必须先确认并保留，不能用 checkout 覆盖。
- 单仓迁移会影响多个原独立仓库的历史、发布方式和 CI，应先做 ADR，再移动文件。
- formatter 会改动 85 个文件，必须独立提交，避免掩盖逻辑 diff。
- CI 平台矩阵成本较高；先建立 Linux 核心门禁，再逐步把 macOS/Windows/Android 设为 required。
- 不应将所有知识写进 `AGENTS.md`。全局规则放 AGENTS，机器事实放 JSON 契约，决策原因放 ADR，操作步骤放 DEVELOPMENT/TESTING。
- 不建议允许 Agent 自动提交、推送、合并或发布；这些应作为显式授权动作，并由 branch protection/环境审批控制。

---

## 8. 完成定义

项目达到“Agent 开发驱动”基础标准时，应同时满足：

- 新机器单次 clone 后可通过脚本完成自举。
- Agent 无需猜测工具版本、依赖目录、入口、架构边界和验证命令。
- 所有权威机器文档可校验，生成物不可漂移。
- 本地与 CI 使用同一质量门禁。
- 任务输入和完成报告可机读、可追踪。
- 每个代码变更都有自动测试或明确人工证据。
- 平台支持状态显式，不支持的平台有可见 fallback。
- 任何规则失败都会阻止合并，而不是只写在文档里。
