# ADR 0001: 单仓布局 (Pub Workspace)

| 属性 | 值 |
|------|-----|
| 状态 | accepted |
| 日期 | 2026-07-25 |
| 决策者 | forest |

## 上下文

项目依赖 4 个共享包（gcode_core, flutter_study_learning, file_picker_bridge, flutter_ioc_core）和 1 个外部工具（flutterguard_cli）。这些包原本以 `../` 相对路径引用，依赖开发机目录布局。

## 决策

1. 内部共享包迁移至 `packages/` 目录，以 Dart Pub Workspace 管理
2. flutterguard_cli 保持为外部 Git 依赖，以不可变 tag/commit 固定
3. 禁止 `path: ../...` 相对路径依赖

## 理由

- Agent 在单一 clone 中即可获取源码、运行测试、提交原子变更
- 不依赖开发机目录布局
- Dart Pub Workspace 提供统一的依赖解析

## 后果

- 4 个共享包从仓库外迁入，git history 分离
- flutterguard_cli 更新需显式修改 Git ref
- 新开发者无需额外 clone 其他仓库
