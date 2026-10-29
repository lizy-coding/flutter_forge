# 开发指南

## 环境要求

| 组件 | 版本 | 说明 |
|------|------|------|
| Flutter | 3.47.8 | 见 `.fvmrc` |
| Dart | 3.13.7 | 随 Flutter |
| Node.js | 24 | 见 `.nvmrc`（供 Agent 文档生成器） |
| Xcode | 26+ | 仅 macOS/iOS 构建 |
| Android SDK | 36+ | 仅 Android 构建 |

Flutter 3.47.8 / Dart 3.13.7 为当前安全修复基线（GHSA-frr6-h895-5pxp）。升级后必须重建应用，既有 Windows/Android 二进制不会因更新 SDK 自动修复。
`.fvmrc` 与各工作流固定版本保持一致。若现有全局 SDK 带本地补丁，应保留它并使用独立 SDK 验证；本轮隔离安装位于 `.release/toolchains/flutter-3.47.8`，运行项目命令前可设置：

```bash
export PATH="$PWD/.release/toolchains/flutter-3.47.8/bin:$PATH"
```

后续正式分发需依据实际新构建重新冻结 release plan，历史报告和已下载的安装包仍对应原工具链。

## 隐私说明维护

联网完整版的应用内来源为 `apps/flutter_forge/lib/app/full_privacy.dart`，从“关于”展开；公开页面为 `apps/flutter_forge/web/privacy.html`。
修改后运行 `python3 tool/export_privacy.py`，用 `python3 tool/export_privacy.py --check` 核对两端一致。
静态页面随 Web 构建提供，但本地生成不等于已部署；公开托管后核对实际 URL，再填写 Partner Center。
Android 离线版继续使用独立的 `offline_privacy.dart` / `privacy-offline.html`。

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
    ├── basic/                 # 基础机制 (6)
    ├── async/                 # 异步并发 (3)
    ├── state/                 # 状态管理 (3)
    ├── ui/                    # UI 与动效 (8)
    ├── popup_table/           # 弹窗与列表 (4)
    └── platform/              # 网络与平台 (9)

packages/
├── desktop_multi_window/      # 桌面多窗口宿主
├── file_picker_bridge/        # 文件选择桥接
├── flutter_battery/           # 电池监控
├── flutter_ioc_core/          # IoC 容器
├── forge_articles/            # 文章工作流
├── forge_scene_viewer/        # 3D 场景查看
├── usb_network_bridge/        # USB 网络桥接
└── video_player_win/          # Windows 视频播放

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
| `boundarylens scan apps/flutter_forge -c boundarylens.yaml` | BoundaryLens 按需扫描（孤儿文件等，各成员包同理） |

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
