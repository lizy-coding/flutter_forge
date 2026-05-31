# AI 模块分析: flutter_ioc

> 自研 IoC 容器教学模块。IoC 核心逻辑已迁移到同级纯 Dart 包 `../flutter_ioc_core`，本模块保留 Provider 接入和计数器教学 UI。

## 文件结构

```
modules/state/flutter_ioc/
├── module_entry.dart       # 创建 flutter_ioc_core.Container 并注入 Provider
├── module_root.dart        # CounterScreen 教学 UI
├── model/counter_model.dart
└── AI_ANALYSIS.md
```

## 外部包依赖

| 包 | 用途 |
|---|---|
| `flutter_ioc_core` | Container、IoCContainer、生命周期、条件注册、属性注入 |

## 修改注意事项

1. IoC 容器能力变更应修改 `../flutter_ioc_core`。
2. 本模块只维护 Flutter/Provider 教学集成。
