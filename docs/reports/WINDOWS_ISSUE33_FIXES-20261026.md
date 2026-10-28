# Windows issue #33 修复与复验边界

对应反馈：[issue #33](https://github.com/lizy-coding/flutter_forge/issues/33)。本轮起点为 `dev` / `3fc98c422a0b391a82d1d5d3994bc41d34fc2a56`；以下为本地工作区修改，不代表已发布版本。验证主机是 macOS，Windows 原生构建、UIA 与真实读屏器验收仍待执行。

## 修改范围

| 反馈 | 本轮处理 | 验证边界 |
| --- | --- | --- |
| WIN-001 | Windows 子窗口先注册窗口定义通道，再进入其他插件回调；Dart 仅对 Windows 启动期 MissingPluginException 重试，最多 40 次、间隔 50ms，总查询另有 3s 超时；验证非空窗口 ID 与字符串参数，其余平台错误立即透出 | 原生注册顺序由源码核对；16 项窗口通道测试通过。原生竞态及窗口关闭、重用、重开仍需 Windows 主机复验 |
| WIN-002 | 约束布局、在线视频控制与 GenUI 数值控件共用 LearningSlider。Windows 使用无 OverlayPortal 的绘制实现，提供焦点、方向键、Home/End、轨道点击、滑块拖动和读屏增减；禁用与固定范围不暴露调节动作；其他平台继续使用 Material Slider | 当前 SDK 的 Material Slider 路由插入已复现孤立节点；修复后检查每帧新增节点从根可达、引用存在及被移除子树的删除，覆盖三处实际页面和 GenUI 回放生成。Windows UIA 和读屏器实际结果待复验 |
| TEST-001 | 当前 HEAD 已断言 PopupPage，保留现有正确实现 | 不重复修改，不以此推断原反馈版本路由损坏 |
| TOOL-001 | workspace 与嵌套 manifest/lock 读取兼容 CRLF；生成物比较忽略 CRLF/LF 差异，同时保留真实内容漂移检测 | CRLF fixture 验证 manifest、lock、workspace CLI 和只读生成检查 |
| TOOL-002 | 校验器统一文档键为 `/`，在解析项目路径前转换 Windows 分隔符 | 模拟 Windows relative/normalize 输出运行完整文档校验器 |
| TOOL-003 | scaffold JSON 及 Dart 字面量往返显式按 UTF-8 解码 stdout/stderr | 原有中文、引号、反斜杠和换行往返测试保留 |
| TEST-002 | 代理环境测试按不区分大小写的键验证用户代理优先级 | 保留系统代理不能覆盖用户配置的断言 |
| ENV-001 | Shell 入口通过 .gitattributes 固定 LF；release fixture 使用兼容旧 Git 的 init + symbolic-ref | Windows 主机仍需完整 Git Bash、项目契约要求的 Node 24 与 Flutter 工具链；本轮未修改本机安装或降低工具链要求 |
| ENV-002 | release fixture 的目录链接显式使用 junction，清理通过 unlinkSync 移除链接 | 保留拒绝链接输出目录的断言，不跳过该用例。Windows 文件系统行为待复验 |

## Windows 手工复验

1. 新检出或刷新 Shell 文件后确认 LF，使用完整 Git Bash 与 Node 24 执行 `bash tool/quality_gate.sh`；旧检出已有的 CRLF 文件不会因新增 attributes 自动重写。
2. 多次创建分类专注窗口，关闭后重开，同分类复用，主窗口关闭时联合退出；确认无 MissingPluginException、启动屏障超时或残留窗口。
3. 打开快速搜索，依次进入约束布局、在线视频与 GenUI；回放生成后确认 UIA 可找到当前页面及“解释当前结果”，日志无 AXTree 更新失败。
4. 用键盘、鼠标与 NVDA/Narrator 检查滑块的聚焦、数值、增减、禁用状态；核对 Windows 轨道与焦点外观。不要用 widget 测试替代真实读屏器结果。

## 本地验证

完整质量门禁 `bash tool/quality_gate.sh`：PASS。生成器输出 74 份文件、零漂移，69 份机器文档通过校验；只读格式与 bare Flutter analyze 均通过。workspace 750 项 Flutter/Dart 测试、32 项 Node 工具测试、17 项 Python 桥接测试及 scaffold 中文往返通过，35/35 模块具备测试。Windows 语义专项的 6 项测试包含在 app 的 512 项测试中，窗口通道 16 项包含在 workspace 总数中。门禁脚本和 CI 语义未作调整。

本机未发现运行中的调试 App；热重载尝试因无活动连接未能执行。上述结果来自本地源码、分析及自动测试，不包含 Windows 可执行文件构建或真实主机操作。

上游机制依据：[Flutter #190357](https://github.com/flutter/flutter/issues/190357)。本轮未修改 Flutter SDK；该控件适配应在未来 SDK 原生语义修复经相同回归测试和 Windows 主机复验后再评估移除。


## 后续测试组织

新增用例、平台分层、真实宿主专项和最新执行记录见 [平台自动化测试实施计划](../PLATFORM_AUTOMATION_TEST_PLAN.md)。上方 750 项记录保留为该轮验证快照；后续本地用例增加不自动代表 Windows 原生验收完成。
