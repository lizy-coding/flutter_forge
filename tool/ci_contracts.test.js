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
  const untracked = path.join(dir, 'apps/flutter_forge/lib/extra.dart');
  fs.mkdirSync(path.dirname(untracked), {recursive:true});
  fs.writeFileSync(untracked, 'const extra = true;');
  assert.throws(() => verify(), /Untracked source\/input/);
  fs.rmSync(untracked);
  const staging = path.join(dir, 'verified-release');
  const stage = (platform, directory = 'verified-release') => execFileSync(process.execPath,
    [path.join(__dirname, 'release_metadata.js'), 'stage', directory],
    {cwd:dir, env:{...env, RELEASE_PLATFORM:platform}, encoding:'utf8', stdio:'pipe'});
  for (const [platform, suffix, raw] of [
    ['macos', 'macos-x64.dmg', 'release-assets/FlutterForge-1.2.8-macos-x64.dmg'],
    ['windows', 'windows-x64.exe', 'flutter_forge-setup-x64.exe'],
    ['android', 'android-arm64-v8a-debug.apk', 'apps/flutter_forge/release-assets/flutter_forge-android-arm64-debug.apk'],
    ['web', 'web.zip', null],
  ]) {
    fs.mkdirSync(staging);
    const artifact = `FlutterForge-1.2.8-${suffix}`;
    fs.writeFileSync(path.join(staging, artifact), 'artifact fixture');
    if (raw) {
      fs.mkdirSync(path.dirname(path.join(dir, raw)), {recursive:true});
      fs.writeFileSync(path.join(dir, raw), 'raw artifact fixture');
    }
    assert.match(stage(platform), /release_identity:PASS/);
    assert.match(stage(platform), /release_identity:PASS/);
    assert.throws(() => verify(), /Untracked source\/input/);
    assert.throws(() => stage(platform, 'other-output'), /must use verified-release/);
    assert.throws(() => stage(platform === 'web' ? 'macos' : 'web'), /Untracked source\/input/);
    const extra = path.join(staging, 'extra.dart');
    fs.writeFileSync(extra, 'untracked source');
    assert.throws(() => stage(platform), /Untracked source\/input/);
    fs.rmSync(extra);
    const manifest = path.join(staging, `RELEASE_MANIFEST-${platform}.json`);
    fs.rmSync(manifest);
    fs.symlinkSync(pubspec, manifest);
    assert.throws(() => stage(platform), /Invalid release output/);
    fs.rmSync(staging, {recursive:true});
    if (raw) fs.rmSync(path.join(dir, raw));
  }
  fs.symlinkSync(path.join(dir, 'apps'), staging);
  assert.throws(() => stage('web'), /Untracked source\/input|symlink/);
  fs.rmSync(staging);
  fs.appendFileSync(pubspec, '# dirty\n');
  assert.throws(() => verify(), /Source changed/);
  git('add', '.');
  git('commit', '-qm', 'candidate outside stable ref');
  git('tag', '-f', 'v1.2.8');
  assert.throws(() => verify({EXPECTED_SHA:git('rev-parse', 'HEAD')}), /outside stable master/);
});
