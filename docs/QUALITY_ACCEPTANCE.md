# flutter_forge 质量验收体系

> 本文件由 ACCEPTANCE_STANDARD.md（分层验收标准）与 AUTOMATION_TEST_PLAN.md（自动化测试计划）合并而来（2026-08-25 文档整理）。
> 分层标准 L0-L6 是验收的权威依据；自动化计划是标准的可执行实例化。

## 一、分层验收标准（L0-L6）

### 当前发布基线（2026-08-31）

- Windows v1.2.2 核心真机验证：PASS。
- Windows USB：DEFERRED；`usb_detector` 保持 Android-only，Windows 显示不可用态。
- macOS/Windows 多窗口稳定性：PENDING，等待三分类窗口、子窗口文件选择、关闭重开和引擎日志专项证据。
- Android host 与 Android 真机/模拟器：DEFERRED，不阻塞当前 PC 阶段。

| 层 | 名称 | 命令/机制 | 执行者 | 通过标准 |
|----|------|-----------|--------|----------|
| L0 | 环境自检 | `flutter doctor`; agent-hub `workspace_bootstrap` graph | Hermes/执行 agent | 无 blocking issue; graph START->check->END 成功 |
| L1 | 仓库门禁 | `bash tool/quality_gate.sh` | Hermes 独立复跑(不信自报) | 6/6 阶段全绿: ①agent 文档不漂移 ②dart format 不漂移 ③bare flutter analyze 零 issue(含 info) ④test_all 全过 ⑤verify_test_layout 合规 ⑥flutterguard 无 HIGH |
| L2 | 远端 CI | `.github/workflows/ci.yml` (push 触发) | GitHub Actions | 最新 push 的 CI run = success; bare analyze 是唯一权威远端验收 |
| L3 | 静态分析 | `flutter analyze`(bare); `dart run flutterguard_cli:flutterguard scan . --fail-on high` | Hermes/执行 agent | 零 issue(含 info); 无 HIGH; MEDIUM 可入 deferred 队列 |
| L4 | 测试层 | `bash tool/test_all.sh`; `bash tool/verify_test_layout.sh` | Hermes 独立复跑 | 全量通过; 模块测试布局合规并输出覆盖报告; 逻辑变更必须伴随定向测试 |
| L5 | 架构层(LangGraph) | agent-hub `shadow_benchmark` 套件 + `score_reviewed_architecture` golden 评分; `context_analysis`/`capability_analysis` graph | agent-hub runtime (Hermes 编排) | shadow suite 全部 case passed; golden ownership_accuracy>=0.75 且 extraction_accuracy>=0.75; 架构分歧计数为 0; context 分析无 blockers |
| L6 | 发布层 | release.yml 构建; Windows 实机验证清单; 多窗口专项 | GitHub Actions + 用户在 Windows/macOS 执行 | v1.2.2 安装包与 Windows 核心功能已通过；多窗口稳定性仍需三分类窗口/子窗口文件选择/关闭重开/引擎日志证据；Windows USB 与 Android 为延期项 |

### 验收执行流程

1. 基线核对: `git log` + `git status` + `origin/dev` 指针(验收前确认无未批准推送)
2. L0 -> L1 -> L4: Hermes 独立复跑(每次验收必做)
3. L2: `gh run list` 查最新 push 的 CI 状态
4. L5: agent-hub `.venv/bin/python` 跑 shadow suite + golden 评分(需 registry 有效)
5. L6: 发布时执行; 实机清单由用户完成并回报
6. 输出验收报告: 每层通过/失败 + 证据(命令输出/指针/SHA)

### 数据漂移规则(agent-hub 侧)

- agent-hub 基准数据(benchmarks/shadow_cases/cases.json、architecture_goldens/*)必须与 flutter_forge 仓库命名同步
- 仓库重命名(如 flutter_study -> flutter_forge)后必须迁移基准数据, 否则 L5 全部 case 失败(2026-08-25 实测: 23+80 处漂移导致 shadow 0/6、golden 0.0 分)
- registry.json 为 gitignore 生成物, 由 `WorkspaceRegistry.refresh()` 重建; L5 前须 validate_registry 为空

### 失败处置

- L1 任一阶段失败: 禁止合并/发布, 由执行 agent 修复后复跑
- L3 新增 HIGH: 禁止合并(受保护路径规则)
- L5 golden 分歧(ownership/extraction 不匹配): 属架构偏差, 记录 architecture_disagreement 并人工评审, 不自动放行
- L6 实机清单任一失败: 修复后重新构建再发布

## 二、自动化测试计划（标准实例化）

### 目标基线

- flutter_forge: dev 分支 HEAD（本地提交; 远端 origin/dev 为已批准基线）
- agent-hub: main 分支（基准数据须与 flutter_forge 命名同步）

### 执行清单（顺序执行, 每层独立判定）

| 步骤 | 层 | 命令 | 工作目录 | 通过标准 | 产物 |
|------|----|------|----------|----------|------|
| S1 | L0 | `flutter --version` 可用; agent-hub `.venv/bin/python -c "import agent_hub"` | 各自仓库 | 无错误 | 版本快照 |
| S2 | L1+L4 | `bash tool/quality_gate.sh` | flutter_forge 根 | 6/6 阶段全绿, exit 0 | 门禁输出 |
| S3 | L3 | 已含于 S2（bare analyze + flutterguard --fail-on high） | 同上 | 零 issue; 无 HIGH | S2 输出 |
| S4 | L2 | `gh run list --limit 3` 查 dev 最新 push CI | flutter_forge 根 | 最新 CI run = success | CI 状态 |
| S5 | L5 | `.venv/bin/python` 调 ShadowBenchmarkRunner: run_shadow_suite + score_reviewed_architecture | agent-hub | 6/6 passed; ownership/extraction>=0.75; disagreement=0 | 套件输出 |
| S6 | L6 | 发布包与 Windows 核心功能已通过；多窗口专项待执行 | - | - | `docs/reports/MULTIWINDOW_ACCEPTANCE-20260901.md` |

### 报告格式（写 ACCEPTANCE_REPORT-<YYYYMMDD>.md）

- 头部: 日期、基线 SHA（flutter_forge HEAD / agent-hub HEAD / origin 指针）、执行者
- 每层: `PASS/FAIL/PENDING` + 关键证据（命令输出摘录, 不含冗长日志）
- 汇总表: L0-L6 状态一览
- 结论: 全 PASS => 基线可发布候选; 任一 FAIL => 附失败项与建议
- 边界声明: 本次执行未修改任何源码/基准数据/门禁脚本; 未执行 git push

### 硬约束

- 只读执行 + 生成报告文件; 禁止修改源码、基准数据、tool/*.sh、.github/workflows/*.yml
- 禁止 git push; 报告文件不自动 commit（提交决策由用户定）
- 失败即停: 某层 FAIL 记录后继续后续层（报告含全部层状态）, 不伪造证据
- L2 需要 gh 认证（本地已配置）; 网络需要时走代理 127.0.0.1:7897

### 验收闭环

- Codex 交付报告后, Hermes 独立复跑 S2（quality_gate）与 S5（套件）核对一致性
- 报告归档于 docs/reports/（历史验收记录, 每次验收新增一条）
