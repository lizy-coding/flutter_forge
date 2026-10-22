# 四端交互实现与 macOS 验收

日期：2026-10-21。**更正：本报告原先的整体鼠标交互 PASS 结论撤回。** 用户随后报告普通鼠标点击失效，复核确认辅助功能触发／Flutter 测试点击绕过了存在问题的原生输入链路。本文保留前轮构建、自动化和辅助功能操作记录，不作为普通鼠标可用性证明；后续修复与真实坐标点击结果见 [鼠标输入修复记录](MACOS_POINTER_INPUT_FIX-20261021.md)。Windows 与 Android 实机验证未执行，Web 完成 Release 构建和 Chrome 自动化验证，不能据此扩大为四端真实设备验收。

## 来源与产物

- 基础 HEAD：`eb500f555b9ce930959d05dfbb09f820985b4c65`，`dev`；本报告针对该 HEAD 加本轮未提交工作区修改，不代表已发布 tag。
- 当前设备：Apple M5，macOS 26.7.1（25G241）；实际运行 arm64。Release 产物同时包含 arm64／x86_64，未声称完成 Intel Mac 运行验收。
- 工具链：Flutter 3.47.2，Framework `d3b14c8769`，Dart 3.13.2。
- 应用：`1.2.9+3`，`com.flutterforge.preview`；未修改版本、签名或发布配置。
- Release：`apps/flutter_forge/build/macos/Build/Products/Release/Flutter Forge.app`，构建约 66.9 MB。
- 原生可执行文件 SHA-256：`fbcca45904f13e227cacb234a003772418dbc1a8bb5a18339cb1cd63abc355c6`。
- `Contents/Frameworks/App.framework/Versions/A/App`（Dart AOT）SHA-256：`8f0730181498acee9e7d3903c858effcd8744c8b0e83026c95a22795fd3fb3af`。
- 原 `pubspec.lock` SHA-256：`2c5a8055a3e1a8bd52ad83595e47ad3351ae118ffd68c9f6550cab0e7e9abd30`。本机镜像曾触发无关重解析，已恢复并用 `PUB_HOSTED_URL=https://pub.dev flutter pub get --enforce-lockfile` 同步；最终未引入依赖升级。
- 修改涉及的生产代码指纹见 [source_sha256.txt](../evidence/interaction_20261021/source_sha256.txt)，包含新增文件；其余未改动源码以基础 HEAD 为准。

## 实现与插件选择

按 ADR 0018 接入基础导航页原生材质、教学实色正文／实验区／侧栏、最低强度标题栏和可关闭的材质外观。实色偏好、明暗偏好与高对比度优先，窗口材质缺失时不使用假透明冒充原生效果。浮层使用高不透明度底色，避免底层正文透入搜索结果。

候选 flutter_acrylic 的 macOS 依赖 macos_window_utils 1.9.1 使用静态 `MainFlutterWindowManipulator.mainFlutterWindow`；初始化会重置主窗口并可能包装内容控制器，不能直接满足当前每引擎分类窗口绑定。因此沿用现有 DesktopWindowHost 的方法通道与每窗口生命周期，新增 NSVisualEffectView／公开 DWM Mica 窄适配，未安装新依赖。Windows 公开 system-backdrop 接口仅在可用且成功时启用，Windows 11 早期版本和 Windows 10 均可实色降级。

源码核查的包归档为 [macos_window_utils 1.9.1](https://pub.dev/api/archives/macos_window_utils-1.9.1.tar.gz)，SHA-256 为 `cb918e1ff0b31fdaa5cd8631eded7c24bd72e1025cf1f95c819e483f0057c652`；关键文件位于 `macos/macos_window_utils/Sources/macos_window_utils/{MacOSWindowUtilsPlugin,MainFlutterWindowManipulator}.swift`。

Web／移动首页调整为搜索、分类、最近访问，作者资料迁入关于。四端共用标题、简介、分类、概念匹配；会话保存检索词和目录滚动位置，最近访问持久保存模块入口。Web 的 imperative 路由同步 URL，新标签页保留当前站点部署路径并使用现有 hash 路由。教学内容复用，未重写模块内部实验。

## macOS 实际操作

以下检查在本机真实窗口中执行，包含最终 Release。两次外观切换均恢复了原有 `light + liquidGlass` 偏好；未更改系统辅助功能设置。

| 检查 | 结果 | 证据范围 |
|---|---|---|
| 基础页系统材质 | PASS | 原生通道报告 materialActive=true、transparencyAllowed=true；目视检查工作台与分类页 |
| 教学实色隔离 | PASS | 主窗口与分类窗口进入三棵树模块，正文、侧栏实色，标题栏保留低强度层次 |
| 原生材质／实色、浅色／深色切换 | PASS | Release 菜单实际切换，页面保持，偏好恢复 |
| 快速打开与概念检索 | PASS | 输入 RenderObject，Enter 打开；返回恢复原检索词与结果 |
| Cmd+K、Cmd+F | PASS | 系统菜单发送到当前窗口；Cmd+K 在主窗口和分类窗口均实际验证 |
| 全屏按钮／F11 | PASS | 独立按钮进入真实全屏，F11 返回窗口模式；原生集成用例检查真实 fullscreen 状态 |
| 原生缩放 | PASS | 原生 zoom 动作扩大／还原，独立全屏入口仍显示“进入全屏”，未改写最大化语义 |
| 最小化／恢复 | PASS | 点击原生最小化，系统 Window 菜单恢复，内容正常 |
| 分类窗口创建／复用 | PASS | 同分类再次打开仍只有一个分类窗口，原教学页保持；不显示其他分类 |
| 分类窗口关闭／重开 | PASS | 关闭后主窗口正常；重开回到新的分类根页 |
| 主窗口关闭 | PASS | 分类窗口存在时点击主窗口关闭，应用整体退出，窗口库存均为未运行 |
| 运行时异常 | PASS（观察范围） | Debug VM 检查无运行时错误；原生集成用例无 Flutter 异常。不代表所有模块均遍历 |

复查过程中发现并修复了快速打开浮层透字，以及最小化恢复后 Flutter 焦点可能影响 Cmd+K 的问题；后者通过现有原生导航菜单提供等价命令，不接管系统窗口按钮。

分类窗口的 Flutter 可访问树未完整暴露给当前自动化环境，其菜单、键盘流程和原生关闭操作已实际执行并截图；本报告不声明完成读屏专项或分类窗口逐控件辅助功能验收。系统关闭透明、增加对比度分支有自动化覆盖，未将其写成系统设置实测结果。

## 自动化与构建

- `PUB_HOSTED_URL=https://pub.dev bash tool/quality_gate.sh`：全部五阶段通过，包括生成物无漂移、格式、bare analyze、workspace／工具测试及 30 个模块测试存在性检查。
- 相关原生 widget 测试：34 项通过；包含搜索恢复、目录路由替换后的滚动恢复、材质不可用与高对比度降级、窗口和主题生命周期。
- `flutter test --no-pub --platform chrome test/shared/platform_interaction_test.dart test/shared/responsive_navigation_layout_test.dart`：13 项通过；包含 320dp 首页、搜索与返回、浏览器中无原生多窗口入口。
- `flutter test --no-pub integration_test/desktop_material_acceptance_test.dart -d macos`：1 项真实宿主集成测试通过；原生状态、教学切换、外观、搜索返回、全屏往返均有断言。
- `flutter build macos --release --no-pub`：通过；最终 Cmd+K 原生补丁重新构建并实际验证。
- `PUB_HOSTED_URL=https://pub.dev bash tool/build_web_release.sh`：通过；本地 CanvasKit、loading shell、受控媒体校验通过。
- 最终 Debug 构建连接 VM 后执行 hot reload 成功，运行时错误检查返回无错误。

原生集成原始输出见本地 [macos_integration.log](../evidence/interaction_20261021/macos_integration.log)；日志按仓库 `*.log` 规则忽略，永久可重跑入口为 `apps/flutter_forge/integration_test/desktop_material_acceptance_test.dart`。构建保留已有 CocoaPods、Swift 弃用及图标字体提示，未修改门禁或编译脚本来隐藏它们；以最终退出码、构建产物和测试汇总判定结果。

## 截图

- [工作台](../evidence/interaction_20261021/macos_workbench.png)
- [概念搜索](../evidence/interaction_20261021/macos_search.png)
- [主窗口实色教学](../evidence/interaction_20261021/macos_teaching_solid.png)
- [分类专注窗口](../evidence/interaction_20261021/macos_category_window.png)
- [分类窗口实色教学](../evidence/interaction_20261021/macos_category_teaching.png)
- [深色材质](../evidence/interaction_20261021/macos_dark.png)
- [关闭材质后的实色外观](../evidence/interaction_20261021/macos_solid_fallback.png)

## 后续平台边界

Windows 已有公开 Mica 接口和降级实现，但未在 Windows 主机编译或操作；Snap、DPI、Mica 与系统透明开关实际行为仍需该主机确认。Android 本轮完成共享实现与紧凑布局自动化，未执行新的 APK 构建或真机操作。Web 完成 Release 和本机 Chrome widget 测试，Safari／Edge 的本轮人工流程与正式部署子路径验证未执行。iOS 仍未新增宿主。

本轮不提交、不推送、不发布；应用运行、构建与各平台实际验收结论分别保留。
