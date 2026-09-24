# Flutter Forge Agent 入口

本目录只保存任务级 Agent 输入；项目规则与事实不在此重复维护。

## 阅读顺序

1. `AGENTS.md`：行为、修改、Git 与发布规则。
2. `AI_PROJECT_CONTEXT.md`：架构、入口、平台和验证契约。
3. `REFACTOR_PLAN.md`：当前任务队列与验收条件。
4. 目标目录最近的 `AI_ANALYSIS.md`：局部所有权与依赖。
5. 平台或导航任务再读 `CONTEXT.md` 和相关 `docs/adr/`。

## 项目模型

```text
apps/flutter_forge/lib/
├── app/              启动、应用壳、路由、NavigationPolicy
├── module_registry/  模块元数据、平台快照、目录判定
├── shared/           教学模板和业务无关能力
└── modules/          六类学习模块；模块之间禁止直接依赖

packages/             Pub Workspace 内部能力包
tool/                 契约生成、测试和质量门禁
```

模块、路由、平台限制和 Agent 契约统一从 `tool/generate_agent_indexes.js` 生成。不要手改生成文件，也不要在本文件记录模块数量、版本、历史进度或测试快照。

## 执行约定

- 开始前检查 `git status`，不覆盖无关改动。
- 任务范围以用户请求和任务 JSON 为准，不自行扩大权限。
- 修改模块前读取模块契约；结构变化同时更新生成源。
- 验证统一执行 `bash tool/quality_gate.sh`。
- 未经明确授权，不提交、不推送、不合并。

任务 JSON 如存在，放在 `.hermes/<task>.codex.json`；它描述单次任务，不替代 `AGENTS.md` 或机器契约。
