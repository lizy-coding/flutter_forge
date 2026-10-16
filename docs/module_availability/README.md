# 模块支持维护

日常维护仅查看 [支持摘要](matrix.md) 和 [机器声明](matrix.json)：模块入口支持的平台、必要功能差异和限制依据。支持声明是项目提供学习入口与功能范围的维护承诺；模块学习完成度独立保留，设备权限和运行结果由页面反馈。

## 修改一次，生成全部

1. 在 `tool/generate_agent_indexes.js` 注册模块元数据与依赖。
2. 共用能力规则维护在 `tool/agent_indexes/availability.js`，从模块依赖和 imports/exports 推导入口与功能策略；不重复手填逐模块平台名单。
3. 可选功能使用 `optionalCapabilities`；产品级整体关闭使用带理由和实现来源的 `entryRestriction`。
4. 执行 `bash tool/generate_harness_ai_analysis.sh`。应用策略、Agent 契约和简明支持声明一同生成，禁止手改生成物。

普通模块默认开放五个目标平台。平台模型包含 iOS，但当前尚无 iOS 应用宿主；宿主目录、安装包与真实设备操作分别描述，不由入口声明推定。

```bash
node tool/module_availability.js list
node tool/module_availability.js list --module flutter_scene_3d
node tool/module_availability.js generate
```

`list` 只读查看支持声明；`generate` 显式执行完整生成。旧 `check` 和 `record` 指令已停用。

## 开发反馈与历史资料

测试结果、源码指纹和历史验收状态不进入日常维护摘要；默认生成不读取证据记录、日志、测试结果或人工用例，不维护 PASS/PENDING/STALE 矩阵。

CI 测试执行保持现有流程，用于修改时发现回归。专项确认按实际需要直接运行对应测试或构建，例如在 `apps/flutter_forge` 执行 `flutter test test/shared/multi_window_manager_test.dart --no-pub`；需要说明操作范围时保存独立报告，不再登记长期模块状态。

[历史用例、视觉流程及报告](archive/README.md) 保留原始版本、环境和引用范围。归档不表示重新验收，也不影响生成或路由准入。

定向工具验证仍使用 `node --test tool/agent_indexes/generator.test.js tool/agent_indexes/availability.test.js`；完整质量门禁仍为 `bash tool/quality_gate.sh`。
