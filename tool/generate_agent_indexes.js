const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');

const contracts = {
  no_natural_language: true,
  index_only: true,
  max_index_depth: 2,
  doc_consumer: 'vibecoding',
  doc_mode: 'harness',
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
  ['popup_table', 'popup_widgets', '/popup-widgets', 'ready', ['flutter_study_learning', 'module_registry']],
  ['popup_table', 'popup_list_interaction', '/popup-list-interaction', 'ready', ['flutter_study_learning', 'module_registry', 'go_router']],
  ['popup_table', 'scroll_table', '/scroll-table', 'ready', ['flutter_study_learning', 'two_dimensional_scrollables', 'module_registry']],
  ['popup_table', 'overlay_follow_compare', '/overlay-compare', 'ready', ['flutter_study_learning', 'module_registry']],
  ['platform', 'dio_interceptor', '/dio-interceptor', 'ready', ['flutter_study_learning', 'dio', 'module_registry', 'go_router']],
  ['platform', 'usb_detector', '/usb-detector', 'ready', ['flutter_study_learning', 'usb_serial', 'device_info_plus', 'module_registry']],
];

const categoryMeta = {
  basic: [['tree_state', 'microtask', 'debounce_throttle'], ['basic_mechanisms'], ['module_registry', 'flutter_study_learning']],
  async: [['stream_subscription', 'isolate_basic', 'isolate_task_manager'], ['async_concurrency'], ['module_registry', 'flutter_study_learning']],
  state: [['status_management', 'flutter_ioc'], ['state_management'], ['provider', 'flutter_riverpod', 'flutter_bloc', 'flutter_ioc_core']],
  ui: [['gcode_visualizer', 'adsorption_line', 'download_animation'], ['ui_animation_custom_paint'], ['provider', 'gcode_core', 'file_picker_bridge', 'flutter_study_learning']],
  popup_table: [['popup_widgets', 'popup_list_interaction', 'scroll_table', 'overlay_follow_compare'], ['popup_overlay_table'], ['module_registry', 'flutter_study_learning', 'two_dimensional_scrollables']],
  platform: [['dio_interceptor', 'usb_detector'], ['network_platform'], ['dio', 'usb_serial', 'device_info_plus', 'flutter_study_learning']],
};

function writeJson(rel, value) {
  const file = path.join(root, rel);
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
      package: 'main_app',
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
    schema: 'vibecoding.harness.ai_analysis_schema.v1',
    syntax: 'json_config',
    prose: 'forbidden',
    markdown: 'forbidden',
    levels: {
      workspace: ['AI_ANALYSIS.md'],
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
      doc_consumer: 'vibecoding',
      doc_mode: 'harness',
    },
    module_contract_policy: {
      keep_for_module_rule: true,
      content: ['route', 'category', 'status', 'entrypoints', 'analysis_parent'],
      avoid: ['class_descriptions', 'long_file_inventory', 'natural_language_notes'],
    },
  });
}

function writeRootIndexes() {
  writeIndex({
    rel: 'AI_ANALYSIS.md',
    id: 'flutter_study.root',
    kind: 'workspace_index',
    entrypoints: ['lib/main.dart', 'lib/app/app.dart', 'lib/app/router/app_route_table.dart'],
    owns: ['app_shell', 'module_registry', 'shared_capabilities', 'learning_modules', 'host_integrations'],
    depends: ['../gcode_core', '../flutter_study_learning', '../file_picker_bridge', '../flutter_ioc_core', '../flutterguard/packages/flutterguard_cli'],
    children: ['lib/AI_ANALYSIS.md', 'lib/app/AI_ANALYSIS.md', 'lib/module_registry/AI_ANALYSIS.md', 'lib/shared/AI_ANALYSIS.md', 'lib/modules/AI_ANALYSIS.md'],
    validation: ['dart format .', 'flutter analyze', 'dart run flutterguard_cli:flutterguard scan --path . --fail-on high'],
  });
  writeIndex({
    rel: 'lib/AI_ANALYSIS.md',
    id: 'main_app.lib',
    kind: 'source_index',
    entrypoints: ['main.dart', 'app/app.dart', 'app/router/app_route_table.dart'],
    owns: ['app', 'module_registry', 'shared', 'modules'],
    depends: ['flutter_sdk', 'go_router', 'flutter_riverpod'],
    children: ['app/AI_ANALYSIS.md', 'module_registry/AI_ANALYSIS.md', 'shared/AI_ANALYSIS.md', 'modules/AI_ANALYSIS.md'],
  });
}

function writeLayerIndexes() {
  writeIndex({
    rel: 'lib/app/AI_ANALYSIS.md',
    id: 'main_app.app',
    kind: 'app_index',
    entrypoints: ['app.dart', 'router/app_router.dart', 'router/app_route_table.dart'],
    owns: ['material_app_router', 'router'],
    depends: ['go_router', 'module_registry', 'modules'],
    children: ['router/AI_ANALYSIS.md'],
  });
  writeIndex({
    rel: 'lib/app/router/AI_ANALYSIS.md',
    id: 'main_app.app.router',
    kind: 'router_index',
    entrypoints: ['app_router.dart', 'app_route_table.dart'],
    owns: ['go_router_root', 'module_route_aggregation', 'module_home_index'],
    depends: ['module_registry', 'modules'],
  });
  writeIndex({
    rel: 'lib/module_registry/AI_ANALYSIS.md',
    id: 'main_app.module_registry',
    kind: 'registry_index',
    entrypoints: ['module_entry.dart', 'module_category.dart'],
    owns: ['module_entry_model', 'module_category_enum', 'difficulty_enum', 'module_status_enum'],
    depends: ['flutter_material'],
  });
  writeIndex({
    rel: 'lib/shared/AI_ANALYSIS.md',
    id: 'main_app.shared',
    kind: 'shared_index',
    entrypoints: ['multi_window', 'platform'],
    owns: ['business_free_capabilities', 'desktop_windowing', 'platform_boundaries'],
    depends: ['desktop_multi_window', '../file_picker_bridge'],
    children: ['multi_window/AI_ANALYSIS.md', 'platform/AI_ANALYSIS.md'],
  });
  writeIndex({
    rel: 'lib/shared/multi_window/AI_ANALYSIS.md',
    id: 'main_app.shared.multi_window',
    kind: 'shared_capability_index',
    entrypoints: ['multi_window_manager.dart', 'category_window_app.dart', 'multi_window_route_filter.dart'],
    owns: ['desktop_window_lifecycle', 'category_window_router', 'module_route_filter'],
    depends: ['desktop_multi_window', 'go_router', 'module_registry'],
  });
  writeIndex({
    rel: 'lib/shared/platform/AI_ANALYSIS.md',
    id: 'main_app.shared.platform',
    kind: 'shared_boundary_index',
    status: 'transition',
    entrypoints: ['AI_ANALYSIS.md'],
    owns: ['platform_boundary', 'host_channel_registry'],
    depends: ['../file_picker_bridge', 'macos/Runner/AppDelegate.swift'],
    validation: ['flutter analyze', 'flutter build macos'],
  });
}

function writeModuleIndexes() {
  writeIndex({
    rel: 'lib/modules/AI_ANALYSIS.md',
    id: 'main_app.modules',
    kind: 'modules_index',
    entrypoints: ['basic', 'async', 'state', 'ui', 'popup_table', 'platform'],
    owns: ['learning_module_categories', 'route_registered_modules'],
    depends: ['module_registry', 'flutter_study_learning'],
    children: ['basic/AI_ANALYSIS.md', 'async/AI_ANALYSIS.md', 'state/AI_ANALYSIS.md', 'ui/AI_ANALYSIS.md', 'popup_table/AI_ANALYSIS.md', 'platform/AI_ANALYSIS.md'],
  });
  for (const [category, [children, owns, depends]] of Object.entries(categoryMeta)) {
    writeIndex({
      rel: `lib/modules/${category}/AI_ANALYSIS.md`,
      id: `main_app.modules.${category}`,
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
    const dir = path.join(root, 'lib/modules', category, module);
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
        id: `main_app.modules.${category}.${module}`,
        kind: 'learning_module',
        package: 'main_app',
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

writeSchema();
writeRootIndexes();
writeLayerIndexes();
writeModuleIndexes();
writeModuleContracts();

console.log('agent index AI_ANALYSIS generation completed');
