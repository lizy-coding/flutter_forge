# Forge A2 · 通透玻璃图标

用户确认的 A2 Clear Glass 方向，所有平台由同一透明前景母版导出；容器、留白与小尺寸锐化按平台适配。这是静态玻璃视觉，未启用 Apple Icon Composer 的系统动态 Liquid Glass。

## 来源与再生成

内置 imagegen 编辑生成，不使用 CLI/API fallback。参考为已确认 A2 对比稿的右侧图形；最终源文件是 `source-foreground.png`（1254×1254 RGBA，真实透明）。提示词见 `PROMPT.txt`。
`tool/generate_app_icons.py` 只做画布合成、尺寸导出、主题亮度与格式转换，不重新生成图形。

```bash
python3 -m pip install -r tool/windows_store_requirements.txt
python3 tool/generate_app_icons.py
python3 tool/generate_app_icons.py --check
```

`exports.json` 保存母版与各导出文件的 SHA-256；`preview.png` 展示各平台及 Windows 浅/深色背景的小尺寸效果。

## 资源与接入

| 平台 | 资源 |
| --- | --- |
| Android | 48/72/96/144/192 legacy PNG；108dp 前景层各密度导出，核心处于 60dp 范围；API 26 adaptive XML，API 33 monochrome 层；背景 #121820 |
| macOS | 16/32/64/128/256/512/1024 PNG，接入现有 AppIcon.appiconset；1024 画布留 96px 外边距，透明外角 |
| Windows Win32 | ICO 含 16/20/24/32/40/48/64/96/128/256；独立深底容器提高小尺寸可辨性，Runner.rc/Inno Setup 继续引用同一路径 |
| Windows MSIX | 44、150、50 基准 PNG；100/125/150/200/250/300/400% scale；14 种 target-size 的 default/unplated/lightunplated，共 66 PNG；浅色 unplated 降低亮度，保持几何与 alpha |
| Web | 192/512 常规与不透明 maskable PNG、32px favicon、180px Apple touch；manifest 主题色同步 |
| iOS 预制 | `ios/AppIcon.appiconset` 含 iPhone/iPad/1024 营销槽位，不透明 RGB 方图；未建 iOS 宿主，后续导入真实 Runner/Assets.xcassets |

微软文档中的 AppList 为示例名，本项目使用与 manifest 对应的 `Square44x44Logo`；unplated 文件只含透明核心。
MSIX 构建时复制已导出资源，用 Windows SDK MakePri 生成 `resources.pri` 后再运行 MakeAppx；预览模式不会在非 Windows 主机伪造 PRI。

`google-play-512.png` 与 `microsoft-store-listing-300.png` 是商店素材备选，提交时仍需核对实际槽位及正式产品身份。
资源替换不自动更新旧安装包，需要重建和安装；验收时记录新包版本与哈希，留意系统图标缓存。

## 官方规则

- [Windows 尺寸和主题](https://learn.microsoft.com/en-us/windows/apps/design/iconography/app-icon-construction)
- [MSIX 资源索引](https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-manual-conversion)
- [Android adaptive icon](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive)
- [Apple app icons](https://developer.apple.com/design/human-interface-guidelines/app-icons/)
