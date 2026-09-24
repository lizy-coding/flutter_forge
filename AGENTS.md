# AGENTS.md — Agent 开发规则

本文件是项目级 Agent 入口。以可执行规则为主；项目事实以机器契约和代码为准。

## 修改前必读

1. `AI_ANALYSIS_SCHEMA.json`
2. `AI_PROJECT_CONTEXT.md`
3. `REFACTOR_PLAN.md`
4. 目标目录最近的 `AI_ANALYSIS.md`

涉及平台、导航、模块准入或发布时，再读 `CONTEXT.md` 与相关 `docs/adr/`。`AI_*.md` 和 `REFACTOR_PLAN.md` 是 JSON 机器契约，禁止加入 Markdown 段落。

## 事实源与边界

- 模块、路由、平台限制及 Agent 文档的生成源：`tool/generate_agent_indexes.js`。
- 生成物禁止手改；修改生成源后运行 `bash tool/generate_harness_ai_analysis.sh`。
- `app/` 负责启动、应用壳和导航；`module_registry/` 负责模块元数据与平台判定。
- `shared/` 只放业务无关能力，不依赖 `app/` 或 `modules/`。
- `modules/` 是学习模块叶子节点，模块之间禁止直接依赖。
- 工作区内部包位于 `packages/`；禁止引用仓库外 `path: ../...` 依赖。

## 模块规则

新增模块必须同时具备：

- `module_entry.dart`，导出 `*Entry` Widget。
- `AI_ANALYSIS.md` 模块契约。
- 生成器中的模块注册、路由和完整 `ModuleEntry` 元数据。
- 至少一个 `lib/shared/learning` 教学模板组件。
- 对应模块测试；涉及状态、异步或平台能力时补行为测试。

标题使用中文学习语义，禁止只有工程目录名或无解释、无交互的孤立 Demo。

## 平台与导航

- 平台限制用 `ModulePlatformSupport.excludedPlatforms` 表达；普通模块使用空排除集合。
- 平台模块必须在生成源中显式声明排除集合并说明依据。
- 目录和路由统一通过 `module_registry` 判定；模块页面不得自行决定目录可见性。
- 不支持的平台保留稳定模块路径，并进入统一不可用说明页。
- 平台可用性与 `ModuleStatus.pending/ready/recommended` 相互独立。
- Android、iOS、Web 和小于 `600dp` 的窗口使用应用内导航。
- 仅桌面宽窗口且多窗口能力可用时创建分类窗口。
- UI 通过 `NavigationPolicy` 选择导航模式；`MultiWindowManager` 只管理桌面窗口生命周期。
- 平台接入、构建通过和真机/真实主机验收必须分开描述；不得扩大证据范围。

## 修改流程

1. 检查 `git status`，保留用户已有改动。
2. 读取目标契约和代码，修改最小必要范围。
3. 模块、依赖、路由、层级或平台声明变化时，同步更新生成源。
4. 逻辑变化补定向测试；教学 UI 变化补人工验收或截图说明。
5. 执行 `bash tool/quality_gate.sh`。

质量门禁必须通过：Agent 文档无漂移、Dart 格式无漂移、bare `flutter analyze` 无 issue、全量测试通过、测试布局合规、FlutterGuard 无 HIGH。

## Git 与发布

- `dev` 是开发分支；功能、修复、文档和发版准备先进入 `dev`。
- `master` 只能通过从 `dev` 发起的 Pull Request 合入；禁止直接或强制推送。
- 未经用户明确授权，不提交、不推送、不合并，不处理无关工作树改动。
- 禁止修改 `.github/workflows/ci.yml`、`tool/quality_gate.sh` 或其他门禁脚本语义，除非任务显式授权 `packaging_change` 并要求人工验收。
- 业务仓库 CI 只能构建暂存产物；GitHub Release 必须由 Agent Hub `release_hosting` 的 `release-plan` / `release-run --execute` 流程执行。

## 常用命令

```bash
bash tool/generate_harness_ai_analysis.sh
bash tool/quality_gate.sh
bash tool/build_web_release.sh
git config core.hooksPath .githooks
```
