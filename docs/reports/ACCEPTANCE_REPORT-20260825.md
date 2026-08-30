# 自动化全层验收报告

- 执行日期：2026-08-25（Asia/Shanghai）
- 执行者：Codex
- flutter_forge HEAD：`c5751a60027b572dafe43e389e6dd370ba9cbb53`（`dev`）
- flutter_forge origin/dev：`432ad04c5cfdfb0080f0373f0d5d54badd7e6a17`
- flutter_forge origin/main：本地未配置该远端跟踪引用
- agent-hub HEAD：`28a2ca4ec9a89670aa32f39fdbd02cebe66dd2f8`（`main`）
- agent-hub origin/main：`6fc68fba1a5fa8d6eb4582f7d9019e163cfb6d32`

## 分层结果

### L0 / S1：环境自检 — PASS

关键证据：

- `flutter --version | head -1`：`Flutter 3.44.6 • channel stable`
- `.venv/bin/python -c "import agent_hub; print('agent_hub OK')"`：`agent_hub OK`

### L1 + L3 + L4 / S2 + S3：本地质量门禁 — PASS

关键证据：

- `bash tool/quality_gate.sh`：退出码 `0`
- 门禁摘要：`通过: 6`，`失败: 0`，`所有门禁通过。`
- FlutterGuard：`Issues: 5`，均为 `MEDIUM`；`FlutterGuard 通过`，无 HIGH 问题。
- S3 的 bare analyze 与 FlutterGuard 检查已包含于上述质量门禁。

### L2 / S4：远端 CI — PASS

关键证据：

- `gh run list --limit 3 --branch dev` 最新记录：run `32803551802`，`completed success`，workflow `CI`，event `push`。
- `gh run view 32803551802`：`headSha=432ad04c5cfdfb0080f0373f0d5d54badd7e6a17`。
- `git ls-remote origin refs/heads/dev`：同为 `432ad04c5cfdfb0080f0373f0d5d54badd7e6a17`。

### L5 / S5：LangGraph ShadowBenchmark 套件 — PASS

关键证据（`ShadowBenchmarkRunner`，配置 `workspace/config.json`）：

- shadow cases：`6/6` 通过；失败 ID：无（`SHADOW_001` 至 `SHADOW_006` 全部 PASS）。
- repository precision / recall：`1.0 / 1.0`。
- evidence coverage / rule coverage：`1.0 / 1.0`。
- unknown preservation：`1.0`；false positive rate：`0.0`。
- architecture goldens：`8`。
- ownership accuracy：`1.0`（要求 `>=0.75`）。
- extraction accuracy：`1.0`（要求 `>=0.75`）。
- unsupported promotions：`0`。
- architecture disagreement count：`0`。

### L6 / S6：发布实机验收 — PENDING

按计划保留待办：安装包构建验证与 Windows 实机清单，发布时执行。本次未将其判定为 PASS。

## 汇总

| 层 | 步骤 | 状态 |
|---|---|---|
| L0 | S1 环境自检 | PASS |
| L1 | S2 质量门禁 | PASS |
| L2 | S4 远端 CI | PASS |
| L3 | S3 静态分析与安全扫描 | PASS |
| L4 | S2 质量门禁集成测试 | PASS |
| L5 | S5 LangGraph 套件 | PASS |
| L6 | S6 安装包与 Windows 实机 | PENDING |

## 边界与结论

本次执行未修改任何源码、基准数据、门禁脚本或 CI 工作流；未执行 `git commit`，未执行 `git push`。两个仓库的既有未跟踪文件均保留不动；本报告是本次唯一新增写入产物。

L0-L5 全部 PASS，L6 因发布实机项未执行而为 PENDING。因此本基线满足自动化验收要求，可作为发布候选；正式发布仍需完成 L6。
