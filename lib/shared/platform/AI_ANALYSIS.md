# Platform 共享层分析

> 平台能力正在从主应用 shared 层迁移到同级 package。

## 当前能力

| 能力 | 包 | 宿主原生实现 |
|---|---|---|
| 文件选择 | `../flutter_study_platform_file_picker` | macOS `AppDelegate.swift` 注册 `flutter_study/file_picker` |

## 后续计划

当需要 Windows/iOS/Android 文件选择实现时，将 `flutter_study_platform_file_picker` 从 Dart API package 升级为完整 Flutter plugin，并迁移 macOS 原生实现。
