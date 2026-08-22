# AGENTS.md - Agent 维护契约

> 本文档约束所有 AI agent 对本项目的修改行为。修改代码前必须阅读。

## 前置阅读

执行任何修改前，agent 必须读取：
1. `AI_ANALYSIS_SCHEMA.json` - agent 文档 schema
2. `AI_PROJECT_CONTEXT.md` - 机器可解析项目契约
3. `REFACTOR_PLAN.md` - 机器可解析任务队列
4. 目标模块的 `AI_ANALYSIS.md` - 机器可解析模块契约

以上 agent 文档均为 JSON，禁止加入 Markdown、自然语言段落或手工文件清单。

## 新增模块规则

新模块 **必须** 包含以下内容，否则视为不合规：

| 必需项 | 说明 |
|--------|------|
| `module_entry.dart` | 导出 `*Entry` Widget，作为模块入口 |
| `AI_ANALYSIS.md` | 模块机器契约：route、category、status、entrypoints、owns、depends、analysis_parent、validation |
| 路由注册 | 在 `lib/router/app_route_table.dart` 的 `_modules` 中注册 |
| 模块元数据 | `ModuleEntry` 必须填写 `category`、`difficulty`、`concepts`、`estimatedMinutes`、`status`、`subtitle` |
| 教学页面 | 至少 1 个页面使用外部 `flutter_study_learning` 包中的教学模板组件（`LearningScaffold` 等） |

## 修改模块规则

1. 修改前先读取该模块的 `AI_ANALYSIS.md`
2. 修改模块、依赖、路由或层级时，更新 `tool/generate_agent_indexes.js` 中的生成源
3. 执行 `bash tool/generate_harness_ai_analysis.sh` 重新生成并校验 agent 文档
4. 如果修改了路由注册，同步更新元数据字段

## 验收规则

每次代码修改后 **必须** 执行：
```bash
bash tool/quality_gate.sh
```

等效手动步骤（quality_gate.sh 内部执行顺序）:
1. `bash tool/generate_harness_ai_analysis.sh` + `git diff --exit-code` (文档不漂移)
2. `dart format .` + `git diff --exit-code -- '*.dart'` (格式不漂移)
3. `flutter analyze` (bare：info/warning 同样视为失败)
4. `bash tool/test_all.sh` (全部测试通过)
5. `bash tool/verify_test_layout.sh` (测试目录布局合规并输出模块测试覆盖报告)
6. `cd apps/flutter_forge && dart run flutterguard_cli:flutterguard scan . --fail-on high` (无 HIGH 问题，仅本地执行)

- `flutter analyze` 必须通过（bare，不允许任何 issue，含 info）
- `flutterguard scan --fail-on high` 必须通过，不允许引入高优问题（仅本地；CI 不运行 flutterguard）
- 远端打包门禁为 `.github/workflows/ci.yml`，同样使用 bare `flutter analyze`，是唯一权威的远端验收
- 涉及逻辑代码时补充测试
- 涉及 UI 教学页时进行人工验收或截图说明

## 禁止事项

| 禁止 | 说明 |
|------|------|
| 孤立 demo | 禁止新增无解释、无交互的粗糙 demo 页面 |
| 纯工程名 | 禁止首页出现纯工程目录名（如 `tree_state`），必须使用中文学习语义标题 |
| 跳过分析文档 | 禁止修改模块后不更新 `AI_ANALYSIS.md` |
| 绕过分析 | 禁止绕过 `flutter analyze` 直接提交 |
| 破坏元数据 | 禁止注册 `ModuleEntry` 时省略 `subtitle`、`category`、`difficulty` 等字段 |
| 修改打包门禁 | 禁止修改 `.github/workflows/ci.yml`、`tool/quality_gate.sh` 及其余 `tool/*.sh` 门禁脚本的语义，除非任务显式声明并经人工验收（agent-hub 侧同样受 `packaging_change` 保护路径守卫约束）。`.github/workflows/release.yml` 是首个安装器发布任务明确授权的打包工作流；后续修改仍需显式 `packaging_change` 任务和人工验收。 |

## Harless 巡检职责

定期执行以下检查：

1. 扫描 `lib/` 下所有模块目录，检查是否都在 `_modules` 中注册
2. 检查每个模块是否有 `AI_ANALYSIS.md`
3. 检查重点模块是否使用教学模板（`flutter_study_learning` 包）
4. 检查 `ModuleEntry` 元数据是否完整（所有必填字段）
5. 标记低质量模块的 `status` 为 `ModuleStatus.pending`
6. 检查 `flutter analyze` 和 `dart format` 是否通过

## 启用预提交钩子

```bash
git config core.hooksPath .githooks
```

这会在每次 `git commit` 前自动执行 FlutterGuard 扫描，阻止引入高优问题的提交。

## 模块分类枚举

```dart
ModuleCategory.basic       // 基础机制
ModuleCategory.async       // 异步并发
ModuleCategory.state       // 状态管理
ModuleCategory.ui          // UI 与动效
ModuleCategory.popupTable  // 弹窗与列表
ModuleCategory.platform    // 网络与平台
```

## 难度等级枚举

```dart
Difficulty.beginner       // 入门
Difficulty.intermediate   // 进阶
Difficulty.advanced       // 实战
```

## 模块状态枚举

```dart
ModuleStatus.pending      // 待整改
ModuleStatus.ready        // 可学习
ModuleStatus.recommended  // 推荐
```
