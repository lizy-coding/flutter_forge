# 四端发布基线评估与验证 — 2026-09-30

## 结论与范围

四端已具备可重复构建和基础打包能力，但当前尚不能判定为完整的正式发布基线。当前候选源码的质量门禁未全绿；四端资产尚未绑定同一个最新提交；版本、签名、远端校验和最新运行验收存在缺口。

本轮只评估及验证。未触发 GitHub Actions、Cloudflare 部署、GitHub Release 写入、Agent Hub 服务端发布、设备安装、Git 提交或推送；未修改业务源码、门禁或发布配置。新增本报告。

评估四端：Android、macOS、Windows、Web。iOS 不在本轮范围。

## 基线身份

| 对象 | 本轮核对结果 |
| --- | --- |
| Forge 本地 HEAD | `d2f1668d4de7d2c6fb43ba68aab3234d44c6ef67`，`dev` |
| Forge 未提交改动 | BLE `module_root.dart`、`state/ble_session.dart`、`ble_session_test.dart` 三个文件 |
| 本轮源码 | HEAD 加上述三处改动的临时快照；原源码文件在验证前后 SHA256 一致 |
| GitHub 远端 dev（API 实时） | `9aa8db2e652b3520be70f1ff36c200ea100af725` |
| 本地 origin/dev 缓存 | `28073107cfbc6fb274180088b3fa24950161f5a5`；缓存已落后，不作为实时远端证据 |
| 应用版本 | `1.2.7` |
| Agent Hub HEAD | `80fdf2a`，已有工作区改动参与本轮本地验证；未改动这些文件 |
| 工具链 | Flutter 3.47.2、Dart 3.13.2、Xcode 26.6、macOS arm64 主机 |
| 证据目录 | `/private/tmp/forge-release-audit-20260930-b6asibw4/` |

质量门禁与构建在复制的源码快照中运行。快照使用独立临时 Git 索引承接起始文件状态，先完成与 CI 相同的依赖 bootstrap，再检测生成/格式步骤是否产生新差异。它验证当前内容可否通过门禁，不代表原工作区已清洁或已提交。

## 当前候选代码实测

| 项目 | 状态 | 本轮证据 |
| --- | --- | --- |
| Agent 文档生成、校验与漂移检查 | PASS | `agent_docs_valid:45`，快照未产生生成物差异 |
| Dart 格式 | PASS | 275 files，0 changed |
| bare Flutter analyze | FAIL | BLE 测试第 2 行 `unnecessary_import`，一条 info 使严格门禁失败 |
| 主应用测试 | PASS | 150 项通过 |
| file_picker_bridge 测试 | PASS | 8 项通过 |
| flutter_ioc_core 测试 | PASS | 22 项通过 |
| 测试布局检查 | PASS | 门禁通过 |
| FlutterGuard | PASS | 无 HIGH；已有 MEDIUM 不扩大为零问题结论 |
| 六阶段质量门禁 | FAIL | 5/6；唯一失败阶段为静态分析 |
| Cloudflare 根路径 Web Release | PASS | `/`；约 59.75 MB，61 文件，最大文件 7,284,602 bytes |
| GitHub 子路径 Web Release | PASS | `/flutter_forge/`；本地 CanvasKit、加载壳和媒体资源检查通过 |
| 本地 Web 浏览器冒烟 | PASS（有界） | Codex 内置浏览器实际首屏、搜索、BLE 不可用态及子路径 `#/bluetooth-ble` 直达通过；console 未见 error/warn |
| macOS Release 编译 | PASS | 当前快照 `flutter build macos --release` 成功 |
| macOS DMG 生成与镜像校验 | PASS | 按工作流的 staging/Applications 链接/hdiutil 流程生成，`hdiutil verify` 成功 |
| macOS Release 启动冒烟 | PASS（有界） | 当前快照可执行文件存活 12 秒，日志确认 Metal Impeller；随后结束该测试进程 |
| Android ARM64 Release APK | PASS | 构建成功；26,764,067 bytes；包内仅 arm64-v8a |
| Android Release AAB | PASS（构建） | 构建成功；67,640,162 bytes；包含 arm64-v8a、armeabi-v7a、x86_64 |
| Windows 当前源码编译/安装 | PENDING | 当前 macOS 主机未执行 Windows 构建；旧远端成功不可替代当前提交 |

这些测试不包含最新 Windows 真机安装/升级、多窗口操作、最新 Android APK 真机升级及通知订阅、macOS 完整 BLE GATT 闭环、Safari/Chrome/Edge 的本轮矩阵或国内多运营商测速。

## 远端与既有产物复核

| 项目 | 结果 |
| --- | --- |
| 最新远端 CI | `9aa8db2`，[36527658876](https://github.com/lizy-coding/flutter_forge/actions/runs/36527658876)，success |
| 最新远端安装器构建 | `9aa8db2`，[36527665591](https://github.com/lizy-coding/flutter_forge/actions/runs/36527665591)，macOS/Windows/Android 三个 build job 成功；Release job skipped |
| 远端构建资产 | DMG、Windows EXE、Android APK/AAB 下载并检查；未过期，但安装器资产保存期为 14 天 |
| 远端 DMG | 镜像校验通过，应用及所检查 frameworks 均为 x86_64 + arm64；版本 1.2.7，签名为 ad-hoc，TeamIdentifier 未设置 |
| 远端 Android APK | 仅 arm64-v8a；`apksigner verify` 通过，证书 DN 为 `Android Debug`；包名 com.flutterforge.preview、APK versionCode 2001、versionName 1.2.7 |
| Android 签名连续性 | 本地与远端 APK 证书 SHA256 不同，不能保证跨构建来源覆盖安装 |
| 远端 Android AAB | 包含三个 ABI，和 “android-arm64.aab” 名称/单 ARM64 契约不一致 |
| 远端 Windows EXE | 文件存在，构建与 Inno Setup 打包步骤成功；本轮未运行安装器。安装器启动器自身为 i386 不用于推断被安装应用架构 |
| GitHub Pages | [36527658868](https://github.com/lizy-coding/flutter_forge/actions/runs/36527658868)，success；线上 HTML、main.dart.js、CanvasKit WASM、MP4 均返回 HTTP 200，WASM MIME 正确 |
| Cloudflare Pages | 本地已有工作流；远端 dev 尚未含该后续提交；GitHub 未配置 Cloudflare secrets 或 ENABLED 变量；未取得真实 Pages 部署或国内访问证据 |
| 现有 v1.2.7 Release | [Release](https://github.com/lizy-coding/flutter_forge/releases/tag/v1.2.7) 非 draft，只有一个 APK，不能认定为四端发布完成 |

线上 HTTP 可达只证明本机网络可读取资源，不证明国内访问速度、首帧性能或媒体完整播放。

## Agent Hub 发布编排验证

本轮在本地内存中调用 release_hosting，`execute=False`，并将外部命令 runner 替换为会直接报错的防护函数。PLAN_ONLY 期间没有外部命令执行，未创建或变更服务端 ReleaseProgram。

- 现有 `release/1.2.7/` 五个暂存资产：PLAN_ONLY 为 READY，SHA256 本地核对 PASS。
- 这些旧资产包括 macOS ZIP；当前流水线已经改为 DMG。它们没有和当前 BLE 源码及本轮新 DMG 绑定。
- 仅提供一个 APK 的计划也被判 READY。当前状态不是“四端齐全”的证明。
- `release_program.py` 不冻结 source SHA、CI run ID、工具链和每端验收结果；`build_matrix` 作为元数据保存，不能替代逐端产物验证。
- 远端 verify_release 只检查文件名与大小，未比较 GitHub digest 或下载后的 SHA256；随后会将资产标为 VERIFIED。不能把该状态表述为远端内容校验和已通过。
- 聚焦 ReleaseProgram 测试：4/4 通过。适配器/分解相关集合：8 通过、1 失败；失败用例硬编码真实工作区必须 CLEAN，而当前工作区为 DIRTY。
- registry 结构校验：无错误。shadow 基准：4/6（SHADOW_002、SHADOW_005 未通过）；ownership=0.50，extraction=0.625，architecture_disagreement_count=4。低于 QUALITY_ACCEPTANCE.md 要求的 0.75/0.75 且零分歧。这属于架构证据/基准未收敛，不等同于应用功能测试失败。

## 缺口与建议顺序

| 优先级 | 缺口 | 发布前应达到的结果 |
| --- | --- | --- |
| P1 | 最新候选门禁未全绿且未提交 | 消除 analyzer info，冻结完整源码 SHA，再取得同 SHA 的 CI 和四端构建证据 |
| P1 | 发布计划不强制四端齐全、不绑定来源 | manifest 包含源码 SHA、版本、工具链、run ID、平台、架构、签名指纹、大小、SHA256；缺端或不匹配时阻断 |
| P1 | 远端 VERIFIED 仅依据名称和大小 | 比较远端 digest，缺少 digest 时下载核对 SHA256，再标 VERIFIED |
| P1 | Android CI 使用 debug 签名，跨构建证书不同 | 固定受保护的发布签名；正式轨道缺凭据时失败；验证上一版到候选版的覆盖升级 |
| P1 | Windows 安装器 AppVersion 写死 1.2.3 | 从同一版本源生成安装器版本，核对安装器、程序、tag 与 manifest 一致 |
| P1 | Web 发布与质量门禁独立触发 | 正式 Web 部署只消费同 SHA 通过门禁的产物，避免 CI 失败时仍部署 |
| P2 | AAB ARM64 命名与实际三个 ABI 不符 | 明确 AAB 多 ABI 还是 ARM64-only，并检查包内容；macOS 双架构产物也应准确标注 |
| P2 | Cloudflare 发布尚未接通 | 补项目/凭据/启用配置后，在另一次明确部署任务中验证 Pages 地址及目标网络；本轮不执行 |
| P2 | 发布资产格式与暂存目录脱节 | 以当前 DMG/EXE/APK/AAB/Web 产物重建冻结资产，不将旧 ZIP 当作当前候选产物 |
| P2 | 最新真实运行证据不足 | Windows 安装/升级/卸载、多窗口；Android 安装升级与 BLE 通知；macOS GATT；Web 浏览器矩阵及冷首帧分别验收 |
| P2 | 架构基准及验收文档落后 | 区分历史阶段 COMPLETE 与当前版本 release-ready；更新 2026-08-31 的旧发布基线并校准 shadow/golden 分歧 |

macOS Developer ID 签名与公证、Windows Authenticode 尚无证据。若继续采用明确告知用户的未签名预览分发，这可作为已批准限制；不能描述为具备正式签名/公证体验。

## 关键定位与证据

- Windows 版本：`apps/flutter_forge/windows/installer/setup.iss:4`。
- Android 签名回退：`apps/flutter_forge/android/app/build.gradle.kts:49`。
- analyzer 问题：`apps/flutter_forge/test/modules/platform/bluetooth_ble/ble_session_test.dart:2`。
- Web 工作流：`.github/workflows/deploy-pages.yml`、`.github/workflows/deploy-cloudflare-pages.yml`。
- 远端校验逻辑：`/Users/forest/code/agent-hub/src/agent_hub/graphs/release_hosting.py:272`。
- 发布冻结结构：`/Users/forest/code/agent-hub/src/agent_hub/projects/release_program.py:48`。
- 完整门禁日志：[quality-gate-final.log](/private/tmp/forge-release-audit-20260930-b6asibw4/quality-gate-final.log)。
- 构建结果：[build-results.json](/private/tmp/forge-release-audit-20260930-b6asibw4/build-results.json)。
- PLAN_ONLY 结果：[release-plan-only.json](/private/tmp/forge-release-audit-20260930-b6asibw4/release-plan-only.json)。
- 架构基准：[shadow-benchmark.json](/private/tmp/forge-release-audit-20260930-b6asibw4/shadow-benchmark.json)。
- 包内证据：[macos-remote-inspection.json](/private/tmp/forge-release-audit-20260930-b6asibw4/macos-remote-inspection.json)、[android-signature.json](/private/tmp/forge-release-audit-20260930-b6asibw4/android-signature.json)、[android-current-inspection.json](/private/tmp/forge-release-audit-20260930-b6asibw4/android-current-inspection.json)。

Web 子路径深层链接实测截图：

![GitHub 子路径产物中的 BLE 不可用说明](/private/tmp/forge-release-audit-20260930-b6asibw4/web-github-deep-link.png)
