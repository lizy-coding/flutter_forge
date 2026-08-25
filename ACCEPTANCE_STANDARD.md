# flutter_forge 自动化验收标准（结合 Agent Hub / LangGraph）

> 制定: 2026-08-25 | 适用范围: flutter_forge 整体验收与稳定版发布门禁
> 分层 L0-L6, 每层有命令、执行者、通过标准; 高层失败可阻塞发布, 低层失败立即阻塞任何合并。

## 分层验收矩阵

| 层 | 名称 | 命令/机制 | 执行者 | 通过标准 |
|----|------|-----------|--------|----------|
| L0 | 环境自检 | `flutter doctor`; agent-hub `workspace_bootstrap` graph | Hermes/执行 agent | 无 blocking issue; graph START->check->END 成功 |
| L1 | 仓库门禁 | `bash tool/quality_gate.sh` | Hermes 独立复跑(不信自报) | 6/6 阶段全绿: ①agent 文档不漂移 ②dart format 不漂移 ③bare flutter analyze 零 issue(含 info) ④test_all 全过 ⑤verify_test_layout 合规 ⑥flutterguard 无 HIGH |
| L2 | 远端 CI | `.github/workflows/ci.yml` (push 触发) | GitHub Actions | 最新 push 的 CI run = success; bare analyze 是唯一权威远端验收 |
| L3 | 静态分析 | `flutter analyze`(bare); `dart run flutterguard_cli:flutterguard scan . --fail-on high` | Hermes/执行 agent | 零 issue(含 info); 无 HIGH; MEDIUM 可入 deferred 队列 |
| L4 | 测试层 | `bash tool/test_all.sh`; `bash tool/verify_test_layout.sh` | Hermes 独立复跑 | 全量通过; 模块测试布局合规并输出覆盖报告; 逻辑变更必须伴随定向测试 |
| L5 | 架构层(LangGraph) | agent-hub `shadow_benchmark` 套件 + `score_reviewed_architecture` golden 评分; `context_analysis`/`capability_analysis` graph | agent-hub runtime (Hermes 编排) | shadow suite 全部 case passed; golden ownership_accuracy>=0.75 且 extraction_accuracy>=0.75; 架构分歧计数为 0; context 分析无 blockers |
| L6 | 发布层 | release.yml 构建; Windows 实机验证清单 | GitHub Actions + 用户在 Windows 执行 | 安装包构建成功(Windows exe + macOS zip); 实机清单全过: 断网打开视频模块不崩溃/停留不崩溃/重试10次不崩溃/联网正常播放 |

## 验收执行流程

1. 基线核对: `git log` + `git status` + `origin/dev` 指针(验收前确认无未批准推送)
2. L0 -> L1 -> L4: Hermes 独立复跑(每次验收必做)
3. L2: `gh run list` 查最新 push 的 CI 状态
4. L5: agent-hub `.venv/bin/python` 跑 shadow suite + golden 评分(需 registry 有效)
5. L6: 发布时执行; 实机清单由用户完成并回报
6. 输出验收报告: 每层通过/失败 + 证据(命令输出/指针/SHA)

## 数据漂移规则(agent-hub 侧)

- agent-hub 基准数据(benchmarks/shadow_cases/cases.json、architecture_goldens/*)必须与 flutter_forge 仓库命名同步
- 仓库重命名(如 flutter_study -> flutter_forge)后必须迁移基准数据, 否则 L5 全部 case 失败(2026-08-25 实测: 23+80 处漂移导致 shadow 0/6、golden 0.0 分)
- registry.json 为 gitignore 生成物, 由 `WorkspaceRegistry.refresh()` 重建; L5 前须 validate_registry 为空

## 失败处置

- L1 任一阶段失败: 禁止合并/发布, 由执行 agent 修复后复跑
- L3 新增 HIGH: 禁止合并(受保护路径规则)
- L5 golden 分歧(ownership/extraction 不匹配): 属架构偏差, 记录 architecture_disagreement 并人工评审, 不自动放行
- L6 实机清单任一失败: 修复后重新构建再发布
