const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const appRoot = path.join(root, 'apps/flutter_forge');
const failures = [];
const documents = new Map();

const VALID_CATEGORIES = ['basic', 'async', 'state', 'ui', 'popup_table', 'platform'];
const workspacePackages = [
  ['gcode_core', 'packages/gcode_core'],
  ['file_picker_bridge', 'packages/file_picker_bridge'],
  ['flutter_ioc_core', 'packages/flutter_ioc_core'],
];

// ── helpers ──────────────────────────────────────────────────────

function readJson(rel) {
  try {
    const source = fs.readFileSync(resolveProjectPath(rel), 'utf8');
    if (/[^\x00-\x7F]/.test(source)) failures.push(`${rel}:non_ascii_content`);
    const document = JSON.parse(source);
    documents.set(rel, document);
    return document;
  } catch (error) {
    failures.push(`${rel}:invalid_json:${error.message}`);
    return null;
  }
}

function collectAnalysisFiles(dir, base = dir) {
  const result = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.') || entry.name === 'build') continue;
    const absolute = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      result.push(...collectAnalysisFiles(absolute, base));
    } else if (entry.name === 'AI_ANALYSIS.md') {
      result.push(path.relative(base, absolute));
    }
  }
  return result;
}

function fileExists(rel) {
  return fs.existsSync(resolveProjectPath(rel));
}

function resolveProjectPath(rel) {
  return path.join(rel === 'lib' || rel.startsWith('lib/') ? appRoot : root, rel);
}

function grepInFile(rel, pattern) {
  if (!fileExists(rel)) return false;
  const content = fs.readFileSync(resolveProjectPath(rel), 'utf8');
  return pattern.test(content);
}

function scanModuleDirs() {
  const dirs = [];
  const modulesRoot = path.join(appRoot, 'lib/modules');
  if (!fs.existsSync(modulesRoot)) return dirs;
  for (const cat of fs.readdirSync(modulesRoot, { withFileTypes: true })) {
    if (!cat.isDirectory() || cat.name.startsWith('.')) continue;
    for (const mod of fs.readdirSync(path.join(modulesRoot, cat.name), { withFileTypes: true })) {
      if (!mod.isDirectory() || mod.name.startsWith('.')) continue;
      const relPath = `lib/modules/${cat.name}/${mod.name}`;
      dirs.push({ category: cat.name, module: mod.name, path: relPath });
    }
  }
  return dirs;
}

// ── collect all machine documents ─────────────────────────────────

const machineDocuments = [
  'AI_ANALYSIS_SCHEMA.json',
  'AI_PROJECT_CONTEXT.md',
  'REFACTOR_PLAN.md',
  'lib/AI_MODULE_INDEX.md',
  'AI_ANALYSIS.md',
  ...collectAnalysisFiles(appRoot),
  ...workspacePackages.map(([, packagePath]) => `${packagePath}/AI_ANALYSIS.md`),
];

// ── phase 1: JSON parse + key validation ──────────────────────────

const requiredAnalysisKeys = [
  'schema', 'mode', 'node', 'entrypoints', 'owns',
  'depends', 'children', 'contracts', 'validation',
];

for (const rel of [...new Set(machineDocuments)].sort()) {
  const document = readJson(rel);
  if (!document) continue;
  const basename = path.basename(rel);
  if (basename !== 'AI_ANALYSIS.md') continue;

  for (const key of requiredAnalysisKeys) {
    if (!(key in document)) failures.push(`${rel}:missing_key:${key}`);
  }
  if (document.contracts?.no_natural_language !== true) {
    failures.push(`${rel}:contract:no_natural_language`);
  }
  if (document.contracts?.doc_consumer !== 'coding_agent') {
    failures.push(`${rel}:contract:doc_consumer`);
  }
  if (document.contracts?.doc_mode !== 'machine_contract') {
    failures.push(`${rel}:contract:doc_mode`);
  }

  for (const child of document.children ?? []) {
    const childPath = path.normalize(path.join(path.dirname(rel), child));
    if (!fileExists(childPath)) {
      failures.push(`${rel}:missing_child:${child}`);
    }
  }
}

// ── phase 2: module index validation ──────────────────────────────

const moduleIndex = documents.get('lib/AI_MODULE_INDEX.md');
if (moduleIndex) {
  if (moduleIndex.count !== moduleIndex.modules?.length) {
    failures.push('lib/AI_MODULE_INDEX.md:count_mismatch');
  }
  const ids = new Set();
  const routes = new Set();
  const indexedModules = new Map();

  for (const mod of moduleIndex.modules ?? []) {
    indexedModules.set(mod.id, mod);

    if (ids.has(mod.id)) failures.push(`lib/AI_MODULE_INDEX.md:duplicate_id:${mod.id}`);
    if (routes.has(mod.route)) failures.push(`lib/AI_MODULE_INDEX.md:duplicate_route:${mod.route}`);
    ids.add(mod.id);
    routes.add(mod.route);

    const contract = documents.get(mod.analysis);
    if (!contract) {
      failures.push(`lib/AI_MODULE_INDEX.md:missing_analysis:${mod.analysis}`);
      continue;
    }
    for (const key of ['route', 'category']) {
      if (contract[key] !== mod[key]) {
        failures.push(`${mod.analysis}:index_mismatch:${key}`);
      }
    }
    if (contract.node?.status !== mod.status) {
      failures.push(`${mod.analysis}:index_mismatch:status`);
    }
  }

  // ── phase 3: directory ↔ index cross-check ──────────────────────

  const dirModules = scanModuleDirs();
  const dirModuleIds = new Set(dirModules.map(d => d.module));
  const dirModulePaths = new Map(dirModules.map(d => [d.module, d.path]));

  // Every directory must be in the index
  for (const dirMod of dirModules) {
    if (!VALID_CATEGORIES.includes(dirMod.category)) {
      failures.push(`${dirMod.path}:invalid_category:${dirMod.category}`);
    }
    if (!ids.has(dirMod.module)) {
      failures.push(`${dirMod.path}:unregistered_module — not found in lib/AI_MODULE_INDEX.md`);
    }
  }

  // Every index entry must have a matching directory
  for (const mod of moduleIndex.modules ?? []) {
    if (!dirModuleIds.has(mod.id)) {
      failures.push(`${mod.analysis}:orphan_index_entry — no directory under lib/modules/`);
      continue;
    }
    const expectedPath = dirModulePaths.get(mod.id);
    if (mod.path !== expectedPath) {
      failures.push(`${mod.analysis}:path_mismatch:index=${mod.path} fs=${expectedPath}`);
    }
  }

  // ── phase 4: naming conventions ─────────────────────────────────

  const SNAKE_CASE = /^[a-z][a-z0-9_]*$/;
  const KEBAB_ROUTE = /^\/[a-z][a-z0-9-]*$/;

  for (const dirMod of dirModules) {
    if (!SNAKE_CASE.test(dirMod.module)) {
      failures.push(`${dirMod.path}:naming_convention:dir must be snake_case, got "${dirMod.module}"`);
    }
  }

  for (const mod of moduleIndex.modules ?? []) {
    if (!KEBAB_ROUTE.test(mod.route)) {
      failures.push(`${mod.analysis}:naming_convention:route must be kebab-case starting with /, got "${mod.route}"`);
    }
  }

  // ── phase 5: module_entry.dart + teaching template check ────────

  for (const mod of moduleIndex.modules ?? []) {
    const entryFile = `${mod.path}/module_entry.dart`;
    if (!fileExists(entryFile)) {
      failures.push(`${mod.path}:missing_module_entry`);
    }

    // Check at least one .dart file in the module imports the shared learning UI.
    const modDir = resolveProjectPath(mod.path);
    if (fs.existsSync(modDir)) {
      let hasTeachingDep = false;
      function walk(dir) {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
          if (entry.name.startsWith('.') || entry.name === 'AI_ANALYSIS.md') continue;
          const abs = path.join(dir, entry.name);
          if (entry.isDirectory()) {
            walk(abs);
          } else if (entry.name.endsWith('.dart')) {
            const content = fs.readFileSync(abs, 'utf8');
            if (/shared\/learning\/learning_scaffold/.test(content)) {
              hasTeachingDep = true;
            }
          }
        }
      }
      walk(modDir);
      if (!hasTeachingDep) {
        failures.push(`${mod.path}:missing_teaching_dependency — no file imports shared learning UI`);
      }
    }
  }

  // ── phase 5b: single-source consistency — generate source vs index vs route table ──

  function readGenerateSourceModules() {
    const source = fs.readFileSync(path.join(root, 'tool/generate_agent_indexes.js'), 'utf8');
    const start = source.indexOf('const modules = [');
    if (start === -1) return [];
    const end = source.indexOf('];', start);
    const block = source.slice(start, end);
    const result = [];
    const re = /\{\s*category:\s*'([a-z0-9_]+)'\s*,\s*id:\s*'([a-z0-9_]+)'\s*,\s*route:\s*'([^']+)'\s*,\s*status:\s*'([a-z_]+)'/g;
    let match;
    while ((match = re.exec(block))) {
      result.push({ category: match[1], id: match[2], route: match[3], status: match[4] });
    }
    return result;
  }

  const generateModules = readGenerateSourceModules();
  const generateById = new Map(generateModules.map((m) => [m.id, m]));
  const routeTableContent = fileExists('lib/app/router/app_route_table.dart')
    ? fs.readFileSync(resolveProjectPath('lib/app/router/app_route_table.dart'), 'utf8')
    : '';

  for (const mod of moduleIndex.modules ?? []) {
    const gen = generateById.get(mod.id);
    if (!gen) {
      failures.push(`generate source:missing_module:${mod.id} — not in tool/generate_agent_indexes.js`);
      continue;
    }
    for (const key of ['category', 'route', 'status']) {
      if (gen[key] !== mod[key]) {
        failures.push(`generate source:${mod.id}:mismatch:${key} index=${mod[key]} source=${gen[key]}`);
      }
    }
    if (routeTableContent && !routeTableContent.includes(`path: '${mod.route}'`)) {
      failures.push(`app_route_table.dart:missing_module_path:${mod.route}`);
    }
  }
  for (const gen of generateModules) {
    if (!ids.has(gen.id)) {
      failures.push(`generate source:orphan_module:${gen.id} — registered but missing from lib/AI_MODULE_INDEX.md`);
    }
  }
}

// ── phase 6: workspace package contract validation ─────────────────

for (const [packageName, packagePath] of workspacePackages) {
  const analysisPath = `${packagePath}/AI_ANALYSIS.md`;
  const manifestPath = `${packagePath}/pubspec.yaml`;
  const contract = documents.get(analysisPath);
  if (!contract) {
    failures.push(`${analysisPath}:missing_package_contract`);
    continue;
  }
  if (contract.mode !== 'package_contract') {
    failures.push(`${analysisPath}:mode:package_contract`);
  }
  if (contract.node?.package !== packageName) {
    failures.push(`${analysisPath}:package_name_mismatch`);
  }
  if (contract.node?.path !== packagePath) {
    failures.push(`${analysisPath}:package_path_mismatch`);
  }

  if (fileExists(manifestPath)) {
    const manifest = fs.readFileSync(path.join(root, manifestPath), 'utf8');
    if (!new RegExp(`^name:\\s*${packageName}$`, 'm').test(manifest)) {
      failures.push(`${manifestPath}:name_mismatch`);
    }
    if (!/^resolution:\s*workspace$/m.test(manifest)) {
      failures.push(`${manifestPath}:missing_workspace_resolution`);
    }
  }
}

// ── phase 7: schema document validation ───────────────────────────

const schema = documents.get('AI_ANALYSIS_SCHEMA.json');
if (schema) {
  // Verify schema declares all known analysis files
  const declared = new Set();
  for (const level of Object.values(schema.levels ?? {})) {
    for (const f of level) {
      // Normalize glob patterns to check if they match
      if (f.includes('*')) {
        // Glob pattern like "lib/modules/*/*/AI_ANALYSIS.md"
        // Count how many actual files match
        let count = 0;
        for (const doc of documents.keys()) {
          if (doc.startsWith('lib/modules/') && path.basename(doc) === 'AI_ANALYSIS.md') {
            // Only match module-level (2 levels deep under modules/)
            const parts = doc.split('/');
            if (parts.length === 5) count++; // lib/modules/cat/mod/AI_ANALYSIS.md
          }
        }
        if (count > 0) declared.add(f);
      } else {
        declared.add(f);
      }
    }
  }
}

// ── report ────────────────────────────────────────────────────────

if (failures.length > 0) {
  process.stderr.write(`${failures.join('\n')}\n`);
  process.exit(1);
}

process.stdout.write(`agent_docs_valid:${new Set(machineDocuments).size}\n`);
