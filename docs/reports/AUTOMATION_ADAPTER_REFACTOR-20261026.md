# 自动化用例统一管理与 adapter 重构

日期：2026-10-26。基线：`dev` / `3fc98c422a0b391a82d1d5d3994bc41d34fc2a56` 与当前未提交工作区。本文记录源码重构与本机自动化结果，不代表四个平台均已验收或已发布。

## 分析与取舍

原始 12 个集成入口分散管理；全模块遍历放在默认 `app_test.dart`，一次基本回归会触发约 31 个可用模块的网络、原生、GPU 或异步初始化。App/Router/Theme 的挂载与释放在通用导航、Windows 文件选择、桌面材质和 3D 流程中重复；等待/滚动/点击也各自实现。仅看到 Scaffold 的断言无法区分应用壳与实际模块。

因此将测试执行单元收拢为一个目录，保留既有专项，用小型平台 adapter 复用确定性用户意图。没有增加测试 DSL、动态插件发现、依赖调度 DAG、额外 Python 依赖或生产代码抽象。真实模型/Hub 流程保持显式凭据与专有会话，不强行塞入 App fixture。原生 UIA 驱动继续负责其 OS 行为；Flutter adapter 不冒充原生输入工具。

| 原结构 | 当前结构 | 维护与执行影响 |
| --- | --- | --- |
| 默认入口遍历全部模块、重做启动 | `app_test.dart` 只调用共用 core smoke；全目录与全分类重复 Drawer 保留到 `module_catalog_test.dart` | 默认两种纯 Flutter 模块、一次挂载；重回归显式选择，原覆盖未删除 |
| 四处独立完整 App 初始化/部分释放 | `AppFixture` / `withApp` 在 finally 中统一卸载、释放 Router/Theme/History | 现由基础、扩展目录、文件选择、材质、3D 五个入口复用 |
| 分散导航、搜索、返回与控件等待 | 平台 adapter + 普通函数；BLE 复用有界等待 | 业务断言保留；搜索结果限定到实际结果容器，嵌套返回限定页面，点击必须唯一且可命中 |
| 单元/模拟/宿主结果易混用 | catalog 执行 adapter 明确 evidence，Flutter JSON reporter 统计实际用例 | 全跳过/零执行/只有 loader 不算通过；错误退出和错误事件保留 |
| 专项隐含昂贵环境/多轮执行 | 23 个显式执行单元；默认只选 smoke | 13 个现有集成文件均登记一次；单元/包测试作为原 quality 集合管理，避免逐断言登记 |

`module_discovery_live_test.dart` 的自有 Router、GPU diagnostics 的直接 runtime、GenUI/工作流/电池/WebView 的专用 session 具有不同测试对象，保留隔离 fixture。共性只在确实出现时提取，避免一层 adapter 承担所有业务。

## 交互标准与入口

详细标准见 [测试指南](../TESTING.md)。源码入口：

- `tool/automation_catalog.json`：全局用例 ID、适用宿主、显式前置条件、入口及执行超时。
- `tool/automation.py`：list/run、平台命令适配、报告与进程所有权；默认一个 smoke case，重复 case ID 去重，没有隐式全量执行或重试。
- `apps/flutter_forge/test/support/automation/`：App fixture、等待/点击/错误收集函数、平台交互 adapter、一份共用 core smoke。
- `apps/flutter_forge/test/automation/`：四个模拟平台分支与等待失败/模糊定位/遮挡点击负向用例。

命令示例（仓库根目录，输出目录必须新建）：

```bash
python3 tool/automation.py list
python3 tool/automation.py run --platform local --output /tmp/forge-smoke-local
python3 tool/automation.py run --platform web --output /tmp/forge-smoke-web
python3 tool/automation.py run --platform macos --output /tmp/forge-smoke-macos
```

Windows 的真实 UIA、消息关闭、文件选择分别记录，不混为一种验收。`windows-posted-close` 仅执行既有脚本的 WM_CLOSE/SC_CLOSE 各一次，证据类型为 `native-posted-close`；它不是 caption/Alt-F4 真实点击。真实模型等三个 live 入口登记为 manual，通用 runner 不收集或代传 token。

## 验证结果

| 执行范围 | 结果 | 证据范围 |
| --- | --- | --- |
| 共用 helper 与四个平台 smoke 分支 | PASS，8 项 | 当前 Mac 的 Widget tester；含超时、遮挡、模糊定位与失败后的 fixture 释放负向用例，不冒充四个平台宿主 |
| runner/catalog 自测 | PASS，15 项 | 覆盖 13 个集成入口完整性、重复注册/执行、错误宿主、Android 设备核对、全跳过/无执行/错误事件、进程超时清理、用户中断、缺失报告及消息关闭证据区分 |
| Windows 既有 UIA/日志驱动自测 | PASS，7 项 | fake 进程与场景编排，不运行 Windows 应用 |
| 统一入口 local smoke | PASS，4 项 | 四种模拟平台，一次 Flutter 进程调用，约 5.4s |
| 统一入口 Chrome smoke | PASS，1 项 | 实际 Chrome 的 Web Widget 交互，约 26.3s（含编译/启动）；不覆盖浏览器历史、Safari/Edge |
| 统一入口 macOS smoke | PASS，1 项 | 真实 macOS Debug embedder，约 28.7s（含构建/启动） |
| 复用 fixture 的 macOS 材质专项 | PASS，1 项 | 原生状态、教学表面、主题、搜索恢复及真实全屏 round trip，约 34.9s |
| 复用 fixture/adapter 的 macOS 3D 流程 | PASS，1 项 | 原有相机、选择、聚焦、清除和返回断言继续通过；不额外宣称 GPU 完成或屏幕呈现测量 |
| 完整质量门禁 | PASS | 767 项 workspace Flutter/Dart 测试、32 项 Node 工具测试、17 项 Python 桥接测试和 scaffold 往返；生成物、格式、bare analyze、35/35 模块测试存在性全部通过 |
| Windows 原生入口 | BLOCKED | 当前不是 Windows 主机；统一入口未启动其他平台冒充 Windows |
| Android 原生入口 | BLOCKED | 当前 `flutter devices --machine` 只有 macOS/Chrome；原 iQOO ID 未连接，入口拒绝启动其他设备 |

macOS Flutter 工具有 `Failed to foreground app; open returned 1` 提示，但 embedder 内的测试用例、原生状态及执行结束事件均成功。该结果是 Flutter 集成测试范围，不是物理坐标点击、UIA/VoiceOver、窗口视觉或安装器验收。此前 iQOO 记录继续按其当时提交/工作区和设备范围解释；本次未重跑该手机。

本机报告位于 `/private/tmp/forge-automation-{local-20261026-final,web-20261026-final,macos-20261026-final,material-20261026-final,scene-20261026,windows-host-check,android-host-check}/result.json`。完整门禁日志为 `/private/tmp/forge-automation-quality-complete.log`。这些是临时证据，结构化报告记录源码 SHA/脏树、命令、证据类型和测试计数；不是发布产物。

## 完成范围审计

- 全局管理：catalog 含全部 13 个宿主集成入口，原单元/包测试仍由既有 quality 执行集合拥有。新增入口漏登记或重复登记会被校验拒绝。
- adapter 与核心标准：共用场景只表达用户意图；桌面工作台、紧凑 Drawer、Web/移动搜索及返回的差异集中于 adapter，模块准入继续从 registry 读取。
- 默认成本：两个纯 Flutter 模块、一次挂载、一个执行 case，无模型、硬件、GPU、全目录、自动重试或压力循环。扩展覆盖保留为显式专项。
- 函数复用与测试重构：五个完整 App 入口共享 fixture，BLE 等共享有界等待；独有业务会话和原生驱动保留各自职责。失败/跳过/不适用不被绿灯掩盖。
- 验证：源码/工具、四平台模拟、Chrome、当前 macOS 的实际 smoke 与两个被重构专项已执行；Windows/Android 当前环境限制被实际报告，未扩大证据。
- 交付边界：未修改 CI、quality/test_all/smoke_baseline 等既有门禁/基线脚本语义；未提交、推送、合并、发布或更新记忆；保留并行 NFC、平台差异和发布目录改动。


命令使用参数向量，解析 PATH/PATHEXT 后调用 subprocess，不开启 shell 展开；空间路径保持为单个参数。此实现参考 [Python subprocess 文档](https://docs.python.org/3/library/subprocess.html) 对完整可执行路径和 Windows 命令解析的说明，Windows 真主机行为仍按上表待验证。
