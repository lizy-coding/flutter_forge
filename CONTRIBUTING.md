# 贡献指南

## 分支策略

- `dev` — 开发主分支
- `feat/<name>` — 功能分支
- `fix/<name>` — 修复分支

## 提交规范

```
<type>(<scope>): <subject>

type: feat, fix, chore, docs, refactor, test
scope: 受影响的模块名或包名
```

示例:
```
feat(tree_state): add repaint boundary demo page
fix(gcode_core): resolve toolpath offset calculation
chore(packages): update agent doc schema
```

## PR 流程

1. 从 `dev` 创建功能分支
2. 修改代码，遵循 AGENTS.md 规则
3. 执行 `bash tool/quality_gate.sh`，确保通过
4. 更新 AI_ANALYSIS.md（如适用）
5. 运行 `bash tool/generate_harness_ai_analysis.sh`
6. 提交 PR，填写 PR 模板

## Definition of Done

- [ ] 代码通过 `dart format .`（0 changed）
- [ ] 代码通过 `flutter analyze`（0 errors）
- [ ] 新增逻辑有测试覆盖
- [ ] Agent 契约已更新（如适用）
- [ ] 质量门禁通过
- [ ] 教学 UI 变更附截图/说明

## 禁止事项

- 禁止 `path: ../...` 外部依赖
- 禁止孤立 demo 页面（无解释无交互）
- 禁止首页出现纯工程目录名
- 禁止修改生成物而不更新生成源
- 禁止直接提交到 protected 分支
