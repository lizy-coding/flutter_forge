const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const vm = require('vm');
const { spawnSync } = require('child_process');
const { test } = require('node:test');
const { candidateFromOptions } = require('./module_spec');
const { categoryComments, catalogFor } = require('./catalog');
const { capabilities, targets, resolveModules } = require('./availability');
const { machineContracts, writeContracts } = require('./contracts');
const { validateModules } = require('./generator');

const base = { category: 'basic', name: 'candidate_lesson', title: '候选学习模块', subtitle: '待补充的学习练习' };

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'forge-module-spec-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  // Seed only the exact evidence paths declared by adapter rules, not a checkout.
  for (const rel of new Set(Object.values(capabilities).flatMap((rule) => rule.sources))) {
    const file = path.join(root, rel);
    if (path.extname(rel)) {
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, 'fixture');
    } else fs.mkdirSync(file, { recursive: true });
  }
  return root;
}

function formalContract(root, declaration) {
  const appRoot = path.join(root, 'apps/flutter_forge');
  const directory = path.join(appRoot, 'lib/modules', declaration.category, declaration.id);
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(path.join(directory, 'module_entry.dart'), "import 'package:flutter/material.dart';\nimport 'module_root.dart';\n");
  fs.writeFileSync(path.join(directory, 'module_root.dart'), "import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';\n");
  const modules = resolveModules(root, [declaration]);
  validateModules(modules, categoryComments, appRoot);
  const outputs = new Map();
  writeContracts({ appRoot, modules, workspacePackages: [], categoryMeta: catalogFor(modules), contracts: machineContracts,
    facts: { gcodeDependency: { url: 'fixture', ref: 'fixture' } }, writeJson: (rel, value) => outputs.set(rel, value) });
  return outputs.get(`lib/modules/${declaration.category}/${declaration.id}/AI_ANALYSIS.md`);
}

test('every catalog category produces pending candidates and the same formal contract', (t) => {
  const root = fixture(t);
  for (const category of Object.keys(categoryComments)) {
    const candidate = candidateFromOptions({ ...base, category }, root);
    assert.equal(candidate.spec.declaration.status, 'pending');
    assert.equal(candidate.spec.routeRegistration, 'explicit_review_required');
    assert.deepEqual(candidate.contract.platform_support.target_platforms, targets);
    assert.deepEqual(candidate.contract.platform_support.excluded_platforms, []);
    assert.deepEqual(candidate.contract, formalContract(root, candidate.spec.declaration));
    const fragment = vm.runInNewContext(`[${candidate.registration}]`);
    assert.equal(JSON.stringify(fragment[0]), JSON.stringify(candidate.spec.declaration));
  }
});

test('required and optional adapters derive real platform boundaries through the formal resolver', (t) => {
  const root = fixture(t);
  const required = candidateFromOptions({ ...base, category: 'platform', depends: 'file_picker_bridge' }, root);
  assert.deepEqual(required.contract.platform_support.excluded_platforms, ['iOS']);
  assert.deepEqual(required.contract, formalContract(root, required.spec.declaration));
  const optional = candidateFromOptions({ ...base, depends: 'file_picker_bridge', 'optional-capabilities': 'file_selection' }, root);
  assert.deepEqual(optional.contract.platform_support.excluded_platforms, []);
  assert.deepEqual(optional.contract.platform_support.features.file_selection.platforms, ['android', 'macOS', 'web', 'windows']);
  assert.deepEqual(optional.contract, formalContract(root, optional.spec.declaration));
});

test('product restrictions require evidence and close entries consistently', (t) => {
  const root = fixture(t);
  fs.writeFileSync(path.join(root, 'restriction.md'), 'product decision');
  const options = { ...base, 'restriction-reason': 'product_workflow_deferred', 'restriction-sources': 'restriction.md' };
  const candidate = candidateFromOptions(options, root);
  assert.deepEqual(candidate.contract.platform_support.excluded_platforms, targets);
  assert.deepEqual(candidate.contract, formalContract(root, candidate.spec.declaration));
  for (const sources of ['', 'missing.md', '../outside.md']) {
    assert.throws(() => candidateFromOptions({ ...options, 'restriction-sources': sources }, root), /restriction/i);
  }
  assert.throws(() => candidateFromOptions({ ...base, 'restriction-sources': 'restriction.md' }, root), /restriction-reason/);
});

test('unknown options, legacy platform declarations and invalid capability intent fail', () => {
  for (const option of ['platforms', 'supportedPlatforms', 'excludedPlatforms', 'unknown']) {
    assert.throws(() => candidateFromOptions({ ...base, [option]: 'web' }), /Unknown or invalid option/);
  }
  assert.throws(() => candidateFromOptions({ ...base, category: 'popupTable' }), /Invalid category/);
  assert.throws(() => candidateFromOptions({ ...base, name: 'bad__class' }), /Invalid module name/);
  assert.throws(() => candidateFromOptions({ ...base, 'optional-capabilities': 'unknown' }), /Unknown optional capability/);
  assert.throws(() => candidateFromOptions({ ...base, 'optional-capabilities': 'file_selection' }), /not discovered/);
  assert.throws(() => candidateFromOptions({ ...base, 'optional-capabilities': 'file_selection,file_selection' }), /Duplicate/);
  assert.throws(() => candidateFromOptions({ ...base, minutes: '1.5' }), /positive integer/);
});

test('loading and previewing the helper never enumerate module sources', () => {
  const source = `const fs = require('fs'); fs.readdirSync = () => { throw Error('unexpected source enumeration'); };
    const helper = require(${JSON.stringify(path.join(__dirname, 'module_spec.js'))});
    helper.candidateFromOptions(${JSON.stringify(base)});
    if (require.cache[require.resolve(${JSON.stringify(path.join(__dirname, '../generate_agent_indexes.js'))})]) throw Error('loaded registry');`;
  const result = spawnSync(process.execPath, ['-e', source], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
});
