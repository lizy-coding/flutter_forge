# GenUI 实验工作区实施记录

日期：2026-10-22。范围：`dev` 的 `b501f21` 加本轮未提交 GenUI 实现。不是发布版本验收，不包含整体框架改造完成声明。

## 当前交付

入口在「UI 与动效 → 生成式实验工作区」，稳定路由 `/genui-workbench`，快速打开可检索 `GenUI`。固定回放、真实闭环与回归通过后，模块状态已调整为 `ready`，不代表所有平台都已验收。

固定回放通过官方 `genui 0.10.4` 的 `A2uiParserTransformer`、`SurfaceController`、`DataModel` 与 `Surface` 执行。采用公开流解析器，使协议异常进入同一可等待的错误处理链路。A2UI 核心固定为 `a2ui_core 0.1.1`，实际依赖版本和摘要见 workspace 锁文件。

目录包括布局、说明、数值参数、模式、约束预览、观测与解释动作。组件可分别组合更新；参数为 60–300dp 的宽度和松紧模式，结果采自 Flutter `RenderBox.size`。追问保留未修改参数；解释带状态版本，修改参数后会提示旧解释失效。

请求失败显示错误，允许重试；创建 Surface 后尚未生成预览的失败也可重试。取消、重置与离开页面后，迟到结果不能覆盖当前状态。不自动把真实生成失败替换成回放。

仅保留当前会话；协议记录有上限，不持久化问题、鉴权或实验任务。默认首页、窗口宿主、现有模块内部实现保持原职责。

## 立即体验固定回放

1. 启动 Forge，在快速打开输入 `GenUI`，进入模块。
2. 点击「为什么设置宽度却没有生效？」。
3. 修改子组件期望宽度，观察实际尺寸；切换「紧约束」，实际宽度应取父容器指定值。
4. 点击生成界面中的「解释当前结果」，展开「观察生成过程」查看消息、状态与动作。
5. 修改参数后检查旧解释提示；再次解释或显式重开工作区。

界面持续标明「固定消息回放 · 未调用模型」。回放只识别有限示例请求，不是自然语言理解或模型质量验收。

## 使用现有 Codex 登录的本机开发路径

官方说明 `codex exec` 可复用已保存的 CLI 登录并运行非交互任务：[非交互模式](https://learn.chatgpt.com/docs/non-interactive-mode)。本机已只读核查 `codex login status`，结果为 ChatGPT 登录；这不证明具体模型或额度当前可用。

本地需要安装 Python 3 与 Codex CLI。桥接独立运行，不打包进发布应用，不自动启动，不从 Forge 读取或导出 Codex 的登录文件。

桥接启动时会解析 CLI 的真实可执行路径，避免长运行服务持有临时命令别名。需要时可用 `--codex /absolute/path/to/codex` 显式指定已安装的 CLI。本次环境使用 Codex CLI 0.162.1。

```bash
python3 tool/genui_codex_bridge.py --token-file /tmp/forge-genui.token
```

在模块点击「连接模型服务」，填写：

| 项目 | 本机值 |
| --- | --- |
| 完整端点 | `http://127.0.0.1:8766/v1/chat/completions` |
| 模型 | `codex-default`，或当前登录允许的具体模型 |
| 临时访问令牌 | 本机 `/tmp/forge-genui.token` 的内容，不是 Codex 登录令牌 |

配置只在当前页面内存中保存。模型请求包含问题、组件 schema、当前组件与实验状态。使用已有 CLI 登录及可用额度，账号可用性由 Codex 自身处理。

桥接只监听 `127.0.0.1`，验证临时令牌与来源，每次只执行一个请求。CLI 在空临时目录内以只读模式运行，不加载用户配置，显式关闭自动指令、项目文档、技能、记忆、Apps/MCP 连接器及 shell、多 Agent 功能，不传递本项目文件。相关开关仅作用于子进程，不修改用户全局配置。请求最多 100KB，CLI 调用上限 90 秒，最终输出有大小限制；不会向 HTTP 调用方返回 CLI 日志。

退出桥接时 Ctrl-C 会移除本次令牌文件；异常终止后若文件残留，确认桥接已停止再自行删除或下次指定新路径。脚本不覆盖已有令牌文件。

浏览器访问本机桥接时需显式允许实际开发 Origin，例如：

```bash
python3 tool/genui_codex_bridge.py --token-file /tmp/forge-genui-web.token \
  --allow-origin http://localhost:7357
```

Web 部署到其他设备时，`127.0.0.1` 指使用者自己的设备，不提供远端访问主机 Codex 的能力。该开发桥接不是公开托管后端。

桥接先等待 Codex 成功完成，再以 SSE 分块交付最终响应，不是逐 token 模型流。取消会中止客户端等待并忽略迟到结果；桥接中已启动的 CLI 调用可能继续到完成或 90 秒超时，期间新的请求返回忙碌状态。

## 验证记录

| 项目 | 状态与范围 |
| --- | --- |
| SDK 依赖解析 | PASS：官方包与当前 Flutter/Dart 可解析，锁文件使用 pub.dev |
| Dart 定向测试 | PASS：9 项，含 SDK 渲染、状态与事件、取消/重置/销毁、窄屏大字体、分块 UTF-8/SSE、非法协议、异常与重试；含桌面 ColoredBox 背景下的 Material 回归，以及不泄露令牌的 HTTP 认证/桥接错误诊断 |
| 桥接离线测试 | PASS：5 项，含参数/命令边界、失败不交付、鉴权与 Origin、SSE 完成标记；模拟 CLI，不调用模型 |
| macOS Debug 构建与运行 | PASS：真实主窗口及分类窗口进入模块，鼠标操作回放与松紧切换；主窗口解释更新；实际宽度从 120 变为 240dp，期望宽度保留 120dp。分类窗口关闭后主窗口保持可用 |
| 热重载与运行时检查 | PASS：修复新模块 ExpansionTile 在桌面 ColoredBox 内的 Material 背景断言，Flutter MCP 热重载/热重启及重新进入模块后无运行时错误 |
| Web release 构建 | PASS：仓库脚本完成 release 编译与本地 CanvasKit、加载壳、媒体文件检查；不等同浏览器交互验收 |
| 完整质量门禁 | PASS：生成物无漂移、格式、bare analyze 无 issue、482 项 workspace Dart 测试、27 项工具测试及 31/31 模块测试存在性通过；桥接的 5 项离线测试另行通过 |
| 真实 Codex 生成 | PASS：用户明确授权测试数据后，macOS 集成测试通过实际配置表单完成连接，连续 3 轮真实生成、追问与 SDK 动作回传；固定回放未参与该测试 |
| Windows / Android / iOS | UNVERIFIED：未执行真实主机/真机验收；iOS 无项目宿主 |
| 生成式工作区相对固定页面的收益 | PENDING：技术闭环已验证，尚未进行正式的成本/收益对照，未声称产品形态已完成改造 |

截图：[回放实际尺寸](../evidence/genui_20261022/macos_replay.png)、[紧约束与新解释](../evidence/genui_20261022/macos_tight.png)、[分类窗口](../evidence/genui_20261022/macos_category_window.png)。仅对应当前 macOS 工作区，不能作为其他平台或模型输出证据。

新增 SDK 带入 `audioplayers` 等传递依赖。当前目录不使用音视频组件；macOS 已检查插件注册后的主窗口与分类子引擎。锁文件只新增必要依赖，未保留镜像切换造成的无关升级；Podfile.lock 使用与既有 CI 相同的 Ruby JSON 序列化摘要，已有 pod 校验值保持不变。没有修改门禁或 CI 语义。

## 后续验收

真实记录见 [codex_live.json](../evidence/genui_20261022/codex_live.json)。第一轮生成松约束实验；本地将期望宽度改为 180dp，布局实测 180dp；第二轮请求仅切换紧约束，模型保留父宽度 240dp 与期望宽度 180dp，Flutter 实测变为 240dp；第三轮点击生成界面中的解释按钮，经 SDK 回传状态 v2 和实际尺寸，模型更新说明。共 3 个请求、1 次 SDK 动作，未发送仓库文件；未设置 API key 环境变量，使用 CLI 已保存的 ChatGPT 登录。模型标识 `codex-default` 表示 CLI 默认选择，不声称核实了具体底层模型名。

后续核查发现，不能仅凭 `--ignore-user-config` 和空工作目录推定自动上下文已关闭：初轮仍带有自动技能说明等默认上下文，因此不将其作为严格上下文边界的最终验收。补充上述显式开关后，以本机模拟 Responses 服务核验请求。保留的 [上下文核验结果](../evidence/genui_20261022/codex_context_audit.json) 仅包含布尔标记和配置项：未发现 AGENTS 指令头、技能/记忆区块或 Forge 仓库路径，不保存模拟请求正文；本机默认全局指令文件为空。该检查验证这些具体边界，不是对全部 CLI 内置提示的穷尽审计。官方配置依据见 [Configuration Reference](https://learn.chatgpt.com/docs/config-file/config-reference)。最终真实记录已替换为显式关闭自动上下文后的成功重验。

最后一次成功用例包含 3 个模型请求；该数量不包含前期排障重试，未统计总额度消耗。测试同时修正了滚动后未等待布局帧、SDK 异步事件尚未开始就检查完成状态的竞态，最终用例通过真实按钮触发回传。桥接已停止，本次临时令牌与测试定义文件已清理。

可重复执行入口为 `apps/flutter_forge/integration_test/genui_workbench_live_test.dart`。该测试默认跳过，仅显式设置 `GENUI_LIVE=true` 与本机临时 `GENUI_LIVE_TOKEN` 才调用模型；临时定义文件不要放入仓库。标准质量门禁不调用外部模型。

```bash
cd apps/flutter_forge
flutter test integration_test/genui_workbench_live_test.dart -d macos \
  --dart-define-from-file=/tmp/forge-genui-live-defines.json
```

定义文件包含 `GENUI_LIVE` 布尔值与 `GENUI_LIVE_TOKEN` 字符串。联调完成后停止桥接、撤销本次临时令牌并删除定义文件；真实凭据不会写入证据 JSON。

后续先评估当前生成工作区与固定页面的实际收益，再决定可选择新入口、第二种实验及整体框架调整。模型仍可能返回无效协议，必须保留诊断和重试入口；一次成功测试不代表所有问题和模型输出均可靠。
