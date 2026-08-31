# macOS Engine 启动顺序修复验收

## 结论

- Engine 启动错误修复：`PASS`
- 当前完整 macOS 门禁：`HOLD`
- Windows 放行：`false`
- UI-01 至 UI-35：`PASS 7 / FAIL 0 / BLOCKED 28`

提交 `b80e41f` 的新 Release 连续启动两次，`Invalid engine handle` 和 `Failed to send message to Flutter engine` 均为 0。M13、M14 已从上一轮 FAIL 转为 PASS。

## 临时自测声明核验

用户给出的临时目录中发现：

```text
/private/var/folders/x4/dv4r23qn30q5dzvvkmf83z2c0000gn/T/ResultBundle_2026-31-08_15-35-0015.xcresult
```

`xcresulttool` 显示 `result=unknown`、`totalTestCount=0`、`passedTests=0`、`failedTests=0`。它不能作为测试通过证据。本轮独立执行的仓库定向测试为 3/3 PASS，质量门禁为 6/6 PASS。

## 新产物

- HEAD：`b80e41fb53aa01498b587d7fbe54bfb21b2f578e`
- 可执行文件时间：2026-08-31 15:47:03 +08:00
- SHA256：`327597c619ec028a063f9c4ebfe437f9cc0bc627730f7c9b6a67a6b285dfc3db`
- Release 构建：PASS，52.2MB

## 剩余阻塞

Computer Use 可以读取窗口和保存截图，但点击 Flutter Forge 时仍返回 `Sky Computer Use native pipe closed before response`。因此三分类窗口、同类复用、关闭重开三轮、子窗口 file_picker、视频和响应式视口尚无真实交互证据，不能把完整 macOS 门禁判为 PASS。

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

本轮未修改源码、未 commit、未 push。
