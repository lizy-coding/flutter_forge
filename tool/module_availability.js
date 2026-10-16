#!/usr/bin/env node
const { supportDeclaration } = require('./agent_indexes/support');

function parseArgs(args) {
  const [command = 'help', ...rest] = args;
  if (!['help', 'list', 'generate'].includes(command)) {
    throw new Error('Maintenance now declares support only; check/record are retired. Use help.');
  }
  if (rest.length && (command !== 'list' || rest.length !== 2 || rest[0] !== '--module' || !rest[1] || rest[1].startsWith('--'))) {
    throw new Error('Usage: list [--module ID|all], generate, or help');
  }
  return { command, module: rest[1] ?? 'all' };
}

function main(args) {
  const options = parseArgs(args);
  if (options.command === 'help') {
    process.stdout.write('Usage: node tool/module_availability.js <list [--module ID|all]|generate>\n' +
      'Declares entry support and feature limits; does not run tests or record verification results.\n' +
      'For development feedback, run Flutter tests or the quality gate directly.\n');
    return;
  }
  const { modules, run } = require('./generate_agent_indexes');
  if (options.command === 'generate') {
    process.stdout.write(`${JSON.stringify(run())}\n`);
    return;
  }
  const selected = options.module === 'all' ? modules : modules.filter((module) => module.id === options.module);
  if (!selected.length) throw new Error(`Unknown module: ${options.module}`);
  process.stdout.write(`${JSON.stringify(supportDeclaration(selected), null, 2)}\n`);
}

if (require.main === module) {
  try { main(process.argv.slice(2)); }
  catch (error) { process.stderr.write(`${error.message}\n`); process.exitCode = 64; }
}

module.exports = { parseArgs, main };
