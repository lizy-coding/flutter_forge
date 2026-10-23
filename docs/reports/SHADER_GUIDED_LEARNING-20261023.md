# Shader 分步学习改造（2026-10-23）

## 范围与学习目标

本记录对应 dev 工作区（基线 HEAD b501f21）的未提交实现。工作区包含其他并行改动；门禁结果是本次运行时整个工作区的结果，不是发布版本验收。

用户确认的基础条件是看懂说明、完成操作；进阶目标是理解适用场景并能调优方案，不强制独立写题。首期只实现渐变与卡片扫光；图片变色、波纹保留后续说明。

## 已实现

- 绘制入门第三步增加进入真实 Shader 的链接；真实 Shader 课程提供返回基础课入口。沿用既有稳定路由，不直接导入其他模块代码。
- 六步：纯色 → 与前课一致的左半蓝规则 → 横向渐变 → 纵向渐变 → 偏移 → 卡片扫光。每步有预测提示、可直接展开的解释、复位和前后切换。
- 点击、拖动或选择固定 U，展示 UV、规则计算、混合比例与 RGBA；CPU 解释只计算选中位置，整个画面由真正的片元 Shader 绘制。
- Dart 思路与 GLSL 对照。高亮行来自实际运行的 GLSL 文件，完整源码折叠显示，避免另存一套示意 GLSL。
- 扫光使用同一 Shader 的距离与 smoothstep 规则，提供位置、半宽、柔和度、扫过秒数和两组静态预设；文字保持普通 Flutter Widget。
- 默认暂停；显式播放；切换步骤、路由覆盖、后台、预览滚出窗口时停止。减少动态效果时只允许手动定位。
- 说明标准渐变、Canvas、自定义 Shader 的场景选择；区分视觉参数调整与性能测量。本示例不报告 GPU 时间或性能提升。
- 在生成源更新课程介绍、概念、时长与 go_router 依赖，运行完整生成器同步机器契约。

## 验证

- `flutter test --no-pub test/modules/ui/shader_playground test/modules/basic/pixel_shader_intro`：23 项通过。
- Shader 输出测试直接读取编译后绘制结果，覆盖纯色、半蓝、渐变、UV、扫光、不同位置和柔和度，并与选点解释核对；保留预乘 alpha 输出检查。
- Widget 覆盖解释展开、逐步参数切换、复位、UV 禁用控件、动画显式启动、后台暂停、减少动态效果、课程互跳、异步加载失败/晚完成释放和 360dp 大字滚动布局。
- 最终 `bash tool/quality_gate.sh`：退出码 0，全部五阶段通过。含 bare Flutter analyze 无 issue、全工作区与工具测试、33/33 模块测试存在性检查。原始记录见 [quality_gate.log](../evidence/shader_guided_learning/quality_gate.log)。
- macOS Debug 已执行热重载和热重启；真实窗口确认纯色、左半蓝及卡片扫光静态渲染。截图：[半蓝规则](../evidence/shader_guided_learning/02_split_macos.png)、[卡片扫光](../evidence/shader_guided_learning/06_sweep_macos.png)。最终读取 Dart runtime errors 为无错误。

## 限制与人工复核

变更 uniform 布局后首次热重载仍复用了旧的 Shader 编译布局，出现索引越界。修改入口 Shader 触发编译并重启后真实窗口绘制恢复。开发中修改被 include 的 GLSL 后，应同时确认入口 Shader 已重新编译。

macOS 后半段原生 UI 自动化出现 AXError.failure 与辅助功能树内容缺失；截图仍能获取且显示正常。不能从此次静态截图与 widget 测试推定辅助功能或完整鼠标连续动画验收通过。未进行 Windows、Web、Android 或 iOS 的真实主机/真机验收，也未进行 Profile 性能对照。

建议人工复核：从入门课进入真实 Shader；依次查看六步解释并点选左右与中点；暂停比较两种扫光预设；调节单个参数；播放/暂停；滚出预览和切换页面后确认停止；开启减少动态效果确认只可手动定位。

## 技术依据

- [Flutter 片元 Shader 官方说明](https://docs.flutter.dev/ui/design/graphics/fragment-shaders)：Canvas 使用方式、uniform、资源与性能注意事项。
- [Flutter 性能分析官方说明](https://docs.flutter.dev/perf/ui-performance)：Profile 模式与目标设备的性能验证边界。
