#!/usr/bin/env python3
"""Validate the distribution ledger and prepare review bundles; no remote mutations."""
import argparse
from datetime import datetime, timezone, timedelta
import hashlib
import json
from pathlib import Path
import re

from privacy_policy import ROOT, binding, generate as generate_privacy

SHA = re.compile(r'[0-9a-f]{64}')
REVIEW = {'needs_verification', 'not_submitted', 'submitted', 'in_review', 'approved', 'rejected'}
PUBLICATION = {'needs_verification', 'not_published', 'scheduled', 'published', 'withdrawn'}


def read_catalog(root=ROOT):
    return json.loads((root / 'docs/distribution/catalog.json').read_text(encoding='utf-8'))


def relative_file(value, root):
    path = (root / value).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError(f'Path escapes repository: {value}')
    return path


def timestamp(value):
    time = datetime.fromisoformat(value.replace('Z', '+00:00'))
    if time.tzinfo is None:
        raise ValueError('Evidence timestamps require timezone')
    return time


def validate(data, root=ROOT):
    if data['schema'] != 'flutter_forge.distribution.v1':
        raise ValueError('Unsupported distribution schema')
    profiles = data['profiles']
    channels = {item['id']: item for item in data['channels']}
    artifacts = {item['id']: item for item in data['artifacts']}
    if len(channels) != len(data['channels']) or len(artifacts) != len(data['artifacts']):
        raise ValueError('Duplicate channel or artifact ID')
    index = json.loads((root / 'docs/privacy/index.json').read_text(encoding='utf-8'))
    for profile in profiles.values():
        if profile['edition'] != profile['policy_edition'] or profile['edition'] not in index['current']:
            raise ValueError('Profile policy edition mismatch')
    for channel in channels.values():
        if channel['profile'] not in profiles or channel['priority'] not in {'primary', 'maintenance', 'deferred'}:
            raise ValueError('Invalid channel profile or priority')
        if channel['kind'] not in {'store', 'github', 'web'}:
            raise ValueError('Invalid channel kind')
        if channel['publication_mode'] != 'explicit_authorization':
            raise ValueError('Remote publication requires explicit authorization')
        if channel['policy_url'] and not channel['policy_url'].startswith('https://'):
            raise ValueError('Public policy URL must use HTTPS')
        if channel['policy_url_verified_at']:
            timestamp(channel['policy_url_verified_at'])
            if not channel['policy_url']:
                raise ValueError('Verified policy URL is missing')
            version = index['versions'].get(channel['policy_url_policy_id'])
            if not version or version['text_sha256'] != channel['policy_url_text_sha256'] or version['edition'] != profiles[channel['profile']]['edition']:
                raise ValueError('Verified public URL requires matching policy version and hash')
    for item in artifacts.values():
        if item['profile'] not in profiles or not SHA.fullmatch(item['sha256']):
            raise ValueError('Invalid artifact profile or SHA256')
        if not re.fullmatch(r'[0-9a-f]{40}', item['source_sha']):
            raise ValueError('Invalid source SHA')
        if item['path']:
            relative_file(item['path'], root)
        if item['policy']:
            policy = item['policy']
            version = index['versions'].get(policy['policy_id'])
            if not version or version['text_sha256'] != policy['text_sha256'] or version['edition'] != profiles[item['profile']]['edition']:
                raise ValueError('Artifact policy hash or edition mismatch')
    ids = set()
    for submission in data['submissions']:
        if submission['id'] in ids:
            raise ValueError('Duplicate submission ID')
        ids.add(submission['id'])
        channel = channels[submission['channel']]
        artifact = artifacts[submission['artifact']]
        if channel['profile'] != artifact['profile']:
            raise ValueError('Submission channel/artifact profile mismatch')
        for event in submission['observations']:
            timestamp(event['at'])
            if not event['evidence'] or event['review'] not in REVIEW or event['publication'] not in PUBLICATION:
                raise ValueError('Portal observation requires evidence and valid states')
    return channels, artifacts


def portal_state(observations, days, now):
    if not observations:
        return 'needs_verification', 'needs_verification', '未核对'
    last = max(observations, key=lambda event: timestamp(event['at']))
    age = now - timestamp(last['at'])
    if age < timedelta(0) or age > timedelta(days=days):
        return 'needs_verification', 'needs_verification', last['at'] + '（需重新核对）'
    return last['review'], last['publication'], last['at']


def render(data, now=None):
    now = now or datetime.now(timezone.utc)
    lines = ['# 分发与上架总览', '', '<!-- Generated by python3 tool/distribution.py generate; edit catalog.json. -->', '',
             f"本地清单整理日期：{data['local_inventory_date']}。后台记录超过 {data['portal_freshness_days']} 天显示待核对；未核对不等于未提交。", '',
             '| 渠道 | 优先级 | 发行配置 | 最新登记提交 | 审核 | 发布 | 最后后台核对 |', '| --- | --- | --- | --- | --- | --- | --- |']
    for channel in data['channels']:
        submissions = [item for item in data['submissions'] if item['channel'] == channel['id']]
        latest = submissions[-1] if submissions else None
        review, publication, checked = portal_state(latest['observations'] if latest else [], data['portal_freshness_days'], now)
        submission_id = latest['id'] if latest else '尚未登记'
        lines.append(f"| {channel['label']} | {channel['priority']} | {channel['profile']} | {submission_id} | {review} | {publication} | {checked} |")
    lines.extend(['', '## 已登记产物', '', '| 产物 ID | 版本 / 构建号 | 签名 | 政策绑定 |', '| --- | --- | --- | --- |'])
    for artifact in data['artifacts']:
        policy = artifact['policy']['policy_id'] if artifact['policy'] else '未知（历史产物）'
        lines.append(f"| {artifact['id']} | {artifact['version']} / {artifact['build_number']} | {artifact['signing']} | {policy} |")
    lines.extend(['', '历史产物登记不代表当前发布或验收通过。iOS 尚未建立宿主，不创建商店就绪记录。', '',
                  '## 当前待办', '', '- 优先渠道：逐次核对最新登记提交的后台审核、发布设置、政策链接和素材版本；旧提交的已发布状态不代表新提交已发布。',
                  '- Microsoft Store：正式身份、真实 Windows 安装/交互、WACK、公开政策和材料分别取证；LocalTest 不作为正式 Store 产物。',
                  '- 核对政策公开 URL 与版本页面的实际内容后再登记；本地 HTML 存在不能代替上线验证。',
                  '- 历史包缺少政策绑定时保持未知；后续构建生成绑定，不修改历史 manifest。',
                  '- GitHub Release 继续使用 Agent Hub release-plan / release-run --execute；所有提交、发布与撤回均需明确授权。', ''])
    return '\n'.join(lines)


def readiness(data, channel_id, artifact_id, root=ROOT):
    channels, artifacts = validate(data, root)
    channel, artifact = channels[channel_id], artifacts[artifact_id]
    problems = []
    if channel['profile'] != artifact['profile']:
        problems.append('channel_artifact_profile_mismatch')
    if channel['priority'] == 'deferred':
        problems.append('channel_deferred')
    if not artifact['policy']:
        problems.append('artifact_policy_binding_unknown')
    if artifact['source_dirty'] is not False:
        problems.append('source_snapshot_not_clean_or_unknown')
    path = relative_file(artifact['path'], root) if artifact['path'] else None
    if path is None or not path.is_file():
        problems.append('artifact_file_missing')
    elif hashlib.sha256(path.read_bytes()).hexdigest() != artifact['sha256']:
        problems.append('artifact_hash_mismatch')
    if channel['kind'] == 'store':
        store_msix = channel_id == 'microsoft-store' and path is not None and path.suffix.lower() == '.msix' and artifact.get('identity_kind') == 'partner-center-config'
        if artifact['build_mode'] != 'release' or artifact['signing'] in {'Android debug certificate', 'local-test'} or (artifact['signing'] == 'unsigned' and not store_msix):
            problems.append('formal_store_build_and_signing_required')
        if not channel['identity_evidence']:
            problems.append('formal_store_identity_evidence_missing')
        if not artifact['acceptance_evidence']:
            problems.append('host_acceptance_evidence_missing')
        if not channel['policy_url'] or not channel['policy_url_verified_at']:
            problems.append('public_policy_url_not_verified')
        elif not timedelta(0) <= datetime.now(timezone.utc) - timestamp(channel['policy_url_verified_at']) <= timedelta(days=data['portal_freshness_days']):
            problems.append('public_policy_url_verification_stale')
        elif artifact['policy'] and (channel['policy_url_policy_id'] != artifact['policy']['policy_id'] or channel['policy_url_text_sha256'] != artifact['policy']['text_sha256']):
            problems.append('public_policy_does_not_match_artifact')
    submissions = [item for item in data['submissions'] if item['channel'] == channel_id and item['artifact'] == artifact_id]
    if channel['kind'] == 'store' and not any(item['listing_version'] for item in submissions):
        problems.append('listing_version_missing')
    return {'schema': 'flutter_forge.submission_bundle.v1', 'channel': channel_id, 'artifact': artifact,
            'readiness': 'blocked' if problems else 'prepared_for_review', 'blockers': problems,
            'remote_action': 'NOT_RUN', 'authorization': 'explicit_authorization_required',
            'policy_url': channel['policy_url'], 'submissions': submissions}


def import_artifact(data, manifest_path, artifact_path, profile_id, artifact_id, root=ROOT):
    if any(item['id'] == artifact_id for item in data['artifacts']):
        raise ValueError('Artifact IDs are immutable; use a new ID')
    manifest_path = relative_file(str(manifest_path), root)
    artifact_path = relative_file(str(artifact_path), root)
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    profile = data['profiles'][profile_id]
    digest = hashlib.sha256(artifact_path.read_bytes()).hexdigest()
    legacy_full = manifest.get('schema') == 'flutter_forge.release_manifest.v1' and not manifest.get('distribution_profile') and profile_id == manifest.get('platform', '') + '-full'
    if manifest.get('distribution_profile') != profile_id and not legacy_full:
        raise ValueError('Manifest/profile mismatch')
    if manifest.get('schema') == 'flutter_forge.windows_store.v1':
        if manifest['package_build'] != 'PASS' or manifest['package']['sha256'] != digest:
            raise ValueError('A built MSIX with matching hash is required')
        version, build = manifest['app_version'].split('+')[0], manifest['package_version']
        source_sha, dirty = manifest['source']['head'], bool(manifest['source']['status'])
        signing = 'local-test' if manifest['identity_kind'] == 'local-test' else manifest['signing']
        mode, certificate = 'release', None
    elif profile_id == 'android-offline':
        if manifest['apk_sha256'] != digest or manifest['internet_permission'] is not False or manifest['build_mode'] != 'release':
            raise ValueError('Verified offline release APK required')
        if manifest['certificate_sha256'] != profile['certificate_sha256']:
            raise ValueError('Release certificate differs from registered profile')
        if not SHA.fullmatch(manifest['certificate_sha256']):
            raise ValueError('Release certificate fingerprint required')
        if manifest['application_id'] != profile['application_id']:
            raise ValueError('Application identity mismatch')
        version, build = manifest['version_name'], str(manifest['version_code'])
        previous = [int(item['build_number']) for item in data['artifacts'] if item['profile'] == profile_id]
        if int(build) <= max(previous, default=0):
            raise ValueError('Android versionCode must increase')
        source_sha, dirty = manifest['source_commit'], manifest['source_dirty']
        signing, mode, certificate = 'release-certificate', 'release', manifest['certificate_sha256']
    elif manifest.get('schema') == 'flutter_forge.release_manifest.v1':
        entries = [item for item in manifest['artifacts'] if item['name'] == artifact_path.name and item['sha256'] == digest]
        if len(entries) != 1 or manifest['platform'] != profile['platform']:
            raise ValueError('Release manifest artifact or platform mismatch')
        version, _, build = manifest['version'].partition('+')
        source_sha, dirty = manifest['source_sha'], False
        signing, mode, certificate = manifest['signing'], manifest['build_mode'], None
    else:
        raise ValueError('Unsupported build evidence format')
    item = {'id': artifact_id, 'profile': profile_id, 'version': version, 'build_number': build,
            'path': artifact_path.relative_to(root.resolve()).as_posix(), 'sha256': digest,
            'source_sha': source_sha, 'source_dirty': dirty, 'build_mode': mode, 'signing': signing,
            'certificate_sha256': certificate, 'policy': manifest.get('policy_binding'),
            'source_manifest': manifest_path.relative_to(root.resolve()).as_posix(),
            'acceptance_evidence': [], 'note': 'Imported build evidence; no submission or publication performed.'}
    if manifest.get('schema') == 'flutter_forge.windows_store.v1':
        item['identity_kind'] = manifest['identity_kind']
        item['identity'] = manifest['identity']
    updated = {**data, 'artifacts': [*data['artifacts'], item]}
    validate(updated, root)
    return updated


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['validate', 'generate', 'check', 'prepare', 'register'])
    parser.add_argument('--channel')
    parser.add_argument('--artifact-id')
    parser.add_argument('--output', type=Path)
    parser.add_argument('--manifest', type=Path)
    parser.add_argument('--artifact', type=Path)
    parser.add_argument('--profile')
    args = parser.parse_args()
    try:
        generate_privacy(check=True)
        data = read_catalog()
        validate(data)
        if args.command == 'register':
            if not all([args.manifest, args.artifact, args.profile, args.artifact_id]):
                raise ValueError('register requires --manifest, --artifact, --profile and --artifact-id')
            data = import_artifact(data, args.manifest, args.artifact, args.profile, args.artifact_id)
            (ROOT / 'docs/distribution/catalog.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
            (ROOT / 'docs/distribution/OVERVIEW.md').write_text(render(data), encoding='utf-8')
        if args.command == 'prepare':
            if not args.channel or not args.artifact_id or not args.output:
                raise ValueError('prepare requires --channel, --artifact-id and --output (new directory)')
            report = readiness(data, args.channel, args.artifact_id)
            args.output.mkdir(parents=True, exist_ok=False)
            (args.output / 'submission.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
            (args.output / 'CHECKLIST.md').write_text('# 提交前核对\n\n' + '\n'.join('- [ ] ' + item for item in report['blockers']) + '\n\n远程操作未执行；准备记录不授予提交或发布权限。\n', encoding='utf-8')
            print(f"{report['readiness']}: {args.output}")
            return 2 if report['blockers'] else 0
        if args.command in {'generate', 'check'}:
            path = ROOT / 'docs/distribution/OVERVIEW.md'
            text = render(data)
            if args.command == 'check':
                if not path.is_file() or path.read_text(encoding='utf-8') != text:
                    raise ValueError('Distribution overview differs; run generate')
            else:
                path.write_text(text, encoding='utf-8')
        print('distribution: ' + args.command + ' complete; no remote actions')
        return 0
    except (ValueError, KeyError, OSError) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    raise SystemExit(main())
