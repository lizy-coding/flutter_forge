# AGENTS.md - Agent 维护契约

> 本文档约束所有 AI agent 对本项目的修改行为。修改代码前必须阅读。

## 前置阅读

执行任何修改前，agent 必须读取：
1. `AI_PROJECT_CONTEXT.md` - 项目整体上下文
2. `REFACTOR_PLAN.md` - 整改计划与优先级
3. 目标模块的 `AI_ANALYSIS.md` - 模块结构与修改建议

## 新增模块规则

新模块 **必须** 包含以下内容，否则视为不合规：

| 必需项 | 说明 |
|--------|------|
| `module_entry.dart` | 导出 `*Entry` Widget，作为模块入口 |
| `AI_ANALYSIS.md` | 模块分析文档：功能、文件结构、数据流、关键类、修改建议 |
| 路由注册 | 在 `lib/router/app_route_table.dart` 的 `_modules` 中注册 |
| 模块元数据 | `ModuleEntry` 必须填写 `category`、`difficulty`、`concepts`、`estimatedMinutes`、`status`、`subtitle` |
| 教学页面 | 至少 1 个页面使用 `lib/shared/learning/` 中的教学模板组件 |

## 修改模块规则

1. 修改前先读取该模块的 `AI_ANALYSIS.md`
2. 修改后同步更新 `AI_ANALYSIS.md` 中的文件结构和关键类信息
3. 如果修改了路由注册，同步更新元数据字段

## 验收规则

每次代码修改后 **必须** 执行：
```bash
dart format .
flutter analyze
dart run flutterguard_cli:flutterguard scan --path . --fail-on high
```

- `flutter analyze` 必须通过，不允许有 error 级别问题
- `flutterguard scan --fail-on high` 必须通过，不允许引入高优问题
- 涉及逻辑代码时补充测试（如有测试框架）
- 涉及 UI 教学页时进行人工验收或截图说明

## 禁止事项

| 禁止 | 说明 |
|------|------|
| 孤立 demo | 禁止新增无解释、无交互的粗糙 demo 页面 |
| 纯工程名 | 禁止首页出现纯工程目录名（如 `tree_state`），必须使用中文学习语义标题 |
| 跳过分析文档 | 禁止修改模块后不更新 `AI_ANALYSIS.md` |
| 绕过分析 | 禁止绕过 `flutter analyze` 直接提交 |
| 破坏元数据 | 禁止注册 `ModuleEntry` 时省略 `subtitle`、`category`、`difficulty` 等字段 |

## Harless 巡检职责

定期执行以下检查：

1. 扫描 `lib/` 下所有模块目录，检查是否都在 `_modules` 中注册
2. 检查每个模块是否有 `AI_ANALYSIS.md`
3. 检查重点模块是否使用教学模板（`lib/shared/learning/`）
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
ModuleCategory.basic      // 基础机制
ModuleCategory.async      // 异步并发
ModuleCategory.state      // 状态管理
ModuleCategory.ui         // UI 与动效
ModuleCategory.platform   // 网络与平台
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
