# 模块可用性维护

入口开放表示允许进入教学流程。逻辑、编译、执行和界面验收均是独立标识，不参与目录或路由准入。

查看 [当前矩阵](matrix.md)、[机器记录](matrix.json) 和 [人工界面用例](acceptance-cases.md)。这些文件由现有生成流水线统一输出，禁止手改。历史 `REFACTOR_PLAN.md` 与报告仍保留其原始版本范围，不用于推断当前验收。

## 修改一次，生成全部

1. 在 `tool/generate_agent_indexes.js` 注册教学元数据与依赖，不再填写平台排除名单。
2. `tool/agent_indexes/availability.js` 从注册依赖和模块目录的 imports/exports 发现能力需求，按项目适配规则推导平台。规则包含理由代码与实现来源；依赖包宣传的平台清单不直接决定准入。
3. 能力为可选功能时填写 `optionalCapabilities`；需要产品级关闭整个入口时填写带理由和来源的 `entryRestriction`。3D 桌面操控和 Android 只读模式消费生成的功能策略。
4. 运行 `bash tool/generate_harness_ai_analysis.sh`。入口、功能策略、Agent 契约、维护矩阵和界面用例一起更新。

识别范围是注册模块及其明确目录，不进行全库猜测。未审阅的外部依赖列在 `unreviewed_dependencies` 中，保持默认入口策略；新增平台能力须补共用适配规则。规则仍需人判断，但判断只维护一处，多个模块自动复用。

## 自动记录逻辑、编译与执行

在仓库根目录执行；工具在主应用目录调用 Flutter。依赖需预先通过 `flutter pub get` 解析。

```bash
node tool/module_availability.js check --kind logic --module all
node tool/module_availability.js check --kind logic --module file_picker
node tool/module_availability.js check --kind compile --platform macOS
node tool/module_availability.js check --kind compile --platform android
node tool/module_availability.js check --kind compile --platform web
node tool/module_availability.js check --kind execution --module flutter_scene_3d --platform macOS --device macos --integration integration_test/flutter_scene_3d_flow_test.dart
```

逻辑检查执行模块测试目录；`--module all` 一次执行全部模块测试，按测试 suite 的实际路径分别归档各模块结果，共用一份日志。它证明测试逻辑在当前宿主通过，不证明五个平台的真实行为。编译记录属于完整应用，不能记录成任意单模块运行成功；原生构建为 Debug，Android 为 ARM64 Debug APK，使用现有 Debug 签名；Web 保留 `tool/build_web_release.sh` 的 Release 路径。执行检查必须关联指定模块的现有 integration test；跳过用例或没有实际完成用例不能记为 PASS。BLE 硬件流程默认跳过，因此仍需独立的硬件验收。

工具保存命令、退出码、测试完成/跳过数量、环境、Git 提交与 dirty 标识、来源指纹、日志和日志哈希。失败也保存记录；每次追加，不覆盖历史。没有执行记录显示 PENDING，来源变化显示 STALE；二者都不改变入口开放状态。

## 人工界面验收

`acceptance_cases.js` 维护通用布局及少量能力专属视觉预期，`visual_flows.js` 保存依据现有测试或实现编写的核心交互流程，平台范围从能力策略推导。生成器同步列出已发现的行为测试名称与文件，供审阅补充；动态测试名称可能未被提取。通用用例不等于完整业务视觉覆盖，遗漏的业务预期需要在此来源补充，不能从当前代码表现推断正确性。

按生成清单执行后，在仓库中保存报告、截图或录屏，使用相对路径登记。例如 macOS 文件选择器需完成入口、布局和真实提供器选择/取消三个用例：

```bash
node tool/module_availability.js record --kind ui --module file_picker --platform macOS --status pass --environment 'macOS，设备型号，Debug，窗口尺寸，文字缩放' --cases entry_navigation,layout_and_readability,file_provider_pick_cancel --evidence docs/reports/实际报告.md
```

只有完成该平台全部列出的用例，才能登记界面 PASS；失败可只记录失败的用例。PASS 的范围始终仅限清单，不承诺其他业务视觉表现。真实执行的人工证据也可用 `record --kind execution` 登记，必须提供环境与实际证据。不得把旧报告用当前时间重新登记为当前验收。

## 指纹与历史

逻辑指纹覆盖目标模块源码与测试、共享能力、内部包 Dart 源码、能力及应用策略生成源、采集器、依赖 manifest/lock。编译、执行和界面记录另覆盖全部已注册模块、应用壳、集成用例、资源和对应宿主实现。界面记录额外覆盖视觉用例来源；单独修改视觉预期不会令逻辑或编译记录过期。生成的 Agent 文档、维护矩阵、证据本身不进入指纹，避免生成导致自我失效。

这是保守的失效策略：共享实现或用例变化可能让多个模块记录过期。证据文件不存在、被修改或逃逸仓库时生成失败，不能静默丢失证据。证据记录应与所引用的日志、报告、媒体一起保留。

定向工具测试：`node --test tool/agent_indexes/generator.test.js tool/agent_indexes/availability.test.js`。完整质量门禁仍使用原有 `bash tool/quality_gate.sh`。
