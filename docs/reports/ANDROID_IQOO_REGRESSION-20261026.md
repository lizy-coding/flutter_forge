# iQOO Android 抽屉与模块回归（2026-10-26）

范围：当前未提交工作区，基线 HEAD `3fc98c422a0b391a82d1d5d3994bc41d34fc2a56`。
这是单台 Android 真机 Debug 验证，不代表发布版本或其他平台验收。

## 问题与修改

原抽屉测试在全页面查找“探索与查阅”并要求唯一，但首页标题与抽屉入口均使用该文案。
失败发生在点击分类前，不能据此判定分类导航损坏。

`integration_test/app_test.dart` 改为限定 `NavigationDrawer` 范围并使用已有目的地 Key，
验证全部六个分类、重复点击当前分类、抽屉关闭、路由与页面一致、返回首页。
另通过 `handlePopRoute` 验证框架收到系统返回时关闭抽屉且保留分类。
没有为通过测试删除文案、放宽唯一性断言或跳过 Android 用例。

最终门禁还发现并行新增的 `learning_slider_test.dart` 缺少 `foundation.dart` 导入；
本轮仅补该导入，保留滑块实现及其他并行改动。

## 设备与结果

- USB 设备：iQOO / vivo V2338A（PD2338），Android 16，屏幕 1260×2800。
- `flutter test integration_test/app_test.dart -d 10AE1404SR000TC --no-pub --reporter expanded`：PASS，3 个测试；31 个可用模块逐个进入/返回、弹窗与表格子路由、扩展后的抽屉导航全部通过。
- `flutter test integration_test/battery_monitor_flow_test.dart -d 10AE1404SR000TC --no-pub --reporter expanded`：PASS，1 个测试；原生读取、独立采样和监听、启停与释放通过。读数为 `available`，电量 95%，外部供电、充满。
- `bash tool/quality_gate.sh`：PASS，生成物无漂移、格式、bare analyze、workspace 全量与工具测试、模块测试存在性全部通过。
- 普通应用入口 `lib/main.dart`：安装启动成功，首页在 UIAutomator 树中可见；hot reload 成功。
- 真实 ADB 触摸：打开抽屉、点击“网络与平台”，分类页面可见。
- 真实 `KEYCODE_BACK`：关闭已打开的抽屉；UIAutomator 确认“网络与平台”页面仍在、抽屉目的地消失。
- `KEYCODE_HOME` 后恢复：同一进程保持运行，Activity 恢复成功。
- 脱离 Flutter 工具后主动停止并冷启动：`LaunchState: COLD`、`Status: ok`，启动耗时 1891ms，首页可见且进程存活。

以上普通应用流程未复现用户反馈的闪退。应用专属日志未出现 `FATAL EXCEPTION`、
`Fatal signal` 或 `Unhandled Exception`；退出记录中的 `USER REQUESTED / FORCE STOP`
对应本轮主动冷启动准备。不能据此认定此前闪退原因已定位或所有场景不存在崩溃。

## 本机证据

临时证据目录：`/private/tmp/forge-android-20261026/`（临时文件，非仓库交付物）。

- `app-test-final.log`：最终导航回归，`01:08 +3: All tests passed!`。
- `battery-test-regression.log`：电池专项，`00:07 +1: All tests passed!`。
- `normal-home.xml`、`normal-drawer.xml`、`normal-category.xml`、`normal-after-back.xml`：普通应用真实触摸与返回键页面证据。
- `normal-cold-start.xml`、`normal-cold-start-logcat.txt`、`normal-exit-info.txt`：普通入口冷启动与退出原因。
- `normal-app.log`：普通入口启动及 hot reload；`normal-app-final.log`：最终恢复普通应用入口。
- `normal-home-final.xml`：最终普通应用首页，进程 `30688` 存活；手机保留正常应用包。
- `quality-gate-verified.log`：最终质量门禁输出。

模块逐个进入仅证明入口与短时渲染/返回，不证明所有模块内部实验、视频实际播放、
文件选择器、BLE 外设、权限拒绝或长时间稳定性均已验收。
