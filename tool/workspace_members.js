const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const text = fs.readFileSync(path.join(root, 'pubspec.yaml'), 'utf8');
const block = text.match(/^workspace:\n((?:[ \t].*\n|\n)+)/m);
if (!block) throw new Error('Missing workspace members');
const members = block[1].split('\n').filter((line) => line.trim() && !line.trim().startsWith('#')).map((line) => {
  const match = line.match(/^  - ([a-zA-Z0-9_/-]+)\s*$/);
  if (!match || path.isAbsolute(match[1]) || match[1].split('/').includes('..')) throw new Error(`Invalid workspace member: ${line}`);
  if (!fs.existsSync(path.join(root, match[1], 'pubspec.yaml'))) throw new Error(`Missing member: ${match[1]}`);
  return match[1];
});
if (!members.length || new Set(members).size !== members.length) throw new Error('Empty or duplicate workspace members');
process.stdout.write(members.join('\n') + '\n');
