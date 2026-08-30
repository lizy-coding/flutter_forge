# Flutter Forge macOS 安装说明

此预览版未使用 Apple Developer ID 签名或公证，首次启动时 macOS Gatekeeper 的拦截属于预期行为。

1. 解压 `flutter_forge-macos-x64.zip`。
2. 在 Finder 中右键点击 `Flutter Forge.app`，选择“打开”，再在确认窗口中点击“打开”。
3. 如果仍被拦截，在终端执行：

```bash
xattr -dr com.apple.quarantine "/path/to/Flutter Forge.app"
```

将命令中的路径替换为实际的应用路径，然后再次打开应用。
