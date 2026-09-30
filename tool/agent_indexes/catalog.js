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
