# 按平台差异组织自动化测试的实施计划

日期：2026-10-26。基线：`dev` / `3fc98c422a0b391a82d1d5d3994bc41d34fc2a56` 与当前未提交工作区。本文基于 [平台差异第一阶段](PLATFORM_DIFFERENCES_PHASE1.md)、[Windows #33 修复](reports/WINDOWS_ISSUE33_FIXES-20261026.md) 和现有测试入口制定；不是各平台已通过验收的声明。

本轮范围是更新已有回归用例、补平台分支测试并制定后续执行计划。没有新增 CI 工作流、调整门禁语义、派遣 Hub Worker 或执行发布。后续实施项仍为待实施；当前用例更新与验证结果见文末。

## 已有证据的使用边界

当前工作区还记录了 [iQOO Android 回归](reports/ANDROID_IQOO_REGRESSION-20261026.md)：单台 Android 16 真机的共用导航、原生电池与普通入口触摸/返回/冷启动已有本地结果。该报告属于并行任务记录，本轮未重新执行其设备操作；T3 应复用这些用例，再补权限、文件提供器、IME 与媒体等缺口，不能把 Android 全部标为从零开始，也不能据此认定所有功能已验收。macOS 既有局部窗口/GPU 记录及 Windows #33 的缺口同样按原报告范围使用。

## 测试分层

| 层次 | 验证内容 | 运行环境 | 结果能证明什么 |
| --- | --- | --- | --- |
| 共用逻辑与契约 | 路由守卫、模块支持声明、状态、异步取消、桥接 Outcome、CRLF/路径/编码 | 现有质量门禁 | 源码逻辑与契约正确，不能证明原生插件已注册或硬件可用 |
| 平台差异 Widget | 注入的平台快照、布局断点、桌面键鼠、移动只读、Windows 滑块语义 | 当前主机上的 Flutter tester；必要时 TargetPlatformVariant | 指定分支行为符合预期；报告明确为模拟平台，不能标为对应宿主 PASS |
| 真实宿主集成 | 真实插件、窗口生命周期、系统返回、浏览器历史、引擎语义更新 | Windows/macOS 主机、Android 设备、实际浏览器 | 仅证明本次主机、构建模式及测试操作的结果 |
| 外部系统与设备 | UIA/VoiceOver/NVDA、系统文件对话框、安装器、权限弹窗、外设和真实 GPU | 各平台原生驱动及设备 | 需要外部观察，不能用 Dart 回调、mock 或进程退出 0 代替 |

平台身份使用现有 `AppPlatformSnapshot`/`AppPlatformScope`；入口准入继续从 `module_registry` 和能力策略读取。窗口宽度只作为布局维度，不替代平台身份。测试选择及结果不写入支持维护矩阵，不建立另一份模块平台白名单。

## 当前入口与待补缺口

| 平台 | 复用入口 | 差异专项与缺口 |
| --- | --- | --- |
| 共用 | `integration_test/app_test.dart`；现有路由、状态、桥接及工具测试 | 通用导航用例按实际平台命名；不适用的用例显示 SKIP；硬件/网络模块后续从确定性冒烟中拆出，逐个检查稳定入口标识，避免仅发现 Scaffold 就算模块已打开 |
| Windows | `test/shared/windows_semantics_test.dart`、`integration_test/windows_acceptance_test.dart`、`tool/windows_ui_acceptance.py` | P1：子引擎创建/关闭/复用/重开；P2：快速搜索退出后三模块 UIA 更新，GenUI 生成后解释按钮可达；文件选择/取消需要外部驱动；最后核对安装器、Win10 实色/Win11 Mica 和 DPI |
| macOS | `integration_test/desktop_material_acceptance_test.dart`、`genui_ax_soak_test.dart`、`webview_macos_test.dart` | 每引擎注册与关闭、系统红黄绿按钮/真实全屏、NSVisualEffectView 与坐标点击、AX 日志与 VoiceOver；现有单窗口结果不扩展到分类窗口 |
| Android | 共用导航/移动 Drawer 集成、`battery_monitor_flow_test.dart`、现有 bridge tests | Drawer 系统返回与软键盘、前后台资源释放、文件提供器选择/取消、视频触摸及权限状态；3D 维持只读，真实 GPU 首帧另验；外设另设显式环境前置条件 |
| Web | `test/shared/web_compatibility_test.dart`、共用路由契约 | Chrome 自动化先覆盖，Safari 独立验收、Edge 冒烟；深链/子路径部署、前进后退、搜索恢复、文件名边界、视频用户手势与 Range/CORS；浏览器不启动原生桌面控件 |
| iOS | 平台模型、支持声明与 Widget 分支测试 | 当前没有宿主目录。仅验证模型与不可用解释，不创建虚假设备任务；宿主建立后再规划系统权限、文件选择与真机流程 |

上述 `integration_test/` 与 `test/` 路径均相对于 `apps/flutter_forge`。设备依赖用例按运行时能力和显式 fixture 选择，正常的“能力不支持”可作为降级用例通过，不能作为“功能成功”用例通过。

## 本轮已更新的用例

- `test/shared/learning/learning_slider_test.dart`：Android/iOS/macOS/Windows 注入分支的拖动、回调边界与禁用语义；Windows RTL 方向键、Home/End 和端点读屏动作。
- `test/shared/web_compatibility_test.dart`：真实浏览器中模拟 Windows 主题平台，验证 Web 仍使用 Material 滑块并能拖动。它与原生 Windows 测试分别执行。
- `test/shared/windows_semantics_test.dart`：复用 #33 的逐帧可达性/引用完整性、三模块页面插入、GenUI 动态生成和输入回归，不把这些用例改名为 UIA 实机测试。
- `integration_test/app_test.dart`：日志使用真实平台标签；移动专用导航在非移动宿主显示 SKIP，保留已有 Drawer 系统返回用例。
- `integration_test/windows_acceptance_test.dart`：检测真实宿主，非 Windows 显示 SKIP；文件对话框超时必须失败；仅 picked/cancelled 是本用例允许的终态，不可用/error 不再算成功。选文件与取消尚未拆为独立原生驱动场景。
- `tool/windows_ui_acceptance.py` / `_test.py`：在现有窗口生命周期观察之外，日志出现 #33 的 MissingPluginException、启动等待失败或 AXTree 更新错误必须失败，即使进程正常退出。测试覆盖错误识别；真实窗口/UIA 的新场景按下阶段补齐。

## 实施顺序与完成条件

| 阶段 | 工作 | 依赖/完成条件 | 当前状态 |
| --- | --- | --- | --- |
| T0 回归真实性 | 完成本轮用例更新；补 Widget 分支、浏览器回归和 Windows 日志错误检测；现有完整门禁继续运行 | 定向测试及完整门禁通过；宿主未运行逐项保留待验收 | 本轮实施，执行记录见下 |
| T1 套件与报告拆分 | 共用 fixture/交互函数/平台 adapter 与一份核心 smoke，扩展用例显式选择 | 统一 catalog 和执行报告；全 SKIP/零执行拒绝通过；CI/门禁不变 | 已实施，见重构报告 |
| T2 Windows/macOS 优先 | Windows：#33 两项闭环、文件选择/取消各自断言；macOS：同类窗口生命周期与 AX 浸泡；共用桌面流程分别跑真实宿主 | 具备可解锁桌面、固定 fixture 和权限；保存 exe/app/engine 哈希与原生错误日志；UIA 与截图均匹配当前页；读屏单列确认 | 待真实宿主实施 |
| T3 Web/Android | Web：浏览器历史/深链和媒体；Android：返回/IME/生命周期/文件提供器与触摸；外设测试与确定性流程分开 | 浏览器或设备明确可用；不以 Chrome 代替 Safari，不以模拟器结果代替指定真机/硬件验收 | 待实施 |
| T4 调度接入 | 将稳定的各平台套件接入各自 runner；共用源码门禁与宿主验收分别报告 | 前三阶段套件稳定、环境可重建；修改 CI/门禁需单独明确 `packaging_change` 授权及人工验收，不从本计划推定已获授权 | 未实施 |

T1 实施采用更小的结构：`test/support/automation/` 持有共用 fixture、交互函数、平台 adapter 与 smoke 场景；`integration_test/app_test.dart` 保留一个真实宿主入口，检测实际平台；`test/automation/smoke_test.dart` 复用该场景做模拟平台与 Chrome Widget 回归。没有为四个平台复制四份同样入口。全目录遍历移至 `integration_test/module_catalog_test.dart`，由统一目录显式选择。

T2 Windows 优先用已有 `tool/windows_ui_acceptance.py`，补 `quick_open_semantics` 场景：用真实鼠标/键盘从快速搜索进入约束布局、在线视频和 GenUI；确认旧搜索控件已消失、当前页面 UIA 控件存在；生成后确认解释按钮可达并记录状态变化。基础专项每场景执行 1 轮；需要压力复现时才显式增加轮数。任何一轮失败都保留结果，不以重试成功覆盖首次失败。窗口场景沿用 `reopen`、`reuse`、`rapid_categories`、主/子窗口关闭；HWND 是原生窗口标识，不能冒充 Dart window UUID 或引擎已销毁证据。

## 执行与记录约定

1. 每次记录源码 SHA、脏树范围/受测文件哈希、实际 OS/版本/架构、Flutter/engine/Dart、Node、构建模式、设备/浏览器及产物哈希。记录不进入日常支持维护矩阵。
2. 单项状态使用 PASS、FAIL、BLOCKED、SKIP、NOT_RUN。缺设备/驱动/解锁桌面为 BLOCKED；产品超时/错误为 FAIL；不适用为 SKIP；未运行为 NOT_RUN。宿主专项全 SKIP 属于配置未就绪，不能提升为该平台已验收。
3. 流程断言看当前页面标识、实际状态变化与原生/UIA 观察；日志无错误、截图存在、构建成功、退出码 0 都不能单独证明功能成功。
4. 外设测试不在后台默默跳过：缺少指定设备、网络或测试资源时给出明确条件。测试仅清理自己创建的进程、窗口和 fixture，禁止按进程名全局结束应用。
5. 真实模型、公共网络和 GPU 的用例独立记录。日常 GenUI 回归用固定回放；真实模型专项显式启用。视频播放使用项目维护的验证资源，随机公共链接不作为稳定基线。

### 当前可运行命令

在仓库根目录：

```bash
bash tool/quality_gate.sh
PYTHONDONTWRITEBYTECODE=1 python3 tool/windows_ui_acceptance_test.py
```

在 `apps/flutter_forge`：

```bash
flutter test --no-pub test/shared/learning/learning_slider_test.dart test/shared/windows_semantics_test.dart
flutter test --no-pub --platform chrome test/shared/web_compatibility_test.dart
```

仅在匹配的真实宿主/驱动就绪后执行，以下不是本轮已完成事实：

```bash
# Windows，先准备外部文件对话框驱动
flutter test integration_test/windows_acceptance_test.dart -d windows
# macOS，真实 embedder 语义压力测试
flutter test integration_test/genui_ax_soak_test.dart -d macos --dart-define=FORGE_AX_SOAK=true
# Android，选定实际设备 ID
flutter test integration_test/app_test.dart -d <android-device-id>
```

Windows 生命周期入口在仓库根目录执行：

```powershell
python tool/windows_ui_acceptance.py --exe <FlutterForge.exe> --output <new-report-directory> --iterations 10
```

## 本轮执行记录

本轮结果：

- PASS：平台分支及 Windows 语义专项 15 项；四种原生主题平台的 Widget 分支均执行，但不代表四种真实宿主运行。
- PASS：实际 Chrome 浏览器测试 6 项，其中包含 Windows 主题平台下的 Web 滑块分支。
- PASS：Windows 自动化工具 7 项；包含真实 Session.finish 路径对 UTF-8 中文启动错误及 AXTree 错误的拒绝，正常退出码不能覆盖这些错误。使用 fake 进程，不启动 Windows 应用。
- PASS：完整质量门禁；759 项 workspace Flutter/Dart 测试、32 项 Node 工具测试、17 项 Python 桥接测试和 scaffold 往返；35/35 模块测试存在性、生成物、格式与 bare analyze 全部通过。Windows 工具的 7 项在门禁之外显式执行，未悄悄调整门禁入口。
- NOT_RUN：本轮未执行 Windows/macOS 原生集成、Android 真机、Safari/Edge、外设和读屏器专项。前述并行 iQOO 记录继续按其原有范围引用，不由本轮状态覆盖。

本机日志为 `/private/tmp/forge-platform-tests-targeted-final.log`、`/private/tmp/forge-platform-tests-browser.log` 和 `/private/tmp/forge-platform-tests-quality-final.log`，是临时执行证据；不作为分发产物或跨主机验收证明。


## 统一管理与 adapter 重构（后续实施）

本节记录 T1 的实际实施结构，取代此前全平台入口复制建议。全局执行单元现登记于 `tool/automation_catalog.json`，通过 `python3 tool/automation.py list/run` 管理；详细交互标准、平台 adapter、轻量默认范围和维护规则见 [测试指南](TESTING.md)。T2/T3 的真实宿主功能缺口继续按实际执行范围保留，不能从测试代码重构推定硬件和所有原生专项已验收。

基础 smoke 只跑两个确定性模块及分类/搜索/子路由，一次挂载；全模块遍历、GPU、外设、真实模型、原生窗口压力均显式选择。现有门禁与 CI 不变。重构后的执行结果、范围审计和环境限制见 [adapter 重构报告](reports/AUTOMATION_ADAPTER_REFACTOR-20261026.md)。
