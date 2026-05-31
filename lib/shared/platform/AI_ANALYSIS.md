# Platform 共享层分析

> `shared/platform/` 归拢平台通道、系统能力和设备能力封装。它提供“能力”，不承载业务流程。

## 功能目标

屏蔽 macOS、Windows、iOS、Android 等平台差异，为学习模块提供稳定的 Dart 接口。模块只传入业务参数，不直接管理 MethodChannel 名称、原生弹窗或系统权限。

## 文件结构

```
shared/platform/
├── AI_ANALYSIS.md
└── file_picker/
    ├── AI_ANALYSIS.md
    ├── file_picker_service.dart
    └── method_channel_file_picker.dart
```

## 数据流

```
module controller/page
  -> shared platform interface
  -> MethodChannel / platform API
  -> native implementation
  -> normalized Dart result
  -> module-owned business flow
```

## 平台能力列表

| 能力 | Dart 接口 | 原生实现 | 使用方 |
|---|---|---|---|
| 文件选择 | `FilePickerService` | macOS `NSOpenPanel` via `AppDelegate.swift` | `gcode_visualizer` |

## 维护规则

1. MethodChannel 名称使用 `flutter_study/<capability>`，例如 `flutter_study/file_picker`。
2. Dart 接口必须业务无关；扩展名、标题、提示文案等由调用模块传入。
3. 原生侧只返回平台结果，不读取或解析业务文件内容。
4. 每个能力目录都需要自己的 `AI_ANALYSIS.md`，记录协议、返回值和扩展计划。
5. 新增平台能力时优先提供 mock-friendly 的 Dart 接口，方便单元测试。
6. macOS sandbox 相关权限必须写入 entitlements，并在能力文档中说明。

## 扩展计划

- 为 `file_picker` 增加 Windows/iOS/Android 实现时保持现有 Dart API 不变。
- 若新增目录如 `device_info/`、`system_dialog/`，先在 shared 层验证，再评估插件化。
