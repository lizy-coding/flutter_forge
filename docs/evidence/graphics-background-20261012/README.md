# 图形绘制技术背景模块

2026-10-12，`dev / b90d5971a8af6de4a6eaedf979344a9e53ef0cac` 加本次未提交工作区。本记录不是发布版本验收；已有绘制入门与 Shader 模块实现均保留。

## 学习入口与内容

基础机制新增「图形绘制背景：认识 GPU、纹理与 Shader」，稳定路径 `/graphics-background`。以显示一张照片为背景，用四块颜色组成的示意图片说明取色位置。

每节先说明问题、名词含义与职责联系，再展示示意图，最后给出一句小结：

1. 像素、显示范围与 Canvas 绘制接口。
2. GPU 执行硬件、纹理输入数据与 Flutter 渲染引擎。
3. UV 取色位置，与画布显示位置的区别；本课的坐标方向约定。
4. Shader 程序、片元输出颜色，以及纹理取色和颜色处理的关系。

UV 节支持选择四个色块中心与放大显示，Shader 节支持灰度输出规则。源图保持彩色，输出色块只代表选中位置的结果。演示使用 Canvas 与 Dart 计算，不执行自定义 GPU Shader，不代表 GPU 性能或真实纹理采样验收。

最后通过稳定路由进入 `/pixel-shader-intro`，返回保留背景课程阅读进度。没有模块间实现依赖，没有新增包或资源下载。

技术背景参考 [Flutter 架构说明](https://docs.flutter.dev/resources/architectural-overview) 与 [Flutter 片元着色器说明](https://docs.flutter.dev/ui/design/graphics/fragment-shaders)。本系列重点为片元着色器，正文说明其与一般图形管线中顶点着色器的区别。

## 自动验证

- 定向测试 PASS：7 项，无跳过。覆盖分节内容与控件准入、UV 位置/颜色、显示大小变化、灰度计算及源图不变、复位与返回章节开头、360×800/800×600 的 1.6 倍文字缩放、基础分类与课程衔接。
- 完整质量门禁 PASS：[日志](quality-gate.log)。生成物、格式、bare analyze、workspace/工具测试、30 个模块测试存在性全部通过。
- macOS 完整应用 Debug 构建 PASS，通过 `tool/module_availability.js check --kind compile --platform macOS` 登记。

## macOS 实际执行冒烟

环境：macOS arm64、Flutter 3.47.2、Debug，Impeller MetalSDF。本轮启动后执行一次热重启，再检查课程。

| 操作 | 观察 | 截图 |
| --- | --- | --- |
| 进入课程 | 第一节先解释像素、显示范围与 Canvas，示意图片不开放取色操作 | [概览](macos-overview.png) |
| 下一节 | 明确 GPU 是处理器、纹理是图像数据、Flutter 引擎衔接绘制工作 | [GPU 与纹理](macos-gpu-texture.png) |
| 选择右下并放大 | UV 保持 (0.75,0.75)，取色和输出仍为黄色 | [UV 取色](macos-uv.png) |
| 选择蓝色并灰度输出 | UV 为 (0.25,0.75)，输入仍为蓝色，输出灰度 29/255；原始四块颜色不变 | [颜色规则](macos-shader-rule.png) |
| 继续学习、返回 | 正常进入绘制入门第一步；返回背景课程第四节，保留取色与灰度状态 | 实际操作与定向测试 |
| 重新学习 | 恢复第一节并回到章节开头 | 实际操作与定向测试 |

本轮 Dart 运行时错误检查为空，宿主日志中的 AXTree/引擎异常行数为 0，见 [日志摘要](runtime-summary.txt)。窗口检查曾因同一应用的旧测试实例超时；核实并关闭上轮由 Agent 启动的旧实例后，当前实例完成检查。

实际执行冒烟 PASS。完整人工 UI、辅助功能稳定性以及其他平台的当前工作区构建、执行与 UI 验收仍为 PENDING；窄屏和大字体目前仅有 widget 测试。此前课程记录中的热重启辅助功能问题不因本轮日志为空而自动视为已修复。

平台入口和验证标识独立；统一证据记录、平台矩阵和验收用例继续由项目工具与生成器维护。
