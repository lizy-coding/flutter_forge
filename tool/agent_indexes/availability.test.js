const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { test } = require('node:test');
const { modules } = require('../generate_agent_indexes');
const { targets, resolveModules, writePolicies } = require('./availability');
const { fingerprint, verificationState, writeAvailability, readEvidence, sha256 } = require('./verification');
const { acceptanceCases, casePlatforms } = require('./acceptance_cases');
const { commandFor, testSummary, parseArgs } = require('../module_availability');
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
  const fontCases = acceptanceCases(font);
  assert.deepEqual(casePlatforms(font, fontCases.find((item) => item.id === 'font_web_boundary'), targets), ['web']);
  const scene = modules.find((module) => module.id === 'flutter_scene_3d');
  assert.deepEqual(scene.platformPolicy.features.scene_controls.platforms, ['macOS', 'windows']);
  const viewOnly = acceptanceCases(scene).find((item) => item.id === 'scene_view_only');
  assert.deepEqual(casePlatforms(scene, viewOnly, targets), ['android']);
});

test('pending, failure and stale evidence never change entry admission', () => {
  const module = modules.find((item) => item.id === 'file_picker');
  const current = fingerprint(root, modules, module.id, 'logic', 'any');
  const record = { module: module.id, kind: 'logic', platform: 'any', fingerprint: current, status: 'fail', recorded_at: '2026-10-04T00:00:00.000Z' };
  assert.equal(verificationState(root, modules, [], module, 'logic', 'any').status, 'pending');
  assert.equal(verificationState(root, modules, [record], module, 'logic', 'any').status, 'fail');
  assert.equal(verificationState(root, modules, [{ ...record, fingerprint: '0'.repeat(64) }], module, 'logic', 'any').status, 'stale');
  const outputs = new Map();
  writeAvailability({ root, modules, writeJson: (rel, value) => outputs.set(rel, value), writeText: () => {} });
  assert.equal(outputs.get('docs/module_availability/matrix.json').modules.find((item) => item.id === module.id).platforms.macOS.entry_open, true);
});

test('source changes invalidate evidence, generated documentation does not', (t) => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'forge-evidence-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  const module = modules.find((item) => item.id === 'file_picker');
  const source = path.join(dir, 'apps/flutter_forge/lib/modules/platform/file_picker');
  fs.mkdirSync(source, { recursive: true });
  fs.writeFileSync(path.join(source, 'module_entry.dart'), 'first');
  const before = fingerprint(dir, [module], module.id, 'logic', 'any');
  fs.writeFileSync(path.join(source, 'AI_ANALYSIS.md'), '{}');
  assert.equal(fingerprint(dir, [module], module.id, 'logic', 'any'), before);
  fs.writeFileSync(path.join(source, 'module_entry.dart'), 'changed');
  assert.notEqual(fingerprint(dir, [module], module.id, 'logic', 'any'), before);
});

test('visual expectation edits expire UI evidence without expiring logic or build evidence', (t) => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'forge-visual-evidence-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  const module = modules.find((item) => item.id === 'font_picker');
  const source = path.join(dir, 'tool/agent_indexes');
  fs.mkdirSync(source, { recursive: true });
  const file = path.join(source, 'visual_flows.js');
  fs.writeFileSync(file, 'first visual expectation');
  const logic = fingerprint(dir, [module], module.id, 'logic', 'any');
  const build = fingerprint(dir, [module], '*', 'compile', 'macOS');
  const ui = fingerprint(dir, [module], module.id, 'ui', 'macOS');
  fs.writeFileSync(file, 'changed visual expectation');
  assert.equal(fingerprint(dir, [module], module.id, 'logic', 'any'), logic);
  assert.equal(fingerprint(dir, [module], '*', 'compile', 'macOS'), build);
  assert.notEqual(fingerprint(dir, [module], module.id, 'ui', 'macOS'), ui);
});

test('evidence artifacts cannot escape the checkout or be silently replaced', (t) => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'forge-evidence-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  const directory = path.join(dir, 'docs/module_availability/evidence');
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(path.join(dir, 'proof.log'), 'proof');
  const record = { schema: 'flutter_forge.module_evidence.v1', source: 'automated_command', command: ['flutter', 'test'], exit_code: 0,
    test_summary: { success: true, completed: 1, failed: 0, skipped: 0 }, module: modules[0].id, kind: 'logic', platform: 'any',
    status: 'pass', fingerprint: '0'.repeat(64), recorded_at: '2026-10-04T00:00:00.000Z', revision: { commit: '0'.repeat(40), dirty: true }, environment: 'host',
    artifacts: [{ path: 'proof.log', sha256: sha256('proof') }] };
  const file = path.join(directory, 'record.json');
  fs.writeFileSync(file, JSON.stringify(record));
  assert.equal(readEvidence(dir, modules).length, 1);
  fs.writeFileSync(path.join(dir, 'proof.log'), 'changed');
  assert.throws(() => readEvidence(dir, modules), /changed evidence artifact/);
  fs.writeFileSync(file, JSON.stringify({ ...record, artifacts: [{ path: '../outside', sha256: '0'.repeat(64) }] }));
  assert.throws(() => readEvidence(dir, modules), /Invalid evidence path/);
});

test('a skipped integration flow cannot be reported as successful execution', () => {
  const events = [
    { type: 'testStart', test: { id: 1 } }, { type: 'testDone', testID: 1, result: 'success', skipped: true, hidden: false }, { type: 'done', success: true },
  ].map(JSON.stringify).join('\n');
  const summary = testSummary(events);
  assert.equal(summary.completed, 0);
  assert.equal(summary.skipped, 1);
  const command = commandFor(root, modules, { kind: 'execution', module: 'flutter_scene_3d', platform: 'macOS', device: 'macos', integration: 'integration_test/flutter_scene_3d_flow_test.dart' });
  assert.ok(command.args.includes('--machine'));
  assert.throws(() => commandFor(root, modules, { kind: 'compile', module: 'file_picker', platform: 'macOS' }), /whole-app/);
  assert.throws(() => parseArgs(['check', '--kind', 'logic', '--kind', 'ui']), /Invalid arguments/);
});

test('batch test results are attributed to their suite directory, including hidden load failures', () => {
  const events = [
    { type: 'suite', suite: { id: 0, path: '/app/test/modules/basic/first/first_test.dart' } },
    { type: 'suite', suite: { id: 1, path: '/app/test/modules/basic/second/second_test.dart' } },
    { type: 'testStart', test: { id: 2, suiteID: 0 } }, { type: 'testStart', test: { id: 3, suiteID: 1 } },
    { type: 'testDone', testID: 2, result: 'success', skipped: false, hidden: false },
    { type: 'testDone', testID: 3, result: 'error', skipped: false, hidden: true }, { type: 'done', success: false },
  ].map(JSON.stringify).join('\n');
  assert.equal(testSummary(events, '/app/test/modules/basic/first').completed, 1);
  assert.equal(testSummary(events, '/app/test/modules/basic/first').failed, 0);
  assert.equal(testSummary(events, '/app/test/modules/basic/second').completed, 0);
  assert.equal(testSummary(events, '/app/test/modules/basic/second').failed, 1);
});

test('generated runtime policy has no acceptance or evidence dependency', () => {
  let output;
  writePolicies({ modules, writeText: (_, content) => { output = content; } });
  assert.match(output, /scene_controls/);
  assert.doesNotMatch(output, /verification|fingerprint|recorded_at|test_summary/);
});
