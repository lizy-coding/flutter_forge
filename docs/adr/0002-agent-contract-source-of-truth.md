# ADR 0002: Agent 契约生成源

| 属性 | 值 |
|------|-----|
| 状态 | accepted |
| 日期 | 2026-07-25 |
| 决策者 | forest |

## 上下文

项目使用机器可解析的 JSON 契约（AI_ANALYSIS.md 系列）和 human-facing 文档（README.md, CONTRIBUTING.md 等）。需要明确哪些文档生成、哪些手写，避免双源漂移。

## 决策

1. Agent 机器契约由 `tool/generate_agent_indexes.js` 生成
2. 生成物包括：AI_MODULE_INDEX.md, AI_PROJECT_CONTEXT.md, REFACTOR_PLAN.md 中的部分字段
3. 路由注册表（app_route_table.dart）为生成源之一
4. 模块级 AI_ANALYSIS.md 为手写 + 生成混合（路由/状态来自生成器，owns/depends 手写）
5. 人类文档（README.md, docs/*）为纯手写

## 理由

- 模块清单、路由和状态不应靠手工重复维护
- 生成 + diff 检测可防止漂移
- 手写部分保留架构意图（owns/depends 不可从代码自动推导）

## 后果

- 修改路由必须更新生成源（route_table.dart）
- 新增模块必须在生成源中注册
- CI 检测生成物漂移会自动失败
