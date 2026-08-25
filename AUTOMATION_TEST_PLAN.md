# flutter_forge 自动化测试计划（2026-08-25 版）

> 配套: ACCEPTANCE_STANDARD.md（分层标准 L0-L6）。本计划是标准的可执行实例化: 对指定基线跑全层验收并产出可审计报告。
> 执行方式: Codex（无沙箱模式）执行 + Hermes 独立复跑关键项验收。

## 1. 目标基线
- flutter_forge: dev 分支 HEAD（本地 c5751a6 待批; 远端 origin/dev=432ad04）
- agent-hub: main 分支（基准数据已迁移: flutter_forge 命名 + apps/flutter_forge 路径前缀）

## 2. 执行清单（顺序执行, 每层独立判定）

| 步骤 | 层 | 命令 | 工作目录 | 通过标准 | 产物 |
|------|----|------|----------|----------|------|
| S1 | L0 | `flutter --version` 可用; agent-hub `.venv/bin/python -c "import agent_hub"` | 各自仓库 | 无错误 | 版本快照 |
| S2 | L1+L4 | `bash tool/quality_gate.sh` | flutter_forge 根 | 6/6 阶段全绿, exit 0 | 门禁输出 |
| S3 | L3 | 已含于 S2（bare analyze + flutterguard --fail-on high） | 同上 | 零 issue; 无 HIGH | S2 输出 |
| S4 | L2 | `gh run list --limit 3` 查 dev 最新 push CI | flutter_forge 根 | 最新 CI run = success | CI 状态 |
| S5 | L5 | `.venv/bin/python` 调 ShadowBenchmarkRunner: run_shadow_suite + score_reviewed_architecture | agent-hub | 6/6 passed; ownership/extraction>=0.75; disagreement=0 | 套件输出 |
| S6 | L6 | 标记 PENDING（安装包构建 + Windows 实机清单, 发布时执行） | - | - | 待办项 |

## 3. 报告格式（写 flutter_forge/ACCEPTANCE_REPORT-<YYYYMMDD>.md）
- 头部: 日期、基线 SHA（flutter_forge HEAD / agent-hub HEAD / origin 指针）、执行者
- 每层: `PASS/FAIL/PENDING` + 关键证据（命令输出摘录, 不含冗长日志）
- 汇总表: L0-L6 状态一览
- 结论: 全 PASS => 基线可发布候选; 任一 FAIL => 附失败项与建议
- 边界声明: 本次执行未修改任何源码/基准数据/门禁脚本; 未执行 git push

## 4. 硬约束
- 只读执行 + 生成报告文件; 禁止修改源码、基准数据、tool/*.sh、.github/workflows/*.yml
- 禁止 git push; 报告文件不自动 commit（提交决策由用户定）
- 失败即停: 某层 FAIL 记录后继续后续层（报告含全部层状态）, 不伪造证据
- L2 需要 gh 认证（本地已配置）; 网络需要时走代理 127.0.0.1:7897

## 5. 验收闭环
- Codex 交付报告后, Hermes 独立复跑 S2（quality_gate）与 S5（套件）核对一致性
- 报告纳入 flutter_forge 仓库（提交与否由用户决定）
