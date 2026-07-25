# 开发指南

## 环境要求

| 组件 | 版本 | 说明 |
|------|------|------|
| Flutter | 3.44.6 | 见 `.fvmrc` |
| Dart | 3.12.2 | 随 Flutter |
| Node.js | 20.20.2 | 见 `.nvmrc`（供 Agent 文档生成器） |
| Xcode | 26+ | 仅 macOS/iOS 构建 |
| Android SDK | 36+ | 仅 Android 构建 |

## 快速开始

```bash
# 1. 自举
bash tool/bootstrap.sh

# 2. 运行应用
flutter run

# 3. 质量门禁（提交前必跑）
bash tool/quality_gate.sh
```

## 项目结构

```
lib/
├── main.dart                  # 入口
├── app/                       # 应用壳 + 路由
│   ├── app_bootstrap.dart     # 宿主引导
│   ├── app.dart               # MaterialApp.router
│   └── router/                # go_router 路由表
├── module_registry/           # 模块元数据
│   ├── module_entry.dart      # ModuleEntry 数据类
│   └── module_category.dart   # 枚举定义
├── shared/                    # 业务无关能力
│   ├── multi_window/          # 桌面多窗口
│   └── platform/              # 平台边界
└── modules/                   # 学习模块
    ├── basic/                 # 基础机制 (3)
    ├── async/                 # 异步并发 (3)
    ├── state/                 # 状态管理 (2)
    ├── ui/                    # UI 与动效 (3)
    ├── popup_table/           # 弹窗与列表 (4)
    └── platform/              # 网络与平台 (2)

packages/
├── gcode_core/                # G-code 解析
├── flutter_study_learning/    # 教学模板组件
├── file_picker_bridge/        # 文件选择桥接
└── flutter_ioc_core/          # IoC 容器

tool/
├── bootstrap.sh               # 环境自举
├── quality_gate.sh            # 全量质量门禁
├── test_all.sh                # 全量测试
├── check_environment.sh       # 环境检查
├── generate_agent_indexes.js  # Agent 文档生成器
├── validate_agent_docs.js     # Agent 文档校验器
└── generate_harness_ai_analysis.sh # 生成+校验入口
```

## 常用命令

| 命令 | 说明 |
|------|------|
| `bash tool/bootstrap.sh` | 环境自举 |
| `bash tool/quality_gate.sh` | 全量质量门禁（提交前必跑） |
| `bash tool/test_all.sh` | 全量测试 |
| `flutter run` | 启动应用 |
| `flutter analyze` | 静态分析 |
| `dart format .` | 格式化 |
| `dart run flutterguard_cli:flutterguard scan . --fail-on high` | 安全扫描 |

## 故障排查

### 依赖解析失败
```bash
flutter clean
flutter pub get
```

### Agent 文档校验失败
```bash
bash tool/generate_harness_ai_analysis.sh
```

### Git hooks 未生效
```bash
git config core.hooksPath .githooks
```
