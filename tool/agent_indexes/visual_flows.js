// Human visual expectations, grounded in the referenced behavior test or UI.
// This is optional acceptance content, not a module/platform registration table.
const flows = {
  constraint_layout: ['拖动父约束手柄；切换松/紧约束与 Row、Column、Wrap；最后重置。', '尺寸连续反馈；紧约束使子尺寸跟随父尺寸；Wrap 在变窄时换行；重置恢复初始状态。', 'test/modules/basic/constraint_layout/constraint_layout_test.dart'],
  tree_state: ['进入“State 生命周期”，点击“setState +1”。', 'Counter 增加 1，日志出现对应的新状态；核心交互缺自动行为测试。', 'lib/modules/basic/tree_state/pages/state_lifecycle_page.dart'],
  microtask: ['进入“微任务队列”，点击“基础微任务测试”。', '日志按顺序执行微任务 1、2、3，随后出现微任务队列测试结束；核心交互缺自动行为测试。', 'lib/modules/basic/microtask/pages/microtask_queue_page.dart'],
  debounce_throttle: ['分别点击“普通点击”“防抖点击”“节流点击”，等待至少 500ms；再快速重复点击比较计数。', '单次点击后三个计数增加；连续点击呈现普通、防抖和节流的差异，说明与计数对应。', 'test/modules/basic/debounce_throttle/debounce_throttle_test.dart'],
  stream_subscription: ['点击“开始推送”，观察状态，再点击“停止推送”。', '状态从推送中变为已停止。已知问题：初次订阅按钮被反向禁用，消息接收流程需另行修复和验收；不能据此宣称订阅功能通过。', 'lib/modules/async/stream_subscription/pages/stream_demo_page.dart'],
  isolate_basic: ['进入“使用 Isolate (流畅示例)”，开始计算；计算期间点击“点击测试响应”。', '响应计数递增，计算最终返回结果；观察实际主机响应与进度，核心交互缺自动行为测试。', 'lib/modules/async/isolate_basic/with_isolate_page.dart'],
  isolate_task_manager: ['添加新任务；待进度变化后暂停、继续，再停止该任务。', '状态分别显示进行中、已暂停、进行中；停止后卡片移除；核心交互缺自动行为测试。', 'lib/modules/async/isolate_task_manager/module_root.dart'],
  status_management: ['进入 Riverpod 状态提升页，点击“加1”再“重置”。', '初始计数 0 增为 1，再回到 0；关联视图同步更新；核心交互缺自动行为测试。', 'lib/modules/state/status_management/pages/riverpod/riverpod_lifting_route.dart'],
  flutter_ioc: ['点击加号悬浮按钮；在“Enter new name”输入名字。', 'Count 增加，Name 随输入更新；核心交互缺自动行为测试。', 'lib/modules/state/flutter_ioc/module_root.dart'],
  local_persistence: ['记录当前计数，点击“+1”；返回后重进，再重启应用。', '新计数被保存并恢复，避免与其他用例清除存储混用；已有控制器测试不替代主机持久化验收。', 'lib/modules/state/local_persistence/module_root.dart'],
  adsorption_line: ['选择“矩形”，在两处空白画布点击创建图形；拖动其一；点击“清空画板”。', '矩形出现、拖动改变位置、清空移除元素；另观察吸附提示是否与对齐一致；核心交互缺自动行为测试。', 'lib/modules/ui/adsorption_line/widgets/drawing_board.dart'],
  download_animation: ['点击任一文件的“下载”，等待飞入动画结束。', '动效连续，随后提示该文件下载完成；此流程是模拟动画，不代表真实网络下载；核心交互缺自动行为测试。', 'lib/modules/ui/download_animation/pages/download_animation_page.dart'],
  font_picker: ['选择字体列表第二项，打开字重与字距对比后返回。', '选中项高亮，预览显示对应字体名称；返回保持正常可操作。', 'test/modules/ui/font_picker/font_picker_test.dart', 'font_preview'],
  gcode_visualizer: ['点击编辑器“示例”，然后“解析”；播放、暂停，再重置。', '显示非零指令/轨迹段并进入可播放状态；进度前进、暂停停止、重置归零；轨迹实际可见；核心交互缺自动行为测试。', 'lib/modules/ui/gcode_visualizer/pages/gcode_visualizer_page.dart'],
  popup_widgets: ['点击悬浮按钮展开持久化底部工具条，再关闭；打开一个对话框并返回。', '工具条和对话框正确显示、关闭；返回后没有残留浮层。', 'test/modules/popup_table/popup_widgets/popup_widgets_test.dart'],
  popup_list_interaction: ['进入“列表交互”；编辑“学习任务 1”并保存；再次编辑另一个值后取消。', '只保留已保存值；取消不提交草稿；离开页面移除编辑浮层。', 'test/modules/popup_table/popup_list_interaction/popup_list_interaction_test.dart'],
  scroll_table: ['在员工信息表中横向、纵向拖动，滚到中间再返回起点。', '数据随滚动移动，首行与首列固定；无错位与不可达单元格；核心交互缺自动行为测试。', 'lib/modules/popup_table/scroll_table/module_root.dart'],
  overlay_follow_compare: ['滚到 Item 8，打开并关闭“Follower 下拉菜单”；对“手动刷新下拉菜单”重复。', '两个菜单均能正确打开、关闭；另观察滚动时菜单跟随与遮挡；核心交互缺自动行为测试。', 'lib/modules/popup_table/overlay_follow_compare/widgets/follower_demo.dart'],
  dio_interceptor: ['用 admin/password123 完成登录，获取文章，再创建文章并观察返回与日志。', '令牌链路与文章结果可见，创建有返回反馈；既有 Web 适配器测试不替代页面交互验收。', 'test/modules/platform/dio_interceptor/web_mock_http_adapter_test.dart'],
  online_video_player: ['等待媒体加载，点击播放，再暂停；观察进度与实际画面。', '图标分别显示暂停、播放，实际画面与进度按操作变化；Fake 播放测试不证明真实媒体播放。', 'test/modules/platform/online_video_player/online_video_player_test.dart'],
  webview: ['输入一个有效 HTTP(S) 地址并打开；再输入 javascript:alert(1) 后点击“打开”。', '有效网页在容器加载；非法地址出现错误提示且不导航；关闭重进没有遗留加载或控制器。', 'test/modules/platform/webview/webview_test.dart'],
};

function visualFlow(module) {
  const flow = flows[module.id];
  if (!flow) return null;
  return {
    id: 'core_visual_flow', platforms: flow[3] ? 'feature' : 'open', feature: flow[3],
    preconditions: '进入本次构建的教学页面；使用页面要求的样本或网络，记录初始状态。',
    steps: flow[0], expected: flow[1], sources: [`apps/flutter_forge/${flow[2]}`],
    evidence: '关键操作录屏、结果截图与异常日志；缺少自动行为测试时保留该缺口。',
  };
}

module.exports = { visualFlow };
