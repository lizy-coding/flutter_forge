# Forge A2 通透玻璃 · 统一图标交付

用户已确认 A2 Clear Glass 并授权接入项目。本轮未提交、推送、发布或改变设备设置；SDK/隐私、Windows 复核工具与 NFC 等已有工作区改动继续保留。

## 交付

- 最终图形源及提示词：`artwork/branding/forge-a2-glass/source-foreground.png`、`PROMPT.txt`，来自内置 imagegen，不使用 API fallback。源图实际为 1254×1254 RGBA；不把提示词要求的 2048 当作实际尺寸。
- 同一母版通过 `tool/generate_app_icons.py` 导出 116 份文件，`exports.json` 保存对应哈希，`preview.png` 展示各平台与 Windows 小尺寸主题适配。
- Android 既有五档 legacy launcher 替换，并加入 API 26 adaptive、API 33 monochrome 与各密度前景层。
- macOS 既有 AppIcon.appiconset 七种 PNG 替换，原 Xcode 槽位保留。Apple 资源编译器另产生有效 `AppIcon.icns`。
- Windows 既有 Runner/安装器资源路径保留，ICO 覆盖 16/20/24/32/40/48/64/96/128/256；MSIX 66 PNG 覆盖基准、7 档 scale 与 14 档 target-size 的默认/浅深 unplated。
- MSIX 不再从低分辨率 ICO 临时生成三张图，而是复制完整品牌导出，并在实际 Windows 构建中新增 MakePri 索引后再 MakeAppx。不能在 macOS 预览中假造 resources.pri。
- Web favicon、PWA、maskable、Apple touch 与 manifest 主题色已接入，实际 Web 构建复制内容经字节对照一致。
- iOS 无宿主：只在 artwork 下预制不透明 RGB AppIcon.appiconset。未伪造 ios/Runner 目录或扩大宿主声明。

这是静态玻璃质感，不是 Icon Composer 系统动态 Liquid Glass。

## 实际验证

| 检查 | 结果与范围 |
| --- | --- |
| 导出漂移 | PASS；116 个导出与清单一致 |
| Windows 规格 | PASS；66 PNG 尺寸、RGBA 与 10 档 ICO 实际帧检查 |
| Apple 目录 | PASS；JSON 槽位、像素尺寸、iOS 不透明 RGB 检查 |
| macOS actool | PASS；实际编译现有 Asset Catalog，输出 ICNS 与 Assets.car |
| iOS actool | PASS；仅预制资产目录编译，无 iOS App 构建或安装证据 |
| Android aapt2 | PASS；实际编译 res，包含新增 adaptive/monochrome XML 与 PNG |
| MSIX 工具测试 | PASS，11 项；含 MakePri 命令顺序与单包配置 fixture，不是 Windows SDK 实测 |
| 完整质量门禁 | PASS；生成物、格式、bare analyze、workspace/tool 测试与模块测试存在性 |
| Web Release | PASS；构建及原有 Web 检查通过，新图标内容与导出源匹配 |
| 新 Windows PRI/MSIX/安装 | NOT_RUN；仍需 Windows runner 和实际系统验收 |

日志：`/private/tmp/forge-icons-quality-20261029.log`、`/private/tmp/forge-icons-web-build-20261029.log`、`/private/tmp/forge-icons-actool-macos.log`、`/private/tmp/forge-icons-actool-ios.log`、`/private/tmp/forge-icons-aapt2.log`。

## 下载包

`.release/forge-a2-glass-icons-20261029.zip`：源图、导出资源、目录元数据、说明和生成脚本，另含 Apple 编译出的 `macos/FlutterForge.icns`。这不是新的应用安装包；旧安装包、已安装图标缓存和线上 Web 不会因本地替换自动更新。

规范链接与再生成方法见 `artwork/branding/forge-a2-glass/README.md`。正式微软商店身份、上架截图、WACK 及真实设备图标观感仍按原发布流程单独确认。
