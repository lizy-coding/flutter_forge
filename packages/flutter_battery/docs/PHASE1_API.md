# 第一阶段：电池读取与观察 API 收口

范围：Android/macOS 的电池读取、能力查询、独立观察。通知、BLE、peer 和 UI 使用独立入口，不属于核心 API；不声明已达到对外发布验收。

## 状态契约

| 状态 | 含义 | 值 |
| --- | --- | --- |
| pending | 会话等待首个样本 | 无 |
| available | 指定样本读取成功 | 完整的类型化快照；可选字段可以为空 |
| noBattery | 原生明确没有电池 | 无 |
| unknown | 存在电池，但指定样本无法判断 | 无 |
| unsupported | 接口/样本未实现 | 无 |
| permissionDenied | 所需权限不足 | 无 |
| unavailable | 原生适配器不可达或通道中断 | 无 |
| invalidData | 载荷或数值不符合契约 | 无 |
| timedOut | 操作未在限定时间内结束 | 无 |
| failed | 已知分类以外的原生操作失败 | 无 |
| closed | 观察会话已关闭 | 无 |

非成功状态由 reason 提供 code/message，不把无电池或正常关闭命名为 failure。运行故障返回类型化结果；调用者非法参数同步抛出 ArgumentError。不把缺失数据转换为零电量、未充电或健康正常；真实零测量保留。时间戳缺失保持空，不制造采样时间。

## API 与破坏性迁移

核心 FlutterBattery 仅暴露 capabilities、read(sample)、observe(options)。读取和打开操作返回 BatteryOutcome；观察只暴露类型化事件、当前结果、生命周期与 close。关闭幂等、有限等待且关闭后不回填。首个样本超过等待上限返回 timedOut；迟到有效数据可恢复。macOS 健康状态读取系统 IOPS 的明确报告，不按循环数或容量阈值推断健康好坏。

全局 callbacks/start/stop、原始 Map 流、业务阈值、优化建议、通知与 widgets 从核心入口移出。旧测试和示例明确转入 legacy 入口，不作为第一阶段对外契约；新 main 与 Forge 使用新入口。

native 方法 readBattery 使用 availability 字段，不靠 0/-1 推断“无电池”。观察协议同时携带设备可用性；健康未知与电池不存在分开处理。Dart 解码集中维护。

## 验收顺序

1. 状态解码与参数表：正常、真实零、缺字段、无电池、未知健康、越界、类型错误和时间戳错误。
2. 方法调用：不支持、权限拒绝、原生不可达、空响应、失败、超时以及重试恢复。
3. 会话：独立类型/间隔、关闭互不影响、关闭幂等、关闭失败、超时后的迟到打开清理、事件错误/中断、关闭后无数据回填。
4. 宿主：新示例与 Forge 迁移，静态分析、插件/模块测试、原生构建及 macOS 实际运行。
5. 发布阶段另补 Android 真机、无电池真实宿主、前后台与引擎重建、最低工具链和包发布验证；本阶段不以构建代替上述验收。

## 当前验证基线

预发布版本 0.1.0-dev.1；Flutter 3.47.2 / Dart 3.11.5。声明与 CI 固定在本次验证基线，不承诺旧工具链兼容。核心返回 reason 而非 failure：无电池、未知及关闭也是有原因的状态。通知/BLE/peer、最低 OS 的真实运行和对外发布均留待后续阶段。

## 第一阶段验收结果（当前工作区，未发布）

- PASS：插件静态分析零问题，74 项插件测试；其中新状态/生命周期矩阵 27 项，其余为底层与 legacy 回归。
- PASS：新核心示例与 legacy 隔离界面测试共 2 项；Forge 模块 3 项测试、原始全量门禁 6/6。
- PASS：Forge Android ARM64 Debug、macOS Debug 正常入口构建；macOS 类型化读取、双观察会话独立关闭及模块重复进入/退出。
- PENDING：Android 真机、真实无电池宿主、前后台/Activity/引擎重建矩阵、最低 OS 与跨设备测量单位验证、通知/BLE/peer 和正式发布。

以上 PASS 只覆盖本次代码与测试范围，不能用于宣称整个插件已达到对外发布状态。Forge 日常门禁仍按原仓库语义执行，插件全套测试在本阶段另行运行；后续 CI 接入需按宿主的 packaging_change 规则处理。

## 交付语义修订：采样与变化互斥、订阅可并行

新增 API 为 sample(BatterySamplingOptions) 与 watchChanges(BatteryChangeOptions)。一个会话仅有一种模式；两种模式分别拥有原生通道和生命周期，可以同时使用。采样保留同值样本；变化订阅使用 IOPS 系统通知或 Android 电池广播，不创建采样计时器。首条 delivery=initial 建立基线；后续分别标记 sample/change。level 仅比较电量与可用性；info 包含供电、充电、测量和容量；health 仅比较健康条件与可用性。时间戳及旧业务建议不是变化。observe 保留兼容；debounceLevel 已移除。
