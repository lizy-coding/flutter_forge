# Agent 生成源维护

执行入口保持为 `tool/generate_agent_indexes.js`。模块声明保留在入口文件中，以兼容现有校验器；生成物禁止直接修改。

| 修改内容 | 维护位置 |
|---|---|
| 模块元数据、路由、平台排除及依据 | `tool/generate_agent_indexes.js` 的 `modules` |
| 分类语义、内部包责任与入口 | `catalog.js` |
| 项目架构与变更策略 | `project.js` |
| 历史里程碑、计划与验收记录 | `plan.js` |
| Agent 契约输出 | `contracts.js` |
| Dart 模块清单与路由输出 | `routes.js` |
| manifest 事实读取、输入校验和写入 | `generator.js` |
| 简明支持声明输出 | `support.js` |
| 脚手架候选声明校验与预览 | `module_spec.js` |

分类成员、分类依赖和 Dart 导入从模块声明推导，不维护第二份模块列表。Git 依赖的 URL、ref 和 resolved-ref 来自应用 pubspec 与 workspace lock；不在文档模板重复固定版本。新增内部包时，应同时更新 workspace manifest 和 `catalog.js` 中的责任契约，否则生成会失败。

`generator.js` 只接受当前 manifest 使用的 block YAML 形式。遇到不支持的格式会报错；需要修改读取器及负向测试，不能静默忽略。所有输出完成渲染后才开始写入，并跳过内容相同的文件。这保证输入或渲染失败不会覆盖文件；不承诺磁盘写入失败时跨文件事务回滚。

在仓库根目录执行：

```bash
node --test tool/agent_indexes/generator.test.js
bash tool/generate_harness_ai_analysis.sh
node tool/generate_agent_indexes.js --check
bash tool/quality_gate.sh
```

`--check` 只比较当前工作区内容，不写文件，也不依赖 Git 提交或暂存状态。质量门禁通过它检查生成漂移，再执行契约校验；待提交改动只要与生成源一致即可通过这一阶段。

宿主目录存在只表示接入文件存在。日常维护使用入口支持范围、必要功能差异与限制依据；教学完成度独立表达，历史计划中的 evidence 保留原版本范围。默认生成不读取历史报告或测试结果，不计算源码指纹、不生成验收状态或人工用例；专项确认资料见 `docs/module_availability/archive/README.md`。CI 测试继续作为开发反馈。

模块脚手架使用同一份分类、能力策略与单模块契约渲染函数。默认仅预览，不读取全部模块源码或写入文件：

```bash
dart run tool/module_scaffold.dart --category popup_table --name candidate_lesson \
  --title '候选学习模块' --subtitle '待补充的学习练习'
```

`--apply` 在候选输出目录写入教学与测试骨架、正式生成器同源的 `AI_ANALYSIS.md`、`module_spec.json` 和可审阅的 `module_registration.js.txt`。候选状态始终为 `pending`；注册片段须显式评审后加入 `tool/generate_agent_indexes.js`，再执行完整生成和校验。脚手架不会自动修改模块清单或路由。

普通候选默认开放五个目标平台。`--depends file_picker_bridge` 按共用规则发现文件能力；配合 `--optional-capabilities file_selection` 将其表达为可选功能，而不关闭普通入口。候选依赖只是待实现意图，不证明能力代码或平台验收已经完成。产品级整体禁用使用 `--restriction-reason` 和 `--restriction-sources`，须提供仓库内已存在的依据；它关闭全部目标平台入口。旧 `--platforms` 与 `supportedPlatforms` 参数不再接受。

脚手架需要 Node.js 运行纯候选辅助函数；默认输出位置仍为 `build/module_scaffold/{name}`。`node --test tool/agent_indexes/module_spec.test.js` 可独立检查候选，既有 `generator.test.js` 入口也包含这些检查；`dart run tool/module_scaffold_test.dart` 验证预览、应用、参数错误、真实 Dart 解析与文字转义。
