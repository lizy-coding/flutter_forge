# NFC 识别学习首期方案

状态：访谈范围已确认；本文是待整体确认的实施方案，尚未实施、提交、派遣或完成真机验收。

## 已确认的体验与实物

首期面向 Android，目标是理解手机如何发现实体卡片。亮屏解锁、NFC 已开启时，从桌面碰卡，经系统分发或应用选择器打开 Forge 并进入 NFC 学习页。前台扫描作为教学入口和排查路径。发现卡片、展示系统提供的技术信息即算发现成功，无 NDEF 内容不算发现失败。

用户有 iQOO 手机及实体银行卡，其他方案采用访谈中的推荐。手机型号、Android/系统版本、实体卡是否支持非接触式通信尚未核实，真机阶段记录，不从品牌或“有芯片”推断 NFC 可用。用户所述银行卡已录入手机，只能作为钱包侧背景信息；本期测试仍使用实体卡靠近手机。

## 学习页与结果含义

页面提供简短原理说明、手机 NFC 能力与开关状态、开始/停止扫描、当前发现结果和再次扫描。教学内容复用 `shared/learning`；紧凑窗口适配触摸操作。模块标题建议“近场识别：认识 NFC 卡片发现”，稳定路由建议 `/nfc-learning`，模块状态先设 `pending`，与平台入口支持分别维护。

当前结果展示发现来源（系统碰卡分发或前台扫描）、技术类型列表，以及系统给出的可选射频标识。标识缺失或变化是允许的，不称为卡号或永久唯一 ID。若卡片提供 NDEF，可展示标准文本/URI及类型说明；没有、未读取或读取失败分别显示，保留已成功发现的技术信息。URI 仅展示，不自动跳转。

首期不实现银行卡业务协议或读取账户数据，不写卡、不复制卡、不模拟卡。结果只在当前模块会话中保留；教学说明只解释观测事实，不推断卡种、发卡行或支付能力。重复回调不重复打开页面，用户离开页面或应用转后台时停止前台扫描，迟到回调不更新已结束会话。

## Forge 分层

| 层级 | 拟落点 | 职责 |
| --- | --- | --- |
| 平台桥接包 | `packages/forge_nfc_bridge/` | 平台接口、永不抛出的能力查询、类型化结果、Android NFC 发现与 Intent 处理、fake 与通道契约测试 |
| 学习模块 | `apps/flutter_forge/lib/modules/platform/nfc_learning/` | 会话、扫描控制、发现结果、教学说明；不直接声明原生通道 |
| 应用壳 | `apps/flutter_forge/lib/app/` 中最小必要入口 | 消费桥接包给出的导航请求，进入稳定模块路由；不解析卡片协议 |
| 注册与契约 | `tool/generate_agent_indexes.js` 与 `tool/agent_indexes/` | 模块元数据、包依赖、路由、Android 能力适配规则与生成物 |

桥接包遵循 ADR 0019 的四件套，以 `FlutterPlugin` / `ActivityAware` 自注册并处理 Activity 绑定、已有启动 Intent 和后续新 Intent。读取和解析卡片的原生逻辑不进入宿主 `MainActivity`。NFC 权限、可选硬件声明及技术过滤资源优先随插件提供；最终由 App 的 merged manifest 验证分发目标和匹配结果。

冷启动需先保留首次发现的元数据，再在路由就绪后消费一次导航请求；不能依赖 Dart 订阅已存在。暖启动复用现有窗口与导航，前台读卡不重复发出导航请求。进入页面后需要再次通信时，明确提示用户重新靠卡，不假定首次碰卡连接仍然有效。

应用外分发按实际测试卡暴露的技术设置有限 `TECH_DISCOVERED` 过滤，核对 NDEF 优先级与已有应用匹配；不使用“任意标签”兜底承诺唤起。前台教学扫描使用 Reader Mode，绑定页面与 Activity 生命周期。银行卡是否提供 NDEF、能否唤起 Forge，均需分别观察。

Android 适配规则接入后，其他产品目标平台由共用规则推导为不可用，保留稳定路径并进入统一说明页。无 NFC 硬件、开关关闭等设备级差异由运行时能力结果呈现。

## Agent Hub 托管

本次按注册项目 `flutter-forge`、运行仓库 `flutter_forge` 对接。开工重新获取有界 `agent-context`，以 NFC 包、模块、导航入口、注册生成源和对应指南作为明确候选；既有维护快照中未包含的 NFC 目标不能视为已分析。当前观察基线为 `dev` 的 `3fc98c4`，不是未来派遣的冻结基线。

遵循 Hub ADR 0004，新工作通过 `dispatch-spec.v1` 声明，不向已冻结的 Forge decomposition 封板序列追加任务。建议以下逻辑顺序在一个完整、可验证的 MEDIUM 风险实施任务中完成，避免分拆后出现未注册 workspace 包或断开的路由。正式 spec 在整体方案确认、源码范围定位后生成；本文不是可执行 spec，也未调用 `dispatch-run --execute`。

1. 建立桥接包和 fake，补能力、结果及通道契约测试；实现 Android 前台发现。
2. 接入学习页、session 和教学模板，覆盖无 NDEF、无标识、重复回调及生命周期。
3. 补系统分发与冷/暖启动的导航衔接；更新生成源并生成正式契约。
4. 完成定向测试、根质量门禁、Android debug 构建，再用 iQOO 与实体卡分别做两项验收。

冻结写范围包含 NFC 包/模块/测试、必要 workspace manifests 与 lock、最小导航消费入口、生成源及其实际输出；不得放开整个 `app/`、整个仓库或宿主原生业务实现。不得改 CI 或质量门禁脚本语义，不包含发布与 Git 操作授权。当前 `release/1.2.10/` 是用户已有未跟踪内容，必须保留；派遣与集成前由 Hub 检查工作区和冻结 HEAD 条件，不擅自清理或提交以满足门禁。

Hub 当前验证命令标识支持 analyze、Flutter 测试及 Android debug 构建，不能直接把 `bash tool/quality_gate.sh` 当成已有 check_id。正式 spec 使用现有合法标识；根质量门禁仍按 Forge 规则单独完整执行、保留证据，不以单条 analyze 或 App 测试替代全 workspace、工具测试和生成物检查。

## 验收与证据

自动化至少覆盖能力缺失/关闭、类型化失败、空标识、技术列表、无 NDEF、可选 NDEF 解析失败、重复发现、停止/离页/后台/释放及迟到结果；还需模拟冷启动初始事件、路由就绪前事件、暖启动新 Intent 和一次性导航消费。通道与 fake 测试不等于真实射频验收。

生成后运行定向测试和 `bash tool/quality_gate.sh`，再从 App 目录构建 Android debug APK。调试构建/签名身份显式记录，成功构建不等于手机已识别。

真机记录手机型号、Android/系统版本、NFC 开关及应用 NFC 启动设置、App revision/build mode、脱敏卡片描述和操作结果，分别验收：

1. **前台发现**：打开 NFC 页开始扫描，将实体卡靠近手机；出现技术信息。移开再靠近、停止后再次扫描、切后台返回均可解释且不重复导航。
2. **应用外碰卡进入**：先正常启动过 App，再回桌面；亮屏解锁且允许 NFC 启动，靠同一张卡后，经系统分发/选择器进入 NFC 页并显示首次发现信息。分别记录进程未运行的冷启动与 App 已运行的暖启动。强行停止或首次安装未打开不作为普通冷启动；系统限制按实际版本说明。

如果前台能发现、应用外未进入，记录为“发现通过、唤起未通过”，沿系统分发与用户设置排查；不能改写为整体通过。如现有卡不能被 NFC 检测，先确认卡片的非接触式能力，必要时另选标准 NFC 标签；不要求为首期增加银行卡协议。

## 官方依据

- [Android NFC basics](https://developer.android.com/develop/connectivity/nfc/nfc)：亮屏解锁扫描、NDEF/TECH 分发优先级与选择器、版本相关启动限制。
- [NfcAdapter / Reader Mode](https://developer.android.com/reference/android/nfc/NfcAdapter)：前台 Reader Mode 与 NFC 能力。
- [Tag / getId](https://developer.android.com/reference/android/nfc/Tag#getId())：标识可随机或为空，不是银行卡业务身份。
- [IsoDep](https://developer.android.com/reference/android/nfc/tech/IsoDep)：ISO 14443-4 能力与上层协议的边界。
- [Android 卡模拟](https://developer.android.com/develop/connectivity/nfc/hce)：手机作为卡片的角色与读实体卡不同。
