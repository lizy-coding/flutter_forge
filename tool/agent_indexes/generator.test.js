const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { test } = require('node:test');
const { loadFacts, validateModules, generate } = require('./generator');
const { categoryComments, workspacePackages, catalogFor } = require('./catalog');
const { modules } = require('../generate_agent_indexes');
const root = path.resolve(__dirname, '../..');
const appRoot = path.join(root, 'apps/flutter_forge');

function fixture(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'forge-generator-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  for (const rel of ['pubspec.yaml', 'pubspec.lock', 'apps/flutter_forge/pubspec.yaml', ...workspacePackages.map((p) => `${p.path}/pubspec.yaml`)]) {
    fs.mkdirSync(path.dirname(path.join(dir, rel)), { recursive: true });
    fs.copyFileSync(path.join(root, rel), path.join(dir, rel));
  }
  return dir;
}

test('dependency and workspace facts match manifests, including the app and window package', () => {
  const facts = loadFacts(root, modules, workspacePackages);
  assert.ok(facts.workspaceMembers.includes('apps/flutter_forge'));
  assert.ok(facts.workspaceMembers.includes('packages/desktop_multi_window'));
  const manifest = fs.readFileSync(path.join(root, 'apps/flutter_forge/pubspec.yaml'), 'utf8');
  assert.ok(manifest.includes(`ref: ${facts.gcodeDependency.ref}`));
  assert.match(facts.gcodeDependency.resolved_ref, /^[a-f0-9]{40}$/);
});

test('Git manifest/lock drift fails rather than publishing stale dependency facts', (t) => {
  const dir = fixture(t);
  const file = path.join(dir, 'apps/flutter_forge/pubspec.yaml');
  const declaredRef = loadFacts(root, modules, workspacePackages).gcodeDependency.ref;
  fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replace(`ref: ${declaredRef}`, `ref: ${declaredRef}-stale`));
  assert.throws(() => loadFacts(dir, modules, workspacePackages), /Git dependency mismatch: gcode_core/);
});

test('unconfigured workspace members cannot disappear from generated contracts', (t) => {
  const dir = fixture(t);
  const file = path.join(dir, 'pubspec.yaml');
  fs.appendFileSync(file, '  - packages/unconfigured\n');
  assert.throws(() => loadFacts(dir, modules, workspacePackages), /Workspace members differ/);
});

test('new module membership and dependencies reach category contracts automatically', () => {
  const extra = { ...modules[0], id: 'additional_module', depends: ['additional_capability'] };
  const category = catalogFor([...modules, extra]).basic;
  assert.ok(category[0].includes('additional_module'));
  assert.ok(category[2].includes('additional_capability'));
});

test('duplicate routes and invalid platform declarations fail preflight', () => {
  assert.throws(() => validateModules([...modules, { ...modules[0], id: 'different_id' }], categoryComments, appRoot), /duplicate module route/);
  const broken = modules.map((m) => m.id === 'bluetooth_ble' ? { ...m, excludedPlatforms: ['linux'] } : m);
  assert.throws(() => validateModules(broken, categoryComments, appRoot), /Invalid excluded platforms/);
});

test('render failure leaves every existing output untouched', (t) => {
  const dir = fixture(t);
  const file = path.join(dir, 'existing.json');
  fs.writeFileSync(file, 'original');
  assert.throws(() => generate({ root: dir, appRoot: path.join(dir, 'apps/flutter_forge') }, ({ writeText }) => {
    writeText('existing.json', 'replacement');
    throw new Error('render failed');
  }), /render failed/);
  assert.equal(fs.readFileSync(file, 'utf8'), 'original');
});

test('check reports drift without writing, generation is idempotent', (t) => {
  const dir = fixture(t);
  const config = { root: dir, appRoot: path.join(dir, 'apps/flutter_forge') };
  const render = ({ writeJson }) => writeJson('example.json', { active: true });
  assert.throws(() => generate({ ...config, check: true }, render), /Generated output drift/);
  assert.equal(fs.existsSync(path.join(dir, 'example.json')), false);
  assert.equal(generate(config, render).changed, 1);
  const stamp = fs.statSync(path.join(dir, 'example.json')).mtimeMs;
  assert.equal(generate(config, render).changed, 0);
  assert.equal(generate({ ...config, check: true }, render).changed, 0);
  assert.equal(fs.statSync(path.join(dir, 'example.json')).mtimeMs, stamp);
});

test('duplicate outputs and escaping paths are rejected before writing', (t) => {
  const dir = fixture(t);
  const config = { root: dir, appRoot: path.join(dir, 'apps/flutter_forge') };
  assert.throws(() => generate(config, ({ writeText }) => writeText('../outside.json', 'bad')), /Invalid or duplicate/);
  assert.throws(() => generate(config, ({ writeText }) => {
    writeText('duplicate.json', 'first');
    writeText('duplicate.json', 'second');
  }), /Invalid or duplicate/);
  assert.equal(fs.existsSync(path.join(dir, 'duplicate.json')), false);
});


test('module preflight rejects direct imports of sibling modules', (t) => {
  const dir = fixture(t);
  const appRoot = path.join(dir, 'apps/flutter_forge');
  const samples = modules.slice(0, 2);
  for (const module of samples) {
    const target = path.join(appRoot, 'lib/modules', module.category, module.id);
    fs.mkdirSync(target, { recursive: true });
    fs.writeFileSync(path.join(target, 'module_entry.dart'), '');
    fs.writeFileSync(path.join(target, 'module_routes.dart'), '');
  }
  fs.writeFileSync(path.join(appRoot, 'lib/modules/basic/tree_state/module_entry.dart'), "import '../microtask/module_entry.dart';");
  assert.throws(() => validateModules(samples, categoryComments, appRoot), /Cross-module dependency/);
});
