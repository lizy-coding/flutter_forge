# macOS 重新打包验证结果

## 结论

- 新 Release 构建：`PASS`
- 定向测试：`3/3 PASS`
- 质量门禁：`6/6 PASS`
- 产物身份：`PASS`
- macOS 界面门禁：`HOLD`
- Windows 放行：`false`

新产物确实由当前工作树重新构建。主可执行文件修改时间为 2026-08-31 14:34:21 +08:00，SHA256 为 `e435751b987860f134ed7c903cf1ea2aebfcf15181fa64f2e3b44114b2ecb50e`。构建包含 HEAD `ce814fbc249bd3c36ca5ab41151bb29fe70cc980` 以及暂存的多窗口修复；暂存 diff 指纹为 `e880cf41e1b6a599079b558d22a9c1b8a722c53c5357f48b44fb054c2fd003cd`。

## 关键失败

两次启动新 Release 均出现：

```text
Invalid engine handle
Failed to send message to Flutter engine on channel 'mixin.one/desktop_multi_window'
```

因此 M13、M14 / UI-24、UI-25 继续为 `FAIL`。当前 Dart 修复通过了 stale controller、live controller 复用和关闭后重建测试，但没有消除启动期 `desktop_multi_window` 原生广播错误。

## 界面执行

新产物首屏正常渲染并已截图。Computer Use 能读取窗口和保存截图，但坐标点击时仍返回 `Sky Computer Use native pipe closed before response`，没有产生导航。因此导航、多窗口、file_picker 和响应式交互全部据实标记 `BLOCKED`。

本轮响应式项目不再是 `NOT_IN_ARTIFACT`：产物已包含 `ce814fb`，但缺少真实交互证据，故 R2-R10 为 `BLOCKED`。

## 汇总

- UI-01 至 UI-35：`PASS 5 / FAIL 2 / BLOCKED 28`
- 完整自测清单：`PASS 18 / FAIL 2 / BLOCKED 44`
- `MACOS_GATE=HOLD`
- `windows_ready=false`

## 证据

- `MACOS_UI_ACCEPTANCE_REPORT.json`
- `screenshots/UI-01-main-window.png`
- `logs/targeted-test.log`
- `logs/quality-gate.log`
- `logs/build-macos-release.log`
- `logs/artifact-provenance.log`
- `logs/runtime.log`
- `logs/app-console.log`
- `logs/final-runtime-evidence.log`

本轮未修改源码、未 commit、未 push；仅构建产物并新增本轮验收证据。
