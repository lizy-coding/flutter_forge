# Flutter 安全基线升级与完整版隐私说明

源码起点 `c384203e`，本轮为未提交工作区修改，未提交、推送、发布或执行 Microsoft Store 提交。原有 Windows 复核工具、NFC 规划与历史 release 产物保持原样。

## SDK

- 项目基线由 Flutter 3.47.2 / Dart 3.13.2 升为 Flutter 3.47.8 / Dart 3.13.7，对应 [GHSA-frr6-h895-5pxp](https://github.com/dart-lang/sdk/security/advisories/GHSA-frr6-h895-5pxp) 的修复稳定版本。
- `.fvmrc`、7 个工作流的 SDK 固定参数、应用 Flutter 最低约束和开发说明已同步。工作流只改 SDK 版本值，门禁命令和验收标准不变。
- 依赖包版本未调整；pubspec.lock 仅同步 Flutter SDK 最低约束。历史报告、测试 fixture 的历史版本值和外部 gcode_core 的原最低版本事实未批量改写。
- 原全局 `/Users/forest/development/flutter` 有用户的 macOS Debug destination 补丁，因此保留原样。新官方 SDK 独立安装在项目 `.release/toolchains/flutter-3.47.8`，本轮所有升级验证使用该 SDK。全局 PATH 与 IDE SDK 设置未切换；后续开发用 FVM 或按 `docs/DEVELOPMENT.md` 设置该 SDK 的 PATH。
- 精确工具链记录：`/private/tmp/forge-flutter-3478-version-clean.json`。

## 隐私说明

- `lib/app/full_privacy.dart` 为联网完整版的单一文字来源，在“关于”中展开，窄窗口可滚动阅读。
- `web/privacy.html` 由 `tool/export_privacy.py` 导出，无脚本、外部字体或追踪资源。`--check` 可检查与应用内文本一致。
- 明确说明端点/模型名持久保存、模型与 Hub 的临时令牌、问题/实验状态与工作流输入、网页/视频访问数据、设备能力、第三方保留规则、本地重置与反馈联系。
- 模型连接对话框增加发送前说明。现有模型连接仍只记住端点和模型名，不新增令牌持久化。
- Android 离线版的独立隐私说明和能力隔离保持不变。

## 实际验证

| 范围 | 结果 |
| --- | --- |
| 现有依赖锁定解析 | PASS；新 SDK 下 pub get --enforce-lockfile |
| 定向 Widget 测试 | PASS，8 项；About 隐私入口、360px 展开阅读、连接数据提示和原连接行为 |
| Android 离线策略的 Widget/逻辑回归 | PASS，7 项；FORGE_OFFLINE=true，不代表 Android 真机 |
| 完整质量门禁 | PASS；生成物、格式、bare analyze、workspace/tool tests、模块测试存在性 |
| Web Release | PASS；新 SDK 构建及现有 Web 验证脚本完成，build/web/privacy.html 与源静态页逐字节相同 |
| 静态隐私页浏览器检查 | PASS；本机回环预览，文字与布局可读，不代表公开托管已上线 |
| 热重载 | 无活动 App，连接两个可发现 DTD 后仍无运行 App，工具返回无法热重载；未用该结果冒充运行验收 |
| 新 Windows/Android 原生产物 | NOT_RUN；本轮 macOS 环境未重建或验收原生分发包 |

日志：`/private/tmp/forge-privacy-targeted-3478.log`、`/private/tmp/forge-privacy-offline-3478.log`、`/private/tmp/forge-flutter-3478-quality.log`、`/private/tmp/forge-web-3478-build.log`。
旧版 actionlint 对原有 `macos-26` runner 标签不识别；忽略这一已知旧工具标签限制后，其余工作流检查通过，未更换 runner 或降低项目门禁。

## 后续分发边界

更新 SDK 不会修复已经分发的旧 Windows/Android 二进制，必须使用新工具链重新构建、验证并分发。
公开隐私 HTML 已准备并进入本地 Web 产物，但尚未部署；对外托管并确认实际可访问 URL 后，再填入 Partner Center。
本说明更新不代表实时 AI 的内容反馈闭环、正式身份、品牌素材、原生验收或 WACK 已全部完成。后续 release plan 应与实际新工具链重新冻结，不能手改历史 manifest 冒充新构建。
