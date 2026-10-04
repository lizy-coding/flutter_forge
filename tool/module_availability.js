#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { spawnSync } = require('child_process');
const { targets } = require('./agent_indexes/availability');
const { acceptanceCases, casePlatforms } = require('./agent_indexes/acceptance_cases');
const { evidenceDirectory, kinds, sha256, relativeFile, fingerprint, testInventory } = require('./agent_indexes/verification');

const root = path.resolve(__dirname, '..');

function parseArgs(args) {
  const [command, ...rest] = args;
  const options = {};
  const allowed = ['module', 'kind', 'platform', 'status', 'environment', 'evidence', 'cases', 'device', 'integration'];
  for (let i = 0; i < rest.length; i += 2) {
    const key = rest[i]?.replace(/^--/, '');
    if (!rest[i]?.startsWith('--') || !allowed.includes(key) || !rest[i + 1] || rest[i + 1].startsWith('--') || Object.hasOwn(options, key)) {
      throw new Error('Invalid arguments; use node tool/module_availability.js help');
    }
    options[key] = rest[i + 1];
  }
  return { command, options };
}

function testSummary(output, suiteDirectory) {
  const tests = new Map();
  const suites = new Map();
  const done = [];
  let success = false;
  for (const line of output.split('\n')) {
    let event;
    try { event = JSON.parse(line); } catch { continue; }
    if (event.type === 'suite') suites.set(event.suite.id, event.suite.path);
    if (event.type === 'testStart') tests.set(event.test.id, event.test);
    if (event.type === 'testDone') done.push(event);
    if (event.type === 'done') success = event.success === true;
  }
  const normalizedDirectory = suiteDirectory?.replace(/\\/g, '/');
  const scoped = done.filter((event) => tests.has(event.testID) && (!suiteDirectory ||
    suites.get(tests.get(event.testID).suiteID)?.replace(/\\/g, '/').startsWith(`${normalizedDirectory}/`)));
  const relevant = scoped.filter((event) => !event.hidden);
  return { completed: relevant.filter((event) => !event.skipped && event.result === 'success').length,
    skipped: relevant.filter((event) => event.skipped).length,
    failed: scoped.filter((event) => event.result === 'error' || event.result === 'failure').length,
    success };
}

function commandFor(root, modules, options) {
  const module = modules.find((item) => item.id === options.module);
  if (options.kind === 'logic') {
    if (!module || (options.platform && options.platform !== 'any')) throw new Error('Logic needs one module and platform any');
    const inventory = testInventory(root, module);
    if (!inventory.files.length) throw new Error(`No module tests: ${module.id}`);
    return { executable: 'flutter', args: ['test', inventory.directory.replace('apps/flutter_forge/', ''), '--no-pub', '--machine'], platform: 'any', module: module.id };
  }
  if (options.kind === 'compile') {
    if (options.module && options.module !== '*') throw new Error('Compilation is whole-app evidence; omit --module');
    const host = ({ macOS: 'macos', iOS: 'ios' })[options.platform] ?? options.platform;
    if (!targets.includes(options.platform) || !fs.existsSync(path.join(root, 'apps/flutter_forge', host))) throw new Error('Compilation needs an existing product host');
    // Keep the repository's special Web release path intact.
    return options.platform === 'web'
      ? { executable: 'bash', args: [path.join(root, 'tool/build_web_release.sh')], platform: options.platform, module: '*' }
      : { executable: 'flutter', args: ['build', options.platform === 'android' ? 'apk' : host, '--debug', '--no-pub',
        ...(options.platform === 'android' ? ['--target-platform', 'android-arm64'] : []), ...(options.platform === 'iOS' ? ['--no-codesign'] : [])], platform: options.platform, module: '*' };
  }
  if (options.kind === 'execution') {
    if (!module || !targets.includes(options.platform) || !options.device || !options.integration) throw new Error('Execution needs module, platform, device and integration path');
    if (!/^integration_test\/[a-z0-9_]+_test\.dart$/.test(options.integration) ||
        !fs.existsSync(path.join(root, 'apps/flutter_forge', options.integration))) throw new Error('Integration test must be an existing app integration_test file');
    // A whole-app integration file is not proof of an arbitrary selected module.
    const source = fs.readFileSync(path.join(root, 'apps/flutter_forge', options.integration), 'utf8');
    if (!source.includes(module.route) && !source.includes(`/modules/${module.category}/${module.id}/`)) throw new Error('Integration source must reference the selected module route or implementation');
    return { executable: 'flutter', args: ['test', options.integration, '-d', options.device, '--no-pub', '--machine'], platform: options.platform, module: module.id };
  }
  throw new Error('check supports logic, compile, execution; use record for manual UI evidence');
}

function revision(root) {
  const git = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' });
  if (git.status !== 0) throw new Error('Cannot identify checkout revision');
  const dirty = spawnSync('git', ['status', '--porcelain'], { cwd: root, encoding: 'utf8' });
  if (dirty.status !== 0) throw new Error('Cannot identify working tree state');
  return { commit: git.stdout.trim(), dirty: Boolean(dirty.stdout.trim()) };
}

function persist(root, modules, record, regenerate = true) {
  const directory = relativeFile(root, evidenceDirectory);
  fs.mkdirSync(directory, { recursive: true });
  const id = `${Date.now()}-${crypto.randomUUID()}`;
  const file = relativeFile(root, `${evidenceDirectory}/${id}.json`);
  fs.writeFileSync(file, `${JSON.stringify(record, null, 2)}\n`, { flag: 'wx' });
  // Validate/render all outputs before updating any generated target.
  if (regenerate) require('./generate_agent_indexes').run();
  process.stdout.write(`Evidence: ${path.relative(root, file)}\n`);
}

function checkAllLogic(root, modules) {
  const before = new Map(modules.map((module) => [module.id, fingerprint(root, modules, module.id, 'logic', 'any')]));
  const args = ['test', 'test/modules', '--no-pub', '--machine'];
  process.stdout.write(`Running: flutter ${args.join(' ')}\n`);
  const result = spawnSync('flutter', args, { cwd: path.join(root, 'apps/flutter_forge'), encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  const output = `${result.stdout ?? ''}${result.stderr ?? ''}${result.error ? `\n${result.error.message}` : ''}`;
  if (modules.some((module) => before.get(module.id) !== fingerprint(root, modules, module.id, 'logic', 'any'))) {
    throw new Error('Sources changed while verification ran; rerun before recording evidence');
  }
  const directory = relativeFile(root, `${evidenceDirectory}/logs`);
  fs.mkdirSync(directory, { recursive: true });
  const log = `${evidenceDirectory}/logs/${Date.now()}-${crypto.randomUUID()}.log`;
  fs.writeFileSync(relativeFile(root, log), output, { flag: 'wx' });
  const version = spawnSync('flutter', ['--version'], { encoding: 'utf8' });
  const common = { schema: 'flutter_forge.module_evidence.v1', source: 'automated_command', kind: 'logic', platform: 'any',
    recorded_at: new Date().toISOString(), revision: revision(root), command: ['flutter', ...args], exit_code: result.status,
    environment: `${os.platform()} ${os.arch()} ${os.release()}; ${version.stdout?.split('\n')[0] ?? 'Flutter version unavailable'}`,
    artifacts: [{ path: log, sha256: sha256(output) }] };
  for (const module of modules) {
    const inventory = testInventory(root, module);
    const summary = testSummary(result.stdout ?? '', path.join(root, inventory.directory));
    const passed = result.status === 0 && summary.success && summary.completed > 0 && summary.failed === 0 && summary.skipped === 0;
    persist(root, modules, { ...common, module: module.id, fingerprint: before.get(module.id),
      status: passed ? 'pass' : 'fail', test_summary: summary, test_scope: inventory.directory }, false);
    process.stdout.write(`${module.id}: ${passed ? 'PASS' : 'FAIL'} ${JSON.stringify(summary)}\n`);
    if (!passed) process.exitCode = 1;
  }
  require('./generate_agent_indexes').run();
}

function check(root, modules, options) {
  const command = commandFor(root, modules, options);
  const before = fingerprint(root, modules, command.module, options.kind, command.platform);
  process.stdout.write(`Running: ${command.executable} ${command.args.join(' ')}\n`);
  const result = spawnSync(command.executable, command.args, { cwd: path.join(root, 'apps/flutter_forge'), encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  const output = `${result.stdout ?? ''}${result.stderr ?? ''}${result.error ? `\n${result.error.message}` : ''}`;
  const summary = options.kind === 'compile' ? null : testSummary(result.stdout ?? '');
  const after = fingerprint(root, modules, command.module, options.kind, command.platform);
  if (before !== after) throw new Error('Sources changed while verification ran; rerun before recording evidence');
  const passed = result.status === 0 && (!summary || (summary.success && summary.completed > 0 && summary.failed === 0 && summary.skipped === 0));
  const directory = relativeFile(root, `${evidenceDirectory}/logs`);
  fs.mkdirSync(directory, { recursive: true });
  const log = `${evidenceDirectory}/logs/${Date.now()}-${crypto.randomUUID()}.log`;
  fs.writeFileSync(relativeFile(root, log), output, { flag: 'wx' });
  const version = spawnSync('flutter', ['--version'], { encoding: 'utf8' });
  persist(root, modules, {
    schema: 'flutter_forge.module_evidence.v1', source: 'automated_command', kind: options.kind, module: command.module, platform: command.platform,
    status: passed ? 'pass' : 'fail', recorded_at: new Date().toISOString(), fingerprint: before,
    revision: revision(root), environment: `${os.platform()} ${os.arch()} ${os.release()}; ${version.stdout?.split('\n')[0] ?? 'Flutter version unavailable'}${options.device ? `; device=${options.device}` : ''}`,
    command: [command.executable, ...command.args], exit_code: result.status, test_summary: summary,
    artifacts: [{ path: log, sha256: sha256(output) }],
  });
  process.stdout.write(`${passed ? 'PASS' : 'FAIL'}${summary ? ` ${JSON.stringify(summary)}` : ''}\n`);
  if (!passed) process.exitCode = 1;
}

function manualRecord(root, modules, options) {
  if (!['ui', 'execution'].includes(options.kind) || !['pass', 'fail'].includes(options.status) ||
      !options.environment || !options.evidence || !targets.includes(options.platform)) throw new Error('Manual evidence needs kind ui/execution, status, platform, environment and evidence');
  const module = modules.find((item) => item.id === options.module);
  if (!module) throw new Error('Manual evidence needs one known module');
  const caseIds = options.cases?.split(',') ?? [];
  if (options.kind === 'ui') {
    const applicable = acceptanceCases(module).filter((item) => casePlatforms(module, item, targets).includes(options.platform)).map((item) => item.id);
    if (!caseIds.length || new Set(caseIds).size !== caseIds.length || caseIds.some((id) => !applicable.includes(id)) ||
        (options.status === 'pass' && applicable.some((id) => !caseIds.includes(id)))) throw new Error(`UI PASS needs all applicable case IDs: ${applicable.join(',')}`);
  }
  const artifacts = options.evidence.split(',').map((rel) => {
    const file = relativeFile(root, rel);
    if (!fs.existsSync(file) || !fs.statSync(file).isFile()) throw new Error(`Evidence file missing: ${rel}`);
    return { path: rel, sha256: sha256(fs.readFileSync(file)) };
  });
  persist(root, modules, { schema: 'flutter_forge.module_evidence.v1', kind: options.kind, module: module.id,
    platform: options.platform, status: options.status, environment: options.environment, recorded_at: new Date().toISOString(),
    fingerprint: fingerprint(root, modules, module.id, options.kind, options.platform), revision: revision(root),
    case_ids: caseIds, artifacts, source: 'manual_operator_record' });
}

function main(args) {
  const { command, options } = parseArgs(args);
  if (command === 'help' || !command) {
    process.stdout.write('Usage: node tool/module_availability.js <generate|check|record> [options]\n' +
      'check --kind logic --module ID|all\ncheck --kind compile --platform android|iOS|macOS|web|windows\n' +
      'check --kind execution --module ID --platform PLATFORM --device DEVICE --integration integration_test/NAME_test.dart\n' +
      'record --kind ui|execution --module ID --platform PLATFORM --status pass|fail --environment TEXT --evidence RELATIVE_FILE[,FILE] [--cases ID,ID]\n');
    return;
  }
  if (options.kind && !kinds.includes(options.kind)) throw new Error('Unknown verification kind');
  const { modules, run } = require('./generate_agent_indexes');
  if (command === 'generate') {
    if (Object.keys(options).length) throw new Error('generate takes no options');
    process.stdout.write(`${JSON.stringify(run())}\n`);
  } else if (command === 'check' && options.kind === 'logic' && options.module === 'all') {
    if (Object.keys(options).some((key) => !['kind', 'module'].includes(key))) throw new Error('Logic all takes only kind and module');
    checkAllLogic(root, modules);
  } else if (command === 'check') check(root, modules, options);
  else if (command === 'record') manualRecord(root, modules, options);
  else throw new Error('Unknown command; use help');
}

if (require.main === module) {
  try { main(process.argv.slice(2)); } catch (error) { process.stderr.write(`${error.message}\n`); process.exitCode = 1; }
}
module.exports = { parseArgs, testSummary, commandFor, manualRecord, check };
