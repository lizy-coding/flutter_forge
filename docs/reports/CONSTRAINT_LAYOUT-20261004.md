# 约束与声明式布局示例

- 分类：基础机制；入口：`/constraint-layout`；学习时长：25 分钟。
- 页面沿用 `LearningScaffold`，包含交互实验、学习目标、概念标签、当前代码、常见误区和练习。
- 实验一：调整父容器宽度与子组件期望尺寸，切换松/紧约束，观察实际布局尺寸。父容器初始高度为 160dp，可通过手柄或滑杆调整至 80～240dp。
- 实验二：同一组 A/B/C 数据切换 Row + Expanded、Column 与 Wrap，缩小父容器观察空间分配和自动换行。
- 重置按钮恢复所有参数；代码片段随约束模式、期望尺寸和布局模式更新。
- Widget Preview 提供 320dp 与 1000dp 配置。

## 验证结果

| 检查 | 结果 |
|---|---|
| 模块定向测试 | PASS，11 项；含连续拖动、拖动边界与取消、Wrap 换行、动画中间帧及减少动态效果、约束限制、滑杆、重置、320/600/1200dp 与 1.5 倍文字 |
| Agent 契约 | PASS，生成校验 48 份文档，`--check` 无漂移 |
| 生成器测试 | PASS，9 项 |
| bare `flutter analyze` | PASS，无 issue |
| Dart 格式 | 本轮格式器扫描 294 个文件，0 改动 |
| 全量测试复核 | PASS，应用 215 项、file_picker_bridge 8 项、flutter_ioc_core 22 项 |
| 测试布局 | PASS；脚本另报告既有 BLE 测试命名提示 |
| FlutterGuard | PASS，无 HIGH |
| 完整 `quality_gate.sh` | FAIL；文档与格式阶段使用 `git diff --exit-code`，当前未提交的新增内容及既有改动导致失败；本轮其余四阶段均通过 |

本次未修改门禁脚本、未暂存或提交代码。运行门禁前后逐文件比较确认：目标模块以外的既有 Dart 文件内容未改变。

## 截图检查

以下为 macOS 上 Flutter widget test 渲染截图，使用系统字体，分别检查松/紧约束的尺寸反馈、控制项排列和教学内容。截图证明指定视口下的 Widget 渲染，不代表浏览器、真机或桌面应用完整运行验收。

- [320dp 松约束](../../apps/flutter_forge/docs/screenshots/constraint_layout/loose-320dp.png)
- [320dp 紧约束](../../apps/flutter_forge/docs/screenshots/constraint_layout/tight-320dp.png)
- [1000dp 松约束](../../apps/flutter_forge/docs/screenshots/constraint_layout/loose-1000dp.png)
- [1000dp 紧约束](../../apps/flutter_forge/docs/screenshots/constraint_layout/tight-1000dp.png)

紧约束截图滚动到约束模式控件，以展示实际尺寸与动态代码；初始松约束截图显示父宽及期望尺寸滑杆。截图检查未见布局溢出，代码区支持换行。

## 父子边界凸显更新

- 父容器采用橙色描边与浅橙底色，表示约束范围；子组件采用蓝色描边与浅蓝底色，表示实际布局尺寸。图例同时使用文字说明。
- 松约束下浅橙区域直观表示剩余空间；紧约束下父子边界重合，通过外侧橙线、内侧蓝线同时呈现。边线不参与约束或尺寸计算。
- Row、Column、Wrap 的整体范围与 A/B/C 子组件沿用相同边线语义；深色主题使用更亮的边线颜色。
- 四张截图已更新，320dp 松/紧约束与桌面图已检查。7 项模块测试通过，原尺寸断言仍通过。
- 本轮完整门禁：静态分析、全量测试（211/8/22）、测试布局、FlutterGuard 均 PASS；文档与格式 diff 检查仍 FAIL（工作区未提交差异）。并行的平台策略生成改动中，`module_platform_policies.dart` 被格式器改写后与生成源存在格式差异；结束前重新运行生成流程，使 `--check` 恢复 PASS，未修改该生成器实现。

## 手工验收步骤

1. 从基础机制进入“约束与声明式布局”。
2. 在松约束下将期望宽度调到 360dp、高度调到 200dp，再缩小父容器；确认实际尺寸不超过约束上限。
3. 将期望尺寸调小，切换紧约束；确认实际尺寸等于父容器尺寸。
4. 切换 Row、Column、Wrap，确认 A/B/C 数据保持一致、位置改变，Wrap 在宽度不足时换行。
5. 点击重置，确认松约束、父宽 100%、期望尺寸 120×80dp 和 Row 均恢复。

## 手动拖拽约束与动效更新

- 上方父框右下角橙色手柄直接调整父宽与父高；父宽限制为可用宽度的 40%～100%，父高限制为 80～240dp。鼠标显示缩放光标，触摸使用同一拖拽手势。
- 拖动期间实时传递真实 BoxConstraints，蓝色子框和读数同步更新。松约束保留期望尺寸或限制到上限，紧约束跟随父框。操作区域保持 260dp 高，减少拖动时内容流动带来的跳动。
- 下方横向手柄共享父宽状态，显示当前父宽。Row 均分、Column 纵向排列、Wrap 自动换行均由实际 Widget 布局产生。
- 布局切换使用 250ms 尺寸过渡与淡入淡出；手动拖动期间即时布局。系统减少动态效果时直接呈现目标布局。
- 重置恢复父高 160dp 及原有参数；滑杆仍可操作，供精确调整和非拖拽输入使用。
- 本轮定向测试 11 项 PASS；bare analyze、全量测试（215/8/22）、测试布局、FlutterGuard PASS。生成 `--check` PASS。完整门禁仍因未提交的文档/Dart diff 返回失败。

[拖动过程动图](../../apps/flutter_forge/docs/screenshots/constraint_layout/drag-320dp.gif)由 widget test 连续手势的 12 帧截图组成；不是实际设备运行录像。

- [320dp 拖动中](../../apps/flutter_forge/docs/screenshots/constraint_layout/dragged-320dp.png)
- [1000dp 拖动中](../../apps/flutter_forge/docs/screenshots/constraint_layout/dragged-1000dp.png)

验收时先设置子组件期望尺寸为 360×200dp，再拖动上方手柄缩小父框；分别观察松约束的尺寸上限和紧约束的跟随效果。随后选择 Wrap，拖动下方横向手柄观察换行临界点。取消手势或松开后应停止更新，再通过重置恢复初始值。
