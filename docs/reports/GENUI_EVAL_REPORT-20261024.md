# GenUI 实际应用夜测评估报告(2026-10-24 夜)

> 状态:**部分降级**。本报告对应夜跑任务阶段 2;固定提示词集 × 10 轮的真实模型统计**未完成**,原因是执行期间本机到 Codex 后端的网络中断(见"环境结论")。已采集 1 例完整真实样本与全套链路验证结果,重跑入口已就绪。

## 已完成并验证的内容

### 1. `codex exec --json` 事件模式核查(替换 P0P1 报告的 UNVERIFIED 项)

使用 codex-cli 0.163.0 实测:

- `exec --json` 输出 JSONL 事件:`thread.started` / `turn.started` / `item.completed` / `turn.completed`,传输回退噪声以 `error` 事件出现(WS→HTTPS fallback),不代表调用失败。
- **agent 文本只在 `item.completed` 一次性到达,不存在 token 级增量事件**(150 字中文回复实测:单条 `item.completed`,len=186)。执行 JSONL 模式时 `turn.failed` 表示调用失败。
- 结论:P0P1 渐进渲染管线的"增量交付"承诺在当前 CLI 上的粒度上限是**每条 agent 消息**,不是每 token。这是 CLI 能力边界,记录为事实;若未来需要 token 级流,需评估 `codex proto`/app-server 协议(新接口面,未开工)。

### 2. 桥接流式化与鲁棒性改造(`tool/genui_codex_bridge.py`,客户端零改动)

- 事件模式:JSONL 事件 → OpenAI delta 形式 SSE 交付;`turn.completed` 校验、`turn.failed`/退出码失败判定;畸形行忽略;MAX_OUTPUT 中途强制。
- 立即响应头 + SSE 注释心跳(10s):真实调用 39–234 秒期间连接始终有字节流动,消除 dio receiveTimeout(100s) 风险;客户端按既有契约跳过非 `data:` 行,零改动验证通过。
- 断连杀进程:心跳写失败即视为客户端离开,取消事件终止 codex 子进程,不再为已断开的读者消耗配额(修复旧实现"生成完才发响应"期间断连照跑到底的问题)。
- 整响应回退:CLI 无 `--json` 时自动降级 legacy 路径(启动时 `--help` 探测,零配额开销)。
- 槽位排队:并发请求由即时 429 改为最长等 90s 再 429,配合下述评测超时修复,消除"一个被杀请求毒化整轮"的级联。
- 系统代理活性检测:系统代理(本机 127.0.0.1:7897)已死时不再注入 CLI 环境,避免每次调用都被死代理拖死。

### 3. 测试

- Python 单测 `tool/genui_codex_bridge_test.py`(运行入口 `python3 tool/genui_codex_bridge_test.py`,标准库 unittest,fake codex 脚本,无真实调用):**15/15 PASS**。覆盖:事件流分片顺序、畸形行、turn.failed→错误载荷、静默成功拒绝、超限拒绝、心跳先行、legacy 回退、help 探测、400/401 契约、断连杀 CLI、代理活性。
- Dart 流式端到端 `test/shared/module_discovery_streaming_test.dart`:**3/3 PASS**。真实回环 SSE 服务器:分片 delta + 注释心跳渲染完整面(证明渐进管线对增量传输源零改动)、缺 [DONE] 显式报错、线上无效尾保留已应用前缀。

### 4. 真实模型样本(仅 1 例,不构成统计)

轮 1 用例 1("我想理解为什么设置宽度不生效,推荐从哪个模块入门?"):

- 25.1s 完成,无错误,`rootIsGroup=true`,1 条 `updateComponents` 消息,2 组件(1 ModuleCard + 1 RefineChoice),引用真实模块《约束与声明式布局》,全部不变量通过。
- 与 2026-10-23/24 验收结论一致:当前提示词在该意图上表现正常。

## 未完成与原因

固定提示词集(3 用例)× ≥10 轮的统计未完成。时间线:

1. 首轮暴露评测框架缺陷:flutter test 默认单测超时 30s 杀掉 25–40s 的真实调用,被杀请求占住桥接单槽,后续用例 6ms 内 429 全灭。已修:`tool/genui_eval.dart` 用例超时对齐 150s + 桥接槽位排队。
2. 修复后重跑,首轮用例 1 成功(上述样本);随后本机到 Codex 后端的网络恶化:绕开桥接直连 CLI 同样 3:52–3:53 后 `turn.failed`(两次间隔 30 分钟复现),系统代理 127.0.0.1:7897 确认死亡,`prefer_websockets=false` 下 HTTPS 直连也失败。**属环境不可用,非桥接或管线缺陷**;按任务书预案降级,不阻塞后续阶段。

## 重跑入口(网络恢复后)

```sh
python3 tool/genui_codex_bridge.py --codex "$(which codex)" --token-file <仓库外临时路径>
cd apps/flutter_forge
GENUI_EVAL_LIVE=1 GENUI_EVAL_ENDPOINT=http://127.0.0.1:8766/v1/chat/completions \
  GENUI_EVAL_TOKEN=<token文件内容> flutter test --no-pub tool/genui_eval.dart
# 每轮 3 用例,GENUI_EVAL|{json} 行为机器可读结果;≥10 轮后汇总不变量。
```

## 建议提示词/校验收敛(本轮实测未触发,供下轮对照)

- 本轮唯一完整样本未出现白名单越界、虚构引用或澄清超限;系统提示词与 `validate()` 白名单在现有目录上保持一致(目录契约测试已固化,见晨间报告阶段 3)。下轮统计若出现违例,收紧入口优先级:validate() 上限 → 系统提示词条目措辞;不新增组件。
