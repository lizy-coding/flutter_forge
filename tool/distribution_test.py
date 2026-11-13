"""Policy immutability and channel/artifact boundary regressions; no network."""
import copy
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

import build_vivo_offline

import distribution as ledger
import privacy_policy as policy


class DistributionTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        shutil.copytree(policy.ROOT / 'docs/privacy', self.root / 'docs/privacy')
        policy.generate(root=self.root)
        self.data = ledger.read_catalog()

    def test_both_export_entries_check_identical_outputs(self):
        policy.generate(check=True, root=self.root)
        page = self.root / 'apps/flutter_forge/web/privacy-offline.html'
        page.write_text('out of date')
        with self.assertRaisesRegex(ValueError, 'outputs differ'):
            policy.generate(check=True, root=self.root)

    def test_policy_text_changes_require_new_version(self):
        path = self.root / 'docs/privacy/policies.json'
        source = json.loads(path.read_text())
        source['common']['feedback'] += '\nchanged'
        path.write_text(json.dumps(source))
        with self.assertRaisesRegex(ValueError, 'immutable'):
            policy.generate(root=self.root)
        old_html = self.root / 'apps/flutter_forge/web/privacy/versions/full-2026-10-30.1.html'
        before = old_html.read_bytes()
        for edition in ('full', 'offline'):
            source['policies'][edition]['id'] = f'{edition}-2026-10-30.2'
        path.write_text(json.dumps(source))
        policy.generate(root=self.root)
        self.assertEqual(before, old_html.read_bytes())

    def test_archived_html_cannot_be_rewritten(self):
        path = self.root / 'apps/flutter_forge/web/privacy/versions/full-2026-10-29.html'
        path.write_text('tampered')
        with self.assertRaisesRegex(ValueError, 'immutable'):
            policy.generate(root=self.root)

    def test_legacy_artifacts_cannot_acquire_current_policy_implicitly(self):
        report = ledger.readiness(self.data, 'vivo', 'vivo-1.2.10-2006', self.root)
        self.assertIn('artifact_policy_binding_unknown', report['blockers'])
        self.assertEqual(report['remote_action'], 'NOT_RUN')
        self.assertEqual(report['readiness'], 'blocked')

    def test_debug_apk_cannot_be_used_for_store(self):
        report = ledger.readiness(self.data, 'vivo', 'github-android-1.2.10-4', self.root)
        self.assertIn('channel_artifact_profile_mismatch', report['blockers'])
        self.assertIn('formal_store_build_and_signing_required', report['blockers'])

    def test_wrong_edition_or_hash_is_rejected(self):
        for binding in (policy.binding('full'), {**policy.binding('offline'), 'text_sha256': '0' * 64}):
            data = copy.deepcopy(self.data)
            data['artifacts'][-1]['policy'] = binding
            with self.assertRaisesRegex(ValueError, 'policy hash or edition'):
                ledger.validate(data, self.root)

    def test_absent_stale_and_future_portal_evidence_remain_unknown(self):
        now = datetime(2026, 10, 30, tzinfo=timezone.utc)
        for at in ('2026-10-01T00:00:00Z', '2026-11-01T00:00:00Z'):
            observation = {'at': at, 'review': 'approved', 'publication': 'published', 'evidence': ['portal']}
            self.assertEqual(ledger.portal_state([observation], 7, now)[0], 'needs_verification')
        self.assertEqual(ledger.portal_state([], 7, now)[1], 'needs_verification')
        observation['at'] = '2026-10-29T00:00:00Z'
        self.assertEqual(ledger.portal_state([observation], 7, now)[:2], ('approved', 'published'))

    def test_artifact_import_verifies_bytes_and_freezes_manifest_policy(self):
        artifact = self.root / 'candidate.apk'
        artifact.write_bytes(b'fixture only, not real APK acceptance')
        next_code = build_vivo_offline.highest_version_code(self.root, self.data) + 1
        manifest = {'distribution_profile': 'android-offline', 'apk_sha256': hashlib.sha256(artifact.read_bytes()).hexdigest(),
                    'internet_permission': False, 'build_mode': 'release', 'certificate_sha256': self.data['profiles']['android-offline']['certificate_sha256'],
                    'application_id': 'com.forge.forest', 'version_name': '1.2.11', 'version_code': next_code,
                    'source_commit': 'b' * 40, 'source_dirty': False, 'policy_binding': policy.binding('offline')}
        file = self.root / 'manifest.json'
        file.write_text(json.dumps(manifest))
        data = ledger.import_artifact(self.data, file, artifact, 'android-offline', 'fixture-2007', self.root)
        self.assertEqual(data['artifacts'][-1]['policy']['policy_id'], 'offline-2026-10-30.1')
        with self.assertRaisesRegex(ValueError, 'immutable'):
            ledger.import_artifact(data, file, artifact, 'android-offline', 'fixture-2007', self.root)
        artifact.write_bytes(b'changed')
        with self.assertRaisesRegex(ValueError, 'Verified offline'):
            ledger.import_artifact(self.data, file, artifact, 'android-offline', 'fixture-2008', self.root)

    def test_old_published_submission_does_not_make_new_submission_published(self):
        data = copy.deepcopy(self.data)
        data['submissions'][0]['observations'] = [{'at': '2026-10-30T00:00:00Z', 'review': 'approved', 'publication': 'published', 'evidence': ['old portal']}]
        data['submissions'].append({**data['submissions'][0], 'id': 'vivo-next', 'observations': []})
        text = ledger.render(data, datetime(2026, 10, 30, tzinfo=timezone.utc))
        row = next(line for line in text.splitlines() if line.startswith('| vivo 应用商店'))
        self.assertIn('vivo-next | needs_verification | needs_verification', row)


    def test_public_url_verification_cannot_point_at_wrong_edition(self):
        data = copy.deepcopy(self.data)
        channel = data['channels'][0]
        channel.update(policy_url='https://example.invalid/policy', policy_url_verified_at='2026-10-30T00:00:00Z',
                       policy_url_policy_id='full-2026-10-30.1', policy_url_text_sha256=policy.binding('full')['text_sha256'])
        with self.assertRaisesRegex(ValueError, 'matching policy'):
            ledger.validate(data, self.root)

    def test_formal_store_msix_can_be_signed_by_store_but_local_test_cannot(self):
        data = copy.deepcopy(self.data)
        artifact = next(item for item in data['artifacts'] if item['id'] == 'github-windows-1.2.10-4')
        path = self.root / 'candidate.msix'
        path.write_bytes(b'fixture bytes')
        artifact.update(path='candidate.msix', sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                        identity_kind='partner-center-config')
        report = ledger.readiness(data, 'microsoft-store', artifact['id'], self.root)
        self.assertNotIn('formal_store_build_and_signing_required', report['blockers'])
        artifact.update(identity_kind='local-test', signing='local-test')
        report = ledger.readiness(data, 'microsoft-store', artifact['id'], self.root)
        self.assertIn('formal_store_build_and_signing_required', report['blockers'])

    def test_vivo_builder_rejects_versioncode_reuse_before_signing_or_building(self):
        with patch('sys.argv', ['build_vivo_offline.py', '--version-code', '2006']), patch('subprocess.run') as build:
            with self.assertRaisesRegex(SystemExit, 'versionCode'):
                build_vivo_offline.main()
            build.assert_not_called()


    def test_vivo_final_version_checks_include_frozen_candidates_and_other_id_is_ignored(self):
        frozen_code = build_vivo_offline.highest_version_code(self.root, self.data) + 1
        path = self.root / '.release/vivo/1.2.14/offline-4010/manifest.json'
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps({'application_id': 'com.forge.forest', 'version_code': str(frozen_code)}))
        self.assertEqual(build_vivo_offline.highest_version_code(self.root, self.data), frozen_code)
        other = path.parent.parent / 'other/manifest.json'
        other.parent.mkdir()
        other.write_text(json.dumps({'application_id': 'other.app', 'version_code': frozen_code + 1000}))
        self.assertEqual(build_vivo_offline.highest_version_code(self.root, self.data), frozen_code)
        with self.assertRaises(SystemExit):
            build_vivo_offline.validate_target(4010, 4010, self.root / 'unused')
        build_vivo_offline.validate_target(4011, 4010, self.root / 'unused')
        with self.assertRaisesRegex(SystemExit, 'exists'):
            build_vivo_offline.validate_target(4011, 4010, path.parent)

    def test_vivo_rejects_legacy_cli_before_any_build_or_signing(self):
        with patch('sys.argv', ['build_vivo_offline.py', '--build-number', '2011']), patch('subprocess.run') as build:
            with self.assertRaises(SystemExit):
                build_vivo_offline.main()
            build.assert_not_called()

    def test_vivo_badging_must_match_expected_version_identity_abi_and_offline_permissions(self):
        valid = "package: name='com.forge.forest' versionCode='4011' versionName='1.2.14'\nnative-code: 'arm64-v8a'\n"
        self.assertEqual(build_vivo_offline.verify_package(valid, '1.2.14', 4011), ('com.forge.forest', '4011', '1.2.14'))
        for badging in [valid.replace('4011', '6011'), valid.replace('1.2.14', '1.2.10'), valid.replace('com.forge.forest', 'wrong.app'), valid.replace("'arm64-v8a'", "'arm64-v8a' 'x86_64'"), valid + "uses-permission: name='android.permission.INTERNET'\n"]:
            with self.subTest(badging=badging), self.assertRaises(SystemExit):
                build_vivo_offline.verify_package(badging, '1.2.14', 4011)

    def test_submission_profile_and_evidence_are_required(self):
        data = copy.deepcopy(self.data)
        data['submissions'][0]['channel'] = 'microsoft-store'
        with self.assertRaisesRegex(ValueError, 'profile mismatch'):
            ledger.validate(data, self.root)
        data = copy.deepcopy(self.data)
        data['submissions'][0]['observations'] = [{'at': '2026-10-30T00:00:00Z', 'review': 'in_review', 'publication': 'not_published', 'evidence': []}]
        with self.assertRaisesRegex(ValueError, 'requires evidence'):
            ledger.validate(data, self.root)


if __name__ == '__main__':
    unittest.main()
