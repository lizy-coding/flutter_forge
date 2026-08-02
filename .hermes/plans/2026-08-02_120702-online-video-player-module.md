# 在线视频播放模块落地计划 (online_video_player)

> 日期: 2026-08-02 | 阶段: planning | 状态: awaiting_execution
> 目标: 新增 platform 分类下的在线视频播放学习模块

## 1. 需求澄清（重要）

用户表述「flutter 官方 media_kit」有误，需要澄清：

| 插件 | 维护方 | 平台支持 | 说明 |
|------|--------|----------|------|
| media_kit 1.2.6 | 社区 (media-kit.dev, verified publisher) | Android/iOS/macOS/Windows/Linux/Web | 基于 libmpv，能力最全：HTTP 流、倍速、音量、seek、轨道、playlist |
| video_player | **Flutter 官方** (flutter/packages) | Android/iOS/Web 官方；macOS/Windows 需第三方适配 | 桌面端是坑，本项目当前宿主就是 macOS/Windows |

**结论: 选 media_kit。** 理由:
1. 本项目 `AI_PROJECT_CONTEXT.md` 声明 current_hosts=[macos, windows]、next_host=android —— media_kit 桌面+移动全覆盖
2. 用户需求「直接播放在线 http 托管视频流 + 基本参数操控」正是 media_kit 强项（Open/Play/Pause/Seek/Volume/Rate）
3. video_player 官方不维护桌面端，会立刻卡在 macOS 宿主上

## 2. 技术验证 (已完成)

- media_kit 1.2.6, media_kit_video 2.0.1, media_kit_libs_video 1.0.7 (pub.dev 核实)
- 平台矩阵: Android 5.0+, iOS 9+, macOS 10.9+, Windows 7+ ✅
- 示例在线视频: `https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4` (media_kit README 官方示例, GitHub 托管 http 直链)
- macOS 沙箱: 现有 entitlements 只有 `network.server`，**缺少 `network.client`**，在线视频必须补

## 3. 模块设计

```
lib/modules/platform/online_video_player/
├── module_entry.dart          # OnlineVideoPlayerEntry → MyHomePage
├── module_root.dart           # MyHomePage: LearningScaffold + interactiveDemo
├── widgets/
│   └── video_player_controls.dart  # 自定义控制条（播放/暂停/进度/音量/倍速）
├── state/
│   └── media_kit_player_adapter.dart  # Player 生命周期封装（可测试）
└── AI_ANALYSIS.md             # 生成物（勿手改）
```

路由: `/online-video-player` | 分类: platform | 难度: intermediate
标题: 「在线视频播放」 | subtitle: 「使用 media_kit 播放在线 HTTP 视频流并操控播放参数」

ModuleEntry 元数据:
- concepts: ['media_kit', '视频解码', 'HTTP 流', '播放控制', '倍速', 'Player 生命周期']
- estimatedMinutes: 35
- status: ModuleStatus.ready

教学组件（flutter_study_learning 包）: LearningScaffold + LearningObjectives + ConceptChips + CodeSnippetCard + CommonPitfalls + ExerciseCard（全部已有）

## 4. 落地步骤（执行顺序）

### Step 1: 依赖接入
- `pubspec.yaml` 增加:
  ```yaml
  media_kit: ^1.2.6
  media_kit_video: ^2.0.1
  media_kit_libs_video: ^1.0.7
  ```
- `flutter pub get` 验证解析（注意 workspace resolution 下依赖进根 pubspec.lock）

### Step 2: 宿主初始化
- `lib/app/app_bootstrap.dart` 在 `WidgetsFlutterBinding.ensureInitialized()` 后加 `MediaKit.ensureInitialized();`
  - 位置: bootstrapFlutterStudyApp() 内第一行之后（runApp 之前）

### Step 3: macOS 网络权限
- `macos/Runner/DebugProfile.entitlements` 和 `Release.entitlements` 增加:
  ```xml
  <key>com.apple.security.network.client</key>
  <true/>
  ```
- 只加 client（出站），不动 server（入站保持现状）

### Step 4: 模块代码
- 按 AGENTS.md 新模块规则创建上述 4 个文件
- 页面结构（仿 usb_detector/module_root.dart）:
  - interactiveDemo: 16:9 Video(controller) + 控制条（播放/暂停、seek 进度条、音量 Slider、倍速 0.5x~2.0x）
  - sections: LearningObjectives / ConceptChips / CodeSnippetCard / CommonPitfalls / ExerciseCard
- 状态封装: `MediaKitPlayerAdapter` 持 Player + VideoController，initState open 在线视频，dispose 释放；暴露 ValueListenable/Stream 给 UI
- 错误分支: open 失败/流不可达时展示错误状态，避免白屏

### Step 5: 路由注册
- `lib/app/router/app_route_table.dart`:
  - import `../../modules/platform/online_video_player/module_entry.dart`
  - `_modules` 中 platform 段追加 `ModuleEntry(...)`

### Step 6: 生成源更新（必须，禁止手改生成物）
- `tool/generate_agent_indexes.js`:
  - `modules` 数组追加 `['platform', 'online_video_player', '/online-video-player', 'ready', ['flutter_study_learning', 'media_kit', 'media_kit_video', 'module_registry']]`
  - `categoryMeta.platform` 的 children 追加 `'online_video_player'`
- 执行 `bash tool/generate_harness_ai_analysis.sh` 重新生成 40+ 契约

### Step 7: 测试
- `test/modules/platform/online_video_player/` widget test:
  - 控制条 UI 渲染（用 adapter 抽象，不真实起 Player 避免 CI 无 GPU/网络问题）
  - 播放/暂停按钮切换逻辑（mock adapter）
  - 失败态展示（open 失败 → 错误提示可见）
- 逻辑代码补充测试（AGENTS.md 要求）

### Step 8: 质量门禁
- `bash tool/quality_gate.sh` 全量 5 阶段
- 特别注意 flutterguard: 避免 HIGH（可变状态暴露等模式，参考现有 5 个 MEDIUM 先例）
- UI 教学页人工验收或截图（AGENTS.md 要求）

## 5. 风险与对策

| 风险 | 影响 | 对策 |
|------|------|------|
| CI (ubuntu) 无 GPU/网络，Player 真实播放失败 | 测试红灯 | widget test 全部走 adapter mock，不 new 真实 Player |
| media_kit_libs_video 体积大 (libmpv) | 构建变慢 | 仅 debug 验证，CI 不 build app 只 analyze+test |
| macOS 沙箱无 network.client | 播放必然失败 | Step 3 补齐 entitlements |
| workspace 下 flutterguard_cli path 依赖 | 已有基线 | 不触碰，保持现状 |
| Android host 尚未创建 | 模块暂无法在 Android 验证 | 模块代码保持平台无关，Android 验证归入 android_host 队列 |

## 6. 验收标准

- [ ] `flutter analyze` 0 error
- [ ] `dart format .` 无漂移
- [ ] `bash tool/quality_gate.sh` 5/5 通过
- [ ] 新模块在首页可见，路由 `/online-video-player` 可达
- [ ] macOS 真机（本机）能播放在线 mp4，控制条可操控
- [ ] `AI_MODULE_INDEX.md` 更新（生成物自动），count 17→18
- [ ] 无 HIGH flutterguard 问题

## 7. 执行方式

按本计划 Step 1→8 顺序执行；每步完成后核对 AGENTS.md 验收规则。
