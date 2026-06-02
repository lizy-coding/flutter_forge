# 整改计划

> 项目重构与代码质量提升计划。优先级从高到低排列。

## Phase 1 — 目录结构重构 ✅

**目标**: 从扁平 `lib/<module>/` 改为 `app/ + module_registry/ + shared/ + modules/<category>/` 层级。

**已完成**:
- [x] `app.dart` → `app/app.dart`
- [x] `router/` → `app/router/`
- [x] 新建 `module_registry/`，拆分 ModuleEntry 模型和枚举
- [x] 按 basic/async/state/ui/platform 分类迁移所有 15 个模块
- [x] 清理目录名（去掉 `_demo`/`_test` 后缀）
- [x] 更新所有 import 路径和文档

## Phase 2 — 共享能力归拢 ⏳

**目标**: 将已经暴露出跨模块价值的能力从具体学习模块中抽出，先归拢到 `lib/shared/`，等复用边界稳定后再考虑独立 Flutter plugin/package。

### 2.1 文件选择能力抽离

**背景**: `gcode_visualizer` 已接入 macOS 原生 `NSOpenPanel`，当前实现位于模块内，具备跨模块复用价值，但尚未证明需要独立发布。

**目标结构**:

```
lib/shared/platform/file_picker/
├── file_picker_service.dart          # 业务无关接口: PickedFile / FilePickerService
├── method_channel_file_picker.dart   # MethodChannel 实现
└── AI_ANALYSIS.md                    # shared 能力分析文档
```

**Dart API 草案**:

```dart
class PickedFile {
  const PickedFile({
    required this.path,
    this.name,
  });

  final String path;
  final String? name;
}

abstract class FilePickerService {
  Future<PickedFile?> pickFile({
    List<String> allowedExtensions = const [],
    String? title,
    String? message,
  });
}
```

**macOS 原生侧目标**:
- Channel 从 `flutter_study/gcode_file_picker` 调整为 `file_picker_bridge/file_picker`
- `pickFile` 支持 `allowedExtensions`、`title`、`message`
- 保留 `com.apple.security.files.user-selected.read-only`
- G-code 模块只传 G-code 扩展名，不再持有平台通道细节

**实施步骤**:
- [x] 新增 `lib/shared/platform/file_picker/` 共享能力目录
- [x] 将 `GcodeFilePicker` 改造成通用 `FilePickerService`
- [x] 调整 macOS `AppDelegate.swift` MethodChannel 名称和参数协议
- [x] `gcode_visualizer` 只依赖 shared file picker 接口
- [x] 删除模块内 `services/gcode_file_picker.dart`
- [x] 补充 shared 能力 `AI_ANALYSIS.md`
- [x] 为 MethodChannel service 增加可 mock 的单元测试

**暂不独立成插件包的原因**:
- 当前只有 macOS 实现，API 仍小
- 只有 `gcode_visualizer` 一个模块实际使用
- 独立 plugin 会引入额外的 package、registrant、Pods/Gradle 维护成本

**升级为独立 plugin/package 的触发条件**:
- 2 个以上模块稳定复用
- 需要 Windows/iOS/Android 文件选择实现
- 需要被其它工程复用
- 需要独立版本、测试、发布节奏

### 2.2 shared 能力治理

- [ ] 为 `lib/shared/learning/` 补充/更新 `AI_ANALYSIS.md`
- [ ] 为 `lib/shared/platform/` 建立边界: 只放跨平台/平台通道能力，不放具体业务解析逻辑
- [ ] 共享能力必须提供业务无关接口，模块只能传入业务参数
- [ ] 共享能力新增后必须至少被 1 个模块接入验证
- [ ] 若 shared 能力 3 个月内仍只有 1 个模块使用，保留在 shared，但不升级为独立插件

## Phase 3 — 模块内部规范化 ⏳

**目标**: 逐步统一模块内部分层（presentation/application/domain/data）。

- [ ] `popup_widgets` — 拆分 895 行 `module_root.dart` 为独立页面
- [ ] `debounce_throttle` — 迁移为 `module_entry + module_root + utils` 精简模式
- [ ] `status_management` — 保持 app/features/shared 分层，添加测试
- [ ] 所有模块补齐 `AI_ANALYSIS.md`（如有缺失）
- [x] `gcode_visualizer` — 文件选择器抽到 `shared/platform/file_picker` 后更新模块分析文档

## Phase 4 — 测试与质量 🔲

**目标**: 提升测试覆盖率和代码质量。

- [ ] 为无测试模块补充基础 Widget 测试
- [ ] 引入 lint 规则增强（如 `prefer_const_constructors`）
- [ ] `scroll_table` 和 `usb_detector` — 从 `ModuleStatus.pending` 提升到 `ready`
- [ ] 建立 shared 能力测试样例: MethodChannel mock、错误分支、取消选择分支
- [ ] FlutterGuard MED 项分批治理，优先处理 shared 与推荐模块

## Phase 5 — 教学体验 🔲

**目标**: 更多模块使用教学模板（`LearningScaffold`）。

- [ ] `adsorption_line` — 改造为教学页面
- [ ] `stream_subscription` — 改造为教学页面
- [ ] `download_animation` — 改造为教学页面

## Phase 6 — 项目整体归拢 🔲

**目标**: 从“模块集合”收敛为“可维护的学习平台”，统一入口、共享能力、模块质量和验收标准。

### 6.1 目录归拢

- [ ] `app/`: 只放应用壳、路由、主题入口，不放模块业务
- [ ] `module_registry/`: 只放模块元数据模型和枚举
- [ ] `shared/learning/`: 只放教学模板组件
- [ ] `shared/platform/`: 只放平台通道、系统能力、设备能力等业务无关服务
- [ ] `modules/<category>/<module>/`: 只放模块内业务、页面、状态、解析器和模块文档

### 6.2 模块质量分级

- [ ] `ModuleStatus.pending`: 有明显结构、文档、体验或质量缺口
- [ ] `ModuleStatus.ready`: 可独立学习，元数据完整，分析文档完整，基础验收通过
- [ ] `ModuleStatus.recommended`: 使用教学模板，交互完整，有测试覆盖，FlutterGuard 无新增 high

### 6.3 每轮重构验收

每次涉及代码调整后继续执行:

```bash
dart format .
flutter analyze
dart run flutterguard_cli:flutterguard scan --path . --fail-on high
```

按变更类型补充:
- 逻辑/解析器: 跑对应 `flutter test`
- macOS 原生改动: 跑 `flutter build macos`
- UI 教学页: 截图或人工验收说明

### 6.4 近期优先级

1. 补齐 shared file picker 错误分支测试和非 macOS 平台降级说明
2. `popup_widgets` 拆分大文件，降低 FlutterGuard MED/LOW 噪音
3. `stream_subscription` 和 `download_animation` 改造为教学模板
4. 建立 shared 能力测试模板，后续平台能力按同一模式接入
5. 对推荐模块逐步补齐截图或人工验收记录
