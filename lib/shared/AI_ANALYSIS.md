# Shared 层分析

> `shared/` 存放跨模块复用能力。这里的代码必须保持业务无关，不能绑定某个学习模块的解析、状态或页面流程。

## 功能目标

为 `modules/` 下的学习模块提供稳定、低耦合的公共能力，包括教学模板、平台通道封装、通用组件、工具函数和主题辅助。

## 文件结构

```
shared/
├── AI_ANALYSIS.md          # shared 层边界与维护规则
├── learning/
│   └── learning_scaffold.dart # 教学页面模板组件
├── platform/
│   ├── AI_ANALYSIS.md         # 平台能力归拢规则
│   └── file_picker/
│       ├── AI_ANALYSIS.md
│       ├── file_picker_service.dart
│       └── method_channel_file_picker.dart
├── widgets/                # 通用 UI 组件（按需新增）
├── utils/                  # 通用纯 Dart 工具（按需新增）
└── theme/                  # 主题扩展（按需新增）
```

## 分层边界

| 子目录 | 放什么 | 不放什么 |
|---|---|---|
| `learning/` | 教学页面骨架、学习目标、概念卡片、代码片段等模板组件 | 具体模块的业务状态和解析逻辑 |
| `platform/` | 文件选择、设备能力、系统 API、MethodChannel 协议 | G-code、Dio、USB 等具体业务规则 |
| `widgets/` | 多模块复用的无业务 UI 小组件 | 单个模块专属页面片段 |
| `utils/` | 通用纯 Dart 工具函数 | 依赖 Flutter Widget 生命周期的逻辑 |
| `theme/` | 主题扩展、颜色/文本样式辅助 | 单模块视觉定制 |

## 依赖方向

```
modules/* -> shared/*
app/router -> module_registry + modules/*
shared/* -X-> modules/*
```

`shared/` 不能 import `modules/`。如果 shared 能力需要业务参数，由模块通过方法参数传入。

## 当前共享能力

| 能力 | 位置 | 使用方 | 状态 |
|---|---|---|---|
| 教学页面模板 | `shared/learning/learning_scaffold.dart` | 多个教学模块 | 可用 |
| 文件选择服务 | `shared/platform/file_picker/` | `modules/ui/gcode_visualizer` | macOS 可用 |

## 修改注意事项

1. 新增 shared 能力必须有清晰接口，优先提供抽象类或业务无关服务。
2. 新增 shared 子能力时同步补充该目录的 `AI_ANALYSIS.md`。
3. shared 能力至少接入 1 个模块验证，不新增无人使用的公共库。
4. 当 shared 能力被 2 个以上模块稳定复用，才评估是否抽成独立 package/plugin。
5. shared 层测试应覆盖成功、取消/空值、异常或平台未实现分支。
