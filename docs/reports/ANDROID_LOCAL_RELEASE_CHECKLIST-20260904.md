# Android 本地 Release 打包验收

日期：2026-09-04
项目：Flutter Forge
构建目录：`apps/flutter_forge`

## 本地标准

```bash
bash tool/android_release_local.sh
```

脚本行为：

- 运行完整 `bash tool/quality_gate.sh`
- 自动生成本地临时 upload keystore 到 `apps/flutter_forge/build/android-release/`
- 通过环境变量注入 Release 签名
- 构建 AAB 和分 ABI APK
- 使用 `apksigner` 校验 APK
- 使用 `jarsigner` 校验 AAB
- 生成 `SHA256SUMS`

## 验收结果

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| Agent 文档生成与校验 | PASS | 44/44 |
| Dart 格式 | PASS | quality gate |
| Flutter analyze | PASS | no issues |
| 全量测试 | PASS | 5 个 workspace package suites |
| 测试布局 | PASS | 21/21 modules have tests |
| FlutterGuard | PASS | 0 HIGH |
| AAB Release 构建 | PASS | `app-release.aab`，60.1MB |
| ARMv7 APK | PASS | v2 signature verified |
| ARM64 APK | PASS | v2 signature verified |
| x86_64 APK | PASS | v2 signature verified |
| ARM64 APK 安装 | PASS | `adb install -r` 返回 Success |
| ARM64 APK 启动 | PASS | Activity resumed，PID 3060 |
| Fatal Android 日志 | PASS | 无 `FATAL EXCEPTION` / `E/flutter` |

## 产物校验和

```text
ff404fa6a2e2f2ae196cedf6a1ad8f106adf44ee0852171592f45f0dfb7b3903  app-release.aab
44def23bdd5a739ea6e78bff75258d53b61fc08fade785e51b97fe936284a329  app-arm64-v8a-release.apk
a2d4d380e8360df8fd8f36a086d3c987099e326740cf65c6a9334a35ea18a519  app-armeabi-v7a-release.apk
2bb0199dac685293357288fe50abef5f34c05082092bbf65b8899886607a5762  app-x86_64-release.apk
```

## 当前发布边界

- 当前签名是本地临时 upload key，只用于本地验收，不能用于正式发布。
- 正式发布前必须接入受保护的 release keystore、Play App Signing 和版本递增校验。
- 当前已证明本地 Release 可构建、可签名、可安装、可启动；远端流水线尚未新增。
