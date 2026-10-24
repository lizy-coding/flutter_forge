# RELEASE-PREP v1.2.10 — 全平台发布准备与自检（2026-10-24）

> 定位：发布**准备**记录，不是发布验收。构建通过、真机/真实主机验收、发布执行三者分开描述（AGENTS.md 边界）。
> 发布执行必须经 Agent Hub `release_hosting` 的 `release-plan` / `release-run --execute` 流程，本文不构成发布授权。

## 基线

- 仓库：flutter_forge，分支 `dev`，HEAD `dee40bd74cfea355aa27fb0565bc5606d69ba5eb`（features: GenUI/工作流/模块发现/网络诊断及相关工具、文档与证据）。
- 本报告对应的版本与自检改动（pubspec bump、本文档、QUALITY_ACCEPTANCE 基线更新）在准备时点为**未提交工作树**；发布流程要求干净树（`tool/release_metadata.js` 对 `git diff HEAD` 非空直接拒绝），因此发布前必须先按"剩余步骤"提交。
- 版本：`apps/flutter_forge/pubspec.yaml` `1.2.9+3` → `1.2.10+4`。依据既有惯例 `v1.2.7=1.2.7 / v1.2.8=1.2.8+2 / v1.2.9=1.2.9+3`，build number 逐版本 +1；`node tool/release_metadata.js version` 已确认读取 `1.2.10`。Windows 安装器版本从该 pubspec 注入。
- 已发布标签：v1.2.2–v1.2.9（v1.2.9 打在 dev `94c7edf`）。注意：`release_metadata.js` stage 时校验发布标签必须位于 `origin/master` 稳定链上，历史标签在 dev 上的事实如实记录、不回改。

## 工具链（自检主机）

- 主机：macOS（darwin 25.6.0, arm64）。
- Flutter 3.47.2 / Node v22.23.1。`release.yml` env 声明 Flutter 3.47.2 / Node 24；Node 主版本差异仅影响本机自检，实际发布构建以 CI runner 为准（manifest toolchain 证据由 `installedToolchain()` 在构建主机现场采集）。

## 四平台自检矩阵（2026-10-24，本机镜像 `release.yml` 步骤）

| 平台 | 命令（与 release.yml 一致） | 结果 | 产物/证据 |
|------|------------------------------|------|-----------|
| Web | `bash tool/build_web_release.sh` | PASS（脚本内置校验：本地 CanvasKit、loading shell、受控媒体均通过） | `apps/flutter_forge/build/web/` |
| macOS | `flutter build macos --release`；随后镜像 Package DMG 步骤（ditto + `hdiutil create` + `hdiutil verify`，CFBundleExecutable 存在性检查） | PASS（app 80.6MB；DMG 33.5MB verify 通过） | `build/macos/Build/Products/Release/Flutter Forge.app`；`/tmp/FlutterForge-1.2.10-macos-x64.dmg`（临时证据，未入仓） |
| Android | `flutter build apk --debug --target-platform android-arm64 --split-per-abi` | PASS（109.9MB） | `apps/flutter_forge/build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` |
| Windows | 本机为 macOS，无法构建 Windows runner/EXE | NOT RUN（见 Windows 待办） | 无 |

- 质量门禁（L1）：`bash tool/quality_gate.sh` 5/5 PASS（生成契约无漂移、Dart 格式、bare analyze 零 issue、workspace+tool 测试全过、模块测试存在性）。工作树含 GenUI P0/P1、AppDelegate 弃用 API 迁移、僵尸文件清除等未提交改动，全部包含在本自检范围内；提交后需复跑一次门禁。
- 本轮基线自 v1.2.9 起的主要变更（对应 HEAD dee40bd 与工作树）：GenUI 工作流/模块发现/网络诊断模块与工具、桌面工作台交互原语（ForgeNavTile/PressableCard/SelectableList）、macOS `allowedFileTypes`→`allowedContentTypes` 迁移、僵尸文件清除（4 个死 Dart 文件 + vendored video_player_win + 旧布局残留）。

## Android debug 构建与 debug 签名（显式记录，AGENTS.md 要求）

- 分发格式：ARM64 **debug** APK（冻结 manifest `build_mode: debug`）。
- 签名：**Android debug certificate**（debug.keystore 自动签名，非上传密钥、非 release 签名）；`tool/android_release_local.sh` 的 local-upload keystore 仅用于历史 AAB 流程，不用于 v1.2.10 冻结 manifest 分发。

## Windows 待办（真实主机）

1. 在 Windows 主机构建 release runner 并用 Inno Setup 产出 `FlutterForge-1.2.10-windows-x64.exe`（版本自 pubspec 注入）。
2. 执行 `tool/windows_acceptance.ps1` 验收清单并回报；多窗口专项（三分类窗口/子窗口文件选择/关闭重开/引擎日志）仍为 PENDING。
3. 以上证据补齐前，Windows 平台不宣称"已验收"。

## 冻结 manifest 与剩余发布步骤

分发格式以 `tool/release_metadata.js` 冻结清单为准：`FlutterForge-1.2.10-macos-x64.dmg` / `FlutterForge-1.2.10-windows-x64.exe` / `FlutterForge-1.2.10-android-arm64-v8a-debug.apk` / `FlutterForge-1.2.10-web.zip`，逐平台产出 `RELEASE_MANIFEST-<platform>.json` 与 `SHA256SUMS-<platform>`。

1. 提交本准备改动与在途功能到 `dev`（需用户授权提交）；复跑 `bash tool/quality_gate.sh` 确认干净基线。
2. Pull Request `dev` → `master` 并合入（禁止直接推送 master）。
3. 打标签 `v1.2.10`（release.yml 在 tag push 上自动构建四平台暂存产物；`release_metadata.js verify` 在构建前校验源/版本一致性）。
4. 经 Agent Hub `release_hosting`：`release-plan` 生成计划，`release-run --execute` 执行 GitHub Release（本仓库 CI 只构建暂存产物，不发布）。
5. Windows 实机验收按上文待办执行并回报，纳入 ACCEPTANCE_REPORT。
