# 绘制入门交付与冷启动复核

2026-10-12，`dev / b90d5971a8af6de4a6eaedf979344a9e53ef0cac` 加未提交工作区。

已在「基础机制」新增「绘制入门：从画形状到算颜色」，路由 `/pixel-shader-intro`。只实现第一模块，用同一个蓝色矩形分三步讲解：画形状、按位置算颜色、比较固定坐标与 UV 比例。保留此前 Shader 模块，后续课程尚未实现。

定向测试 11 项、完整质量门禁、macOS Debug 构建均 PASS。实现与原始截图范围见 [首期验证记录](README.md)，最终门禁见 [日志](quality-gate.log)。

## 本机日志补充

先前多次热重启的调试会话出现了 Flutter 宿主辅助功能桥接日志：

```text
[ERROR:flutter/shell/platform/common/accessibility_bridge.cc(114)]
Failed to update ui::AXTree, error: 106 will not be in the tree and is not the new root
```

Dart VM 的运行时错误检查为空，不覆盖这类宿主日志。没有确认该报错的根因，也没有将其归因为课程代码或 SDK 缺陷。

关闭测试窗口后，以 `flutter run -d macos --no-pub` 全新启动，未进行热重载/热重启。调整到宽窗口，再从基础机制目录进入课程，完成三步切换、宽 400、固定/比例规则比较、位置预设、重新学习、返回目录及再次进入。

- 固定规则下选中 x=100 输出白色，蓝色区域宽 100。
- 切换比例规则后，同一位置 U=0.25 输出蓝色，蓝色区域宽 200。
- 重新学习回到第一步开头，退出重进也从第一步开始。
- 此次冷启动日志中 AXTree/引擎异常行数为 0；连接期间 Dart 运行时错误检查为空。

冷启动流程实际执行冒烟 PASS。该结果不证明热重启问题已经修复；热重启辅助功能稳定性及完整人工 UI 验收仍为 PENDING。其他平台当前工作区的构建、运行和界面验收未执行。

证据：[冷启动截图](macos-cold-start-uv.png)、[本机日志摘要](cold-start-log-summary.txt)。平台证据仍由 `tool/module_availability.js` 登记，本页不替代生成矩阵。
