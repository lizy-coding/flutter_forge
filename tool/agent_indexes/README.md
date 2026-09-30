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

分类成员、分类依赖和 Dart 导入从模块声明推导，不维护第二份模块列表。Git 依赖的 URL、ref 和 resolved-ref 来自应用 pubspec 与 workspace lock；不在文档模板重复固定版本。新增内部包时，应同时更新 workspace manifest 和 `catalog.js` 中的责任契约，否则生成会失败。

`generator.js` 只接受当前 manifest 使用的 block YAML 形式。遇到不支持的格式会报错；需要修改读取器及负向测试，不能静默忽略。所有输出完成渲染后才开始写入，并跳过内容相同的文件。这保证输入或渲染失败不会覆盖文件；不承诺磁盘写入失败时跨文件事务回滚。

在仓库根目录执行：

```bash
node --test tool/agent_indexes/generator.test.js
bash tool/generate_harness_ai_analysis.sh
node tool/generate_agent_indexes.js --check
bash tool/quality_gate.sh
```

`--check` 只比较内容，不写文件，也不依赖 Git 提交状态。质量门禁中的 Git diff 检查仍要求生成物和 Dart 改动已进入提交基线；工作树有待提交变化时，该阶段会失败，即使只读检查没有漂移。

宿主目录存在只表示接入文件存在。模块入口开放、教学质量状态、构建结果和平台验收分别表达；历史计划中的 evidence 不代表当前 revision 已通过验收。
