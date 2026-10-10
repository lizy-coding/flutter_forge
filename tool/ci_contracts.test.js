const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {versionOf, checkTag, metadata} = require('./release_metadata');
test('release tag must agree with application version', () => {
  assert.equal(versionOf('version: 1.2.8+2\n'), '1.2.8+2');
  checkTag('v1.2.8', '1.2.8+2');
  assert.throws(() => checkTag('v1.2.7', '1.2.8+2'), /mismatch/);
  assert.throws(() => versionOf('name: example'), /Missing/);
});
test('artifact verification rejects absent, empty and wrong-format output', (t) => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'forge-artifact-'));
  t.after(() => fs.rmSync(dir, {recursive:true, force:true}));
  assert.throws(() => metadata(dir, {platform:'android'}), /No release/);
  fs.writeFileSync(path.join(dir, 'test.apk'), '');
  assert.throws(() => metadata(dir, {platform:'android'}), /Invalid artifact/);
  fs.writeFileSync(path.join(dir, 'test.apk'), 'bytes');
  assert.throws(() => metadata(dir, {platform:'windows'}), /Missing windows/);
  const data = metadata(dir, {platform:'android'});
  assert.equal(data.build_mode, 'debug');
  assert.equal(data.signing, 'Android debug certificate');
  assert.equal(data.artifacts[0].size, 5);
  assert.match(data.artifacts[0].sha256, /^[a-f0-9]{64}$/);
});
test('deployment and packaging cannot bypass quality dependencies', () => {
  for (const name of ['deploy-pages.yml', 'deploy-cloudflare-pages.yml', 'release.yml', 'android-release.yml']) {
    const text = fs.readFileSync(path.join(__dirname, '../.github/workflows', name), 'utf8');
    assert.match(text, /uses: \.\/\.github\/workflows\/quality.yml/);
    assert.match(text, /needs: quality/);
    assert.doesNotMatch(text, /gh release (create|upload)|continue-on-error/);
  }
});

test('release CLI verifies exact clean source and rejects dirty or unrelated tag commits', (t) => {
  const {execFileSync} = require('node:child_process');
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'forge-release-source-'));
  t.after(() => fs.rmSync(dir, {recursive:true, force:true}));
  fs.mkdirSync(path.join(dir, 'apps/flutter_forge'), {recursive:true});
  const pubspec = path.join(dir, 'apps/flutter_forge/pubspec.yaml');
  fs.writeFileSync(pubspec, 'version: 1.2.8+2\n');
  const gitExe = process.platform === 'darwin' && fs.existsSync('/Library/Developer/CommandLineTools/usr/bin/git')
    ? '/Library/Developer/CommandLineTools/usr/bin/git' : 'git';
  const git = (...args) => execFileSync(gitExe, args, {cwd:dir, encoding:'utf8', stdio:'pipe'}).trim();
  git('init', '-q', '-b', 'master');
  git('config', 'user.name', 'Release fixture');
  git('config', 'user.email', 'fixture@example.invalid');
  git('add', '.');
  git('commit', '-qm', 'fixture');
  const sha = git('rev-parse', 'HEAD');
  git('update-ref', 'refs/remotes/origin/master', sha);
  git('tag', 'v1.2.8');
  const env = {...process.env, RELEASE_TAG:'v1.2.8', EXPECTED_SHA:sha};
  if (gitExe !== 'git') env.PATH = `${path.dirname(gitExe)}:${env.PATH}`;
  const verify = (extra = {}) => execFileSync(process.execPath, [path.join(__dirname, 'release_metadata.js'), 'verify'], {cwd:dir, env:{...env, ...extra}, encoding:'utf8', stdio:'pipe'});
  assert.match(verify(), /release_identity:PASS/);
  assert.throws(() => verify({EXPECTED_SHA:'wrong'}), /Checkout differs/);
  fs.appendFileSync(pubspec, '# dirty\n');
  assert.throws(() => verify(), /Source changed/);
  git('add', '.');
  git('commit', '-qm', 'candidate outside stable ref');
  git('tag', '-f', 'v1.2.8');
  assert.throws(() => verify({EXPECTED_SHA:git('rev-parse', 'HEAD')}), /outside stable master/);
});
