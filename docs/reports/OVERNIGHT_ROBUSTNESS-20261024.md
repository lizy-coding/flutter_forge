# 夜跑晨间报告 — GenUI 链路流式化、实测加固与扩展性守护(2026-10-24 夜)

> 执行:单次自动化(用户 2026-10-24 批准)。范围:GenUI 鲁棒性 + 模块扩展性 + deferred_queue 测试补课。**全程未 commit、未 push、未发布**;所有改动留在工作树,与既有未提交 GenUI 改动可分离。基线门禁 PASS,终版门禁见文末。

## 总览

| 阶段 | 计划 | 结果 |
|---|---|---|
| 0 基线冻结 | quality_gate PASS + 回归基线 | ✅ 基线 gate PASS;test/shared 139 项 |
| 1 桥接真流式化 | 事件模式 + 回退 + 测试 | ✅ 完成;Python 15/15 + Dart 流式 3/3 |
| 2 GenUI 真实模型夜测 ≥10 轮 | 统计 + 收敛 | ⚠️ **降级**:网络中断,得 1 例有效样本;重跑入口就绪 |
| 3 双会话管线鲁棒性 | 错误路径 + 契约测试 | ✅ 完成;+10 测试全绿 |
| 4 widget_test_coverage 补课 | 薄弱模块交互测试 | ✅ 完成;3 模块 +14 测试,全模块套件 314/314 |
| 收尾 | 终跑 gate + 本报告 | ✅(gate 结果见文末) |

## 阶段 1:桥接(`tool/genui_codex_bridge.py`)

核查结论(替换 P0P1 报告 UNVERIFIED 项):`codex exec --json` 存在且可用,但 **agent 文本按 `item.completed` 一次性到达,无 token 级增量**;`error` 事件是 WS→HTTPS 回退噪声。据此落地:

- 事件模式 → SSE delta 交付,`turn.completed` 校验、失败显式化、畸形行忽略、MAX_OUTPUT 中途强制;无 `--json` 的 CLI 自动走整响应回退(启动时 `--help` 探测,零配额)。
- 响应头立即返回 + 10s SSE 注释心跳:39–234s 的生成期间连接不再静默,消除 dio receiveTimeout(100s) 风险;心跳写失败即杀 codex 子进程(断连不再烧配额)。
- 槽位由即时 429 改为最长 90s 排队;系统代理活性检测(死代理不注入 CLI 环境)。
- 新增 `tool/genui_codex_bridge_test.py` 15 项(fake codex,无真实调用);`test/shared/module_discovery_streaming_test.dart` 3 项(真实回环 SSE:分片+心跳渲染完整面、缺 [DONE] 显式报错、无效尾保留前缀)。
- **客户端(shared/)零改动**——渐进渲染管线对增量传输源零改动兼容的承诺经受住了实测。

## 阶段 2:夜测(降级,详见 [GENUI_EVAL_REPORT-20261024.md](GENUI_EVAL_REPORT-20261024.md))

- 1 例完整真实样本通过全部不变量(25.1s,1 ModuleCard 引用真实模块)。
- 未达 ≥10 轮统计:执行中本机到 Codex 后端网络中断(直连 CLI 两次 3:52/3:53 后 `turn.failed` 复现,系统代理死亡,`prefer_websockets=false` 亦失败),按任务书预案降级。
- 过程中修复评测框架两处缺陷:`tool/genui_eval.dart` 用例超时 30s→150s(否则 flutter 默认超时谋杀真实调用并引发桥接槽位级联);配套桥接排队。

## 阶段 3:双会话管线 + 对话框 + 目录契约

新增测试 10 项,`test/shared/` 152/152 PASS(基线 139 + 新增 13,含阶段 1 流式 3 项):

- `genui_session_core_test.dart` +5:中途取消保留已应用前缀、流中源错误保留前缀、运行中 dispose 冻结、取消后新提交走新 epoch、非本机明文端点在发请求前拒绝。
- `model_connection_dialog_test.dart` +2:输入与异步恢复竞态下输入值必胜、空保存值回退默认。
- `model_connection_dialog_test.dart` 现覆盖工作树未提交改动(+48/-5)的持久化与竞态分支。
- `module_discovery_catalog_contract_test.dart` +3(新文件):目录组件 ↔ validate 白名单样本 ↔ 系统提示词清单三者一致性 + 未知组件拒绝——把 P1-3 的"新增受限组件要改哪几处"固化为可执行检查。

## 阶段 4:deferred_queue 的 widget_test_coverage

4 个 9 行占位文件中加固 3 个(第 4 个 scroll_table 未动,时间预算内优先前三),全模块套件 **314/314 PASS**:

- `isolate_task_manager`:9→7 项(占位 + 6)。注入可控隔离:进度回调流、暂停门控/恢复、完成即释放隔离资源、停止后晚到消息丢弃、dispose 后创建抛错、spawn 失败记录并通知。
- `dio_interceptor`:9→3 项。LessonSession 租约池:共享会话至最后关闭、关闭租约 API 抛错、失败启动被下一次 acquire 替换(高并发下网络往返加一次测试侧重试,避免 10s receiveTimeout 偶发)。
- `flutter_ioc`:9→4 项。模型通知序、JSON/Map 往返、真机交互(Provider 注入下 FAB 计数 + 改名)。

## 发现的缺陷与观察

**已修(本夜,均含测试)**:

1. flutter test 默认 30s 超时谋杀真实模型调用并级联毒化桥接槽位(genui_eval.dart)。
2. 桥接对已断开客户端继续跑完生成、白烧配额(旧实现结构使然,已随流式化修复)。
3. 死系统代理被注入 CLI 环境导致调用全超时(本机 127.0.0.1:7897,与已知推送代理问题同源)。
4. dio 测试在全量高并发下的偶发超时(测试侧重试加固)。

**记录不修(留给维护者决策)**:

1. `AuthInterceptor.onResponse` 自动捕获顶层 `token`,而 MockServer 把 token 嵌在 `data.token`——自动捕获实际不生效,当前由登录页手动 `setToken` 兜底。两处形状不一致属设计选择,改动拦截器会变更行为,未动。
2. token 级流式需要 `codex proto`/app-server 协议(新接口面),当前 CLI exec 事件模式无此能力。
3. `scroll_table` 占位测试未加固(时间预算取舍)。

## 明确未做(按任务书)

deferred_queue 的 3D 两项与 `recommended_module_visual_evidence`;平台实机验收(Windows/真机/Web);新增依赖;任何组件目录扩展;prompt 结构重写。

## 变更清单(全部未提交)

- 修改:`tool/genui_codex_bridge.py`(流式化)、`apps/flutter_forge/tool/genui_eval.dart`(超时对齐)
- 新增:`tool/genui_codex_bridge_test.py`、`apps/flutter_forge/test/shared/module_discovery_streaming_test.dart`、`apps/flutter_forge/test/shared/module_discovery_catalog_contract_test.dart`
- 加固:`test/shared/genui_session_core_test.dart`、`test/shared/model_connection_dialog_test.dart`、`test/modules/async/isolate_task_manager/isolate_task_manager_test.dart`、`test/modules/platform/dio_interceptor/dio_interceptor_test.dart`、`test/modules/state/flutter_ioc/flutter_ioc_test.dart`
- 报告:本文件 + [GENUI_EVAL_REPORT-20261024.md](GENUI_EVAL_REPORT-20261024.md)
- 既有未提交改动(GenUI P0/P1、model_connection_dialog 等)保持原样,未混入本夜改动。

## 终版门禁

`bash tool/quality_gate.sh`:**5/5 PASS**(生成契约无漂移、Dart 格式、analyze 零 issue、workspace/tool 测试、33/33 模块测试存在)。桥接仍在 127.0.0.1:8766 挂着(token:`/tmp/genui-night-token`),供网络恢复后按 GENUI_EVAL_REPORT 的入口直接重跑评测。
