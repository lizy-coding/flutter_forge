const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');
function versionOf(text) {
  const match = text.match(/^version:\s*['"]?(\d+\.\d+\.\d+(?:\+\d+)?)['"]?\s*$/m);
  if (!match) throw new Error('Missing application version');
  return match[1];
}
function checkTag(tag, version) {
  if (tag && tag !== `v${version.split('+')[0]}`) throw new Error(`Tag/version mismatch: ${tag} / ${version}`);
}
function metadata(directory, context) {
  const names = fs.readdirSync(directory).filter((name) => !name.startsWith('RELEASE_MANIFEST-') && !name.startsWith('SHA256SUMS-')).sort();
  if (!names.length) throw new Error('No release artifacts');
  const artifacts = names.map((name) => {
    const file = path.join(directory, name);
    const stat = fs.lstatSync(file);
    if (!stat.isFile() || stat.isSymbolicLink() || !stat.size) throw new Error(`Invalid artifact: ${name}`);
    return { name, size: stat.size, sha256: crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') };
  });
  const platform = context.platform;
  const expected = {macos: '.dmg', windows: '.exe', android: '.apk', web: '.zip'}[platform];
  if (!expected || !artifacts.some((a) => a.name.endsWith(expected))) throw new Error(`Missing ${platform} artifact`);
  return {...context, schema: 'flutter_forge.release_manifest.v1', build_mode: platform === 'android' ? 'debug' : 'release', signing: platform === 'android' ? 'Android debug certificate' : platform === 'web' ? 'not applicable' : 'unsigned', artifacts};
}
if (require.main === module) {
  const mode = process.argv[2];
  const version = versionOf(fs.readFileSync('apps/flutter_forge/pubspec.yaml', 'utf8'));
  if (mode === 'version') { console.log(version.split('+')[0]); process.exit(0); }
  const tag = process.env.RELEASE_TAG || (process.env.GITHUB_REF_TYPE === 'tag' ? process.env.GITHUB_REF_NAME : '');
  checkTag(tag, version);
  const git = (...args) => execFileSync('git', args, {encoding: 'utf8'}).trim();
  const source_sha = git('rev-parse', 'HEAD');
  if (process.env.EXPECTED_SHA && source_sha !== process.env.EXPECTED_SHA) throw new Error('Checkout differs from quality-gate SHA');
  try { git('diff', '--quiet', 'HEAD'); } catch { throw new Error('Source changed after checkout; refusing release artifacts'); }
  if (tag) {
    if (git('rev-parse', `${tag}^{commit}`) !== source_sha) throw new Error('Tag differs from checkout');
    try { git('merge-base', '--is-ancestor', source_sha, 'origin/master'); } catch { throw new Error('Release tag is outside stable master'); }
  }
  if (mode === 'stage') {
    const directory = process.argv[3];
    const data = metadata(directory, {version, tag: tag || null, source_sha, platform: process.env.RELEASE_PLATFORM, run_id: process.env.GITHUB_RUN_ID || null, run_attempt: process.env.GITHUB_RUN_ATTEMPT || null});
    fs.writeFileSync(path.join(directory, `RELEASE_MANIFEST-${data.platform}.json`), JSON.stringify(data, null, 2) + '\n');
    fs.writeFileSync(path.join(directory, `SHA256SUMS-${data.platform}`), data.artifacts.map((a) => `${a.sha256}  ${a.name}`).join('\n') + '\n');
  } else if (mode !== 'verify') throw new Error('Usage: node tool/release_metadata.js verify|stage [directory]');
  console.log(`release_identity:PASS:${source_sha}:${version}`);
}
module.exports = {versionOf, checkTag, metadata};
