# macOS 鼠标输入修复验收

日期：2026-10-21。范围为 `dev` 基础 HEAD `eb500f555b9ce930959d05dfbb09f820985b4c65` 加当前未提交修改；不是发布验收。

后续用户反馈新窗口启动黑屏／崩溃，新增修复和最新产物见 [窗口启动修复记录](MACOS_WINDOW_STARTUP_FIX-20261021.md)。下文指纹和“当前运行”仅指本记录当时状态。

## 问题与修复

修复前，真实坐标点击无法操作侧栏，而辅助功能动作可以触发同一入口，Dart 运行时未报告异常。故障位于新增原生材质后的窗口输入链路，不能由 Widget 测试或辅助功能点击证明其正常。上一轮报告的整体鼠标 PASS 已撤回。

将材质从 AppKit 私有窗框层级移入 `contentView` 内、置于 Flutter 内容下方；材质装饰视图的 `hitTest` 始终返回空，且不接受第一响应者。窗口保留实色输入背景和 `isOpaque=true`，Flutter 背景按材质状态切换。仅恢复窗口不透明标记的中间方案未解决问题，最终以结构调整后的真实鼠标结果为准。

## 验收结果

- PASS：重建 macOS Release；原生集成测试同时重建 Debug。原生改动通过完整重启加载，不依赖热重载。
- PASS：Release 主窗口真实坐标点击侧栏切换分类、模块卡进入教学、标题栏打开／关闭快速搜索、返回分类、打开分类专注窗口。
- PASS：教学页真实坐标点击“基础 Widget 重建”及“触发重建”，计数从 0 变为 1。证据：[计数变化](../evidence/pointer_input_fix_20261021/mouse_counter_changed.png)。
- PASS：分类专注窗口激活后，真实坐标点击模块卡进入“三棵树与生命周期”。证据：[子窗口模块](../evidence/pointer_input_fix_20261021/mouse_child_module.png)。窗口激活使用系统菜单，模块操作使用坐标点击，不以辅助功能动作代替鼠标验收。
- PASS：`flutter test --no-pub integration_test/desktop_material_acceptance_test.dart -d macos`；原生返回 `materialActive=true`、`inputSurfaceOpaque=true`、`materialInsideContent=true`、`materialIgnoresPointer=true`。该测试为补充回归，不代替上述真实鼠标检查。
- PASS：`bash tool/quality_gate.sh`，包含生成物无漂移、格式、analyze 无 issue、workspace／工具测试、30/30 模块测试存在性。
- PASS：`git diff --check`。

本轮未重新验收 Windows、Web、Android 或 iOS。保留原有依赖锁文件与无关工作区修改，未提交、未推送。当前运行的是修复后的本机 Release。

## 当前 Release 指纹

产物：`apps/flutter_forge/build/macos/Build/Products/Release/Flutter Forge.app`（约 77.7 MB）。以下 SHA-256 对应本轮产物，不沿用旧报告指纹。

| 对象 | SHA-256 |
|---|---|
| AppDelegate.swift | `7d255beaa8488c700eaee92ffd5af04be162dac97574acdd0a8c3d2c1274d847` |
| desktop_material_acceptance_test.dart | `3fdef39385fa2abf6ce4dad58672a81134efe363c4cf1c21107c2f272bb826e1` |
| pubspec.lock | `7fb9af0c3549a4b218ee58f0bf097ea9944d34a41d33bcbc5d97121b795e502e` |
| Contents/MacOS/Flutter Forge | `c319bf4b3b12966f141e1304403ebc04154e20f9583f2a6d845fc222cfa68b79` |
| Contents/Frameworks/App.framework/App | `9f0517c8eb2b70947ea38e82b3252ad4a1637b047b47e89c5af98977d8623bb6` |
