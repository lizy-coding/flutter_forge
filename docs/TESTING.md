# 测试指南

Windows MSIX 的下载、哈希/证书核对、开始菜单激活、核心交互、真机扩展与卸载清理见
[跨设备测试清单](../apps/flutter_forge/windows/store/TEST_CHECKLIST.md)。清单随 Actions artifact 一起提供；安装包验收与源码宿主集成分别记录。

## 统一入口

自动化执行单元统一登记在 `tool/automation_catalog.json`。每条记录只保存 ID、入口、执行 adapter、适用宿主、显式前置条件和超时，不逐条登记数百个单元断言，也不复制模块支持白名单。

```bash
# 仓库根目录；只列出用例，不执行
python3 tool/automation.py list
# 默认只运行 smoke，一次 Flutter 调用；报告目录必须是新目录
python3 tool/automation.py run --platform local --output /tmp/forge-smoke-local
python3 tool/automation.py run --platform web --output /tmp/forge-smoke-chrome
python3 tool/automation.py run --platform macos --output /tmp/forge-smoke-macos
python3 tool/automation.py run --platform windows --output C:/temp/forge-smoke-windows
python3 tool/automation.py run --platform android --device <android-id> --output /tmp/forge-smoke-android
```

`local` 是当前主机 Flutter tester 的平台分支模拟；`web` 是 Chrome 中的 Widget 测试；macOS/Windows/Android 是实际宿主集成。报告的 `evidence` 区分这三种范围。Android 设备 ID 还会核对 `flutter devices --machine`；不能将 macOS 设备或主题平台覆盖当成 Android 主机结果。iOS 尚无宿主，保留平台模型/Widget 测试，不注册虚假原生执行项。

默认 smoke 只执行一次共用流程：启动首页 → 分类 → 三棵树模块 → 返回 → 搜索/恢复 → 弹窗与列表子路由。两种确定性模块共用一次 App 挂载，不访问真实模型、外设、媒体或 GPU，不遍历全部模块。扩展目录回归保留为单独的 `catalog` 执行项。

## 核心交互与 adapter

Windows 真机报告中的开始菜单重启与原生标题栏复核使用以下显式专项，不进入默认 smoke。
先用 `Get-AppxPackage -Name Forest.FlutterForge.LocalTest` 取得安装目录，在解锁的交互桌面执行：

```powershell
# WIN-01：每轮由测试者仅从开始菜单启动；脚本不通过 AppsFolder 或直接执行 EXE 兜底
python tool/windows_ui_acceptance.py --exe '<InstallLocation>/flutter_forge.exe' --output C:/temp/forge-start-menu-01 --launch-mode manual-start-menu --cases main_with_child --iterations 10
# WIN-02：仅运行主窗口与分类窗口的原生最大化/还原点击与状态对照
python tool/automation.py run --platform windows --case windows-caption --exe '<InstallLocation>/flutter_forge.exe' --output C:/temp/forge-caption-01
```

第一条必须直接从可交互终端执行，按每轮提示操作；没有终端、已存在同路径进程或无法唯一识别新 PID 时为 BLOCKED。
每次手工开始菜单确认最多等待 180 秒，超时为 BLOCKED。该手工入口直接执行，不受统一 runner 的进程级总时限保护；catalog 中的预算不能当成它已具备总进程超时。
它记录测试者确认的开始菜单来源、PID、每轮时间与退出结果；不是机器自动证明开始菜单点击，也不替代 AppModel 原始激活事件。
结束时（包括失败路径）只读采集该时间段中匹配应用路径/包身份的 AppModel/TWinUI XML，保存在 `activationEvents`；禁用、无法访问或可能截断分别标记，不开启系统日志，不把“无事件”当成成功或产品失败。
失败后不会终止测试者启动的进程，便于继续观察。应用标准输出无法附加时 `applicationLogCaptured=false`，不能据此断言应用没有日志错误。
第二条每次原生点击重新读取 DWM 按钮边界，并用实际最大化状态确认响应；两种窗口都保存调整前/最大化/还原截图，图标可辨性继续标为 `PENDING`，必须人工核对。
Snap、最小化、F11、跨 DPI、主题和读屏继续按测试清单各自复核，不能由该最大化/还原专项自动判为通过。

共用代码在 `apps/flutter_forge/test/support/automation/`，只属于测试层，不进入业务能力层。

| 文件 | 职责 |
| --- | --- |
| `app_fixture.dart` | 创建 App/Router/Theme/History；测试持有并在 finally 中释放，不写用户偏好 |
| `interactions.dart` | 有界等待、连续动画下的帧推进、定位唯一且可命中的真实点击、收集 Flutter 错误 |
| `platform_adapter.dart` | 桌面工作台、紧凑 Drawer、Web/移动搜索与返回的差异；模块准入从 registry 查询 |
| `smoke_scenarios.dart` | 一份核心用户流程，供模拟平台 Widget、Chrome 和原生集成复用 |

交互标准：

1. **定位**：优先已有 Key，并限定当前页面/对话框范围；多个匹配不能随意取第一个。滚动容器的 `.first` 仅用于选定页面持有的外层 Scrollable。
2. **输入**：共用点击函数确认唯一、滚动居中并等待可命中，再调用 `tester.tap`；不直接调用 onPressed 冒充用户点击，不忽略遮挡警告。
3. **等待**：以页面/状态断言为准并设置上限；需要推进动画时使用有界帧推进。GPU、视频或流式页面不能无界等待 settle。由统一 runner 执行的项还有进程级超时；手工专项的边界按其入口说明记录。
4. **断言**：同时检查路由和注册模块 Entry 挂载，不能只看到应用壳 Scaffold 就判定模块已打开。平台功能专项继续保留其业务、原生及设备断言。
5. **返回**：桌面工作台返回、移动页面返回、搜索关闭各自由 adapter 处理；嵌套子页面限定到该页面的 BackButton。Android 框架返回与 ADB 物理按键证据分开描述。
6. **释放**：通过 `withApp` 在 finally 中卸载 Widget，再释放 router/theme/history。场景内创建的硬件/网络会话仍由该场景关闭，不交给 UI fixture 偷偷管理。

`app_test.dart` 是精简后的实际宿主 smoke；`module_catalog_test.dart` 保留全模块遍历和六分类重复 Drawer 回归；Windows 文件选择、桌面材质和桌面 3D 流程复用同一 App fixture。BLE 等专项复用等待函数，独立保留设备操作和授权条件。没有为提高通过率删掉专项断言。

## 套件选择与成本

```bash
# 扩展目录；可能启动原生、网络或 GPU 模块，必须显式选择
python3 tool/automation.py run --platform macos --case catalog --output /tmp/forge-catalog
# 桌面材质专项
python3 tool/automation.py run --platform macos --case desktop-material --output /tmp/forge-material
# Windows 真实窗口/UIA；每个场景仅 1 轮，不隐式做压力浸泡
python3 tool/automation.py run --platform windows --case windows-lifecycle --exe <app.exe> --output <new-dir>
# 前置条件必须由调用方确认；否则 BLOCKED，不能默默跳过
python3 tool/automation.py run --platform windows --case windows-file --ready external-file-dialog-driver --output <new-dir>
# runner/catalog 自测与 Windows 日志驱动测试不启动 App
python3 tool/automation.py run --platform local --case manager-tests --case windows-log-tests --output /tmp/forge-tool-tests
```

同一 case 重复传入会去重；只执行显式选择的项，不自动追加全量门禁、全目录、压力测试或硬件用例。多个 case 按顺序执行，不增加并发引擎和自动重试。需要压力复现时直接使用原有专项的轮数参数，结果和基础冒烟分别记录。

真实模型及 Hub 集成在目录中标为 `manual`，通过原入口及显式凭据执行；通用 runner 不收集、打印或代传 token。BLE 需要显式确认硬件与权限。不要为了让一条日常命令“全绿”而给这些用例默认填入真实服务或跳过其前置条件。

## 结果与可追溯性

每次执行写入新目录中的 `result.json` 与各项原始日志；包含源码 SHA、脏树路径、实际执行命令、证据种类、用例计数和耗时，不写入模块支持维护矩阵。Windows 原生驱动自己的报告继续持有可执行文件哈希、PID/HWND、截图及事件日志；通用报告不扩大它的证据范围。

- PASS：命令成功且 Flutter JSON reporter 确认至少一项真实用例成功，无失败事件。
- FAIL：测试失败、产品超时、报告不完整或退出非零。退出码 0 和一行“All tests passed”不能代替执行事件。
- BLOCKED：目标宿主、设备、驱动、命令或显式前置条件缺失；Flutter 全跳过也不能冒充平台通过。
- NOT_RUN：中断后未执行的后续项。失败不自动重试覆盖；Ctrl-C 只停止并清理本次创建的进程树，不按名称全局结束 App。

runner 总退出码：0=PASS、1=FAIL、2=BLOCKED、130=用户中断。不适用平台不能作为 PASS。原生 UIA、读屏器、系统文件对话框、真实 GPU 和外设验收仍使用各自实际观察，mock/主题平台注入不构成这些结果。

## 用例维护

- 新单元/Widget 测试放在 `apps/flutter_forge/test/` 或所属 package 的 `test/`，继续由原质量门禁管理，不逐项扩展 catalog。
- 新宿主集成入口登记 catalog；校验器检查 `integration_test/` 内入口完整且只登记一次，防止文件存在但没有任何执行入口。
- 可复用的只有定位、等待、Fixture 和已出现的共同流程。保留模块业务断言，不建立描述任意 UI 的 JSON DSL、插件注册框架或新的调度 DAG。
- 不复刻每个平台整份流程；优先共用函数与小型 adapter。只有宿主接口或业务语义确实不同才单独编写专项。
- 修改 catalog/runner 后执行 `PYTHONDONTWRITEBYTECODE=1 python3 tool/automation_test.py`；交互 helper 由 `test/automation/` 的定向测试覆盖。

## 原有入口与质量门禁

```bash
# 原有入口语义保留；无需同时再跑同等范围的 runner case
bash tool/quality_gate.sh
bash tool/test_all.sh
bash tool/smoke_baseline.sh
bash tool/smoke_baseline.sh --ax-soak
# 主应用定向测试从 apps/flutter_forge 执行
cd apps/flutter_forge
flutter test --no-pub test/automation
flutter test --no-pub test/shared/learning/learning_slider_test.dart
```

`quality`、`source-baseline`、`node-tools` 等 case 只是这些已有入口的显式索引，没有修改 CI 或门禁脚本语义。基线脚本保留其 GenUI、工作流和窗口回归范围，不与新的基本 UI smoke 混淆。平台专项的实施背景见 [平台自动化计划](PLATFORM_AUTOMATION_TEST_PLAN.md)。
