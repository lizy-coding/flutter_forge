const fs = require('fs');
const path = require('path');

const targets = ['android', 'iOS', 'macOS', 'web', 'windows'];

// Adapter rules describe this application's implementation, not plugin advertising
// or acceptance results. A dependency discovers a requirement; optional features
// and product restrictions remain explicit module intent.
const capabilities = {
  battery_monitor: {
    dependencies: ['flutter_battery'], platforms: ['android', 'macOS'],
    reason: 'battery_android_macos_native_adapters',
    sources: ['packages/flutter_battery/pubspec.yaml', 'apps/flutter_forge/lib/modules/platform/battery_monitor/module_entry.dart'],
  },
  isolates: {
    imports: ['dart:isolate'], platforms: ['android', 'iOS', 'macOS', 'windows'],
    reason: 'safari_isolate_progress_unreliable',
    sources: ['apps/flutter_forge/lib/modules/async/isolate_basic', 'apps/flutter_forge/lib/modules/async/isolate_task_manager'],
  },
  gcode_render: {
    dependencies: ['gcode_core'], platforms: ['macOS'],
    reason: 'macos_gcode_adapter_only',
    sources: ['apps/flutter_forge/lib/modules/ui/gcode_visualizer/module_entry.dart', 'apps/flutter_forge/pubspec.yaml'],
  },
  scene_render: {
    dependencies: ['flutter_scene'], platforms: ['android', 'macOS', 'windows'],
    reason: 'scene_gpu_adapters',
    sources: ['apps/flutter_forge/android/app/src/main/AndroidManifest.xml', 'apps/flutter_forge/windows/runner/main.cpp', 'apps/flutter_forge/lib/modules/ui/flutter_scene_3d/module_entry.dart'],
    features: ['scene_controls'],
  },
  scene_controls: {
    platforms: ['macOS', 'windows'],
    reason: 'desktop_scene_controls_android_view_only',
    sources: ['apps/flutter_forge/test/modules/ui/flutter_scene_3d/flutter_scene_3d_test.dart'],
  },
  file_selection: {
    dependencies: ['file_picker_bridge'], platforms: ['android', 'macOS', 'web', 'windows'],
    reason: 'file_bridge_adapters_web_filename_only',
    sources: ['packages/file_picker_bridge/lib/file_picker_bridge.dart'],
  },
  font_file_import: {
    fileNames: ['font_loader_service.dart'], replaces: ['file_selection'],
    platforms: ['android', 'iOS', 'macOS', 'windows'], requires: ['file_selection'],
    reason: 'font_import_requires_native_bytes_and_file_bridge',
    sources: ['apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_page.dart', 'apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_web_page.dart'],
    features: ['font_preview'],
  },
  font_preview: {
    platforms: ['android', 'iOS', 'macOS', 'windows'],
    reason: 'web_font_page_has_no_native_preview_controls',
    sources: ['apps/flutter_forge/lib/modules/ui/font_picker/pages/font_picker_web_page.dart'],
  },
  media_playback: {
    dependencies: ['video_player', 'video_player_web', 'video_player_win'], platforms: ['android', 'macOS', 'web', 'windows'],
    reason: 'media_backend_adapters',
    sources: ['apps/flutter_forge/lib/modules/platform/online_video_player/module_entry.dart', 'apps/flutter_forge/pubspec.yaml'],
  },
  embedded_web: {
    dependencies: ['webview_flutter', 'webview_windows'], platforms: ['android', 'macOS', 'windows'],
    reason: 'embedded_web_adapters',
    sources: ['apps/flutter_forge/lib/modules/platform/webview/module_entry.dart'],
  },
  ble_central: {
    dependencies: ['universal_ble'], platforms: ['android', 'macOS', 'windows'],
    reason: 'ble_central_adapters',
    sources: ['apps/flutter_forge/lib/modules/platform/bluetooth_ble/module_entry.dart', 'apps/flutter_forge/lib/modules/platform/bluetooth_ble/state/ble_session.dart'],
  },
};

function dartFiles(directory) {
  if (!fs.existsSync(directory)) return [];
  return fs.readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name)).flatMap((entry) => {
    if (entry.name.startsWith('.')) return [];
    const file = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`Source must not be a symlink: ${file}`);
    return entry.isDirectory() ? dartFiles(file) : entry.name.endsWith('.dart') ? [file] : [];
  });
}

function sourceImports(root, module) {
  return [...new Set(dartFiles(path.join(root, 'apps/flutter_forge/lib/modules', module.category, module.id))
    .flatMap((file) => [...fs.readFileSync(file, 'utf8').matchAll(/^(?:import|export)\s+['"]([^'"]+)['"]/gm)].map((match) => match[1])))].sort();
}

function validateRules(root, rules) {
  for (const [id, rule] of Object.entries(rules)) {
    if (!Array.isArray(rule.platforms) || new Set(rule.platforms).size !== rule.platforms.length ||
        rule.platforms.some((host) => !targets.includes(host)) || !rule.reason || !rule.sources?.length) {
      throw new Error(`Invalid capability rule: ${id}`);
    }
    for (const source of rule.sources) {
      if (path.isAbsolute(source) || source.split('/').includes('..') || !fs.existsSync(path.join(root, source))) {
        throw new Error(`Missing capability source: ${id}/${source}`);
      }
    }
    for (const feature of [...(rule.features ?? []), ...(rule.requires ?? []), ...(rule.replaces ?? [])]) {
      if (!Object.hasOwn(rules, feature)) throw new Error(`Unknown capability feature: ${feature}`);
    }
  }
}

function supportedPlatforms(id, rules, visiting = new Set()) {
  if (visiting.has(id)) throw new Error(`Cyclic capability requirement: ${id}`);
  const next = new Set([...visiting, id]);
  const prerequisites = (rules[id].requires ?? []).map((required) => supportedPlatforms(required, rules, next));
  return rules[id].platforms.filter((host) => prerequisites.every((platforms) => platforms.includes(host)));
}

function resolveModules(root, modules, rules = capabilities) {
  validateRules(root, rules);
  return modules.map((module) => {
    if (Object.hasOwn(module, 'excludedPlatforms') || Object.hasOwn(module, 'platformSupportComment')) {
      throw new Error(`Module platform lists are derived; declare capability intent instead: ${module.id}`);
    }
    const imports = sourceImports(root, module);
    const names = dartFiles(path.join(root, 'apps/flutter_forge/lib/modules', module.category, module.id)).map((file) => path.basename(file));
    let discovered = Object.entries(rules).filter(([, rule]) =>
      (rule.dependencies ?? []).some((dep) => module.depends.includes(dep) || imports.some((uri) => uri.startsWith(`package:${dep}/`))) ||
      (rule.imports ?? []).some((uri) => imports.includes(uri)) ||
      (rule.fileNames ?? []).some((name) => names.includes(name))).map(([id]) => id);
    discovered = discovered.filter((id) => !discovered.some((other) => (rules[other].replaces ?? []).includes(id)));
    const optional = module.optionalCapabilities ?? [];
    if (!Array.isArray(optional) || new Set(optional).size !== optional.length || optional.some((id) => !discovered.includes(id))) {
      throw new Error(`Optional capability is not discovered: ${module.id}`);
    }
    const required = discovered.filter((id) => !optional.includes(id));
    const features = [...new Set([...optional, ...discovered.flatMap((id) => rules[id].features ?? [])])];
    const restriction = module.entryRestriction;
    if (restriction && (!restriction.reason || !restriction.sources?.length ||
        restriction.sources.some((source) => path.isAbsolute(source) || source.split('/').includes('..') || !fs.existsSync(path.join(root, source))))) {
      throw new Error(`Invalid product restriction: ${module.id}`);
    }
    const excludedPlatforms = targets.filter((host) => restriction || required.some((id) => !supportedPlatforms(id, rules).includes(host)));
    const platformPolicy = {
      required_capabilities: required,
      unreviewed_dependencies: [...new Set(imports.filter((uri) => uri.startsWith('package:')).map((uri) => uri.slice(8).split('/')[0]))]
        .filter((dep) => !['flutter', 'flutter_forge_app', 'go_router', 'provider', 'flutter_riverpod', 'flutter_bloc', 'flutter_ioc_core', 'shared_preferences', 'vector_math', 'dio'].includes(dep) &&
          !Object.values(rules).some((rule) => (rule.dependencies ?? []).includes(dep)))
        .sort(),
      optional_capabilities: optional,
      reasons: discovered.map((id) => ({ capability: id, reason: rules[id].reason, sources: rules[id].sources })),
      restriction: restriction ?? null,
      features: Object.fromEntries(features.map((id) => [id, {
        platforms: targets.filter((host) => !excludedPlatforms.includes(host) && supportedPlatforms(id, rules).includes(host)),
        reason: rules[id].reason, sources: rules[id].sources,
      }])),
    };
    return { ...module, excludedPlatforms, platformPolicy };
  });
}

function platformContract(module) {
  return { target_platforms: targets, excluded_platforms: module.excludedPlatforms, ...module.platformPolicy };
}

function writePolicies({ modules, writeText }) {
  function set(label, hosts, indent) {
    const values = hosts.map((host) => `AppTargetPlatform.${host}`);
    const inline = `${indent}${label}: {${values.join(', ')}},`;
    return inline.length <= 80 ? inline : `${indent}${label}: {\n${values.map((value) => `${indent}  ${value},`).join('\n')}\n${indent}},`;
  }
  const lines = ['// GENERATED by tool/generate_agent_indexes.js - DO NOT EDIT', '', "import 'app_platform_snapshot.dart';", "import 'module_platform_support.dart';", '',
    'const modulePlatformPolicies = <String, ModulePlatformSupport>{'];
  for (const module of modules) {
    if (!module.excludedPlatforms.length && !Object.keys(module.platformPolicy.features).length) {
      lines.push(`  '${module.id}': ModulePlatformSupport(),`);
      continue;
    }
    lines.push(`  '${module.id}': ModulePlatformSupport(`);
    if (module.excludedPlatforms.length) {
      lines.push(set('excludedPlatforms', module.excludedPlatforms, '    '));
    }
    if (Object.keys(module.platformPolicy.features).length) {
      lines.push('    features: {');
      for (const [id, feature] of Object.entries(module.platformPolicy.features)) {
        lines.push(set(`'${id}'`, feature.platforms, '      '));
      }
      lines.push('    },');
    }
    lines.push('  ),');
  }
  lines.push('};', '');
  writeText('lib/module_registry/module_platform_policies.dart', lines.join('\n'));
}

module.exports = { targets, capabilities, dartFiles, resolveModules, platformContract, writePolicies };
