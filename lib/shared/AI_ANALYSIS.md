# Shared 层分析

> shared 层已完成第一轮外置迁移。教学模板、平台文件选择等可复用能力已迁移到项目同级 package，主应用通过 path dependency 引用。

## 当前定位

`lib/shared/` 只保留跨模块共享能力的项目内文档和后续过渡能力。新增稳定能力时优先评估是否直接进入同级 package。

## 已迁移能力

| 能力 | 同级包 | 当前使用方 |
|---|---|---|
| 教学模板 | `../flutter_study_learning` | tree_state, gcode_visualizer |
| 文件选择 Dart API | `../flutter_study_platform_file_picker` | gcode_visualizer |

## 维护规则

1. `shared/` 不得 import `modules/`。
2. 新增 shared 代码前优先评估是否应放入同级 package。
3. 业务模块只能依赖 package API，不直接依赖平台通道细节。
