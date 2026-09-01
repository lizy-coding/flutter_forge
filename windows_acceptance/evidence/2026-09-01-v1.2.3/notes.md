# Windows UI 验收基线 — v1.2.3

## 记录

- 日期：2026-09-01
- 基线：tag v1.2.3（run 33511073139，三 job success）
- head_sha：0dd8f676388cb55b453844c4935ce58b9790b2b3
- 产物：flutter_forge-setup-x64.exe
- SHA256：fd5de214dd5f5db83c685553368a0d98878fb3c131d9d8ea32250dcef9f9d67f
- 大小：12,045,069 bytes（PE32 Intel 80386）
- Release：https://github.com/lizy-coding/flutter_forge/releases/tag/v1.2.3

## 本基线包含的关键源码（相对 v1.2.2）

1. 5ef5a81 — Issue #18 紧凑布局修复（microtask / isolate-basic / adsorption-line 360x860）
2. 92bb625 — 多窗口生命周期诊断（diagnostic sink：category/argumentsType/controllerId/operation/elapsedMs/error）
3. cb48fd0 — 子窗口时序修复：hiddenAtLaunch=false + 移除 post-frame 延迟 show + mac_window.dart 后端协议 + adsorption_line 工具栏 <600dp Wrap
4. 0dd8f67 — 版本 bump 1.2.3（pubspec + setup.iss AppVersion 同步）

## 验证状态

```text
windows_preflight           = PASS（远端构建成功 + 产物身份已核验）
installer_startup           = PENDING_REAL_MACHINE
module_navigation           = PENDING_REAL_MACHINE
multiwindow_stability       = PENDING_REAL_MACHINE
windows_file_picker         = PENDING_REAL_MACHINE
online_video_player         = PENDING_REAL_MACHINE
responsive_360_600_1024     = PENDING_REAL_MACHINE
windows_usb_detector        = DEFERRED（Android-only）
windows_ready               = false
windows_final_acceptance    = HOLD
```

## 下一步（Windows 真机）

在 Windows x64 真机执行 windows_acceptance/WINDOWS_SELF_TEST_CHECKLIST.md：

- 前置 P1-P8 → 安装 W1-W6 → 导航 N1-N8 → 视频 V1-V6 → 多窗口 M1-M17 → 响应式 R1-R13
- 重点：三分类窗口快速开关 3 轮（M16）、关闭最后子窗口主窗口存活（M17）、360dp 下 adsorption_line 工具栏换行（R11）
- 崩溃证据：Event Viewer / WER（0xc0000005 / 0xc000041d / Invalid engine handle / Failed to send message）
- 结果回填本目录 screenshots/ + logs/ + notes.md
