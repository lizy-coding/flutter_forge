# Flutter Forge macOS 安装说明

此预览版未使用 Apple Developer ID 签名或公证，首次启动时 macOS Gatekeeper 的拦截属于预期行为。DMG 只是安装镜像，不会替应用增加签名或公证。

1. 双击 `FlutterForge-<版本>-macos-x64.dmg` 挂载磁盘映像。
2. 将 `Flutter Forge.app` 拖到 `Applications` 快捷方式。
3. 在“应用程序”中右键点击 `Flutter Forge.app`，选择“打开”，再在确认窗口中点击“打开”。
4. 如果仍被拦截，在终端执行：

```bash
xattr -dr com.apple.quarantine "/path/to/Flutter Forge.app"
```

将命令中的路径替换为实际的应用路径，然后再次打开应用。用完后可在 Finder 侧边栏推出 `Flutter Forge` 磁盘映像。
