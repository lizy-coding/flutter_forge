# File Picker 共享能力分析

> 业务无关的文件选择能力，当前由 macOS 原生 `NSOpenPanel` 实现。

## 功能目标

为各学习模块提供统一文件选择入口。模块只声明允许的扩展名、弹窗标题和提示文案，不直接依赖 MethodChannel 名称或原生实现细节。

## 文件结构

```
shared/platform/file_picker/
├── file_picker_service.dart        # PickedFile 数据模型与 FilePickerService 抽象接口
├── method_channel_file_picker.dart # 通过 MethodChannel 调用平台文件选择器
└── AI_ANALYSIS.md                  # 共享能力说明文档
```

## 数据流

```
module page/controller
  -> FilePickerService.pickFile(allowedExtensions, title, message)
  -> MethodChannel('flutter_study/file_picker').invokeMapMethod('pickFile')
  -> macOS NSOpenPanel
  -> PickedFile(path, name)
  -> module-owned file reader/parser
```

## 关键类

| 类 | 作用 |
|---|------|
| `PickedFile` | 平台文件选择结果，只承载路径和可选文件名 |
| `FilePickerService` | 业务无关接口，便于模块注入 mock 或替换实现 |
| `MethodChannelFilePicker` | 默认实现，封装 MethodChannel 协议 |

## 平台协议

Channel: `flutter_study/file_picker`

Method: `pickFile`

参数:
- `allowedExtensions`: `List<String>`，不带点号的扩展名
- `title`: 弹窗标题，可为空
- `message`: 弹窗提示，可为空

返回:
- `null`: 用户取消选择
- `{ "path": String, "name": String? }`: 已选择文件

## 修改注意事项

1. shared 层只做“选择文件”，不做业务解析、路径规范化或内容读取。
2. 业务模块负责传入扩展名和文案，负责后续读取与错误展示。
3. 新增平台实现时必须保持同一 MethodChannel 协议。
4. 若该能力被多个工程复用，再考虑抽成独立 Flutter plugin/package。
