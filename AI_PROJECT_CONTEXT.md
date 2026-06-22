# AI 项目上下文

> 此文件为 AI 编程助手提供项目整体上下文，修改代码前请先阅读。

## 项目概述

- **名称**: main_app
- **类型**: Flutter 学习项目集合，单应用多模块架构
- **支持平台**: macOS, Windows, iOS, Android
- **技术栈**: Flutter 3.x / Dart 3.x

## 架构模式

- **路由**: go_router 统一管理，首页为模块列表，点击后 push 到对应模块
- **状态管理**: 项目实验多种方案（Provider, Riverpod, Bloc, ChangeNotifier, 自研 IoC）
- **模块组织**: 每个功能模块位于 `lib/modules/<category>/<module_name>/` 下，通过 `module_entry.dart` 暴露入口 Widget

## 关键约定

1. **模块入口**: 每个模块必须有 `module_entry.dart`，导出名为 `*Entry` 的 Widget
2. **路由注册**: 新模块需在 `lib/app/router/app_route_table.dart` 的 `_modules` 列表中注册
3. **依赖**: 所有依赖在根 `pubspec.yaml` 中声明，模块间不共享独立依赖
4. **命名**: 模块目录使用 snake_case，路由路径使用 kebab-case

## 目录结构

```
lib/
├── main.dart              # 应用入口，ProviderScope 包裹
├── app/
│   ├── app.dart           # MaterialApp.router 配置
│   └── router/            # go_router 路由配置
│       ├── app_router.dart
│       ├── app_route_table.dart # 路由表 + 模块列表 + 首页 UI
│       └── AI_ANALYSIS.md
├── module_registry/       # 模块元数据定义
│   ├── module_entry.dart
│   └── module_category.dart
├── shared/                # 共享能力
│   ├── multi_window/      # 多窗口能力封装
│   └── platform/          # 平台通道与系统能力封装
├── modules/               # 学习模块分区
│   ├── basic/             # 基础机制
│   ├── async/             # 异步并发
│   ├── state/             # 状态管理
│   ├── ui/                # UI 与动效
│   ├── popup_table/       # 弹窗与列表
│   └── platform/          # 网络与平台
```

教学模板组件由外部包 `flutter_study_learning` 提供（`LearningScaffold`、`LearningObjectives`、`ConceptChips`、`CodeSnippetCard`、`CommonPitfalls`、`ExerciseCard`、`StateLogView`）。

## 模块内部结构（推荐）

```
modules/<category>/<module>/
├── module_entry.dart       # 模块入口 Widget
├── module_routes.dart      # 子路由定义（有子路由时才需要）
├── AI_ANALYSIS.md          # 模块分析文档
├── presentation/           # UI 层（pages/ + widgets/）
├── application/            # 应用层（state/ + services/）
├── domain/                 # 领域层（models/）
└── data/                   # 数据层（api/ + parser/ + mock/）
```

简单模块可以保留精简版：
```
modules/basic/debounce_throttle/
├── module_entry.dart
├── module_root.dart
├── AI_ANALYSIS.md
└── utils/
```

## 添加新模块步骤

1. 在 `lib/modules/<category>/` 下创建模块目录 `lib/modules/<category>/my_module/`
2. 创建 `module_entry.dart`，导出 `MyModuleEntry` Widget
3. 在 `lib/app/router/app_route_table.dart` 中：
   - import 模块入口
   - 在 `_modules` 列表添加 `ModuleEntry`
4. 如需子路由，在模块内定义 `List<GoRoute>` 并在 `ModuleEntry.routes` 中传入

## 常用命令

```bash
flutter pub get          # 安装依赖
flutter run -d macos     # 运行 macOS 版本
flutter analyze          # 代码检查
dart format .            # 格式化
flutter build macos      # 构建 macOS 版本
```
