# 插件维护实施与验收记录

日期：2026-10-26。技术修复已实施，核心认证及通知系统调用已执行真实macOS验证；按用户最新要求停止扩展全局冒烟测试。不能据本报告宣称其他平台或发布版本验收通过。

## 源码与授权范围

- 使用当前本地 checkout，`dev` HEAD `f64ae49c3343a8f5425bc43d0168e980612b9503`，相对本地 origin/dev 超前8；未更新远程跟踪引用。App 版本保留 `1.2.10+4`。
- 开始时已有桌面工作台、discovery、GenUI、BLE client/scan/GATT 拆分及 `release/1.2.10` 未提交产物。原 tracked diff 快照保存于 `/private/tmp/forge-maintenance-baseline.patch`。非本轮作用范围未回退；desktop_workbench_test 在会话期间还有并行新增/格式化，已保留。BLE session/scan/GATT 拆分保留，仅调整既有未跟踪 ble_client 的系统边界。
- `release/1.2.10` 的旧 DMG/EXE/APK/ZIP/manifest 不作为本轮证据，未覆盖、发布或重打包。无 commit/push/merge/release。
- 已读取根机器契约、目标模块/包契约、ADR0019 与生成器规则。Agent Hub projects.json 已读；agent-context 尝试仍因写 Hub workspace 临时目录受限而失败，不表示 Forge 功能失败。
- 用户在本会话批准将“指纹认证/面容认证”更名为“强生物识别/弱或更强生物识别”，保留三个入口和原认证允许/凭据回退策略，并纠正能力说明。没有变更任何平台入口或 USB entryRestriction。

## 各能力域实施

| 能力域 | 修改及理由 | 验证范围 |
|---|---|---|
| 生物识别 | 从锁定提交内部化为 packages/flutter_biometric；Android 凭据类型改为 androidx 命名常量；成功方式独立为 biometric/deviceCredential/unknown；macOS 回退策略成功返回 unknown；原生持有 prompt/context 和操作ID，busy/取消/detach/窗口退出保证唯一终态；Dart 严格解析畸形响应；session dispose 结束等待，隔离迟到结果，finally 释放 loading | Dart通道/操作持有者/session/widget回归、Android原生类型与终态JUnit、Swift Fake LAContext原生回归、宿主构建；真实结果另表记录 |
| 通知 | session 初始化/权限查询/请求/投递/撤回均有销毁与操作所有权保护；严格校验顶层/状态/原因/id/cancelled；Android 配置重建移除旧监听器并保留有限等待，永久detach明确结束；请求代码隔离旧回调；UUID tag避免ID哈希碰撞；macOS 每实例回调与期限及窗口关闭清理 | Dart回归、Android PermissionRequest 持有者JUnit、Swift唯一终态/关闭/超时/迟到回调回归、构建；真实授权与可见展示另表记录 |
| BLE系统边界 | MainActivity 的 BluetoothSystemChannel 迁入独立 bluetooth_system_bridge FlutterPlugin；平台接口/token/不抛出能力查询/域内Outcome/逐条解析；缺适配、无适配器、关闭、权限拒绝与空列表分开；Activity/engine退出结束查询并回收profile proxy，迟到proxy继续释放 | bridge通道及BLE原有session/widget回归、Android编译与注册；没有替换universal_ble或改扫描/连接/GATT主要流程 |
| USB枚举 | 正式测试确认错误布尔字段引发TypeError；仅修 queryCapabilities 的错误类型降级为none | 插件14项测试，逐条错误记录已有回归保持通过；entryRestriction保留 |
| 电池 | 定点核查 battery_monitoring.dart 的首次采样期限、迟到恢复、close幂等和有界结果，以及 native_battery_monitoring.dart 的owner、定时器、订阅和finally清理。未发现本轮必须改写的已确认缺陷 | 原有95项Dart测试通过；不把Dart测试当作真实电池设备验收 |
| USB网络/FFI | 核查 backend_native.dart 的FFI分配/finally、句柄转移、socket超时、失败关闭和幂等close；macOS bound_tcp.c / Windows bound_tcp.cpp 的停止标记、有限轮询及资源退出。没有确认需修改的缺陷 | 原有3项测试及macOS宿主编译；没有新增真实USB设备证据 |
| 多窗口/相邻插件 | MainFlutterWindow与AppDelegate分类窗口回调均执行GeneratedPluginRegistrant；本轮插件实例状态不使用进程级全局认证owner；窗口清理按所属view.window过滤。3D/视频/文件选择依赖版本保持原锁定 | workspace测试、macOS/Android/Web编译；真实每引擎操作按下表，Windows仍需真实主机 |

真实验收补修：首次通知请求观察到macos_error_1，用户随后确认已允许，重新进入模块读到granted。不能据此推断具体系统时序；已将UNErrorDomain.notificationsNotAllowed映射为permissionDenied/notifications_not_allowed，其他域同码仍为failed，保留原一般错误原因码。session在请求失败后非交互重查权限事实，避免用错误回调覆盖后续系统状态；对应Dart及Swift回归通过。错误类型依据：[Apple notificationsNotAllowed](https://developer.apple.com/documentation/usernotifications/unerror/notificationsnotallowed)。

成功投递的表述改为“系统已受理通知（不保证可见）”，撤回true仅表示系统受理撤回请求；不承诺再次弹框、不把未知认证方式伪造为生物特征。取消原生认证实际调用 cancelAuthentication/LAContext.invalidate。系统通知权限询问无法强制关闭，退出/120秒未返回意味着等待结束并隔离旧结果，不声称系统操作已回滚。

macOS 当前 FlutterPlugin 协议没有 detachFromEngine 钩子：实际采用每窗口willClose监听、弱回调与deinit资源清理，未保留无效的同名方法。普通通知原生等待10秒，权限等待120秒；BLE原生profile查询4秒、Dart边界6秒；生物识别查询10秒、取消传输5秒，正常交互认证不套用电池采样周期或随意认证超时。

## 来源、API与生成契约

`flutter_biometric` 原始来源为 https://github.com/lizy-coding/flutter_biometric ，v0.2.0，提交 `84f36aa567384ea83e9148822355dc12db72eeb0`。只读取锁定来源的插件源码并复制进workspace；没有改写pub-cache中的插件源码或外部仓库。LICENSE原样保留，其实际内容为 `TODO: Add your license here.`，不能据此宣称MIT等具体授权，后续对外分发须维护者明确许可证。来源与本地差异见 packages/flutter_biometric/UPSTREAM.md。

破坏性API变化：成功结果新增method，usedDeviceCredential为bool?，unknown返回null；认证实例具有cancel/幂等close，关闭后拒绝新认证；能力增加strongAvailable/weakAvailable/sensorEnrollmentKnown。Forge所有调用方已同步。Dart旧bool结果可解码，但缺失/错误类型不会伪装成功。新BLE桥接仅拥有系统能力域，不引入硬件全局门面。

根workspace、App path依赖、catalog、能力规则来源和模块depends已更新并由生成器重建74个输出。支持矩阵平台集合未变；matrix.json仅更新依据路径。pubspec.lock仅移除外部flutter_biometric Git条目；其他依赖版本与源保持原锁定。未修改CI/quality_gate/test_all/check_generated_docs/verify_test_layout语义。

Android认证类型依据：[AndroidX BiometricPrompt官方API](https://developer.android.com/reference/androidx/biometric/BiometricPrompt)。设备凭据=1、生物特征=2，使用命名常量而非magic number；API29及以下仍拒绝原有strongWithCredential组合，不偷偷更改回退策略。

## 自动验证与构建

环境：macOS 27.0.1 (26A434) arm64，Flutter 3.47.2，Dart 3.13.2；Android使用Android Studio自带JDK。此为本机未提交源码验证，无生产/签名分发结论。

| 项目 | 本轮结果 |
|---|---|
| 修复前正式回归 | 12项失败复现两个session销毁回调和两个插件畸形响应；另1项USB错误布尔字段失败。均不是修复通过证据 |
| 完整 `PUB_HOSTED_URL=https://pub.dev bash tool/quality_gate.sh` | 五阶段PASS：生成无漂移、Dart格式、bare flutter analyze无issue、workspace+工具全量测试、35/35模块测试存在性 |
| workspace Dart测试 | 730项：App501，forge_articles3，file_picker8，ioc22，multi_window7，battery95，usb_network3，scene22，usb_detector14，notification25，biometric24，bluetooth_system6 |
| Android原生JUnit | 生物识别2项、通知1项，0失败/错误；验证命名常量映射、唯一终态、busy、中断释放、旧请求不能完成新请求 |
| macOS原生fake回归 | 认证busy/cancel/迟到回调/unknown及通知唯一终态/关闭/未决期限/迟到结果/权限错误域分类通过；未调用真实系统认证或通知接口 |
| macOS Debug | 最终Flutter Forge.app构建通过；输出 apps/flutter_forge/build/macos/Build/Products/Debug/Flutter Forge.app |
| Android ARM64 debug | 最终app-debug.apk构建通过，debug构建/Android debug签名；不是Release APK或真机验收 |
| Web Release | 最终 `flutter build web --release --no-pub`通过；不是浏览器交互或正式分发包装验收 |
| Windows | 本机尝试返回“build windows only supported on Windows hosts”；未验证Windows构建，按用户最新范围不继续扩展冒烟 |

旧依赖存在KGP/Gradle、Swift Package Manager和视频插件弃用警告；本轮编译无失败，未借此扩大成全量依赖升级。没有运行应用时先查询DTD，未找到已连接App；完成修改后冷启动本轮最终Debug构建。运行进程已核实为上述build目录路径，而非旧release安装包。后续真实验收发现的通知补修已由flutter run重新编译并启动最终Debug App，连接VM服务执行hot reload成功；连接后的运行时错误检查未发现错误。调试工具已detach，应用保留供用户使用。

原生复验示例（项目根目录）：

```bash
# Android（JAVA_HOME设置为可用JDK）
cd apps/flutter_forge/android
./gradlew :flutter_biometric:testDebugUnitTest :forge_notification_bridge:testDebugUnitTest
```

macOS原生测试可用xcrun swiftc编译各包Classes/插件.swift及test/native/main.swift，以当前Flutter SDK的 `bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.xcframework/macos-arm64_x86_64` 为 `-F` 和 `DYLD_FRAMEWORK_PATH`，链接 `-framework FlutterMacOS` 后执行。具体命令及摘要见本报告相邻 validation.txt。

## 真实验收（持续记录）

用户已在本会话授权并配合macOS真实验收。自动化不录入密码、不代替用户触摸传感器，不把系统受理当可见投递。

| 用例 | 观察与范围 |
|---|---|
| 本轮构建启动/能力 | 本机真实窗口正常显示；能力显示已录入指纹并支持凭据回退，三个新语义按钮可见 |
| 强生物识别成功 | 已真实返回authenticated，界面显示“本次由生物特征完成”；用户确认看到了系统提示并用了Touch ID |
| 用户取消 | 用户点击取消后真实返回userCancel / macos_error_-2，界面恢复可用 |
| 凭据回退成功/unknown | 用户确认使用系统密码完成，真实返回authenticated并显示“系统未披露本次认证方式（unknown）”；未读取或记录密码 |
| 认证中切换模块/再进入 | 发起认证后切换通知模块，用户确认认证框自动关闭；再进入认证页是新会话，未被旧结果覆盖 |
| 通知权限/投递/撤回 | 查询granted；投递返回ID 711981F5-15AB-4C9A-8359-9BFA88933643；按同ID撤回返回系统受理。用户未看到通知，usernoted日志明确该ID受display shared静默策略影响；可见横幅不标PASS，待非屏幕共享环境复验。首次请求错误及补修详见上文 |
| 主/分类窗口注册与关闭隔离 | 已通过“在新窗口打开”显示网络与平台分类窗口；未完成独立插件操作及关闭隔离验收。用户要求核心功能可用即可，不再继续扩大全局冒烟范围 |

360dp/1.5倍文字下，两模块主要按钮可见、可点击且无布局异常，新增2项widget行为回归通过；这不代表四端真实输入或读屏专项验收。

通知可见性系统证据见 [notification_system.log](plugin_maintenance_20261026/notification_system.log)，只保存本轮通知ID记录，没有修改系统专注/屏幕共享设置。

Android API29/30+的认证成功、凭据回退、取消、锁定和通知授权detach、真实BLE外设扫描/GATT、Windows构建/设备操作与Web浏览器交互仍待对应环境。原生JUnit/fake覆盖不替代这些设备验收。

## 待批准项与后续边界

- 用户最新收尾要求：保证核心功能可用，不再继续全局冒烟；相应未测项保留边界，不作为阻塞本轮技术维护交付的理由。
- 按钮语义修正已得到本会话明确批准，已实施；没有其他被暂停的核心能力变更。
- 不解除USB entryRestriction，不改变认证允许策略、默认流程、支持平台或删除实验入口。
- CI原生覆盖改进仅形成方案：以插件/调用方/manifest/lock路径触发macOS和Android宿主编译及原生回归，保留现有五阶段；明确Windows需对应runner。需用户另行显式授权packaging_change及人工验收后才改CI/门禁。
- 许可证由来源占位文件留下的问题须维护者在未来分发前明确；本次不捏造许可证，也不发布。
