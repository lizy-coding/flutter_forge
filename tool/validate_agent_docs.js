const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const failures = [];
const documents = new Map();

function readJson(rel) {
  try {
    const source = fs.readFileSync(path.join(root, rel), 'utf8');
    if (/[^\x00-\x7F]/.test(source)) failures.push(`${rel}:non_ascii_content`);
    const document = JSON.parse(source);
    documents.set(rel, document);
    return document;
  } catch (error) {
    failures.push(`${rel}:invalid_json:${error.message}`);
    return null;
  }
}

function collectAnalysisFiles(dir) {
  const result = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.') || entry.name === 'build') continue;
    const absolute = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      result.push(...collectAnalysisFiles(absolute));
    } else if (entry.name === 'AI_ANALYSIS.md') {
      result.push(path.relative(root, absolute));
    }
  }
  return result;
}

const machineDocuments = [
  'AI_ANALYSIS_SCHEMA.json',
  'AI_PROJECT_CONTEXT.md',
  'REFACTOR_PLAN.md',
  'lib/AI_MODULE_INDEX.md',
  ...collectAnalysisFiles(root),
];

const requiredAnalysisKeys = [
  'schema',
  'mode',
  'node',
  'entrypoints',
  'owns',
  'depends',
  'children',
  'contracts',
  'validation',
];

for (const rel of [...new Set(machineDocuments)].sort()) {
  const document = readJson(rel);
  if (!document) continue;
  if (path.basename(rel) !== 'AI_ANALYSIS.md') continue;

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
    if (!fs.existsSync(path.join(root, childPath))) {
      failures.push(`${rel}:missing_child:${child}`);
    }
  }
}

const moduleIndex = documents.get('lib/AI_MODULE_INDEX.md');
if (moduleIndex) {
  if (moduleIndex.count !== moduleIndex.modules?.length) {
    failures.push('lib/AI_MODULE_INDEX.md:count_mismatch');
  }
  const ids = new Set();
  const routes = new Set();
  for (const module of moduleIndex.modules ?? []) {
    if (ids.has(module.id)) failures.push(`lib/AI_MODULE_INDEX.md:duplicate_id:${module.id}`);
    if (routes.has(module.route)) failures.push(`lib/AI_MODULE_INDEX.md:duplicate_route:${module.route}`);
    ids.add(module.id);
    routes.add(module.route);

    const contract = documents.get(module.analysis);
    if (!contract) {
      failures.push(`lib/AI_MODULE_INDEX.md:missing_analysis:${module.analysis}`);
      continue;
    }
    for (const key of ['route', 'category']) {
      if (contract[key] !== module[key]) {
        failures.push(`${module.analysis}:index_mismatch:${key}`);
      }
    }
    if (contract.node?.status !== module.status) {
      failures.push(`${module.analysis}:index_mismatch:status`);
    }
  }
}

if (failures.length > 0) {
  process.stderr.write(`${failures.join('\n')}\n`);
  process.exit(1);
}

process.stdout.write(`agent_docs_valid:${new Set(machineDocuments).size}\n`);
