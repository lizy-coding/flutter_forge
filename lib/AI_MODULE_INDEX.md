# AI 模块索引

> 此文件描述 lib/ 下所有模块的结构，AI 修改模块代码前请查阅对应模块的 AI_ANALYSIS.md。

## 模块列表

| 模块 | 路径 | 路由路径 | 状态管理 | 复杂度 | AI 分析文件 |
|------|------|---------|---------|--------|------------|
| adsorption_line | `modules/ui/adsorption_line` | /adsorption-line | ChangeNotifier + Provider | 高 | `modules/ui/adsorption_line/AI_ANALYSIS.md` |
| debounce_throttle | `modules/basic/debounce_throttle` | /debounce-throttle | StatefulWidget | 低 | `modules/basic/debounce_throttle/AI_ANALYSIS.md` |
| download_animation | `modules/ui/download_animation` | /download-animation | StatefulWidget | 中 | `modules/ui/download_animation/AI_ANALYSIS.md` |
| flutter_ioc | `modules/state/flutter_ioc` | /flutter-ioc | 自研 IoC + Provider | 中 | `modules/state/flutter_ioc/AI_ANALYSIS.md` |
| gcode_visualizer | `modules/ui/gcode_visualizer` | /gcode-visualizer | ChangeNotifier + AnimationController | 高 | `modules/ui/gcode_visualizer/AI_ANALYSIS.md` |
| dio_interceptor | `modules/platform/dio_interceptor` | /dio-interceptor | 无（Dio 拦截器） | 中 | `modules/platform/dio_interceptor/AI_ANALYSIS.md` |
| isolate_task_manager | `modules/async/isolate_task_manager` | /isolate-stream | StatefulWidget | 中 | `modules/async/isolate_task_manager/AI_ANALYSIS.md` |
| isolate_basic | `modules/async/isolate_basic` | /isolate-basic | StatefulWidget | 低 | `modules/async/isolate_basic/AI_ANALYSIS.md` |
| microtask | `modules/basic/microtask` | /microtask | StatefulWidget | 低 | `modules/basic/microtask/AI_ANALYSIS.md` |
| popup_widgets | `modules/popup_table/popup_widgets` | /popup-widgets | StatefulWidget | 中 | `modules/popup_table/popup_widgets/AI_ANALYSIS.md` |
| popup_list_interaction | `modules/popup_table/popup_list_interaction` | /popup-list-interaction | StatefulWidget | 低 | `modules/popup_table/popup_list_interaction/AI_ANALYSIS.md` |
| scroll_table | `modules/popup_table/scroll_table` | /scroll-table | 无 | 低 | `modules/popup_table/scroll_table/AI_ANALYSIS.md` |
| overlay_follow_compare | `modules/popup_table/overlay_follow_compare` | /overlay-compare | StatefulWidget | 中 | `modules/popup_table/overlay_follow_compare/AI_ANALYSIS.md` |
| status_management | `modules/state/status_management` | /status-management | Provider/Riverpod/Bloc | 高 | `modules/state/status_management/AI_ANALYSIS.md` |
| stream_subscription | `modules/async/stream_subscription` | /stream-subscription | StreamController | 中 | `modules/async/stream_subscription/AI_ANALYSIS.md` |
| tree_state | `modules/basic/tree_state` | /tree-state | StatefulWidget | 低 | `modules/basic/tree_state/AI_ANALYSIS.md` |
| usb_detector | `modules/platform/usb_detector` | /usb-detector | StreamController | 中 | `modules/platform/usb_detector/AI_ANALYSIS.md` |

## 模块模式分类

### 模式 A: 简单入口（module_entry -> module_root）
- debounce_throttle
- download_animation
- flutter_ioc
- isolate_task_manager
- isolate_basic
- overlay_follow_compare
- popup_list_interaction
- popup_widgets
- scroll_table
- usb_detector

### 模式 B: 功能分区（无 module_root，直接 features/pages 组织）
- adsorption_line（models/state/services/widgets）
- gcode_visualizer（models/parser/services/state/widgets/pages）
- dio_interceptor（pages/network/models/mock_server）
- microtask（features/core）
- status_management（app/features/shared）
- stream_subscription（pages/services/utils/models）
- tree_state（pages/routes）
