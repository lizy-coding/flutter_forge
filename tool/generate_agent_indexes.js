const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const appRoot = path.join(root, 'apps/flutter_forge');

const contracts = {
  no_natural_language: true,
  index_only: true,
  max_index_depth: 2,
  doc_consumer: 'coding_agent',
  doc_mode: 'machine_contract',
  update_required_on_file_change: true,
  import_direction_enforced: true,
};

const modules = [
  {
    category: 'basic',
    id: 'tree_state',
    route: '/tree-state',
    status: 'recommended',
    depends: ['flutter_study_learning', 'module_registry', 'go_router'],
    title: '三棵树与生命周期',
    subtitle: '理解 Widget/Element/RenderObject 的关系与重建机制',
    difficulty: 'beginner',
    concepts: ['Widget 树', 'Element 树', 'RenderObject', '生命周期'],
    estimatedMinutes: 30,
    entry: 'TreeStateEntry',
    routes: 'TreeStateRoutes',
  },
  {
    category: 'basic',
    id: 'microtask',
    route: '/microtask',
    status: 'recommended',
    depends: ['flutter_study_learning', 'module_registry', 'go_router'],
    title: '事件循环与微任务',
    subtitle: '掌握 Dart 事件循环中微任务队列与事件队列的执行顺序',
    difficulty: 'beginner',
    concepts: ['Microtask', 'Event Queue', 'async/await', 'Zone'],
    estimatedMinutes: 25,
    entry: 'MicrotaskEntry',
    routes: 'MicrotaskRoutes',
  },
  {
    category: 'basic',
    id: 'debounce_throttle',
    route: '/debounce-throttle',
    status: 'ready',
    depends: ['flutter_study_learning', 'module_registry'],
    title: '防抖与节流',
    subtitle: '对比防抖和节流的执行时序，理解适用场景',
    difficulty: 'beginner',
    concepts: ['Debouncer', 'Throttle', 'Timer'],
    estimatedMinutes: 15,
    entry: 'DebounceThrottleEntry',
  },
  {
    category: 'async',
    id: 'stream_subscription',
    route: '/stream-subscription',
    status: 'recommended',
    depends: ['flutter_study_learning', 'module_registry', 'go_router'],
    title: 'Stream 订阅机制',
    subtitle: '学习单订阅流与广播流的区别及使用场景',
    difficulty: 'intermediate',
    concepts: ['StreamController', '单订阅', '广播流', 'Stream 变换'],
    estimatedMinutes: 30,
    entry: 'StreamSubscriptionEntry',
    routes: 'StreamSubscriptionRoutes',
  },
  {
    category: 'async',
    id: 'isolate_basic',
    route: '/isolate-basic',
    status: 'ready',
    depends: ['flutter_study_learning', 'module_registry', 'go_router'],
    title: 'Isolate 并发对比',
    subtitle: '对比主线程与 Isolate 执行耗时计算对 UI 流畅度的影响',
    difficulty: 'intermediate',
    concepts: ['Isolate', 'SendPort', 'ReceivePort', '性能优化'],
    estimatedMinutes: 20,
    entry: 'IsolateTestEntry',
    routes: 'IsolateTestRoutes',
  },
  {
    category: 'async',
    id: 'isolate_task_manager',
    route: '/isolate-stream',
    status: 'ready',
    depends: ['flutter_study_learning', 'module_registry'],
    title: '多任务 Isolate 管理器',
    subtitle: '使用 Isolate 并行处理多任务，通过 Stream 实时上报进度',
    difficulty: 'advanced',
    concepts: ['Isolate.spawn', '多任务', '进度上报', '暂停/恢复'],
    estimatedMinutes: 35,
    entry: 'IsolateStreamEntry',
  },
  {
    category: 'state',
    id: 'status_management',
    route: '/status-management',
    status: 'recommended',
    depends: ['flutter_study_learning', 'provider', 'flutter_riverpod', 'flutter_bloc', 'module_registry', 'go_router'],
    title: '状态管理演进',
    subtitle: '串联 setState、Provider、Riverpod、Bloc，对比不同方案',
    difficulty: 'intermediate',
    concepts: ['Provider', 'Riverpod', 'Bloc', '状态提升', 'FutureProvider'],
    estimatedMinutes: 45,
    entry: 'StatusManageEntry',
    routes: 'StatusManagementRoutes',
    subRoutesExpander: true,
  },
  {
    category: 'state',
    id: 'flutter_ioc',
    route: '/flutter-ioc',
    status: 'ready',
    depends: ['flutter_study_learning', 'flutter_ioc_core', 'provider', 'module_registry'],
    title: 'Flutter IoC 容器',
    subtitle: '自研 IoC 容器实现，支持单例/瞬态/作用域生命周期',
    difficulty: 'advanced',
    concepts: ['IoC', '依赖注入', '生命周期', '作用域'],
    estimatedMinutes: 30,
    entry: 'FlutterIocEntry',
  },
  {
    category: 'ui',
    id: 'gcode_visualizer',
    route: '/gcode-visualizer',
    status: 'ready',
    depends: ['flutter_study_learning', 'gcode_core', 'file_picker_bridge', 'module_registry'],
    title: 'G-code 解析与轨迹动画',
    subtitle: '解析 G-code 指令，绘制刀路轨迹并用动画展示执行过程',
    difficulty: 'advanced',
    concepts: ['G-code', 'Parser', 'CustomPaint', 'PathMetric', '动画控制'],
    estimatedMinutes: 45,
    entry: 'GcodeVisualizerEntry',
  },
  {
    category: 'ui',
    id: 'adsorption_line',
    route: '/adsorption-line',
    status: 'ready',
    depends: ['flutter_study_learning', 'provider', 'module_registry'],
    title: '智能吸附线画板',
    subtitle: '类似设计工具的对齐吸附功能，学习自定义绘制与手势',
    difficulty: 'advanced',
    concepts: ['CustomPaint', '手势检测', '吸附算法', '状态管理'],
    estimatedMinutes: 40,
    entry: 'AdsorptionLineEntry',
  },
  {
    category: 'ui',
    id: 'download_animation',
    route: '/download-animation',
    status: 'ready',
    depends: ['flutter_study_learning', 'module_registry', 'go_router'],
    title: '下载飞入动效',
    subtitle: '三种实现方式对比：Custom View / CustomPaint / Overlay',
    difficulty: 'intermediate',
    concepts: ['Tween 动画', 'CustomPaint', 'OverlayEntry', '动画配置'],
    estimatedMinutes: 30,
    entry: 'DownloadAnimationEntry',
    routes: 'DownloadAnimationRoutes',
  },
  {
    category: 'ui',
    id: 'font_picker',
    route: '/font-picker',
    status: 'ready',
    depends: ['flutter_study_learning', 'file_picker_bridge', 'module_registry', 'go_router'],
    title: '字体选择器',
    subtitle: '命名列表中直观对比不同字体族与字重样式，并通过文件选择器加载本地字体',
    difficulty: 'intermediate',
    concepts: ['fontFamily', 'TextStyle', '字重', '字距', '字体 fallback', '平台字体', 'FontLoader', '中台复用'],
    estimatedMinutes: 30,
    entry: 'FontPickerEntry',
    routes: 'FontPickerRoutes',
  },
  {
    category: 'popup_table',
    id: 'popup_widgets',
    route: '/popup-widgets',
    status: 'ready',
    depends: ['flutter_study_learning', 'module_registry'],
    title: '弹窗合集',
    subtitle: '全面展示 Flutter 中的对话框、底部抽屉、菜单等弹窗类型',
    difficulty: 'beginner',
    concepts: ['AlertDialog', 'BottomSheet', 'Overlay', 'ContextMenu'],
    estimatedMinutes: 20,
    entry: 'PopWidgetEntry',
  },
  {
    category: 'popup_table',
    id: 'popup_list_interaction',
    route: '/popup-list-interaction',
    status: 'ready',
    depends: ['flutter_study_learning', 'module_registry', 'go_router'],
    title: '弹窗与列表交互',
    subtitle: 'Flutter 弹窗组件与二维滚动表格的综合演示',
    difficulty: 'beginner',
    concepts: ['Dialog', 'BottomSheet', 'Overlay', 'TableView', '二维滚动'],
    estimatedMinutes: 25,
    entry: 'PopupListInteractionEntry',
    routes: 'PopupListInteractionRoutes',
  },
  {
    category: 'popup_table',
    id: 'scroll_table',
    route: '/scroll-table',
    status: 'ready',
    depends: ['flutter_study_learning', 'two_dimensional_scrollables', 'module_registry'],
    title: '二维滚动表格',
    subtitle: '使用 two_dimensional_scrollables 实现固定表头的表格',
    difficulty: 'beginner',
    concepts: ['TableView', '固定表头', '二维滚动'],
    estimatedMinutes: 15,
    entry: 'ScrollTableEntry',
  },
  {
    category: 'popup_table',
    id: 'overlay_follow_compare',
    route: '/overlay-compare',
    status: 'ready',
    depends: ['flutter_study_learning', 'module_registry'],
    title: 'Overlay 跟随方案对照组',
    subtitle: '对比 CompositedTransformFollower 与 markNeedsBuild 两种浮层跟随方案',
    difficulty: 'intermediate',
    concepts: ['Overlay', 'LayerLink', 'CompositedTransformFollower', 'markNeedsBuild', 'ScrollController'],
    estimatedMinutes: 30,
    entry: 'OverlayFollowCompareEntry',
  },
  {
    category: 'platform',
    id: 'dio_interceptor',
    route: '/dio-interceptor',
    status: 'ready',
    depends: ['flutter_study_learning', 'dio', 'module_registry', 'go_router'],
    title: 'Dio 拦截器链路',
    subtitle: 'Auth/Error/Retry/Log 拦截器 + 本地 Mock Server 实战',
    difficulty: 'intermediate',
    concepts: ['Dio', '拦截器', 'Token 刷新', 'Mock Server', '重试机制'],
    estimatedMinutes: 35,
    entry: 'InterceptorTestEntry',
    routes: 'InterceptorTestRoutes',
  },
  {
    category: 'platform',
    id: 'usb_detector',
    route: '/usb-detector',
    status: 'ready',
    depends: ['flutter_study_learning', 'device_info_plus', 'module_registry'],
    title: 'USB 设备检测',
    subtitle: '跨平台 USB 设备检测与状态监控',
    difficulty: 'intermediate',
    concepts: ['Android USB', 'UsbManager', 'MethodChannel', 'Stream 广播', '设备扫描'],
    estimatedMinutes: 25,
    entry: 'UsbDetectorEntry',
    supportedPlatforms: ['android'],
  },
  {
    category: 'platform',
    id: 'file_picker',
    route: '/file-picker',
    status: 'ready',
    depends: ['flutter_study_learning', 'file_picker_bridge', 'module_registry'],
    title: '文件选择器',
    subtitle: '复用 file_picker_bridge 中台能力，演示扩展过滤、取消分支与平台差异',
    difficulty: 'intermediate',
    concepts: ['FilePickerService', 'MethodChannel', '平台桥接', '扩展名过滤', '取消分支'],
    estimatedMinutes: 20,
    entry: 'FilePickerEntry',
    supportedPlatforms: ['macOS'],
  },
  {
    category: 'platform',
    id: 'online_video_player',
    route: '/online-video-player',
    status: 'ready',
    depends: ['flutter_study_learning', 'dio', 'video_player', 'video_player_win', 'module_registry'],
    title: '在线视频播放',
    subtitle: '使用 video_player 播放在线 HTTP 视频流并操控播放参数',
    difficulty: 'intermediate',
    concepts: ['video_player', '平台播放器', 'HTTP 流', '播放控制', '倍速', 'Controller 生命周期'],
    estimatedMinutes: 35,
    entry: 'OnlineVideoPlayerEntry',
    supportedPlatforms: ['macOS', 'windows'],
  },
];

const categoryComments = {
  basic: '基础机制',
  async: '异步并发',
  state: '状态管理',
  ui: 'UI 与动效',
  popup_table: '弹窗与列表',
  platform: '网络与平台',
};

const categoryEnumNames = {
  basic: 'basic',
  async: 'async',
  state: 'state',
  ui: 'ui',
  popup_table: 'popupTable',
  platform: 'platform',
};

const routeTableImportOrder = [
  ['basic', 'debounce_throttle'],
  ['basic', 'microtask'],
  ['basic', 'microtask', 'routes'],
  ['basic', 'tree_state'],
  ['basic', 'tree_state', 'routes', 'gap'],
  ['async', 'isolate_basic'],
  ['async', 'isolate_basic', 'routes'],
  ['async', 'isolate_task_manager'],
  ['async', 'stream_subscription'],
  ['async', 'stream_subscription', 'routes', 'gap'],
  ['state', 'flutter_ioc'],
  ['state', 'status_management', 'routes', 'gap'],
  ['state', 'status_management'],
  ['ui', 'adsorption_line'],
  ['ui', 'download_animation'],
  ['ui', 'download_animation', 'routes'],
  ['ui', 'font_picker'],
  ['ui', 'font_picker', 'routes'],
  ['ui', 'gcode_visualizer'],
  ['popup_table', 'popup_widgets'],
  ['popup_table', 'popup_list_interaction'],
  ['popup_table', 'popup_list_interaction', 'routes'],
  ['popup_table', 'scroll_table'],
  ['popup_table', 'overlay_follow_compare', 'entry', 'gap'],
  ['platform', 'dio_interceptor'],
  ['platform', 'dio_interceptor', 'routes'],
  ['platform', 'file_picker'],
  ['platform', 'online_video_player'],
  ['platform', 'usb_detector'],
];

const categoryMeta = {
  basic: [['tree_state', 'microtask', 'debounce_throttle'], ['basic_mechanisms'], ['module_registry', 'flutter_study_learning']],
  async: [['stream_subscription', 'isolate_basic', 'isolate_task_manager'], ['async_concurrency'], ['module_registry', 'flutter_study_learning']],
  state: [['status_management', 'flutter_ioc'], ['state_management'], ['provider', 'flutter_riverpod', 'flutter_bloc', 'flutter_ioc_core']],
  ui: [['gcode_visualizer', 'adsorption_line', 'download_animation', 'font_picker'], ['ui_animation_custom_paint'], ['provider', 'gcode_core', 'file_picker_bridge', 'flutter_study_learning', 'module_registry']],
  popup_table: [['popup_widgets', 'popup_list_interaction', 'scroll_table', 'overlay_follow_compare'], ['popup_overlay_table'], ['module_registry', 'flutter_study_learning', 'two_dimensional_scrollables']],
  platform: [['dio_interceptor', 'usb_detector', 'file_picker', 'online_video_player'], ['network_platform'], ['dio', 'usb_serial', 'device_info_plus', 'video_player', 'video_player_win', 'flutter_study_learning', 'file_picker_bridge']],
};

const flutterGuardDependency = {
  package: 'flutterguard_cli',
  source: 'git',
  url: 'https://github.com/lizy-coding/flutterguard.git',
  ref: '9f9be84a73dc4b99a956a8529b8c334849566b03',
  immutable: true,
  lock_status: 'git_pinned',
};

const workspacePackages = [
  {
    name: 'gcode_core',
    kind: 'flutter_package',
    path: 'packages/gcode_core',
    entrypoints: ['lib/gcode_core.dart'],
    owns: ['gcode_parsing', 'line_reading', 'toolpath_building', 'flutter_visualization_widgets'],
    depends: ['flutter_sdk'],
    validation: ['flutter pub get', 'flutter analyze', 'flutter test'],
    test_status: 'configured',
  },
  {
    name: 'flutter_study_learning',
    kind: 'flutter_package',
    path: 'packages/flutter_study_learning',
    entrypoints: ['lib/flutter_study_learning.dart'],
    owns: ['learning_scaffold_widgets', 'teaching_ui_components'],
    depends: ['flutter_sdk'],
    validation: ['flutter pub get', 'flutter analyze', 'flutter test'],
    test_status: 'configured',
  },
  {
    name: 'file_picker_bridge',
    kind: 'flutter_bridge_package',
    path: 'packages/file_picker_bridge',
    entrypoints: ['lib/file_picker_bridge.dart'],
    owns: ['file_picker_api', 'method_channel_client'],
    depends: ['flutter_sdk'],
    validation: ['flutter pub get', 'flutter analyze', 'flutter test'],
    test_status: 'configured',
  },
  {
    name: 'flutter_ioc_core',
    kind: 'dart_package',
    path: 'packages/flutter_ioc_core',
    entrypoints: ['lib/flutter_ioc_core.dart'],
    owns: ['ioc_container', 'registration_lifetimes', 'scoped_resolution'],
    depends: [],
    validation: ['dart pub get', 'dart analyze', 'dart test'],
    test_status: 'configured',
  },
];

function writeJson(rel, value) {
  const outputRoot = rel === 'lib' || rel.startsWith('lib/') ? appRoot : root;
  const file = path.join(outputRoot, rel);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

function nodePath(rel) {
  return rel.replace(/\/?AI_ANALYSIS\.md$/, '') || '.';
}

function writeIndex({
  rel,
  id,
  kind,
  status = 'active',
  entrypoints = [],
  owns = [],
  depends = [],
  children = [],
  validation = ['flutter analyze'],
}) {
  writeJson(rel, {
    schema: 'vibecoding.harness.ai_analysis.v2',
    mode: 'index',
    node: {
      id,
      kind,
      package: 'flutter_forge_app',
      path: nodePath(rel),
      status,
    },
    entrypoints,
    owns,
    depends,
    children,
    contracts,
    validation,
  });
}

function writeSchema() {
  writeJson('AI_ANALYSIS_SCHEMA.json', {
    schema: 'flutter_forge.agent_docs.schema.v2',
    syntax: 'json_config',
    prose: 'forbidden',
    markdown: 'forbidden',
    generated_by: 'tool/generate_agent_indexes.js',
    documents: {
      project_context: 'AI_PROJECT_CONTEXT.md',
      refactor_plan: 'REFACTOR_PLAN.md',
      module_index: 'lib/AI_MODULE_INDEX.md',
      analysis_glob: '**/AI_ANALYSIS.md',
    },
    levels: {
      workspace: ['AI_ANALYSIS.md'],
      package_contract: workspacePackages.map(({ path: packagePath }) => `${packagePath}/AI_ANALYSIS.md`),
      section: [
        'lib/AI_ANALYSIS.md',
        'lib/app/AI_ANALYSIS.md',
        'lib/module_registry/AI_ANALYSIS.md',
        'lib/shared/AI_ANALYSIS.md',
        'lib/modules/AI_ANALYSIS.md',
      ],
      subsection: [
        'lib/app/router/AI_ANALYSIS.md',
        'lib/shared/platform/AI_ANALYSIS.md',
        'lib/shared/multi_window/AI_ANALYSIS.md',
        'lib/modules/basic/AI_ANALYSIS.md',
        'lib/modules/async/AI_ANALYSIS.md',
        'lib/modules/state/AI_ANALYSIS.md',
        'lib/modules/ui/AI_ANALYSIS.md',
        'lib/modules/popup_table/AI_ANALYSIS.md',
        'lib/modules/platform/AI_ANALYSIS.md',
      ],
      module_contract: ['lib/modules/*/*/AI_ANALYSIS.md'],
    },
    required_keys: ['schema', 'mode', 'node', 'entrypoints', 'owns', 'depends', 'children', 'contracts', 'validation'],
    node_required_keys: ['id', 'kind', 'package', 'path', 'status'],
    contracts_required: {
      no_natural_language: true,
      index_only: true,
      max_index_depth: 2,
      doc_consumer: 'coding_agent',
      doc_mode: 'machine_contract',
    },
    module_contract_policy: {
      keep_for_module_rule: true,
      content: ['route', 'category', 'status', 'entrypoints', 'analysis_parent'],
      avoid: ['class_descriptions', 'long_file_inventory', 'natural_language_notes'],
    },
    package_contract_policy: {
      required_for_workspace_member: true,
      content: ['package_type', 'workspace', 'entrypoints', 'owns', 'depends', 'validation', 'test_status'],
      avoid: ['platform_claims_not_proven_by_manifest', 'natural_language_notes'],
    },
  });
}

function writeProjectContext() {
  writeJson('AI_PROJECT_CONTEXT.md', {
    schema: 'flutter_forge.agent_docs.project_context.v1',
    consumer: 'coding_agent',
    package: {
      name: 'flutter_forge_app',
      type: 'flutter_modular_learning_app',
      sdk: ['flutter_3', 'dart_3'],
    },
    platform: {
      current_hosts: ['macos', 'windows'],
      next_host: 'android',
      target_hosts: ['android', 'ios', 'macos', 'windows'],
    },
    entrypoints: {
      process: 'lib/main.dart',
      bootstrap: 'lib/app/app_bootstrap.dart',
      app: 'lib/app/app.dart',
      router: 'lib/app/router/app_router.dart',
      route_table: 'lib/app/router/app_route_table.dart',
    },
    repository: {
      layout: 'pub_workspace',
      workspace_root: '.',
      members: workspacePackages.map(({ path: packagePath }) => packagePath),
      resolution_status: 'active',
      resolution_blocker: 'none',
    },
    internal_packages: workspacePackages.map(({ name, kind, path: packagePath, entrypoints }) => ({
      name,
      type: kind,
      path: packagePath,
      entrypoint: entrypoints[0],
    })),
    external_tools: [flutterGuardDependency],
    layers: [
      {
        id: 'app',
        path: 'lib/app',
        owns: ['host_bootstrap', 'app_shell', 'navigation_policy', 'route_composition'],
        may_depend_on: ['module_registry', 'shared', 'modules'],
      },
      {
        id: 'module_registry',
        path: 'lib/module_registry',
        owns: ['module_metadata', 'catalog_operations'],
        may_depend_on: ['flutter', 'go_router'],
      },
      {
        id: 'shared',
        path: 'lib/shared',
        owns: ['business_neutral_capabilities', 'platform_boundaries'],
        forbidden_dependencies: ['app', 'modules'],
      },
      {
        id: 'modules',
        path: 'lib/modules/{category}/{module}',
        owns: ['learning_ui', 'module_state', 'module_domain', 'module_data'],
        forbidden_dependencies: ['other_modules'],
      },
    ],
    module_contract: {
      required_files: ['module_entry.dart', 'AI_ANALYSIS.md'],
      required_registration: 'lib/app/router/app_route_table.dart',
      required_metadata: ['category', 'difficulty', 'concepts', 'estimatedMinutes', 'status', 'subtitle'],
      required_learning_dependency: 'flutter_study_learning',
      route_path_style: 'kebab_case',
      directory_style: 'snake_case',
    },
    platform_rules: {
      router_platform_api: 'forbidden',
      module_host_navigation: 'forbidden',
      desktop_window_policy: 'lib/app/category_navigation.dart',
      navigation_policy: 'lib/app/navigation_policy.dart',
      compact_width_breakpoint_dp: 600,
      mobile_window_policy: 'in_app_navigation_only',
      platform_capability_contract: 'business_neutral_interface',
    },
    change_protocol: {
      pre_read: ['AI_PROJECT_CONTEXT.md', 'REFACTOR_PLAN.md', '{target}/AI_ANALYSIS.md'],
      update_source: ['tool/generate_agent_indexes.js'],
      generate: 'bash tool/generate_harness_ai_analysis.sh',
      validate: [
        'bash tool/generate_harness_ai_analysis.sh + git diff --exit-code',
        'dart format . + git diff --exit-code -- *.dart',
        'flutter analyze (bare)',
        'bash tool/test_all.sh',
        'bash tool/verify_test_layout.sh',
        'dart run flutterguard_cli:flutterguard scan . --fail-on high (cd apps/flutter_forge)',
      ],
      ci: {
        authoritative_remote_packaging_gate: '.github/workflows/ci.yml',
        analyze_standard: 'bare flutter analyze (info/warning treated as failure)',
        steps: [
          'flutter pub get',
          'agent doc generation + drift check',
          'dart format + drift check',
          'flutter analyze (bare)',
          'bash tool/test_all.sh',
        ],
        flutterguard: 'not run in CI (previously failed from repo root with empty match); enforced only by local quality_gate.sh stage 6',
      },
    },
  });
}

function writeRefactorPlan() {
  writeJson('REFACTOR_PLAN.md', {
    schema: 'flutter_forge.agent_docs.refactor_plan.v1',
    objective: 'android_readiness_after_architecture_convergence',
    active_phase: 'agent_managed',
    completed_milestones: [
      'directory_layers',
      'shared_package_extraction',
      'module_analysis_coverage',
      'app_navigation_boundary',
      'host_bootstrap_boundary',
      'workspace_package_import',
      'agent_takeover_ready',
    ],
    dependency_migration: {
      layout: 'pub_workspace',
      internal_packages: workspacePackages.map(({ path: packagePath }) => packagePath),
      workspace_resolution_status: 'active',
      workspace_resolution_blocker: 'none',
      external_tool: flutterGuardDependency,
    },
    work_queue: [
      {
        id: 'module_platform_contract',
        priority: 1,
        status: 'completed',
        changes: ['ModuleEntry.platform_support', 'ModuleHomePage.availability_state'],
        acceptance: ['catalog_platform_metadata_complete', 'unsupported_module_state_visible'],
      },
      {
        id: 'responsive_navigation_policy',
        priority: 2,
        status: 'completed',
        changes: ['NavigationPolicy', 'CategoryNavigation.mobile_in_app_mode'],
        acceptance: ['android_ios_web_in_app_navigation', 'compact_width_in_app_navigation', 'desktop_large_window_policy_test'],
      },
      {
        id: 'platform_plugin_audit',
        priority: 3,
        status: 'pending',
        targets: ['desktop_multi_window', 'file_picker_bridge', 'usb_android_method_channel', 'device_info_plus'],
        acceptance: ['android_support_matrix', 'unsupported_fallbacks'],
      },
      {
        id: 'usb_platform_boundary',
        priority: 4,
        status: 'pending',
        targets: ['lib/modules/platform/usb_detector'],
        acceptance: ['no_windows_hardcode', 'android_system_info', 'error_branch_test'],
      },
      {
        id: 'mobile_layout_baseline',
        priority: 5,
        status: 'pending',
        viewport_width_dp: 360,
        targets: ['module_home', 'category_home', 'ready_modules', 'recommended_modules'],
        acceptance: ['no_overflow', 'safe_area', 'keyboard_avoidance', 'touch_targets'],
      },
      {
        id: 'android_host',
        priority: 6,
        status: 'blocked_by_dependencies',
        depends_on: ['module_platform_contract', 'platform_plugin_audit', 'mobile_layout_baseline'],
        acceptance: ['android_directory', 'manifest_capabilities', 'debug_apk', 'emulator_smoke'],
      },
    ],
    quality_gate: [
      'node tool/validate_agent_docs.js',
      'dart format .',
      'flutter analyze:no_error',
      'flutterguard:no_high',
      'logic_change:targeted_test',
      'teaching_ui_change:visual_evidence',
    ],
    deferred_queue: [
      'popup_widgets_decomposition',
      'widget_test_coverage',
      'flutterguard_med_reduction',
      'recommended_module_visual_evidence',
    ],
  });
}

function writeModuleIndex() {
  writeJson('lib/AI_MODULE_INDEX.md', {
    schema: 'flutter_forge.agent_docs.module_index.v1',
    registry: 'lib/app/router/app_route_table.dart',
    count: modules.length,
    modules: modules.map(({ category, id, route, status, depends }) => ({
      id,
      category,
      path: `lib/modules/${category}/${id}`,
      route,
      status,
      depends,
      analysis: `lib/modules/${category}/${id}/AI_ANALYSIS.md`,
    })),
  });
}

function conceptsLiteral(concepts) {
  const literal = `[${concepts.map((item) => `'${item}'`).join(', ')}]`;
  if (literal.length + 14 <= 80) return literal;
  const items = concepts.map((item) => `      '${item}',`).join('\n');
  return `[\n${items}\n    ]`;
}

function writeRouteTable() {
  const file = path.join(appRoot, 'lib/app/router/app_route_table.dart');
  const lines = [];

  lines.push('// GENERATED by tool/generate_agent_indexes.js - DO NOT EDIT');
  lines.push('');
  lines.push("import 'package:flutter/foundation.dart';");
  lines.push("import 'package:go_router/go_router.dart';");
  lines.push('');
  lines.push("import '../module_home_page.dart';");
  lines.push("import '../../module_registry/module_category.dart';");
  lines.push("import '../../module_registry/module_catalog_utils.dart';");
  lines.push("import '../../module_registry/module_entry.dart';");

  const emittedImports = new Set();
  for (const [category, id, kind, gap] of routeTableImportOrder) {
    if (!modules.some((m) => m.category === category && m.id === id)) continue;
    const fileName = kind === 'routes' ? 'module_routes.dart' : 'module_entry.dart';
    lines.push(`import '../../modules/${category}/${id}/${fileName}';`);
    emittedImports.add(`${category}/${id}/${fileName}`);
    if (gap === 'gap') lines.push('');
  }
  for (const m of modules) {
    for (const fileName of ['module_entry.dart', m.routes ? 'module_routes.dart' : null].filter(Boolean)) {
      if (emittedImports.has(`${m.category}/${m.id}/${fileName}`)) continue;
      lines.push(`import '../../modules/${m.category}/${m.id}/${fileName}';`);
    }
  }

  lines.push('');
  if (modules.some((m) => m.subRoutesExpander)) {
    lines.push('// ==================== 状态管理子路由（模块内部已定义映射） ====================');
    lines.push('');
    lines.push('List<GoRoute> _buildStatusManageRoutes() => StatusManagementRoutes');
    lines.push('    .routes');
    lines.push('    .entries');
    lines.push('    .map(');
    lines.push('      (entry) => GoRoute(');
    lines.push("        path: entry.key.startsWith('/') ? entry.key.substring(1) : entry.key,");
    lines.push('        builder: (context, state) => entry.value(context),');
    lines.push('      ),');
    lines.push('    )');
    lines.push('    .toList();');
    lines.push('');
  }
  lines.push('// ==================== 模块注册 ====================');
  lines.push('');
  lines.push('final List<ModuleEntry> _modules = [');
  let previousCategory = null;
  for (const m of modules) {
    if (m.category !== previousCategory) {
      if (previousCategory !== null) lines.push('');
      lines.push(`  // ${categoryComments[m.category]}`);
      previousCategory = m.category;
    }
    lines.push('  ModuleEntry(');
    lines.push(`    title: '${m.title}',`);
    lines.push(`    path: '${m.route}',`);
    lines.push(`    subtitle: '${m.subtitle}',`);
    lines.push(`    category: ModuleCategory.${categoryEnumNames[m.category]},`);
    lines.push(`    difficulty: Difficulty.${m.difficulty},`);
    lines.push(`    concepts: ${conceptsLiteral(m.concepts)},`);
    lines.push(`    estimatedMinutes: ${m.estimatedMinutes},`);
    lines.push(`    status: ModuleStatus.${m.status},`);
    if (m.supportedPlatforms) {
      lines.push(`    supportedPlatforms: {${m.supportedPlatforms.map((platform) => `TargetPlatform.${platform}`).join(', ')}},`);
    }
    lines.push(`    builder: (context) => const ${m.entry}(),`);
    if (m.subRoutesExpander) {
      lines.push('    routes: _buildStatusManageRoutes(),');
    } else if (m.routes) {
      lines.push(`    routes: ${m.routes}.routes,`);
    }
    lines.push('  ),');
  }
  lines.push('];');
  lines.push('');
  lines.push('final List<GoRoute> _routes = [');
  lines.push('  GoRoute(');
  lines.push("    path: '/',");
  lines.push('    builder: (context, state) => ModuleHomePage(modules: _modules),');
  lines.push('  ),');
  lines.push('  for (final module in availableModules(_modules))');
  lines.push('    GoRoute(');
  lines.push('      path: module.path,');
  lines.push('      builder: (context, state) => module.builder(context),');
  lines.push('      routes: module.routes,');
  lines.push('    ),');
  lines.push('];');
  lines.push('');
  lines.push('class AppRouteTable {');
  lines.push('  static List<GoRoute> get routes => _routes;');
  lines.push('  static List<ModuleEntry> get modules => _modules;');
  lines.push('}');
  lines.push('');

  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, lines.join('\n'));
}

function writeRootIndexes() {
  writeIndex({
    rel: 'AI_ANALYSIS.md',
    id: 'flutter_forge.root',
    kind: 'workspace_index',
    entrypoints: ['lib/main.dart', 'lib/app/app_bootstrap.dart', 'lib/app/app.dart', 'lib/app/router/app_route_table.dart'],
    owns: ['app_shell', 'module_registry', 'shared_capabilities', 'learning_modules', 'host_integrations'],
    depends: [
      'packages/gcode_core',
      'packages/flutter_study_learning',
      'packages/file_picker_bridge',
      'packages/flutter_ioc_core',
      `git:${flutterGuardDependency.url}#${flutterGuardDependency.ref}`,
    ],
    children: [
      'lib/AI_ANALYSIS.md',
      'lib/app/AI_ANALYSIS.md',
      'lib/module_registry/AI_ANALYSIS.md',
      'lib/shared/AI_ANALYSIS.md',
      'lib/modules/AI_ANALYSIS.md',
      ...workspacePackages.map(({ path: packagePath }) => `${packagePath}/AI_ANALYSIS.md`),
    ],
    validation: ['bash tool/generate_harness_ai_analysis.sh', 'dart format .', 'flutter analyze', 'dart run flutterguard_cli:flutterguard scan . --fail-on high'],
  });
  writeIndex({
    rel: 'lib/AI_ANALYSIS.md',
    id: 'flutter_forge_app.lib',
    kind: 'source_index',
    entrypoints: ['main.dart', 'app/app_bootstrap.dart', 'app/app.dart', 'app/router/app_route_table.dart'],
    owns: ['app', 'module_registry', 'shared', 'modules'],
    depends: ['flutter_sdk', 'go_router', 'flutter_riverpod'],
    children: ['app/AI_ANALYSIS.md', 'module_registry/AI_ANALYSIS.md', 'shared/AI_ANALYSIS.md', 'modules/AI_ANALYSIS.md'],
  });
}

function writeLayerIndexes() {
  writeIndex({
    rel: 'lib/app/AI_ANALYSIS.md',
    id: 'flutter_forge_app.app',
    kind: 'app_index',
    entrypoints: ['app.dart', 'app_bootstrap.dart', 'module_home_page.dart', 'category_navigation.dart', 'navigation_policy.dart', 'category_window_app.dart', 'router/app_router.dart', 'router/app_route_table.dart'],
    owns: ['host_bootstrap', 'material_app_router', 'router', 'module_home', 'responsive_navigation_policy', 'adaptive_category_navigation', 'desktop_category_window_shell'],
    depends: ['go_router', 'module_registry', 'shared/multi_window', 'modules'],
    children: ['router/AI_ANALYSIS.md'],
  });
  writeIndex({
    rel: 'lib/app/router/AI_ANALYSIS.md',
    id: 'flutter_forge_app.app.router',
    kind: 'router_index',
    entrypoints: ['app_router.dart', 'app_route_table.dart'],
    owns: ['go_router_root', 'module_route_aggregation', 'module_catalog_composition'],
    depends: ['app/module_home_page', 'module_registry', 'modules'],
  });
  writeIndex({
    rel: 'lib/module_registry/AI_ANALYSIS.md',
    id: 'flutter_forge_app.module_registry',
    kind: 'registry_index',
    entrypoints: ['module_entry.dart', 'module_category.dart', 'module_catalog_utils.dart'],
    owns: ['module_entry_model', 'module_category_enum', 'difficulty_enum', 'module_status_enum', 'module_catalog_filtering', 'category_route_rebasing'],
    depends: ['flutter_material', 'go_router'],
  });
  writeIndex({
    rel: 'lib/shared/AI_ANALYSIS.md',
    id: 'flutter_forge_app.shared',
    kind: 'shared_index',
    entrypoints: ['multi_window', 'platform'],
    owns: ['business_free_capabilities', 'desktop_window_lifecycle', 'platform_boundaries'],
    depends: ['desktop_multi_window', 'packages/file_picker_bridge'],
    children: ['multi_window/AI_ANALYSIS.md', 'platform/AI_ANALYSIS.md'],
  });
  writeIndex({
    rel: 'lib/shared/multi_window/AI_ANALYSIS.md',
    id: 'flutter_forge_app.shared.multi_window',
    kind: 'shared_capability_index',
    entrypoints: ['multi_window_manager.dart'],
    owns: ['desktop_window_lifecycle', 'desktop_window_arguments'],
    depends: ['desktop_multi_window', 'module_registry'],
  });
  writeIndex({
    rel: 'lib/shared/platform/AI_ANALYSIS.md',
    id: 'flutter_forge_app.shared.platform',
    kind: 'shared_boundary_index',
    status: 'transition',
    entrypoints: ['AI_ANALYSIS.md'],
    owns: ['platform_boundary', 'host_channel_registry'],
    depends: ['packages/file_picker_bridge', 'macos/Runner/AppDelegate.swift'],
    validation: ['flutter analyze', 'flutter build macos'],
  });
}

function writeModuleIndexes() {
  writeIndex({
    rel: 'lib/modules/AI_ANALYSIS.md',
    id: 'flutter_forge_app.modules',
    kind: 'modules_index',
    entrypoints: ['basic', 'async', 'state', 'ui', 'popup_table', 'platform'],
    owns: ['learning_module_categories', 'route_registered_modules'],
    depends: ['module_registry', 'flutter_study_learning'],
    children: ['basic/AI_ANALYSIS.md', 'async/AI_ANALYSIS.md', 'state/AI_ANALYSIS.md', 'ui/AI_ANALYSIS.md', 'popup_table/AI_ANALYSIS.md', 'platform/AI_ANALYSIS.md'],
  });
  for (const [category, [children, owns, depends]] of Object.entries(categoryMeta)) {
    writeIndex({
      rel: `lib/modules/${category}/AI_ANALYSIS.md`,
      id: `flutter_forge_app.modules.${category}`,
      kind: 'module_category_index',
      entrypoints: children,
      owns,
      depends,
      children: children.map((module) => `${module}/AI_ANALYSIS.md`),
    });
  }
}

function writeModuleContracts() {
  for (const { category, id: module, route, status, depends } of modules) {
    const dir = path.join(appRoot, 'lib/modules', category, module);
    const entrypoints = [];
    for (const item of ['module_entry.dart', 'module_root.dart', 'module_routes.dart']) {
      if (fs.existsSync(path.join(dir, item))) entrypoints.push(item);
    }
    for (const item of ['pages', 'widgets', 'state']) {
      if (fs.existsSync(path.join(dir, item))) entrypoints.push(item);
    }
    writeJson(`lib/modules/${category}/${module}/AI_ANALYSIS.md`, {
      schema: 'vibecoding.harness.ai_analysis.v2',
      mode: 'module_contract',
      node: {
        id: `flutter_forge_app.modules.${category}.${module}`,
        kind: 'learning_module',
        package: 'flutter_forge_app',
        path: `lib/modules/${category}/${module}`,
        status,
      },
      route,
      category,
      entrypoints: entrypoints.length ? entrypoints : ['module_entry.dart'],
      owns: ['module_entry', 'module_ui', 'module_docs'],
      depends,
      children: [],
      analysis_parent: `lib/modules/${category}/AI_ANALYSIS.md`,
      contracts,
      validation: ['flutter analyze'],
    });
  }
}

function writePackageContracts() {
  for (const packageMeta of workspacePackages) {
    writeJson(`${packageMeta.path}/AI_ANALYSIS.md`, {
      schema: 'vibecoding.harness.ai_analysis.v2',
      mode: 'package_contract',
      node: {
        id: `flutter_forge.workspace.${packageMeta.name}`,
        kind: packageMeta.kind,
        package: packageMeta.name,
        path: packageMeta.path,
        status: 'active',
      },
      package_type: packageMeta.kind,
      workspace: {
        member: true,
        resolution: 'workspace',
        resolution_status: 'active',
        resolution_blocker: 'none',
      },
      entrypoints: packageMeta.entrypoints,
      owns: packageMeta.owns,
      depends: packageMeta.depends,
      children: [],
      contracts,
      validation: packageMeta.validation,
      test_status: packageMeta.test_status,
    });
  }
}

writeSchema();
writeProjectContext();
writeRefactorPlan();
writeModuleIndex();
writeRouteTable();
writeRootIndexes();
writeLayerIndexes();
writeModuleIndexes();
writeModuleContracts();
writePackageContracts();

console.log('agent index AI_ANALYSIS generation completed');
