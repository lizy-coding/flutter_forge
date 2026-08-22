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
  ['basic', 'tree_state', '/tree-state', 'recommended', ['flutter_study_learning', 'module_registry', 'go_router']],
  ['basic', 'microtask', '/microtask', 'recommended', ['flutter_study_learning', 'module_registry', 'go_router']],
  ['basic', 'debounce_throttle', '/debounce-throttle', 'ready', ['flutter_study_learning', 'module_registry']],
  ['async', 'stream_subscription', '/stream-subscription', 'recommended', ['flutter_study_learning', 'module_registry', 'go_router']],
  ['async', 'isolate_basic', '/isolate-basic', 'ready', ['flutter_study_learning', 'module_registry', 'go_router']],
  ['async', 'isolate_task_manager', '/isolate-stream', 'ready', ['flutter_study_learning', 'module_registry']],
  ['state', 'status_management', '/status-management', 'recommended', ['flutter_study_learning', 'provider', 'flutter_riverpod', 'flutter_bloc', 'module_registry', 'go_router']],
  ['state', 'flutter_ioc', '/flutter-ioc', 'ready', ['flutter_study_learning', 'flutter_ioc_core', 'provider', 'module_registry']],
  ['ui', 'gcode_visualizer', '/gcode-visualizer', 'ready', ['flutter_study_learning', 'gcode_core', 'file_picker_bridge', 'module_registry']],
  ['ui', 'adsorption_line', '/adsorption-line', 'ready', ['flutter_study_learning', 'provider', 'module_registry']],
  ['ui', 'download_animation', '/download-animation', 'ready', ['flutter_study_learning', 'module_registry', 'go_router']],
  ['ui', 'font_picker', '/font-picker', 'ready', ['flutter_study_learning', 'file_picker_bridge', 'module_registry', 'go_router']],
  ['popup_table', 'popup_widgets', '/popup-widgets', 'ready', ['flutter_study_learning', 'module_registry']],
  ['popup_table', 'popup_list_interaction', '/popup-list-interaction', 'ready', ['flutter_study_learning', 'module_registry', 'go_router']],
  ['popup_table', 'scroll_table', '/scroll-table', 'ready', ['flutter_study_learning', 'two_dimensional_scrollables', 'module_registry']],
  ['popup_table', 'overlay_follow_compare', '/overlay-compare', 'ready', ['flutter_study_learning', 'module_registry']],
  ['platform', 'dio_interceptor', '/dio-interceptor', 'ready', ['flutter_study_learning', 'dio', 'module_registry', 'go_router']],
  ['platform', 'usb_detector', '/usb-detector', 'ready', ['flutter_study_learning', 'usb_serial', 'device_info_plus', 'module_registry']],
  ['platform', 'file_picker', '/file-picker', 'ready', ['flutter_study_learning', 'file_picker_bridge', 'module_registry']],
  ['platform', 'online_video_player', '/online-video-player', 'ready', ['flutter_study_learning', 'video_player', 'module_registry']],
];

const categoryMeta = {
  basic: [['tree_state', 'microtask', 'debounce_throttle'], ['basic_mechanisms'], ['module_registry', 'flutter_study_learning']],
  async: [['stream_subscription', 'isolate_basic', 'isolate_task_manager'], ['async_concurrency'], ['module_registry', 'flutter_study_learning']],
  state: [['status_management', 'flutter_ioc'], ['state_management'], ['provider', 'flutter_riverpod', 'flutter_bloc', 'flutter_ioc_core']],
  ui: [['gcode_visualizer', 'adsorption_line', 'download_animation', 'font_picker'], ['ui_animation_custom_paint'], ['provider', 'gcode_core', 'file_picker_bridge', 'flutter_study_learning', 'module_registry']],
  popup_table: [['popup_widgets', 'popup_list_interaction', 'scroll_table', 'overlay_follow_compare'], ['popup_overlay_table'], ['module_registry', 'flutter_study_learning', 'two_dimensional_scrollables']],
  platform: [['dio_interceptor', 'usb_detector', 'file_picker', 'online_video_player'], ['network_platform'], ['dio', 'usb_serial', 'device_info_plus', 'video_player', 'flutter_study_learning', 'file_picker_bridge']],
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
      platform_capability_contract: 'business_neutral_interface',
    },
    change_protocol: {
      pre_read: ['AI_PROJECT_CONTEXT.md', 'REFACTOR_PLAN.md', '{target}/AI_ANALYSIS.md'],
      update_source: ['tool/generate_agent_indexes.js'],
      generate: 'bash tool/generate_harness_ai_analysis.sh',
      validate: [
        'bash tool/generate_harness_ai_analysis.sh',
        'dart format .',
        'flutter analyze',
        'dart run flutterguard_cli:flutterguard scan . --fail-on high',
      ],
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
        status: 'pending',
        changes: ['ModuleEntry.platform_support', 'ModuleHomePage.availability_state'],
        acceptance: ['catalog_platform_metadata_complete', 'unsupported_module_state_visible'],
      },
      {
        id: 'platform_plugin_audit',
        priority: 2,
        status: 'pending',
        targets: ['desktop_multi_window', 'file_picker_bridge', 'usb_serial', 'device_info_plus'],
        acceptance: ['android_support_matrix', 'unsupported_fallbacks'],
      },
      {
        id: 'usb_platform_boundary',
        priority: 3,
        status: 'pending',
        targets: ['lib/modules/platform/usb_detector'],
        acceptance: ['no_windows_hardcode', 'android_system_info', 'error_branch_test'],
      },
      {
        id: 'mobile_layout_baseline',
        priority: 4,
        status: 'pending',
        viewport_width_dp: 360,
        targets: ['module_home', 'category_home', 'ready_modules', 'recommended_modules'],
        acceptance: ['no_overflow', 'safe_area', 'keyboard_avoidance', 'touch_targets'],
      },
      {
        id: 'android_host',
        priority: 5,
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
    modules: modules.map(([category, module, route, status, depends]) => ({
      id: module,
      category,
      path: `lib/modules/${category}/${module}`,
      route,
      status,
      depends,
      analysis: `lib/modules/${category}/${module}/AI_ANALYSIS.md`,
    })),
  });
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
    entrypoints: ['app.dart', 'app_bootstrap.dart', 'module_home_page.dart', 'category_navigation.dart', 'category_window_app.dart', 'router/app_router.dart', 'router/app_route_table.dart'],
    owns: ['host_bootstrap', 'material_app_router', 'router', 'module_home', 'adaptive_category_navigation', 'desktop_category_window_shell'],
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
  for (const [category, module, route, status, depends] of modules) {
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
writeRootIndexes();
writeLayerIndexes();
writeModuleIndexes();
writeModuleContracts();
writePackageContracts();

console.log('agent index AI_ANALYSIS generation completed');
