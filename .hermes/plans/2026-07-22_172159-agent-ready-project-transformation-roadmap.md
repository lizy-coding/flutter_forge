# Agent-Ready Project Transformation Roadmap

# 1. Transformation Objective

## 当前项目状态

当前项目已经完成第一轮面向 Agent 的架构整理，具备以下基础：

- 已形成清晰的 Flutter 应用壳、模块注册、共享能力和教学模块分层。
- 已有 `AGENTS.md`、项目级机器上下文、重构任务队列、模块索引和模块级契约。
- 已有 Agent 文档生成与校验工具，当前机器文档能够通过基础一致性校验。
- 已引入 FlutterGuard 和本地 pre-commit hook。
- 已有部分 Widget/逻辑测试和平台工程。

但工程仍处于“Agent 可以获得部分上下文，但不能稳定独立闭环”的状态。当前最大限制不是继续增加说明文档，而是环境不可复现、依赖布局不自包含、质量门禁不能稳定运行、远端 CI 缺失、任务和交付协议尚未结构化。

## 为什么需要 Agent 化改造

Agent 协同开发需要把原本存在于开发者经验中的隐性知识，转换为可读取、可约束、可执行和可验证的工程能力。否则 Agent 即使能够生成代码，也可能出现：

- 无法在新环境完成依赖解析或运行项目。
- 不知道哪些文件是权威源，造成文档、路由和模块索引漂移。
- 修改范围失控，引入跨层依赖或无关重构。
- 只报告“已完成”，但没有真实测试和构建证据。
- 无法在新会话中继承架构决策、历史约束和未完成任务。
- 多个 Agent 并行工作时发生重复修改、契约冲突和知识分叉。

因此，本次改造目标不是“增加 AI 文档”，而是建立一套由工程机制保证的 Agent 协作系统。

## 改造后的目标状态

### AI Agent 可以理解项目上下文

- 能从统一入口定位项目目标、技术栈、架构边界、模块清单、平台支持和当前任务。
- 能区分手写权威文档、生成文档、历史记录和非权威说明。
- 能在局部修改前自动定位目标模块契约及相关 ADR。

### AI Agent 可以安全修改代码

- 每个任务具有明确的允许范围、禁止范围、风险等级和验收条件。
- 架构边界、路由一致性、模块元数据和平台能力由工具校验。
- 高风险操作需要人工授权，Agent 不能默认提交、推送、合并或发布。

### AI Agent 可以遵循项目规范

- 本地与 CI 使用同一个 bootstrap 和 quality gate。
- 格式化、静态分析、测试、文档漂移、架构扫描和安全检查不可绕过。
- 任务完成标准由命令和证据定义，而不是由 Agent 自我声明。

### AI Agent 可以持续维护项目知识

- 任务执行后输出结构化变更报告。
- 架构变化必须关联 ADR 和上下文更新。
- 自动检测过期路径、失效文档链接、生成文件漂移和模块契约缺失。
- 稳定知识进入项目契约；临时进度进入任务系统；历史原因进入 ADR。

### AI Agent 可以参与架构演进

- Agent 可以提出 ADR、影响分析和迁移计划，但架构决策需经过 Review。
- 架构规则可以逐步转化为自动化检查。
- 通过质量指标和失败反馈持续改进规则、测试与上下文，而不是无限扩张文档。

---

# 2. Current Gap Analysis

## A. Knowledge Gap

| 问题 | 影响程度 | 优先级 | 改造收益 |
|---|---|---|---|
| 项目已有机器上下文，但缺少统一 Agent 导航清单，权威源与生成物关系不够显式 | High | P0 | Agent 能快速定位上下文，避免重复读取和误改生成文件 |
| 缺少正式 ADR 体系，架构拆分和平台边界的“为什么”没有稳定记录 | High | P1 | 新 Agent 能理解历史取舍，减少反复推翻既有决策 |
| README 存在失效文档引用和迁移前路径 | Medium | P0 | 消除错误引导，降低环境准备和定位成本 |
| 技术栈只声明大版本，没有精确工具链和兼容矩阵 | High | P0 | 提升构建复现性，减少 Agent 环境差异 |
| 模块索引、路由注册和生成器中存在重复清单 | High | P1 | 建立单一事实源，防止模块、路由和契约漂移 |
| 测试策略、平台验收和 UI 证据要求分散在规则及任务计划中 | Medium | P1 | Agent 能根据变更类型选择正确验证层级 |
| 缺少项目级术语、状态和风险等级定义 | Low | P2 | 降低多 Agent 对同一概念的解释差异 |

## B. Engineering Process Gap

| 问题 | 影响程度 | 优先级 | 改造收益 |
|---|---|---|---|
| 仓库依赖多个未声明的父目录 path dependency，单次 clone 无法自举 | High | P0 | 新环境和 CI 可以独立完成依赖解析与验证 |
| FlutterGuard 依赖路径失效，导致 analyze、test 和安全扫描均无法运行 | High | P0 | 恢复完整质量基线，是后续所有改造的前提 |
| 已有 Agent 修改规范，但缺少统一 Definition of Done | High | P1 | 所有任务使用一致完成标准，减少“代码写完但未验证” |
| 缺少结构化 Task Specification | High | P1 | 任务边界、依赖和验收可被 Agent 精确执行 |
| 缺少结构化 Execution Report | Medium | P1 | Review 可以追溯实际命令、结果、风险和人工证据 |
| 缺少标准化 Review 流程和风险分级 | High | P1 | 高风险修改获得额外审查，普通任务保持高效 |
| pre-commit 只运行 FlutterGuard，没有覆盖文档、格式、分析和测试 | Medium | P1 | 本地更早发现失败，减少无效 CI 往返 |
| 格式基线未收敛，大量文件会被 formatter 修改 | Medium | P0 | 后续逻辑 diff 更清晰，格式门禁有实际信号 |
| 缺少依赖升级、发布和回滚流程 | Medium | P2 | Agent 可以安全参与维护和版本演进 |

## C. Agent Collaboration Gap

| 问题 | 影响程度 | 优先级 | 改造收益 |
|---|---|---|---|
| 已有 `AGENTS.md`，但缺少面向多 Agent 的统一入口 manifest | Medium | P1 | 不同 Agent/IDE 能解析同一上下文入口 |
| 缺少任务允许路径、禁止路径和副作用声明 | High | P1 | 防止越界修改、无关重构和危险操作 |
| 缺少 Agent 完成报告和证据格式 | High | P1 | 避免不可验证的成功声明，提升 Review 效率 |
| 缺少多 Agent 任务依赖、占用范围和冲突管理机制 | Medium | P2 | 降低并行修改同一模块导致的冲突 |
| 缺少项目知识生命周期规则 | High | P2 | 明确哪些信息进入契约、ADR、任务记录或应被删除 |
| 缺少 Agent 规则变更的 Review 和版本机制 | Medium | P2 | 防止规则被临时任务污染或持续膨胀 |
| 缺少架构提案模板和影响分析要求 | Medium | P2 | Agent 可以参与演进，但不能直接绕过架构治理 |
| 缺少失败复盘到规则/工具的反馈闭环 | Low | P2 | 将重复错误转化为长期工程能力 |

## D. Automation Gap

| 问题 | 影响程度 | 优先级 | 改造收益 |
|---|---|---|---|
| 没有远端 CI workflow | High | P0 | 所有提交获得不可绕过的统一验证 |
| analyze、test、FlutterGuard 当前被依赖路径阻断 | High | P0 | 恢复真实质量反馈和工程可运行性 |
| 测试只覆盖部分模块，缺少全模块入口 smoke | High | P1 | Agent 修改模块时能快速发现入口、路由和渲染回归 |
| 缺少生成文档的 deterministic/drift check | High | P1 | 保证机器上下文与代码同步 |
| 缺少路由、模块目录和注册表的自动交叉校验 | High | P1 | 防止孤立模块、重复路由和元数据缺失 |
| 缺少 Android/iOS/macOS/Windows 的分层 CI 策略 | Medium | P1 | 平台支持从声明变为真实构建证据 |
| UI 教学页缺少稳定截图或 Golden 验收体系 | Medium | P2 | Agent 能提供可审计的视觉修改证据 |
| 缺少依赖、密钥、权限和供应链检查 | Medium | P1 | 降低 Agent 引入不安全依赖和平台权限的风险 |
| 缺少机器可读测试、扫描和覆盖率产物 | Low | P2 | Agent 与 Reviewer 能更高效消费失败信息 |

---

# 3. Transformation Roadmap

## Phase 0: Project Baseline

### 目标

建立可复现、可运行、可验证的项目基线。任何开发者或 Agent 在一次 clone 后，都能够通过固定命令准备环境并执行核心检查。

### 能力建设

- 修复失效依赖并消除未声明的父目录依赖。
- 确定单仓 workspace 或固定版本多仓依赖策略；默认推荐单仓。
- 精确锁定 Flutter、Dart、Node 和平台工具要求。
- 建立 environment check、bootstrap 和统一命令入口。
- 清理 README 的失效路径和错误事实。
- 将全量格式化作为独立基线变更。
- 取得真实 analyze、test、FlutterGuard 基线。

### Exit Criteria

- 新 clone 不依赖开发者私有目录结构。
- bootstrap 可以完成依赖准备。
- 核心 quality gate 可以完整执行并返回可信状态。
- README 中的运行命令与真实环境一致。

## Phase 1: Agent Context Foundation

### 目标

建立统一、分层、可维护的 Agent 项目认知能力，并明确每类知识的权威来源。

### 能力建设

- 建立 `.agent/manifest.json` 作为 Agent 导航入口，不复制已有上下文。
- 定义 project、architecture、module、platform 和 command context 的引用关系。
- 建立 ADR 体系，记录仓库布局、单一事实源、平台边界和质量门禁决策。
- 扩展 Agent 文档 schema 与验证器。
- 消除路由、模块清单和索引之间的双源维护。
- 定义知识分类和生命周期：契约、ADR、任务、运行产物、历史档案。
- 建立文档 ownership、generated 标识和漂移检测。

### Exit Criteria

- Agent 可以从 `.agent/manifest.json` 定位所有必要上下文。
- Agent 能判断文档是否可编辑、由谁生成、何时更新。
- 新增或修改模块时，注册、索引、契约和验证保持一致。
- 架构决策有 ADR，可追溯且可 Review。

## Phase 2: Agent Development Workflow

### 目标

让 Agent 能够在明确边界内参与任务执行、变更报告和代码 Review。

### 能力建设

- 定义 Task Specification Schema。
- 定义 Execution Report Schema。
- 定义任务风险等级、允许路径、禁止路径和人工审批条件。
- 建立统一 Definition of Done。
- 建立 Agent PR/Review 模板和双阶段 Review：规范符合性、代码质量。
- 建立任务依赖、状态流转、冲突范围和变更跟踪机制。
- 提供模块新增、Bug 修复、架构提案等任务模板。
- 明确 Agent 不可默认执行的副作用：commit、push、merge、release、凭据和平台权限修改。

### Exit Criteria

- 任一任务可在新会话中仅凭任务规格和仓库上下文执行。
- 每次 Agent 交付都包含真实命令、结果、风险和未完成项。
- Reviewer 可以根据结构化证据判断是否满足完成条件。
- 高风险任务不能绕过人工审批。

## Phase 3: Engineering Quality System

### 目标

通过自动化门禁保证 Agent 修改可靠，使本地验证与远端验证一致。

### 能力建设

- 建立统一 `quality_gate`，覆盖生成文档、格式、analyze、test、FlutterGuard。
- 建立 GitHub Actions 核心 CI 和平台 smoke matrix。
- 补齐模块入口 smoke、路由/registry contract 和平台 fallback 测试。
- 定义单元、Widget、Golden、集成和平台测试策略。
- 建立代码覆盖率的渐进基线，而不是一次性追求高百分比。
- 增加依赖审计、secret scanning、权限变更检查和 SARIF 输出。
- 建立教学 UI 的窄屏、桌面、文字缩放和视觉证据流程。
- 将 required checks 与 branch protection 绑定。

### Exit Criteria

- 未格式化、文档漂移、analyze error、test failure、FlutterGuard high 都会阻止合并。
- 关键平台至少有构建或 smoke 证据。
- 新模块没有入口测试、元数据或教学模板时自动失败。
- CI 产物可以支持 Agent 自主定位失败原因。

## Phase 4: Continuous Agent Engineering

### 目标

形成长期可持续的 Agent 协作、知识维护和架构演进机制。

### 能力建设

- 建立知识 freshness 检查和定期维护任务。
- 将重复失败转化为规则、测试、脚本或 ADR。
- 建立架构提案、影响分析、迁移计划和弃用流程。
- 建立 Agent 规则版本和变更 Review。
- 建立多 Agent 并行任务冲突控制。
- 跟踪 CI 失败原因、返工率、文档漂移、测试稳定性和任务完成质量。
- 建立依赖升级、平台升级和 release readiness 自动检查。
- 定期删除无效知识，避免上下文无限增长。

### Exit Criteria

- 项目知识随代码变化持续更新，而不是依赖集中补文档。
- Agent 能提出架构演进方案，并通过 ADR 与质量门禁安全落地。
- 高频错误持续减少，规则和自动化保持高信号。
- 多 Agent 并行开发具有明确任务边界和冲突处理方式。

---

# 4. Task Breakdown

```yaml
- task_id: AR-P0-001
  title: 恢复依赖解析基线
  phase: Phase 0
  objective: 修复当前失效的 FlutterGuard 依赖，使主工程核心命令恢复可执行。
  background: 当前 flutterguard_cli path 指向已经不存在的子目录，analyze、test 和扫描均在依赖解析阶段失败。
  required_changes:
    - 确认并修正 flutterguard_cli 的实际依赖位置。
    - 保留当前 pubspec.yaml 和 pubspec.lock 中已有未提交修改。
    - 重新解析依赖并记录真实版本。
  affected_files:
    - pubspec.yaml
    - pubspec.lock
  constraints:
    - 不覆盖用户现有 pubspec 修改。
    - 不同时迁移其他依赖或格式化业务代码。
  acceptance_criteria:
    - flutter pub get 成功。
    - flutterguard_cli 可被 dart run 解析。
  validation:
    - flutter pub get
    - dart run flutterguard_cli:flutterguard --help

- task_id: AR-P0-002
  title: 决定并落实可复现仓库布局
  phase: Phase 0
  objective: 消除主工程对未声明父目录结构的依赖。
  background: 当前多个共享包通过 ../ path 引用，新 clone 和 CI 无法保证这些目录存在。
  required_changes:
    - 编写仓库布局 ADR，比较单仓 workspace 与固定 Git 依赖。
    - 默认将共享包迁入 packages/，将工具迁入 tools/ 或使用固定发布版本。
    - 更新依赖路径、测试入口和 Agent 上下文生成源。
  affected_files:
    - docs/adr/0001-repository-layout.md
    - pubspec.yaml
    - pubspec.lock
    - packages/**
    - tools/**
    - tool/generate_agent_indexes.js
  constraints:
    - 每个迁入包必须保留自身 pubspec、测试和公共 API。
    - 不在迁移任务中重构包内部业务逻辑。
  acceptance_criteria:
    - 仓库内不存在未声明的 path: ../ 依赖。
    - 全新 clone 可以完成依赖解析。
    - 所有迁入包可独立测试。
  validation:
    - flutter pub get
    - bash tool/test_all.sh
    - search repository for forbidden parent path dependencies

- task_id: AR-P0-003
  title: 锁定开发工具链
  phase: Phase 0
  objective: 让开发者、Agent 和 CI 使用一致的 Flutter 与 Node 工具版本。
  background: 当前文档只声明 Flutter 3.x/Dart 3.x，无法保证格式化、分析和生成结果一致。
  required_changes:
    - 锁定 Flutter 3.44.6。
    - 锁定 Node.js 20.20.2。
    - 声明 Dart、JDK、Android SDK、Xcode 和 CocoaPods 的兼容要求。
  affected_files:
    - .fvmrc
    - .nvmrc
    - docs/DEVELOPMENT.md
    - README.md
  constraints:
    - 不将 Docker 作为 iOS/macOS 唯一开发环境。
    - 版本事实只维护一个权威来源。
  acceptance_criteria:
    - 环境文档包含精确版本和兼容策略。
    - CI 使用相同 Flutter/Node 版本。
  validation:
    - fvm flutter --version
    - node --version
    - flutter doctor -v

- task_id: AR-P0-004
  title: 建立环境检查和自举入口
  phase: Phase 0
  objective: 用固定脚本完成环境诊断、依赖准备和 hook 启用。
  background: 当前环境准备步骤分散，且不会提前发现依赖目录和平台工具缺失。
  required_changes:
    - 新增只读环境检查脚本。
    - 新增 bootstrap 脚本。
    - 输出稳定阶段标识、缺失项和修复建议。
  affected_files:
    - tool/check_environment.sh
    - tool/bootstrap.sh
    - docs/agent/COMMANDS.json
    - README.md
  constraints:
    - 环境检查不得修改业务代码。
    - bootstrap 必须可重复执行。
    - 不自动安装需要管理员权限的软件。
  acceptance_criteria:
    - 新环境可通过一个命令得到完整诊断。
    - bootstrap 重复执行不产生额外 diff。
  validation:
    - bash tool/check_environment.sh
    - bash tool/bootstrap.sh
    - git diff --check

- task_id: AR-P0-005
  title: 收敛格式化基线
  phase: Phase 0
  objective: 将当前格式差异收敛为独立、无逻辑修改的基线变更。
  background: 当前 formatter 会修改大量 Dart 文件，后续变更容易被格式噪声掩盖。
  required_changes:
    - 对全仓 Dart 文件执行统一 formatter。
    - 确保该任务不包含业务逻辑变更。
  affected_files:
    - lib/**/*.dart
    - test/**/*.dart
  constraints:
    - 独立提交。
    - 不修改 YAML、JSON、Markdown 或依赖版本。
  acceptance_criteria:
    - 第二次执行 formatter 不产生 diff。
    - analyze 和 tests 不因格式化产生行为变化。
  validation:
    - dart format .
    - git diff --exit-code after second format run
    - flutter analyze
    - flutter test

- task_id: AR-P0-006
  title: 清理项目入口文档漂移
  phase: Phase 0
  objective: 让 README 只包含当前真实且可执行的信息。
  background: README 存在失效计划文档引用，专项计划包含迁移前路径。
  required_changes:
    - 删除或恢复失效文档引用。
    - 更新迁移前路径。
    - 将历史测试数字标记为历史记录或移出权威说明。
    - 将详细环境步骤链接到 DEVELOPMENT 文档。
  affected_files:
    - README.md
    - GCODE_VISUALIZER_EVOLUTION_PLAN.md
    - docs/DEVELOPMENT.md
  constraints:
    - 不复制机器上下文中的模块清单。
    - 不声明未经真实构建验证的平台支持。
  acceptance_criteria:
    - 仓库内文档链接均有效。
    - README 命令可在当前基线运行。
  validation:
    - run repository documentation link checker
    - bash tool/bootstrap.sh

- task_id: AR-P1-001
  title: 建立 Agent 上下文导航入口
  phase: Phase 1
  objective: 让任意 Agent 从单一 manifest 定位项目权威上下文。
  background: 当前上下文文件已经较完整，但入口分散，不同 Agent 可能读取不同集合。
  required_changes:
    - 创建 .agent/manifest.json。
    - 引用 AGENTS、project context、task queue、schema、module index、commands 和 ADR index。
    - 标注 authored/generated、owner、update trigger 和读取优先级。
  affected_files:
    - .agent/manifest.json
    - AI_ANALYSIS_SCHEMA.json
    - AGENTS.md
  constraints:
    - manifest 只做导航，不复制上下文内容。
    - 使用 JSON，不引入自然语言 Markdown 机器契约。
  acceptance_criteria:
    - manifest 可通过 schema 校验。
    - Agent 能从 manifest 找到所有必读内容。
  validation:
    - node tool/validate_agent_docs.js
    - validate .agent/manifest.json against schema

- task_id: AR-P1-002
  title: 建立 ADR 治理体系
  phase: Phase 1
  objective: 记录不可从代码直接推导的架构决策及其原因。
  background: 当前已有架构结果，但缺少正式决策记录、替代方案和废弃流程。
  required_changes:
    - 定义 ADR 模板、状态和索引。
    - 补录仓库布局、上下文权威源、平台能力边界和质量门禁决策。
  affected_files:
    - docs/adr/README.md
    - docs/adr/0001-repository-layout.md
    - docs/adr/0002-agent-context-source-of-truth.md
    - docs/adr/0003-platform-capability-boundary.md
    - docs/adr/0004-quality-gate.md
  constraints:
    - ADR 记录 why，不复制代码结构清单。
    - 已接受 ADR 的替换必须通过新 ADR supersede。
  acceptance_criteria:
    - 每个核心架构约束都有可追溯决策。
    - ADR 状态和替代关系可被工具解析。
  validation:
    - run ADR index validator
    - run documentation link checker

- task_id: AR-P1-003
  title: 消除模块元数据双源维护
  phase: Phase 1
  objective: 建立路由、模块元数据和 Agent 模块索引的单一事实源。
  background: 当前模块清单同时存在于 Dart 路由表和 Node 生成器中。
  required_changes:
    - 选择结构化 registry manifest 或可解析的 Dart registry 作为唯一源。
    - 从唯一源生成或验证路由与 Agent 索引。
    - 删除生成器中的重复手写模块数组。
  affected_files:
    - lib/app/router/app_route_table.dart
    - tool/generate_agent_indexes.js
    - tool/validate_agent_docs.js
    - lib/AI_MODULE_INDEX.md
    - lib/modules/**/AI_ANALYSIS.md
  constraints:
    - 不改变现有公开 route。
    - 生成过程必须 deterministic。
  acceptance_criteria:
    - 新增模块只需修改一个权威注册源。
    - 重复 route、缺失 entry、缺失 metadata 会校验失败。
  validation:
    - bash tool/generate_harness_ai_analysis.sh
    - run generator twice and assert zero diff
    - node tool/validate_agent_docs.js

- task_id: AR-P1-004
  title: 扩展 Agent 文档一致性校验
  phase: Phase 1
  objective: 将已有文档规则转化为自动化结构和交叉引用检查。
  background: 当前验证器只覆盖基础 JSON、必需键和部分索引一致性。
  required_changes:
    - 校验 module_entry.dart、分析文档、路由注册和 metadata 完整性。
    - 校验父子索引、命名风格、状态值和教学模板要求。
    - 增加 validator fixtures 和自动测试。
  affected_files:
    - tool/validate_agent_docs.js
    - tool/test_agent_docs/**
    - AI_ANALYSIS_SCHEMA.json
  constraints:
    - 失败输出必须稳定且包含文件路径和错误代码。
    - 不通过扫描生成手工文件清单。
  acceptance_criteria:
    - 每类违规至少有一个负向 fixture。
    - 校验器失败能精确定位原因。
  validation:
    - run Node validator test suite
    - node tool/validate_agent_docs.js

- task_id: AR-P1-005
  title: 定义项目知识生命周期
  phase: Phase 1
  objective: 规定知识应进入契约、ADR、任务记录还是运行产物。
  background: 缺少生命周期会导致 AGENTS 和上下文不断膨胀，临时事实长期残留。
  required_changes:
    - 定义知识分类、owner、review 周期和删除条件。
    - 规定临时进度不得进入长期上下文。
    - 规定架构变化、模块变化和命令变化的更新触发器。
  affected_files:
    - docs/agent/KNOWLEDGE_LIFECYCLE.md
    - .agent/manifest.json
    - AGENTS.md
  constraints:
    - 不复制现有模块契约内容。
    - 每类知识必须只有一个权威位置。
  acceptance_criteria:
    - 常见知识类型均可映射到明确存储位置。
    - generated 与 authored 文档更新责任明确。
  validation:
    - manual architecture review
    - run documentation consistency checker

- task_id: AR-P2-001
  title: 定义 Agent Task Specification
  phase: Phase 2
  objective: 将开发任务表达为边界明确、可验证的机器契约。
  background: 当前任务队列有目标与验收，但缺少修改范围、风险、禁止行为和人工审批字段。
  required_changes:
    - 创建 Task Schema。
    - 定义 goal、scope、dependencies、acceptance、validation、risk 和 manual_review。
    - 提供 feature、bugfix、refactor 和 architecture proposal 示例。
  affected_files:
    - docs/agent/TASK_SCHEMA.json
    - docs/agent/examples/tasks/*.json
    - REFACTOR_PLAN.md
    - tool/generate_agent_indexes.js
  constraints:
    - 每个 acceptance criterion 必须映射到命令或人工证据。
    - 单个任务必须具有单一目标。
  acceptance_criteria:
    - 示例任务全部通过 schema 校验。
    - REFACTOR_PLAN 中活动任务可以映射到新 schema。
  validation:
    - run JSON Schema validation for task examples
    - node tool/validate_agent_docs.js

- task_id: AR-P2-002
  title: 定义 Agent Execution Report
  phase: Phase 2
  objective: 让 Agent 交付包含可审计的修改、验证和风险证据。
  background: 自然语言完成说明不利于自动 Review，也无法防止虚构或遗漏验证结果。
  required_changes:
    - 创建 Change Report Schema。
    - 定义 changed_files、commands、exit_codes、tests、artifacts、risks 和 followups。
    - 提供成功、部分完成和阻塞三类示例。
  affected_files:
    - docs/agent/CHANGE_REPORT_SCHEMA.json
    - docs/agent/examples/reports/*.json
  constraints:
    - 报告不得将未执行命令标为成功。
    - 外部副作用必须包含可验证 handle。
  acceptance_criteria:
    - 三类示例均通过 schema 校验。
    - CI 可读取报告并展示验证摘要。
  validation:
    - run JSON Schema validation for report examples

- task_id: AR-P2-003
  title: 建立统一 Definition of Done
  phase: Phase 2
  objective: 定义所有人类和 Agent 任务的共同完成标准。
  background: 当前验收规则存在，但分散在 AGENTS、README 和计划文档中。
  required_changes:
    - 定义通用完成条件。
    - 定义逻辑、UI、平台、依赖和架构变更的附加条件。
    - 将命令引用到 COMMANDS，而不是重复命令实现。
  affected_files:
    - CONTRIBUTING.md
    - docs/agent/COMMANDS.json
    - AGENTS.md
  constraints:
    - 完成条件必须可验证。
    - 不允许以“Agent 认为完成”作为验收依据。
  acceptance_criteria:
    - 每类变更都有明确自动和人工验收要求。
    - AGENTS 与 CONTRIBUTING 不重复维护命令细节。
  validation:
    - manual process review
    - documentation consistency check

- task_id: AR-P2-004
  title: 建立风险分级和副作用授权规则
  phase: Phase 2
  objective: 防止 Agent 默认执行高风险工程操作。
  background: 依赖升级、原生权限、发布和 Git 远端操作需要比普通代码修改更强的控制。
  required_changes:
    - 定义 low、medium、high 风险级别。
    - 定义必须人工审批的变更类别。
    - 将风险要求接入任务 schema 和 PR 模板。
  affected_files:
    - docs/agent/RISK_POLICY.md
    - docs/agent/TASK_SCHEMA.json
    - .github/pull_request_template.md
    - AGENTS.md
  constraints:
    - commit、push、merge、release 和凭据操作默认禁止。
    - 不在文档中记录任何密钥值。
  acceptance_criteria:
    - 高风险示例任务缺少 manual_review 时 schema 校验失败。
    - PR 模板能够显式展示风险和审批状态。
  validation:
    - run task policy tests
    - manual security review

- task_id: AR-P2-005
  title: 建立 Agent Review 流程
  phase: Phase 2
  objective: 将规范符合性 Review 与代码质量 Review 分离。
  background: 单次泛化 Review 容易同时遗漏任务越界和实现质量问题。
  required_changes:
    - 定义第一阶段 spec compliance review。
    - 定义第二阶段 code quality/security review。
    - 建立 PR checklist 和 review report 模板。
  affected_files:
    - docs/agent/REVIEW_PROCESS.md
    - .github/pull_request_template.md
    - .github/CODEOWNERS
  constraints:
    - 规范不符合时不得进入代码质量批准。
    - Reviewer 不得仅依赖 Agent 自述，必须检查真实 diff 和 CI。
  acceptance_criteria:
    - Review 模板覆盖 scope、acceptance、tests、architecture 和 risk。
    - 高风险目录拥有明确 owner。
  validation:
    - dry-run one existing task through review template
    - manual maintainer approval

- task_id: AR-P2-006
  title: 建立多 Agent 任务冲突协议
  phase: Phase 2
  objective: 让并行 Agent 在明确范围内工作并提前暴露冲突。
  background: 多 Agent 可能同时修改路由、生成源、pubspec 或同一模块。
  required_changes:
    - 定义任务 claim、allowed paths、shared hotspots 和 dependency 状态。
    - 定义冲突检测和重新排队规则。
    - 标记必须串行执行的全局文件。
  affected_files:
    - docs/agent/COLLABORATION_PROTOCOL.md
    - docs/agent/TASK_SCHEMA.json
    - REFACTOR_PLAN.md
  constraints:
    - 不引入复杂分布式锁服务。
    - 先使用任务元数据和 CI 冲突检查实现。
  acceptance_criteria:
    - 两个重叠 scope 的 active 任务可被检测。
    - 全局生成源变更会自动标记为串行任务。
  validation:
    - run overlap detection fixtures
    - simulate two conflicting task specifications

- task_id: AR-P3-001
  title: 建立统一质量门禁
  phase: Phase 3
  objective: 用一个脚本执行所有核心质量检查并保留准确失败码。
  background: 当前检查命令分散，本地与未来 CI 容易产生差异。
  required_changes:
    - 建立 quality_gate 脚本。
    - 依次执行生成文档、漂移检查、格式、analyze、tests 和 FlutterGuard。
    - 输出稳定阶段标识和最终摘要。
  affected_files:
    - tool/quality_gate.sh
    - tool/test_all.sh
    - docs/agent/COMMANDS.json
    - AGENTS.md
    - .githooks/pre-commit
  constraints:
    - 任一阶段失败必须返回非零状态。
    - CI 与本地调用同一个脚本。
  acceptance_criteria:
    - 模拟每类失败时 quality gate 都能阻止通过。
    - 全部通过时工作区没有未预期生成差异。
  validation:
    - bash tool/quality_gate.sh
    - run failure fixtures for each gate stage

- task_id: AR-P3-002
  title: 建立核心 CI Workflow
  phase: Phase 3
  objective: 在远端对所有 PR 执行不可绕过的核心质量门禁。
  background: 当前没有 .github/workflows，规则只依赖本地配置。
  required_changes:
    - 创建 Linux 核心 CI。
    - 配置 Flutter/Node 缓存与精确版本。
    - 上传测试、覆盖率和 FlutterGuard SARIF。
    - 配置并发取消和超时。
  affected_files:
    - .github/workflows/ci.yml
    - .github/CODEOWNERS
    - .github/pull_request_template.md
  constraints:
    - CI 必须调用仓库内 quality_gate。
    - 不在 workflow 中复制质量门禁逻辑。
  acceptance_criteria:
    - PR 自动运行核心门禁。
    - 失败检查阻止合并。
    - 日志和产物足以定位失败。
  validation:
    - trigger CI on test pull request
    - verify required check and SARIF upload

- task_id: AR-P3-003
  title: 建立测试策略和模块最低测试契约
  phase: Phase 3
  objective: 明确不同变更类型所需测试，并为每个模块建立入口 smoke 基线。
  background: 当前测试只覆盖部分模块，不能保证所有 module entry 和 route 可渲染。
  required_changes:
    - 定义单元、Widget、Golden、集成和平台测试适用条件。
    - 为所有模块增加或生成入口 smoke 测试。
    - 增加 registry/route contract tests。
  affected_files:
    - docs/TESTING.md
    - test/modules/**
    - test/shared/module_registry_contract_test.dart
    - tool/validate_agent_docs.js
  constraints:
    - smoke test 不依赖脆弱的精确像素和动画时序。
    - 逻辑测试覆盖正常、边界和错误路径。
  acceptance_criteria:
    - 每个注册模块至少有入口 smoke 证据。
    - 路由和 registry 不一致时测试失败。
  validation:
    - flutter test
    - node tool/validate_agent_docs.js

- task_id: AR-P3-004
  title: 建立平台构建与 Smoke Matrix
  phase: Phase 3
  objective: 将平台支持声明转化为实际构建和降级行为证据。
  background: 当前目标平台包括 Android、iOS、macOS 和 Windows，但尚无远端平台矩阵。
  required_changes:
    - 创建 macOS、Windows、Android 分层 workflow。
    - Android readiness 完成后加入 emulator smoke。
    - 为不支持的平台验证 availability/fallback 状态。
  affected_files:
    - .github/workflows/platform-smoke.yml
    - integration_test/**
    - REFACTOR_PLAN.md
  constraints:
    - Windows build 只在 Windows runner 执行。
    - iOS/macOS 只在 macOS runner 执行。
    - 尚未 ready 的平台先作为 non-blocking check。
  acceptance_criteria:
    - 已声明支持的平台至少有 build 证据。
    - unsupported module 不崩溃并展示明确状态。
  validation:
    - flutter build macos
    - flutter build windows on Windows CI
    - flutter build apk --debug
    - flutter test integration_test

- task_id: AR-P3-005
  title: 建立安全与供应链门禁
  phase: Phase 3
  objective: 降低 Agent 引入不安全依赖、密钥和平台权限的风险。
  background: 当前已有 FlutterGuard，但缺少依赖、secret 和权限变更专项检查。
  required_changes:
    - 配置 secret scanning 和 dependency review。
    - 配置 Dependabot 或等价依赖更新机制。
    - 对 Android/iOS/macOS/Windows 权限文件设置 owner 和 Review 要求。
    - 保留 FlutterGuard SARIF。
  affected_files:
    - .github/dependabot.yml
    - .github/workflows/security.yml
    - .github/CODEOWNERS
    - SECURITY.md
  constraints:
    - 不自动合并依赖升级。
    - 高风险权限变更必须人工 Review。
  acceptance_criteria:
    - 测试密钥 fixture 会触发扫描失败。
    - 依赖变更会生成 review 报告。
    - 平台权限文件变更需要指定 owner。
  validation:
    - run security workflow with fixtures
    - verify dependency review on test PR

- task_id: AR-P3-006
  title: 建立教学 UI 视觉证据流程
  phase: Phase 3
  objective: 为 Agent 的 UI 修改提供稳定、可审计的视觉验收证据。
  background: 当前规则要求人工验收或截图，但没有统一生成和保存方式。
  required_changes:
    - 定义 360dp、桌面宽屏和文字缩放场景。
    - 为 recommended 模块建立 screenshot/golden harness。
    - 在 CI 上传差异图和运行截图。
  affected_files:
    - docs/TESTING.md
    - test/goldens/**
    - tool/capture_learning_pages.sh
    - .github/workflows/platform-smoke.yml
  constraints:
    - Golden 更新必须显式审批。
    - 动画页面使用稳定状态，不依赖随机时间点。
  acceptance_criteria:
    - UI PR 能产出前后视觉证据。
    - 窄屏 overflow 和文字缩放问题可被测试发现。
  validation:
    - flutter test --update-goldens only in approved update flow
    - flutter test test/goldens
    - verify CI artifact upload

- task_id: AR-P4-001
  title: 建立知识 Freshness 检查
  phase: Phase 4
  objective: 自动发现过期路径、失效链接、陈旧版本和未更新契约。
  background: 当前已出现 README 失效引用和专项计划旧路径，说明知识会随重构漂移。
  required_changes:
    - 增加文档链接和路径检查。
    - 比对工具版本声明与锁定文件。
    - 对生成文档增加更新时间来源而非手工时间戳。
  affected_files:
    - tool/check_knowledge_freshness.js
    - docs/agent/COMMANDS.json
    - .github/workflows/ci.yml
  constraints:
    - 不依赖容易误报的自由文本语义判断作为阻断条件。
    - 优先检查可确定的路径、链接、版本和 schema。
  acceptance_criteria:
    - 失效仓库路径和文档链接会使 CI 失败。
    - 版本声明漂移会被检测。
  validation:
    - run freshness checker fixtures
    - node tool/check_knowledge_freshness.js

- task_id: AR-P4-002
  title: 建立架构演进提案流程
  phase: Phase 4
  objective: 让 Agent 可以提出、评估并安全实施架构变化。
  background: Agent 当前可以修改代码，但缺少正式的影响分析和迁移治理流程。
  required_changes:
    - 定义 architecture proposal 模板。
    - 要求 alternatives、impact、migration、rollback 和 enforcement plan。
    - 将已接受提案转化为 ADR、任务和自动规则。
  affected_files:
    - docs/agent/ARCHITECTURE_PROPOSAL.md
    - docs/adr/README.md
    - docs/agent/TASK_SCHEMA.json
  constraints:
    - Agent 不得自行批准架构提案。
    - 架构变化必须包含回滚或兼容策略。
  acceptance_criteria:
    - 提案可以拆分为可执行任务。
    - 接受后的约束至少有文档或自动化 enforcement。
  validation:
    - dry-run one platform-boundary proposal
    - manual architecture board review

- task_id: AR-P4-003
  title: 建立失败反馈到工程规则的闭环
  phase: Phase 4
  objective: 将重复出现的 Agent 失败转化为测试、检查或知识改进。
  background: 仅记录失败不会提高后续 Agent 的成功率，需要明确升级机制。
  required_changes:
    - 定义失败分类和复盘模板。
    - 规定重复失败升级为规则、fixture、测试、脚本或 ADR的条件。
    - 记录修复后的防回归证据。
  affected_files:
    - docs/agent/FAILURE_FEEDBACK_LOOP.md
    - docs/agent/CHANGE_REPORT_SCHEMA.json
    - tool/quality_gate.sh
  constraints:
    - 不将单次临时故障直接写入长期 AGENTS。
    - 新规则必须有真实失败案例和验证方式。
  acceptance_criteria:
    - 重复失败可关联到具体防回归机制。
    - 无效或高误报规则可以被废弃并记录原因。
  validation:
    - review three historical failure examples
    - verify each selected example maps to a durable control

- task_id: AR-P4-004
  title: 建立 Agent 工程健康指标
  phase: Phase 4
  objective: 用少量高信号指标评估 Agent 化改造是否真正提升交付质量。
  background: 缺少指标时容易以文档数量代替工程效果。
  required_changes:
    - 跟踪 bootstrap 成功率、CI 首次通过率、返工率、漂移失败和 flaky tests。
    - 跟踪任务越界、缺失验证和人工回退原因。
    - 定义季度清理和改进节奏。
  affected_files:
    - docs/agent/ENGINEERING_METRICS.md
    - .github/workflows/ci.yml
    - tool/report_engineering_health.js
  constraints:
    - 不以代码量、文档量或 Agent 调用次数作为核心成功指标。
    - 不收集密钥、提示内容或个人敏感数据。
  acceptance_criteria:
    - 指标可以由 CI 和任务报告自动汇总。
    - 每个指标都有明确改善动作，而不是只展示数字。
  validation:
    - generate sample engineering health report from CI fixtures
    - manual quarterly review dry-run

- task_id: AR-P4-005
  title: 建立知识和规则精简机制
  phase: Phase 4
  objective: 防止 Agent 上下文、规则和历史文档无限增长。
  background: 长期 Agent 协作容易积累重复、过期和互相冲突的规则。
  required_changes:
    - 定义规则合并、废弃和归档流程。
    - 检测重复命令、重复约束和孤立文档。
    - 对 AGENTS、manifest 和机器上下文设置规模与职责边界。
  affected_files:
    - docs/agent/KNOWLEDGE_LIFECYCLE.md
    - tool/check_knowledge_freshness.js
    - .agent/manifest.json
  constraints:
    - 删除架构知识前必须确认是否已被 ADR 或代码规则吸收。
    - 不保留可以从代码稳定生成的手工清单。
  acceptance_criteria:
    - 重复和孤立知识可自动报告。
    - 每次季度维护可以删除或合并无效上下文。
  validation:
    - run duplicate/orphan knowledge checker
    - manual review of generated cleanup report
```

---

## Recommended Execution Order

1. `AR-P0-001` 恢复依赖解析。
2. `AR-P0-002` 落实单仓或固定依赖布局。
3. `AR-P0-003` 至 `AR-P0-006` 建立可复现基线。
4. `AR-P1-*` 建立上下文单一事实源和 ADR。
5. `AR-P2-*` 建立任务、报告、风险和 Review 协议。
6. `AR-P3-001` 与 `AR-P3-002` 优先建立强制质量门禁。
7. 逐步完成测试、安全、平台和视觉证据能力。
8. 最后启用 `AR-P4-*` 的长期治理与反馈闭环。

## Transformation Completion Definition

当以下条件同时满足时，项目可视为达到 Agent-Ready 基础成熟度：

- 一次 clone 后可以通过标准脚本自举。
- Agent 能从统一 manifest 获取上下文和规则。
- 每个任务有明确 scope、风险、验收和验证。
- 每次交付有真实、机器可读的执行证据。
- 代码、文档、模块索引和架构约束之间不存在未检测漂移。
- 本地与 CI 使用同一质量门禁，失败会阻止合并。
- 架构演进通过 ADR、Review 和自动 enforcement 落地。
- 项目知识能够更新、精简和淘汰，而不是只增不减。
