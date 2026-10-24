# AGENTS.md — Agent 开发规则

本文件是项目级 Agent 入口。以可执行规则为主；项目事实以机器契约和代码为准。

## 修改前必读

1. `AI_ANALYSIS_SCHEMA.json`
2. `AI_PROJECT_CONTEXT.md`
3. `REFACTOR_PLAN.md`
4. 目标目录最近的 `AI_ANALYSIS.md`

涉及平台、导航、模块准入或发布时，再读 `CONTEXT.md` 与相关 `docs/adr/`。`AI_*.md` 和 `REFACTOR_PLAN.md` 是 JSON 机器契约，禁止加入 Markdown 段落。

## 有界探索

- 先从 Agent Hub 的 `workspace/projects.json` 与 `agent-context --project flutter-forge` 获取身份、近期 Git 路径与定点证据。
- Context/Capability 图必须传入明确的 `candidate_paths`；返回数量限制不代表实际读取范围受限。
- 先读当前 HEAD、工作区差异、根契约和目标目录最近的指南，再沿明确 imports/exports 扩展相关文件。禁止用全库递归扫描替代定位。
- 未提交实现可作为当前工作区事实，不能标成发布版本验收。已有生成物、截图和报告按其提交/主机范围解释。

## 事实源与边界

- 模块、路由、平台限制及 Agent 文档入口：`tool/generate_agent_indexes.js`；生成流水线和契约实现位于 `tool/agent_indexes/`，遵循该目录 `AGENTS.md`。
- 生成物禁止手改；修改生成源后运行 `bash tool/generate_harness_ai_analysis.sh`。
- `apps/flutter_forge/lib/app/` 负责启动、应用壳、导航与主题；遵循其 `AGENTS.md`。`module_registry/` 负责模块元数据与平台判定。
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
- 平台限制由 `tool/agent_indexes/availability.js` 的共用能力适配规则推导；模块仅声明可选能力或带依据的产品级禁用例外，禁止重复手填平台名单。
- 日常维护仅生成入口支持范围、必要功能差异与限制依据；`tool/module_availability.js list` 只读查看支持声明。测试结果、源码指纹和历史验收状态不进入维护矩阵，也不作为日常健康判定标准；专项报告按需保留，CI 测试继续作为开发反馈。
- 目录和路由统一通过 `module_registry` 判定；模块页面不得自行决定目录可见性。
- 不支持的平台保留稳定模块路径，并进入统一不可用说明页。
- 平台可用性与 `ModuleStatus.pending/ready/recommended` 相互独立。
- Android、iOS、Web 和小于 `600dp` 的窗口使用应用内导航。
- 桌面主框架遵循 `docs/adr/0016-shared-desktop-workbench.md`：macOS/Windows 共用 Flutter 沉浸式标题栏、工作台首页、两层分类／模块导航和快速打开；内容区共用布局；窗口控制遵循平台规范，macOS 左侧原生红黄绿按钮，Windows 右侧原生窗口按钮。
- 标题栏主页按钮进入当前窗口根路由；空白区双击遵循系统习惯；独立全屏按钮和 F11 切换真实全屏／窗口模式，不改变原生最大化按钮语义。主窗口关闭退出应用，分类窗口关闭仅影响自身。
- 四端交互遵循 `docs/adr/0018-platform-interaction-and-native-materials.md`，实施状态见生成计划。桌面基础导航页面默认原生材质；教学内容与侧栏实色、标题栏最低强度。现有 DesktopWindowHost 提供每窗口系统材质，macOS 使用系统模糊，Windows 使用公开 Mica 接口；旧系统／能力缺失／关闭透明或高对比度时回退实色，保持用户实色偏好。新增插件仍须先验证每引擎绑定与窗口控制兼容性。
- Web／移动首页为搜索、分类、最近访问，作者资料进入关于；移动以快速查阅为主，不新增底部标签栏。四端检索标题、简介、分类与概念，同会话返回保留检索词与目录位置；Web 保留浏览器历史语义。最近访问只持久保存模块入口，不恢复实验任务。
- 本期调整 app 入口、导航、表面与阅读容器，复用既有教学内容；模块内部重排后续单独推进，阻碍阅读和操作的溢出纳入本期修正。目标规则不能作为已实现或已验收事实。
- 仅桌面窗口且多窗口能力可用时，由用户显式打开分类专注窗口；普通分类与模块点击使用应用内导航。
- 应用层选择通用桌面框架，移动／Web 的紧凑、Rail 和侧栏布局由 `NavigationPolicy` 选择；`MultiWindowManager` 只管理桌面窗口生命周期。
- 平台接入、构建通过和真机/真实主机验收必须分开描述；不得扩大证据范围。

## 修改流程

1. 检查 `git status`，保留用户已有改动。
2. 读取目标契约和代码，修改最小必要范围。
3. 模块、依赖、路由、层级或平台声明变化时，同步更新生成源。
4. 逻辑变化补定向测试；教学 UI 变化补人工验收或截图说明。
5. 执行 `bash tool/quality_gate.sh`。

质量门禁必须通过：全部生成物无漂移、Dart 格式合规、bare `flutter analyze` 无 issue、workspace 全量测试和工具测试通过、模块测试存在性合规。通用目录命名、测试顶层目录与源码依赖扫描不属于本仓库门禁；
FlutterGuard（已更名 BoundaryLens）独立安装，后续仅通过外部插件或工具集按需使用，不属于依赖解析、提交、CI 或发布的强制要求。
`tool/verify_test_layout.sh` 仅保留模块测试存在性检查；稳定路由、教学组件、注册一致性和支持声明仍是业务契约。

## Git 与发布

- `dev` 是开发分支；功能、修复、文档和发版准备先进入 `dev`。
- `master` 只能通过从 `dev` 发起的 Pull Request 合入；禁止直接或强制推送。
- 未经用户明确授权，不提交、不推送、不合并，不处理无关工作树改动。
- 禁止修改 `.github/workflows/ci.yml`、`tool/quality_gate.sh` 或其他门禁脚本语义，除非任务显式授权 `packaging_change` 并要求人工验收。
- 业务仓库 CI 只能构建暂存产物；GitHub Release 必须由 Agent Hub `release_hosting` 的 `release-plan` / `release-run --execute` 流程执行。
- 分发格式以当前工作流与冻结 manifest 为准：macOS DMG、Windows EXE、Android ARM64 debug APK、Web 静态包。Windows 安装器从应用 `pubspec.yaml` 注入版本；Android debug 构建和 debug 签名必须显式记录。

## 常用命令

```bash
bash tool/generate_harness_ai_analysis.sh
bash tool/quality_gate.sh
bash tool/build_web_release.sh
git config core.hooksPath .githooks
```
