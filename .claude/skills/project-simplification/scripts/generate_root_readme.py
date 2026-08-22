#!/usr/bin/env python3
"""
Generate root README file with all module information.
"""

import os
import json
from datetime import datetime

# Root README template
ROOT_README_TEMPLATE = """# Flutter 学习示例集合

> 一个包含多个 Flutter 示例模块的学习项目，涵盖状态管理、动画、网络请求、异步编程等核心知识点。

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev/)

## 📚 项目概述

本项目是一个 Flutter 学习示例集合，包含 **{module_count} 个独立模块**，每个模块专注于特定的 Flutter 功能或概念。

### 项目统计

- **模块数量**: {module_count} 个
- **总文件数**: {total_files} 个
- **代码总量**: {total_lines:,} 行
- **最后更新**: {update_date}

## 🎯 模块列表

{module_list}

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.x 或更高版本
- Dart SDK 3.x 或更高版本
- Android Studio / VS Code / IntelliJ IDEA

### 安装步骤

1. **克隆项目**

```bash
git clone <repository-url>
cd flutter_forge
```

2. **安装依赖**

```bash
flutter pub get
```

3. **运行项目**

```bash
flutter run
```

4. **选择模块**

在应用主页选择你想要查看的示例模块。

## 📖 模块分类

### UI & 动画
{ui_modules}

### 异步 & 并发
{async_modules}

### 架构 & 状态
{arch_modules}

### 网络 & 平台
{network_modules}

## 💡 学习路径

### 初学者路径
1. **{beginner_1}** - 基础概念
2. **{beginner_2}** - UI 组件
3. **{beginner_3}** - 状态管理入门

### 进阶路径
1. **{advanced_1}** - 高级状态管理
2. **{advanced_2}** - 性能优化
3. **{advanced_3}** - 架构设计

## 🛠️ 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart 3.x
- **路由**: GoRouter
- **状态管理**: Provider, Riverpod, BLoC
- **网络**: Dio
- **其他**: {other_deps}

## 📁 项目结构

```
flutter_forge/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── app.dart                  # App 配置
│   ├── router/                   # 路由配置
│   │   ├── app_router.dart
│   │   └── app_route_table.dart  # 统一路由表
│   ├──{module_structure}
├── .claude/                      # Claude Code 配置
│   └── skills/
│       └── project-simplification/  # 项目简化 Skill
├── PROJECT_SIMPLIFICATION_WORKFLOW.md
├── pubspec.yaml                  # 依赖配置
└── README.md                     # 本文件
```

## 🔧 开发工具

### Claude Code Skill

本项目包含自定义的 Claude Code Skill，用于项目简化和维护：

```bash
# 使用 Skill 分析项目
"Simplify my Flutter project"
"Analyze my project structure"
"Find redundant documentation"
```

详见 [PROJECT_SIMPLIFICATION_WORKFLOW.md](PROJECT_SIMPLIFICATION_WORKFLOW.md)

### 常用命令

```bash
# 代码分析
flutter analyze

# 格式化代码
dart format lib/

# 运行测试
flutter test

# 构建 APK
flutter build apk

# 清理缓存
flutter clean
```

## 📚 学习资源

### 官方文档
- [Flutter 官方文档](https://flutter.dev/docs)
- [Dart 官方文档](https://dart.dev/guides)
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)

### 推荐阅读
- [Flutter 实战](https://book.flutterchina.club/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

### 贡献步骤

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 代码规范

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 风格指南
- 使用 `dart format` 格式化代码
- 通过 `flutter analyze` 检查
- 为新功能添加示例和文档

## 📝 更新日志

### {update_date}
- 项目结构优化
- 添加 {module_count} 个示例模块
- 完善文档和注释
- 添加项目简化工具

详见各模块的 README.md 文件。

## 📄 许可证

本项目仅用于学习目的。

## 📮 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue
- 发起 Discussion

---

**最后更新**: {update_date}
**生成工具**: Claude Code Project Simplification Skill
"""

def categorize_modules(modules):
    """Categorize modules by functionality."""
    categories = {
        'ui': [],
        'async': [],
        'arch': [],
        'network': []
    }

    ui_keywords = ['widget', 'animation', 'pop', 'scroll', 'download', 'paint', 'tree']
    async_keywords = ['isolate', 'stream', 'debounce', 'throttle', 'microtask']
    arch_keywords = ['ioc', 'status', 'state', 'manage']
    network_keywords = ['interceptor', 'http', 'api', 'usb', 'detector']

    for module_name, module_info in modules.items():
        module_lower = module_name.lower()
        desc_lower = module_info.get('description', '').lower()

        if any(keyword in module_lower or keyword in desc_lower for keyword in ui_keywords):
            categories['ui'].append(module_name)
        elif any(keyword in module_lower or keyword in desc_lower for keyword in async_keywords):
            categories['async'].append(module_name)
        elif any(keyword in module_lower or keyword in desc_lower for keyword in arch_keywords):
            categories['arch'].append(module_name)
        elif any(keyword in module_lower or keyword in desc_lower for keyword in network_keywords):
            categories['network'].append(module_name)
        else:
            categories['ui'].append(module_name)  # Default to UI

    return categories

def generate_root_readme(modules):
    """Generate root README content."""

    # Calculate statistics
    total_files = sum(m.get('file_count', 0) for m in modules.values())
    total_lines = sum(m.get('line_count', 0) for m in modules.values())
    module_count = len(modules)

    # Categorize modules
    categories = categorize_modules(modules)

    # Generate module list
    module_list_items = []
    for i, (module_name, module_info) in enumerate(sorted(modules.items()), 1):
        desc = module_info.get('description', '')
        files = module_info.get('file_count', 0)
        lines = module_info.get('line_count', 0)

        module_list_items.append(
            f"{i}. **[{module_name}](lib/{module_name}/README.md)** - {desc} "
            f"({files} 文件, {lines:,} 行)"
        )

    module_list = "\n".join(module_list_items)

    # Generate category sections
    def format_category_modules(module_names):
        if not module_names:
            return "- 暂无"
        items = []
        for name in sorted(module_names):
            desc = modules[name].get('description', '')
            items.append(f"- **[{name}](lib/{name}/README.md)** - {desc}")
        return "\n".join(items)

    ui_modules = format_category_modules(categories['ui'])
    async_modules = format_category_modules(categories['async'])
    arch_modules = format_category_modules(categories['arch'])
    network_modules = format_category_modules(categories['network'])

    # Learning paths
    all_modules = list(modules.keys())
    beginner_modules = all_modules[:3] if len(all_modules) >= 3 else all_modules + [''] * (3 - len(all_modules))
    advanced_modules = all_modules[3:6] if len(all_modules) >= 6 else all_modules[3:] + [''] * (3 - len(all_modules) + 3)

    # Collect unique dependencies
    all_deps = set()
    for module_info in modules.values():
        all_deps.update(module_info.get('dependencies', []))

    common_deps = {'provider', 'riverpod', 'bloc', 'dio', 'go_router'}
    other_deps = ', '.join(sorted(all_deps - common_deps)[:5])
    if not other_deps:
        other_deps = "flutter_svg, collection, equatable"

    # Generate module structure sample
    sample_modules = list(modules.keys())[:3]
    module_structure = ""
    for mod in sample_modules:
        module_structure += f"\n│   ├── {mod}/                 # {modules[mod].get('description', '')[:30]}..."

    # Fill template
    readme_content = ROOT_README_TEMPLATE.format(
        module_count=module_count,
        total_files=total_files,
        total_lines=total_lines,
        update_date=datetime.now().strftime("%Y-%m-%d"),
        module_list=module_list,
        ui_modules=ui_modules,
        async_modules=async_modules,
        arch_modules=arch_modules,
        network_modules=network_modules,
        beginner_1=beginner_modules[0],
        beginner_2=beginner_modules[1],
        beginner_3=beginner_modules[2],
        advanced_1=advanced_modules[0],
        advanced_2=advanced_modules[1],
        advanced_3=advanced_modules[2],
        other_deps=other_deps,
        module_structure=module_structure
    )

    return readme_content

def main():
    # Load module descriptions
    if not os.path.exists('module_descriptions.json'):
        print("Error: module_descriptions.json not found!")
        print("Please run generate_module_descriptions.py first.")
        return

    with open('module_descriptions.json', 'r', encoding='utf-8') as f:
        modules = json.load(f)

    print("=" * 70)
    print("Generating Root README")
    print("=" * 70)

    # Generate README content
    readme_content = generate_root_readme(modules)

    # Write to file
    readme_path = "README.md"
    try:
        with open(readme_path, 'w', encoding='utf-8') as f:
            f.write(readme_content)
        print(f"\n✓ Generated: {readme_path}")
        print(f"✓ Modules included: {len(modules)}")
        print(f"✓ Total lines: {sum(m.get('line_count', 0) for m in modules.values()):,}")
    except Exception as e:
        print(f"\n✗ Error generating {readme_path}: {e}")

    print("\n" + "=" * 70)
    print("✓ Root README generation complete")
    print("=" * 70)

if __name__ == '__main__':
    main()
