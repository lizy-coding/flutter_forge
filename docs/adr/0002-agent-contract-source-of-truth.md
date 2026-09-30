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
2. 生成物包括：AI_MODULE_INDEX.md, AI_PROJECT_CONTEXT.md, REFACTOR_PLAN.md 和各层 AI_ANALYSIS.md 的完整机器契约
3. 模块声明维护在生成入口；app_route_table.dart 与 module_manifest.dart 均为生成物
4. 模块级 AI_ANALYSIS.md 整体生成；owns/depends 等架构意图维护在生成源中，禁止直接修改生成物
5. 人类文档（README.md, docs/*）为纯手写

## 理由

- 模块清单、路由和状态不应靠手工重复维护
- 生成 + diff 检测可防止漂移
- 手写部分保留架构意图（owns/depends 不可从代码自动推导）

## 后果

- 修改路由必须更新 tool/generate_agent_indexes.js 中的模块声明
- 新增模块必须在生成源中注册
- CI 检测生成物漂移会自动失败

## 2026-09-30 生成源维护修订

- 保留 `tool/generate_agent_indexes.js` 作为唯一执行入口及模块声明位置，兼容现有模块准入校验。
- `tool/agent_indexes/catalog.js` 管理分类语义与内部包契约；分类成员和依赖由模块声明推导。
- `project.js` 管理项目策略，`plan.js` 保留历史计划与验收记录，`contracts.js` 和 `routes.js` 分别渲染机器契约和 Dart 注册表。
- `generator.js` 从 pubspec 与 lock 读取工作区及 Git 依赖事实，生成前校验输入，收集全部输出后再写入。
- `node tool/generate_agent_indexes.js --check` 比较当前文件与预期输出，不写文件，也不要求工作树已提交。
- 宿主目录存在、模块入口开放和历史验收记录分别表达，不据此声明当前版本平台验收通过。
