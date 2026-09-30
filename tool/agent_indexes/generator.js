const fs = require('fs');
const path = require('path');

// These readers deliberately accept only the block YAML forms used by our manifests.
// A format change must be handled explicitly rather than silently dropping facts.
function scalar(value) {
  const text = value.trim();
  const quoted = text.match(/^(['"])(.*)\1$/);
  if (quoted) return quoted[2];
  if (!text || /[\s#{}\[\]]/.test(text)) throw new Error(`Unsupported manifest scalar: ${text}`);
  return text;
}

function yamlBlock(source, key, indent) {
  const lines = source.split('\n');
  const start = lines.findIndex((line) => line === `${' '.repeat(indent)}${key}:`);
  if (start < 0) throw new Error(`Missing manifest block: ${key}`);
  const block = [];
  for (const line of lines.slice(start + 1)) {
    if (!line.trim() || line.trimStart().startsWith('#')) continue;
    const spaces = line.length - line.trimStart().length;
    if (spaces <= indent) break;
    block.push(line);
  }
  return block.join('\n');
}

function field(block, key, indent) {
  const match = block.match(new RegExp(`^${' '.repeat(indent)}${key}:\\s*(.+)$`, 'm'));
  if (!match) throw new Error(`Missing manifest field: ${key}`);
  return scalar(match[1]);
}

function gitDependency(manifest, lock, section, name) {
  const declaration = yamlBlock(yamlBlock(manifest, section, 0), name, 2);
  const git = yamlBlock(declaration, 'git', 4);
  const url = field(git, 'url', 6);
  const ref = field(git, 'ref', 6);
  const locked = yamlBlock(yamlBlock(lock, 'packages', 0), name, 2);
  const description = yamlBlock(locked, 'description', 4);
  if (field(locked, 'source', 4) !== 'git' || field(description, 'url', 6) !== url || field(description, 'ref', 6) !== ref) {
    throw new Error(`Manifest/lock Git dependency mismatch: ${name}`);
  }
  return { name, source: 'git', url, ref, resolved_ref: field(description, 'resolved-ref', 6) };
}

function loadFacts(root, modules, workspacePackages) {
  const workspace = fs.readFileSync(path.join(root, 'pubspec.yaml'), 'utf8');
  const manifest = fs.readFileSync(path.join(root, 'apps/flutter_forge/pubspec.yaml'), 'utf8');
  const lock = fs.readFileSync(path.join(root, 'pubspec.lock'), 'utf8');
  const workspaceMembers = yamlBlock(workspace, 'workspace', 0).split('\n').map((line) => {
    const match = line.match(/^  - (.+)$/);
    if (!match) throw new Error(`Unsupported workspace member: ${line}`);
    return scalar(match[1]);
  });
  const expected = ['apps/flutter_forge', ...workspacePackages.map((entry) => entry.path)];
  if (new Set(workspaceMembers).size !== workspaceMembers.length ||
      JSON.stringify([...workspaceMembers].sort()) !== JSON.stringify([...expected].sort())) {
    throw new Error('Workspace members differ from configured package contracts');
  }
  for (const member of workspaceMembers) {
    const memberManifest = fs.readFileSync(path.join(root, member, 'pubspec.yaml'), 'utf8');
    if (field(memberManifest, 'resolution', 0) !== 'workspace') throw new Error(`Missing workspace resolution: ${member}`);
    const packageMeta = workspacePackages.find((entry) => entry.path === member);
    if (field(memberManifest, 'name', 0) !== (packageMeta?.name ?? 'flutter_forge_app')) throw new Error(`Package name mismatch: ${member}`);
  }
  const tool = gitDependency(manifest, lock, 'dev_dependencies', 'flutterguard_cli');
  if (!/^[a-f0-9]{40}$/.test(tool.ref)) throw new Error('FlutterGuard must retain an immutable Git pin');
  const gcodeModule = modules.find((module) => module.id === 'gcode_visualizer');
  if (!gcodeModule) throw new Error('Missing G-code module contract');
  return {
    workspaceMembers,
    currentHosts: ['android', 'ios', 'macos', 'web', 'windows'].filter((host) => fs.existsSync(path.join(root, 'apps/flutter_forge', host))),
    gcodeDependency: gitDependency(manifest, lock, 'dependencies', 'gcode_core'),
    gcodeEntryPlatforms: ['android', 'iOS', 'macOS', 'web', 'windows'].filter((host) => !(gcodeModule.excludedPlatforms ?? []).includes(host)),
    flutterGuardDependency: { package: tool.name, source: tool.source, url: tool.url, ref: tool.ref, resolved_ref: tool.resolved_ref, immutable: true, lock_status: 'git_pinned' },
  };
}

function validateModules(modules, categories, appRoot) {
  const ids = new Set();
  const routes = new Set();
  for (const module of modules) {
    if (!Object.hasOwn(categories, module.category)) throw new Error(`Unknown category: ${module.category}`);
    if (!/^[a-z][a-z0-9_]*$/.test(module.id) || ids.has(module.id)) throw new Error(`Invalid or duplicate module id: ${module.id}`);
    if (!/^\/[a-z][a-z0-9-]*$/.test(module.route) || routes.has(module.route)) throw new Error(`Invalid or duplicate module route: ${module.route}`);
    ids.add(module.id);
    routes.add(module.route);
    if (!['pending', 'ready', 'recommended'].includes(module.status)) throw new Error(`Invalid module status: ${module.id}`);
    if (!['beginner', 'intermediate', 'advanced'].includes(module.difficulty)) throw new Error(`Invalid module difficulty: ${module.id}`);
    if (!module.title || !module.subtitle || !/^[A-Za-z][A-Za-z0-9]*Entry$/.test(module.entry) ||
        !Number.isInteger(module.estimatedMinutes) || module.estimatedMinutes <= 0 ||
        !Array.isArray(module.concepts) || !module.concepts.length || !Array.isArray(module.depends)) {
      throw new Error(`Incomplete learning metadata: ${module.id}`);
    }
    if (module.category === 'platform' && (!Array.isArray(module.excludedPlatforms) || !module.platformSupportComment)) {
      throw new Error(`Platform module must declare exclusions and rationale: ${module.id}`);
    }
    const excluded = module.excludedPlatforms ?? [];
    if (!Array.isArray(excluded) || new Set(excluded).size !== excluded.length ||
        excluded.some((host) => !['android', 'iOS', 'macOS', 'web', 'windows'].includes(host))) {
      throw new Error(`Invalid excluded platforms: ${module.id}`);
    }
    const dir = path.join(appRoot, 'lib/modules', module.category, module.id);
    for (const file of ['module_entry.dart', ...(module.routes ? ['module_routes.dart'] : [])]) {
      if (!fs.existsSync(path.join(dir, file))) throw new Error(`Missing module entry file: ${module.id}/${file}`);
    }
  }
}

function generate({ root, appRoot, check = false }, render) {
  const outputs = new Map();
  function writeText(rel, content) {
    const base = rel === 'lib' || rel.startsWith('lib/') ? appRoot : root;
    const file = path.resolve(base, rel);
    if (path.isAbsolute(rel) || !file.startsWith(`${base}${path.sep}`) || outputs.has(file)) {
      throw new Error(`Invalid or duplicate generated path: ${rel}`);
    }
    outputs.set(file, content);
  }
  render({ writeText, writeJson: (rel, value) => writeText(rel, `${JSON.stringify(value, null, 2)}\n`) });
  // Complete rendering and input validation before touching any generated file.
  const changed = [...outputs].filter(([file, content]) => {
    if (fs.existsSync(file) && fs.lstatSync(file).isSymbolicLink()) throw new Error(`Generated target must not be a symlink: ${file}`);
    return !fs.existsSync(file) || fs.readFileSync(file, 'utf8') !== content;
  });
  if (check && changed.length) throw new Error(`Generated output drift:\n${changed.map(([file]) => path.relative(root, file)).join('\n')}`);
  if (!check) {
    for (const [file, content] of changed) {
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, content);
    }
  }
  return { outputs: outputs.size, changed: changed.length };
}

module.exports = { loadFacts, validateModules, generate };
