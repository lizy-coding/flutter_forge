#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT="$(cd "$ROOT/.." && pwd)"
FORCE="${1:-}"

PACKAGES=(
  "gcode_core"
  "flutter_study_learning"
  "flutter_study_platform_file_picker"
  "flutter_ioc_core"
)

if [[ ! -d "$ROOT/lib/modules/ui/gcode_visualizer/application" ]]; then
  echo "Migration source directories are not present. The sibling package migration appears to have already been applied." >&2
  echo "Refusing to re-run to avoid overwriting the migrated sibling packages from incomplete in-app sources." >&2
  exit 1
fi

if [[ "$FORCE" != "--force" ]]; then
  for package in "${PACKAGES[@]}"; do
    if [[ -e "$PARENT/$package" ]]; then
      echo "Refusing to overwrite $PARENT/$package. Re-run with --force." >&2
      exit 1
    fi
  done
fi

for package in "${PACKAGES[@]}"; do
  if [[ "$FORCE" == "--force" ]]; then
    rm -rf "$PARENT/$package"
  fi
done

mkdir -p "$PARENT/gcode_core/lib/src" "$PARENT/gcode_core/test/application"
cp -R "$ROOT/lib/modules/ui/gcode_visualizer/application" "$PARENT/gcode_core/lib/src/"
cp -R "$ROOT/lib/modules/ui/gcode_visualizer/data" "$PARENT/gcode_core/lib/src/"
cp -R "$ROOT/lib/modules/ui/gcode_visualizer/domain" "$PARENT/gcode_core/lib/src/"
cp -R "$ROOT/lib/modules/ui/gcode_visualizer/models" "$PARENT/gcode_core/lib/src/"
cp -R "$ROOT/lib/modules/ui/gcode_visualizer/parser" "$PARENT/gcode_core/lib/src/"
cp -R "$ROOT/lib/modules/ui/gcode_visualizer/services" "$PARENT/gcode_core/lib/src/"
cp "$ROOT/test/gcode_visualizer/gcode_parser_test.dart" "$PARENT/gcode_core/test/"
cp "$ROOT/test/gcode_visualizer/toolpath_builder_test.dart" "$PARENT/gcode_core/test/"
cp "$ROOT/test/gcode_visualizer/application/gcode_readline_pipeline_test.dart" "$PARENT/gcode_core/test/application/"

cat > "$PARENT/gcode_core/pubspec.yaml" <<'EOF'
name: gcode_core
description: Pure Dart G-code parsing, line reading, and toolpath building core.
publish_to: 'none'
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0
EOF

cat > "$PARENT/gcode_core/lib/gcode_core.dart" <<'EOF'
library gcode_core;

export 'src/application/gcode_readline_pipeline.dart';
export 'src/data/readers/file_gcode_line_reader.dart';
export 'src/data/readers/gcode_line_reader.dart';
export 'src/data/readers/string_gcode_line_reader.dart';
export 'src/domain/gcode_line_record.dart';
export 'src/domain/gcode_load_snapshot.dart';
export 'src/domain/gcode_load_stage.dart';
export 'src/domain/parsed_gcode_line.dart';
export 'src/models/gcode_command.dart';
export 'src/models/machine_position.dart';
export 'src/models/toolpath_segment.dart';
export 'src/parser/gcode_parse_result.dart';
export 'src/parser/gcode_parser.dart';
export 'src/services/toolpath_builder.dart';
EOF

cat > "$PARENT/gcode_core/README.md" <<'EOF'
# gcode_core

Pure Dart G-code core extracted from `flutter_study`.

## Scope

- Read G-code from strings or files line by line.
- Parse G0/G1 commands with X/Y/F parameters.
- Collect parse errors with line metadata.
- Build incremental or batch toolpath segments.

This package contains no Flutter UI, animation, canvas drawing, or file picker code.

## Test

```bash
dart test
```
EOF

cat > "$PARENT/gcode_core/AI_ANALYSIS.md" <<'EOF'
# gcode_core 分析

> 纯 Dart G-code 解析与轨迹构建核心。

## 功能目标

把 G-code 文本/文件读取、单行解析、错误收集和刀路段构建从 Flutter UI 模块中拆出，供教学 UI、CLI 或其它可视化前端复用。

## 文件结构

```
gcode_core/
├── lib/
│   ├── gcode_core.dart
│   └── src/
│       ├── application/gcode_readline_pipeline.dart
│       ├── data/readers/
│       ├── domain/
│       ├── models/
│       ├── parser/
│       └── services/toolpath_builder.dart
└── test/
```

## 边界

- 不依赖 Flutter。
- 不打开系统文件选择器。
- 不绘制 Canvas。
- 不管理播放动画。
EOF

perl -0pi -e "s/import 'package:flutter_test\/flutter_test.dart';/import 'package:test\/test.dart';/g" \
  "$PARENT/gcode_core/test/gcode_parser_test.dart" \
  "$PARENT/gcode_core/test/toolpath_builder_test.dart" \
  "$PARENT/gcode_core/test/application/gcode_readline_pipeline_test.dart"
perl -0pi -e "s/import 'package:main_app\/modules\/ui\/gcode_visualizer\/(?:application|data\/readers|domain|models|parser|services)\/[^']+';/import 'package:gcode_core\/gcode_core.dart';/g" \
  "$PARENT/gcode_core/test/gcode_parser_test.dart" \
  "$PARENT/gcode_core/test/toolpath_builder_test.dart" \
  "$PARENT/gcode_core/test/application/gcode_readline_pipeline_test.dart"
perl -0pi -e "s/(import 'package:gcode_core\/gcode_core.dart';\n)+/import 'package:gcode_core\/gcode_core.dart';\n/g" \
  "$PARENT/gcode_core/test/gcode_parser_test.dart" \
  "$PARENT/gcode_core/test/toolpath_builder_test.dart" \
  "$PARENT/gcode_core/test/application/gcode_readline_pipeline_test.dart"

mkdir -p "$PARENT/flutter_study_learning/lib/src"
cp "$ROOT/lib/shared/learning/learning_scaffold.dart" "$PARENT/flutter_study_learning/lib/src/learning_scaffold.dart"
cat > "$PARENT/flutter_study_learning/pubspec.yaml" <<'EOF'
name: flutter_study_learning
description: Shared learning scaffold widgets for Flutter study modules.
publish_to: 'none'
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
EOF
cat > "$PARENT/flutter_study_learning/lib/flutter_study_learning.dart" <<'EOF'
library flutter_study_learning;

export 'src/learning_scaffold.dart';
EOF
cat > "$PARENT/flutter_study_learning/README.md" <<'EOF'
# flutter_study_learning

Shared teaching page widgets for Flutter study modules.

## Scope

- `LearningScaffold`
- Learning objectives, concept chips, code snippets, state logs, pitfalls, and exercise cards

This package has no module-specific business logic.
EOF
cat > "$PARENT/flutter_study_learning/AI_ANALYSIS.md" <<'EOF'
# flutter_study_learning 分析

> Flutter 学习模块的共享教学页面组件包。

## 边界

只承载教学表达组件，不持有任何模块状态、解析器、网络请求或平台能力。
EOF

mkdir -p "$PARENT/flutter_study_platform_file_picker/lib/src" "$PARENT/flutter_study_platform_file_picker/test"
cp "$ROOT/lib/shared/platform/file_picker/file_picker_service.dart" "$PARENT/flutter_study_platform_file_picker/lib/src/"
cp "$ROOT/lib/shared/platform/file_picker/method_channel_file_picker.dart" "$PARENT/flutter_study_platform_file_picker/lib/src/"
cp "$ROOT/test/shared/platform/file_picker/method_channel_file_picker_test.dart" "$PARENT/flutter_study_platform_file_picker/test/"
cat > "$PARENT/flutter_study_platform_file_picker/pubspec.yaml" <<'EOF'
name: flutter_study_platform_file_picker
description: MethodChannel file picker API used by Flutter study modules.
publish_to: 'none'
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
EOF
cat > "$PARENT/flutter_study_platform_file_picker/lib/flutter_study_platform_file_picker.dart" <<'EOF'
library flutter_study_platform_file_picker;

export 'src/file_picker_service.dart';
export 'src/method_channel_file_picker.dart';
EOF
cat > "$PARENT/flutter_study_platform_file_picker/README.md" <<'EOF'
# flutter_study_platform_file_picker

Business-neutral file picker API for Flutter study modules.

Current host implementation is registered by `main_app` on macOS through the `flutter_study/file_picker` MethodChannel. This package owns the Dart API and mock-friendly channel implementation; it can be upgraded into a full Flutter plugin when more platforms are needed.
EOF
cat > "$PARENT/flutter_study_platform_file_picker/AI_ANALYSIS.md" <<'EOF'
# flutter_study_platform_file_picker 分析

> 文件选择能力包，当前承载 Dart API 和 MethodChannel 客户端。

## 平台协议

- Channel: `flutter_study/file_picker`
- Method: `pickFile`
- 返回: `null` 或 `{ path: String, name: String? }`

## 迁移状态

macOS 原生实现仍在宿主应用 `macos/Runner/AppDelegate.swift` 中注册。后续若升级为完整 Flutter plugin，再迁移原生代码。
EOF
perl -0pi -e "s#import 'package:main_app/shared/platform/file_picker/method_channel_file_picker.dart';#import 'package:flutter_study_platform_file_picker/flutter_study_platform_file_picker.dart';#g" \
  "$PARENT/flutter_study_platform_file_picker/test/method_channel_file_picker_test.dart"

mkdir -p "$PARENT/flutter_ioc_core/lib/src"
cp "$ROOT/lib/modules/state/flutter_ioc/ioc/container.dart" "$PARENT/flutter_ioc_core/lib/src/"
cp "$ROOT/lib/modules/state/flutter_ioc/ioc/types.dart" "$PARENT/flutter_ioc_core/lib/src/"
cat > "$PARENT/flutter_ioc_core/pubspec.yaml" <<'EOF'
name: flutter_ioc_core
description: Pure Dart IoC container core extracted from Flutter study.
publish_to: 'none'
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dev_dependencies:
  test: ^1.25.0
  lints: ^4.0.0
EOF
cat > "$PARENT/flutter_ioc_core/lib/flutter_ioc_core.dart" <<'EOF'
library flutter_ioc_core;

export 'src/container.dart';
export 'src/types.dart';
EOF
cat > "$PARENT/flutter_ioc_core/README.md" <<'EOF'
# flutter_ioc_core

Pure Dart IoC container extracted from the Flutter IoC teaching module.
EOF
cat > "$PARENT/flutter_ioc_core/AI_ANALYSIS.md" <<'EOF'
# flutter_ioc_core 分析

> 教学用 IoC 容器核心，支持 singleton/transient/scoped 生命周期、条件注册、属性注入和作用域。

不依赖 Flutter。
EOF

perl -0pi -e "s/\n  gcode_core:\n    path: \.\.\/gcode_core\n//g; s/\n  flutter_study_learning:\n    path: \.\.\/flutter_study_learning\n//g; s/\n  flutter_study_platform_file_picker:\n    path: \.\.\/flutter_study_platform_file_picker\n//g; s/\n  flutter_ioc_core:\n    path: \.\.\/flutter_ioc_core\n//g" "$ROOT/pubspec.yaml"
perl -0pi -e "s/dependencies:\n/dependencies:\n  gcode_core:\n    path: ..\/gcode_core\n  flutter_study_learning:\n    path: ..\/flutter_study_learning\n  flutter_study_platform_file_picker:\n    path: ..\/flutter_study_platform_file_picker\n  flutter_ioc_core:\n    path: ..\/flutter_ioc_core\n/" "$ROOT/pubspec.yaml"

perl -0pi -e "s#import '../../../../shared/learning/learning_scaffold.dart';#import 'package:flutter_study_learning/flutter_study_learning.dart';#g" \
  "$ROOT/lib/modules/ui/gcode_visualizer/pages/gcode_visualizer_page.dart" \
  "$ROOT/lib/modules/basic/tree_state/pages/basic_widgets_page.dart"
perl -0pi -e "s#import '../domain/gcode_load_stage.dart';#import 'package:gcode_core/gcode_core.dart';#g" \
  "$ROOT/lib/modules/ui/gcode_visualizer/pages/gcode_visualizer_page.dart"
perl -0pi -e "s#import '../../../../shared/platform/file_picker/file_picker_service.dart';\nimport '../../../../shared/platform/file_picker/method_channel_file_picker.dart';\nimport '../application/gcode_readline_pipeline.dart';\nimport '../data/readers/file_gcode_line_reader.dart';\nimport '../data/readers/gcode_line_reader.dart';\nimport '../data/readers/string_gcode_line_reader.dart';\nimport '../domain/gcode_load_stage.dart';\nimport '../models/toolpath_segment.dart';\nimport '../parser/gcode_parse_result.dart';#import 'package:flutter_study_platform_file_picker/flutter_study_platform_file_picker.dart';\nimport 'package:gcode_core/gcode_core.dart';#s" \
  "$ROOT/lib/modules/ui/gcode_visualizer/state/gcode_player_controller.dart"
perl -0pi -e "s#import '../models/gcode_command.dart';\nimport '../models/toolpath_segment.dart';#import 'package:gcode_core/gcode_core.dart';#s" \
  "$ROOT/lib/modules/ui/gcode_visualizer/widgets/gcode_canvas.dart"
perl -0pi -e "s#import '../models/gcode_command.dart';\nimport '../parser/gcode_parse_result.dart';#import 'package:gcode_core/gcode_core.dart';#s" \
  "$ROOT/lib/modules/ui/gcode_visualizer/widgets/command_timeline.dart"
cat > "$ROOT/lib/modules/ui/gcode_visualizer/gcode_readline.dart" <<'EOF'
export 'package:gcode_core/gcode_core.dart';
EOF
perl -0pi -e "s#import 'ioc/ioc.dart' as ioc;#import 'package:flutter_ioc_core/flutter_ioc_core.dart' as ioc;#g" \
  "$ROOT/lib/modules/state/flutter_ioc/module_entry.dart"

perl -0pi -e "s/import 'package:main_app\/modules\/ui\/gcode_visualizer\/(?:application|data\/readers|domain|models|parser|services)\/[^']+';/import 'package:gcode_core\/gcode_core.dart';/g" \
  "$ROOT/test/gcode_visualizer/gcode_parser_test.dart" \
  "$ROOT/test/gcode_visualizer/toolpath_builder_test.dart" \
  "$ROOT/test/gcode_visualizer/application/gcode_readline_pipeline_test.dart"
perl -0pi -e "s/(import 'package:gcode_core\/gcode_core.dart';\n)+/import 'package:gcode_core\/gcode_core.dart';\n/g" \
  "$ROOT/test/gcode_visualizer/gcode_parser_test.dart" \
  "$ROOT/test/gcode_visualizer/toolpath_builder_test.dart" \
  "$ROOT/test/gcode_visualizer/application/gcode_readline_pipeline_test.dart"
perl -0pi -e "s#import 'package:main_app/shared/platform/file_picker/method_channel_file_picker.dart';#import 'package:flutter_study_platform_file_picker/flutter_study_platform_file_picker.dart';#g" \
  "$ROOT/test/shared/platform/file_picker/method_channel_file_picker_test.dart"

rm -rf "$ROOT/lib/modules/ui/gcode_visualizer/application" \
       "$ROOT/lib/modules/ui/gcode_visualizer/data" \
       "$ROOT/lib/modules/ui/gcode_visualizer/domain" \
       "$ROOT/lib/modules/ui/gcode_visualizer/models" \
       "$ROOT/lib/modules/ui/gcode_visualizer/parser" \
       "$ROOT/lib/modules/ui/gcode_visualizer/services" \
       "$ROOT/lib/modules/state/flutter_ioc/ioc" \
       "$ROOT/lib/shared/learning" \
       "$ROOT/lib/shared/platform/file_picker"
rm -rf "$ROOT/test/shared/platform/file_picker"

cat > "$ROOT/lib/modules/ui/gcode_visualizer/AI_ANALYSIS.md" <<'EOF'
# G-code Visualizer 模块分析

> G-code 解析与轨迹动画演示模块。纯解析与轨迹构建逻辑已迁移到同级包 `../gcode_core`，本模块只保留 Flutter 教学 UI、状态编排和绘制交互。

## 功能目标

调用 `gcode_core` 将 G-code 文本或文件解析为轨迹段，并通过 CustomPaint、AnimationController 和教学模板展示 G0/G1 刀路执行过程。

## 文件结构

```
modules/ui/gcode_visualizer/
├── module_entry.dart              # 入口: 返回 GcodeVisualizerPage
├── AI_ANALYSIS.md                 # 模块分析文档
├── gcode_readline.dart            # 兼容导出: export package:gcode_core/gcode_core.dart
├── pages/
│   └── gcode_visualizer_page.dart # 教学页面，依赖 flutter_study_learning
├── state/
│   └── gcode_player_controller.dart # ChangeNotifier + AnimationController，编排解析、文件选择和播放
└── widgets/
    ├── command_timeline.dart      # 指令列表，高亮当前执行行
    ├── gcode_canvas.dart          # CustomPaint 轨迹画布
    ├── gcode_editor_panel.dart    # 编辑器 + 文件路径输入/选择/提取按钮
    └── playback_controls.dart     # 播放/暂停/重置/进度/速度控制
```

## 外部包依赖

| 包 | 用途 |
|---|---|
| `gcode_core` | G-code 读取、解析、错误收集、轨迹构建 |
| `flutter_study_learning` | 教学页面模板组件 |
| `flutter_study_platform_file_picker` | 文件选择 Dart API，macOS 原生通道仍由宿主应用注册 |

## 数据流

```
source text / path input / file picker
  -> gcode_core GcodeLineReader
  -> gcode_core GcodeReadlinePipeline
  -> GcodePlayerController
  -> GcodeCanvas / CommandTimeline / PlaybackControls
```

## 修改注意事项

1. 新增 G-code 语法、reader 或 toolpath 规则时修改 `../gcode_core`。
2. 本模块只处理 Flutter UI、播放状态和教学表达。
3. 文件选择能力来自 `flutter_study_platform_file_picker`，模块只传入 G-code 扩展名和弹窗文案。
4. 教学页面组件来自 `flutter_study_learning`。
EOF

cat > "$ROOT/lib/shared/AI_ANALYSIS.md" <<'EOF'
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
EOF

cat > "$ROOT/lib/shared/platform/AI_ANALYSIS.md" <<'EOF'
# Platform 共享层分析

> 平台能力正在从主应用 shared 层迁移到同级 package。

## 当前能力

| 能力 | 包 | 宿主原生实现 |
|---|---|---|
| 文件选择 | `../flutter_study_platform_file_picker` | macOS `AppDelegate.swift` 注册 `flutter_study/file_picker` |

## 后续计划

当需要 Windows/iOS/Android 文件选择实现时，将 `flutter_study_platform_file_picker` 从 Dart API package 升级为完整 Flutter plugin，并迁移 macOS 原生实现。
EOF

cat > "$ROOT/lib/modules/state/flutter_ioc/AI_ANALYSIS.md" <<'EOF'
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
EOF

perl -0pi -e 's#lib/shared/learning/learning_scaffold.dart#package:flutter_study_learning#g; s#`lib/shared/platform/file_picker/`#`../flutter_study_platform_file_picker`#g; s#`shared/platform/file_picker/`#`../flutter_study_platform_file_picker`#g' \
  "$ROOT/README.md" "$ROOT/AI_PROJECT_CONTEXT.md" "$ROOT/REFACTOR_PLAN.md" "$ROOT/PLUGIN_DECOMPOSITION_PLAN.md" "$ROOT/lib/modules/basic/tree_state/AI_ANALYSIS.md"

echo "Sibling package migration completed."
