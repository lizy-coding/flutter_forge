# Agent index generator guide

## 事实源

`tool/generate_agent_indexes.js` 是声明与 CLI 入口；本目录 `generator.js` 负责 preflight、render 和写入，`contracts.js` 输出层级契约，`project.js` 读取 manifest/lock 事实，`plan.js` 输出计划，`routes.js` 组装路由语义。生成的 JSON 形式 AI_*.md/REFACTOR_PLAN.md 禁止手改。

## 不变量

- manifest 与 lock 不一致必须失败；外部 Git 依赖记录 requested ref 和 resolved ref，不得把未锁定依赖或工作区改动当作发布验收。
- workspace members、module dependencies 与稳定 route 通过注册来源生成；excludedPlatforms 与功能差异由 availability.js 的共用适配规则推导，不新增第二份逐模块平台注册表。
- schema、别名和依赖映射与实际 imports 一致；输出路径必须位于项目内且不重复，render 失败不得部分覆盖旧生成物。
- `lib/...` 是主应用内路径，真实根目录为 `apps/flutter_forge`；内部 package 路径相对 workspace。

## 有界维护

先读取近期 Git 差异命中的生成源与对应输出，按 Hub candidate_paths 定点分析。文档审查不运行递归生成器或全库 validator。若修改模块/依赖/路由声明，需要执行仓库规定的完整生成与校验，并明确其读取范围；不能把不完整的部分生成当作契约全通过。

本目录行为测试入口：`node --test tool/agent_indexes/generator.test.js tool/agent_indexes/availability.test.js`。

支持声明：availability.js 识别注册模块能力并推导策略；support.js 只从同源策略生成简明支持矩阵。默认生成不读取历史报告、测试结果或源码指纹；不聚合验收状态或人工用例。tool/module_availability.js 提供只读 list 和显式 generate，旧 check/record 已停用。历史资料独立归档，专项确认按需执行。生成后检查目标契约差异并运行对应定向测试；根质量门禁与 CI 测试执行保持原语义。
