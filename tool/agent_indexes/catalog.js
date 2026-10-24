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

const categoryOwnership = {
  basic: ['basic_mechanisms'],
  async: ['async_concurrency'],
  state: ['state_management'],
  ui: ['ui_animation_custom_paint_3d_scene'],
  popup_table: ['popup_overlay_table'],
  platform: ['network_platform'],
};

const workspacePackages = [
  {
    name: 'forge_articles', kind: 'dart_package',
    path: 'packages/forge_articles', entrypoints: ['lib/forge_articles.dart'],
    owns: ['article_request_api', 'synthetic_article_adapter', 'article_workflow_execution'],
    depends: ['dio'], validation: ['dart analyze', 'flutter test'], test_status: 'configured',
  },
  {
    name: 'forge_scene_viewer', kind: 'flutter_package',
    path: 'packages/forge_scene_viewer', entrypoints: ['lib/forge_scene_viewer.dart', 'lib/build_hooks.dart'],
    owns: ['scene_runtime', 'orbit_camera', 'scene_selection', 'render_scheduling', 'render_diagnostics'],
    depends: ['flutter_sdk', 'flutter_scene', 'vector_math'],
    validation: ['flutter analyze', 'flutter test'], test_status: 'configured',
  },
  {
    name: 'usb_network_bridge', kind: 'flutter_plugin_package',
    path: 'packages/usb_network_bridge', entrypoints: ['lib/usb_network_bridge.dart'],
    owns: ['ncm_interface_enumeration', 'interface_bound_tcp', 'native_relay_lifecycle'],
    depends: ['flutter_sdk', 'ffi'],
    validation: ['flutter analyze', 'flutter test'], test_status: 'configured',
  },
  {
    name: 'flutter_battery', kind: 'flutter_plugin_package',
    path: 'packages/flutter_battery', entrypoints: ['lib/flutter_battery.dart'],
    owns: ['battery_api', 'battery_native_adapters', 'battery_event_lifecycle'],
    depends: ['flutter_sdk', 'plugin_platform_interface'],
    validation: ['flutter analyze', 'flutter test'], test_status: 'configured',
  },
  {
    name: 'file_picker_bridge',
    kind: 'flutter_bridge_package',
    path: 'packages/file_picker_bridge',
    entrypoints: ['lib/file_picker_bridge.dart'],
    owns: ['file_picker_api', 'method_channel_client', 'file_selector_client'],
    depends: ['flutter_sdk', 'file_selector', 'file_selector_web'],
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
  {
    name: 'desktop_multi_window',
    kind: 'flutter_plugin_package',
    path: 'packages/desktop_multi_window',
    entrypoints: ['lib/desktop_multi_window.dart'],
    owns: ['desktop_window_lifecycle', 'multi_window_host_bridge'],
    depends: ['flutter_sdk'],
    validation: ['flutter pub get', 'flutter analyze', 'flutter test'],
    test_status: 'configured',
  },
];


function catalogFor(modules) {
  return Object.fromEntries(Object.keys(categoryComments).map((category) => {
    const entries = modules.filter((module) => module.category === category);
    return [category, [entries.map(({ id }) => id), categoryOwnership[category],
      [...new Set(entries.flatMap(({ depends }) => depends))]]];
  }));
}

module.exports = { categoryComments, categoryEnumNames, workspacePackages, catalogFor };
