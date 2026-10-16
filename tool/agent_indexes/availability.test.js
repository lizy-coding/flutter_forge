const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { test } = require('node:test');
const { modules } = require('../generate_agent_indexes');
const { targets, resolveModules, writePolicies } = require('./availability');
const { supportDeclaration, writeSupport } = require('./support');
const { parseArgs } = require('../module_availability');
const root = path.resolve(__dirname, '../..');

function raw(module) {
  const { excludedPlatforms, platformPolicy, ...declaration } = module;
  return declaration;
}

test('existing entry policy is preserved while shared requirements are discovered', () => {
  const expected = {
    isolate_basic: ['web'], isolate_task_manager: ['web'],
    gcode_visualizer: ['android', 'iOS', 'web', 'windows'],
    flutter_scene_3d: ['iOS', 'web'], usb_detector: targets,
    battery_monitor: ['iOS', 'web', 'windows'],
    usb_network: ['android', 'iOS', 'web'],
    bluetooth_ble: ['iOS', 'web'], file_picker: ['iOS'], online_video_player: ['iOS'], webview: ['iOS', 'web'],
  };
  for (const module of modules) assert.deepEqual(module.excludedPlatforms, expected[module.id] ?? [], module.id);
  assert.deepEqual(modules.find((module) => module.id === 'isolate_basic').platformPolicy.required_capabilities, ['isolates']);
});

test('new modules sharing an adapter inherit its policy without per-module platform lists', () => {
  const filePicker = raw(modules.find((module) => module.id === 'file_picker'));
  const extra = { ...filePicker, id: 'new_picker' };
  assert.deepEqual(resolveModules(root, [extra])[0].excludedPlatforms, ['iOS']);
  assert.throws(() => resolveModules(root, [{ ...extra, excludedPlatforms: [] }]), /platform lists are derived/);
  assert.throws(() => resolveModules(root, [{ ...extra, optionalCapabilities: ['unknown'] }]), /not discovered/);
});

test('optional features do not close the module entry and Android scene remains view-only', () => {
  const font = modules.find((module) => module.id === 'font_picker');
  assert.deepEqual(font.excludedPlatforms, []);
  assert.equal(font.platformPolicy.features.font_file_import.platforms.includes('iOS'), false);
  assert.equal(font.platformPolicy.features.font_file_import.platforms.includes('web'), false);
  assert.equal(font.platformPolicy.features.font_preview.platforms.includes('iOS'), true);
  assert.equal(font.platformPolicy.features.font_preview.platforms.includes('web'), false);
  const scene = modules.find((module) => module.id === 'flutter_scene_3d');
  assert.deepEqual(scene.platformPolicy.features.scene_controls.platforms, ['macOS', 'windows']);
});

test('support declarations match runtime entry and feature policy without result tracking', () => {
  const declaration = supportDeclaration(modules);
  assert.equal(declaration.schema, 'flutter_forge.module_support.v1');
  assert.deepEqual(declaration.target_platforms, targets);
  for (const module of modules) {
    const row = declaration.modules.find((item) => item.id === module.id);
    assert.deepEqual(row.supported_platforms, targets.filter((host) => !module.excludedPlatforms.includes(host)));
    for (const [id, feature] of Object.entries(module.platformPolicy.features)) {
      assert.deepEqual(row.features[id], feature.platforms);
    }
  }
  const file = declaration.modules.find((item) => item.id === 'file_picker');
  assert.equal(file.limitations[0].reason, 'file_bridge_adapters_web_filename_only');
  const scene = declaration.modules.find((item) => item.id === 'flutter_scene_3d');
  assert.ok(scene.limitations.some((item) => item.capability === 'scene_controls'));
  assert.equal(declaration.modules.find((item) => item.id === 'usb_detector').supported_platforms.length, 0);
  assert.ok(declaration.modules.find((item) => item.id === 'usb_detector').restriction.sources.length);
  assert.doesNotMatch(JSON.stringify(declaration), /"(?:verification|tests|cases|fingerprint|test_summary|recorded_at)"/);
});

test('default generation never reads archived reports or inventories test results', () => {
  const source = `const fs = require('fs'); const path = require('path');
    for (const method of ['readFileSync', 'readdirSync']) {
      const original = fs[method];
      fs[method] = (file, ...args) => {
        const name = typeof file === 'string' ? path.resolve(file).split(path.sep).join('/') : '';
        const retired = ['/docs/module_availability/evidence', '/docs/module_availability/archive', '/docs/evidence', '/docs/reports'];
        if (retired.some((directory) => name.endsWith(directory) || name.includes(directory + '/')) || name.includes('/test/') || name.endsWith('/test')) {
          throw Error('unexpected maintenance evidence/test read: ' + name);
        }
        return original(file, ...args);
      };
    }
    require(${JSON.stringify(path.join(root, 'tool/generate_agent_indexes.js'))}).run({check: true});`;
  const result = spawnSync(process.execPath, ['-e', source], { cwd: root, encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
});

test('support output is compact, escapes table cells and does not emit acceptance cases', () => {
  const outputs = new Map();
  writeSupport({ modules: [{ ...modules[0], title: '学习 | 模块\n新行' }],
    facts: { currentHosts: ['android', 'macos', 'web', 'windows'] },
    writeJson: (rel, value) => outputs.set(rel, value), writeText: (rel, value) => outputs.set(rel, value) });
  assert.deepEqual([...outputs.keys()], ['docs/module_availability/matrix.json', 'docs/module_availability/matrix.md']);
  assert.match(outputs.get('docs/module_availability/matrix.md'), /学习 \\\| 模块 新行/);
  assert.match(outputs.get('docs/module_availability/matrix.md'), /iOS 当前仅建模/);
  assert.doesNotMatch(outputs.get('docs/module_availability/matrix.md'), /STALE|PENDING|PASS|FAIL/);
});

test('support CLI is read-only and rejects retired result commands', () => {
  const matrix = path.join(root, 'docs/module_availability/matrix.json');
  const before = fs.readFileSync(matrix, 'utf8');
  const cli = path.join(root, 'tool/module_availability.js');
  const result = spawnSync(process.execPath, [cli, 'list', '--module', 'file_picker'], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(JSON.parse(result.stdout).modules.map((module) => module.id), ['file_picker']);
  assert.equal(fs.readFileSync(matrix, 'utf8'), before);
  for (const args of [['check'], ['record'], ['list', '--kind', 'logic'], ['list', '--module', 'missing']]) {
    assert.equal(spawnSync(process.execPath, [cli, ...args], { encoding: 'utf8' }).status, 64);
  }
  assert.throws(() => parseArgs(['generate', '--module', 'file_picker']), /Usage/);
  assert.throws(() => parseArgs(['list', '--module', 'file_picker', '--module', 'font_picker']), /Usage/);
});

test('generated runtime policy has no acceptance or evidence dependency', () => {
  let output;
  writePolicies({ modules, writeText: (_, content) => { output = content; } });
  assert.match(output, /scene_controls/);
  assert.doesNotMatch(output, /verification|fingerprint|recorded_at|test_summary/);
});
