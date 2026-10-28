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

// Keep candidate/source consistency checks in the existing quality-gate entry.
require('./module_spec.test');

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

test('manifest and lock facts accept CRLF checkouts', (t) => {
  const dir = fixture(t);
  for (const rel of ['pubspec.yaml', 'pubspec.lock', 'apps/flutter_forge/pubspec.yaml', ...workspacePackages.map((p) => `${p.path}/pubspec.yaml`)]) {
    const file = path.join(dir, rel);
    fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replace(/\r?\n/g, '\r\n'));
  }
  assert.deepEqual(loadFacts(dir, modules, workspacePackages).workspaceMembers,
    loadFacts(root, modules, workspacePackages).workspaceMembers);
  const {execFileSync} = require('node:child_process');
  fs.mkdirSync(path.join(dir, 'tool'));
  fs.copyFileSync(path.join(root, 'tool/workspace_members.js'), path.join(dir, 'tool/workspace_members.js'));
  const members = execFileSync(process.execPath, [path.join(dir, 'tool/workspace_members.js')], {encoding:'utf8'}).trim().split('\n');
  assert.deepEqual(members, loadFacts(root, modules, workspacePackages).workspaceMembers);
});

test('document validator accepts Windows relative path separators', () => {
  const vm = require('node:vm');
  const {createRequire} = require('node:module');
  const file = path.join(root, 'tool/validate_agent_docs.js');
  const localRequire = createRequire(file);
  const output = [];
  vm.runInNewContext(fs.readFileSync(file, 'utf8'), {
    __dirname: path.dirname(file),
    require: (name) => name === 'path' ? {
      ...path,
      relative: (...args) => path.relative(...args).replace(/\//g, '\\'),
      normalize: (value) => path.normalize(value).replace(/\//g, '\\'),
    } : localRequire(name),
    console: {log: (...args) => output.push(args.join(' ')), error: (...args) => output.push(args.join(' '))},
    process: {stdout: {write: (value) => output.push(value)}, stderr: {write: (value) => output.push(value)}, exit: (code) => assert.fail(`validator exited ${code}: ${output.join('\n')}`)},
  }, {filename: file});
  assert.match(output.join('\n'), /agent_docs_valid:\d+/);
});


test('CRLF generated output is equivalent and check remains read-only', (t) => {
  const dir = fixture(t);
  const config = {root: dir, appRoot: path.join(dir, 'apps/flutter_forge')};
  const render = ({writeJson}) => writeJson('example.json', {active: true});
  generate(config, render);
  const file = path.join(dir, 'example.json');
  const crlf = fs.readFileSync(file, 'utf8').replace(/\n/g, '\r\n');
  fs.writeFileSync(file, crlf);
  assert.equal(generate({...config, check: true}, render).changed, 0);
  assert.equal(fs.readFileSync(file, 'utf8'), crlf);
  fs.writeFileSync(file, crlf.replace('true', 'false'));
  assert.throws(() => generate({...config, check: true}, render), /Generated output drift/);
});
