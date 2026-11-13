const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'apps/flutter_forge/web/index.html'), 'utf8');
const script = html.match(/<script>\s*([\s\S]*?)<\/script>/)[1];
const resources = fs.readFileSync(path.join(root, 'apps/flutter_forge/web/startup_localizations.js'), 'utf8');
function start(preference, languages, unavailable = false) {
  const nodes = Object.fromEntries(['flutter-forge-loading', 'flutter-forge-loading-status', 'flutter-forge-reload'].map(id => [id, {textContent: '', style: {}, remove() {}}]));
  const context = {window: {}, document: {documentElement: {}, getElementById: id => nodes[id]}, localStorage: {getItem() {if (unavailable) throw Error('denied'); return preference;}}, navigator: {languages}, performance: {now: () => 0, mark() {}}, setTimeout: () => 1, clearTimeout() {}, console};
  vm.runInNewContext(resources, context);
  vm.runInNewContext(script, context);
  return {context, nodes};
}
test('startup honors saved preference over browser language and handles unavailable storage', () => {
  assert.equal(start('"en"', ['zh-CN']).context.document.documentElement.lang, 'en');
  assert.equal(start('"zh"', ['en-US']).context.document.documentElement.lang, 'zh');
  assert.equal(start('"system"', ['fr-FR', 'en-GB']).context.document.documentElement.lang, 'en');
  assert.equal(start(null, ['zh-TW']).context.document.documentElement.lang, 'zh');
  assert.equal(start(null, ['fr']).context.document.documentElement.lang, 'zh');
  assert.equal(start('{}', ['en']).context.document.documentElement.lang, 'en');
  assert.equal(start('invalid JSON', ['en']).context.document.documentElement.lang, 'en');
  const result = start(null, ['en'], true);
  assert.equal(result.nodes['flutter-forge-loading-status'].textContent, 'Loading application…');
  result.context.window.flutterForgeLoading.fail('fixture');
  assert.equal(result.nodes['flutter-forge-loading-status'].textContent, 'Loading failed. Please reload.');
});
