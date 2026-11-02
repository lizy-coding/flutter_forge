"""Portable self-test contracts using fixture bytes; no Windows acceptance claimed."""
from datetime import datetime, timedelta, timezone
import hashlib
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import zipfile

import windows_self_test as tool


def write_json(path, data):
    path.write_text(json.dumps(data), encoding='utf-8')


def fixture(bundle):
    bundle.mkdir()
    binary = b'fixture executable, not a real Windows binary'
    cert = b'fixture public certificate'
    (bundle / 'test.cer').write_bytes(cert)
    identity = {'identity_name': 'Forest.FlutterForge.LocalTest', 'publisher': 'CN=Fixture'}
    xml = f'<Package xmlns="{tool.NS["p"]}"><Identity Name="{identity["identity_name"]}" Publisher="CN=Fixture" Version="1.2.11.0" ProcessorArchitecture="x64"/></Package>'
    for name in ['unsigned.msix', 'signed.msix']:
        with zipfile.ZipFile(bundle / name, 'w') as package:
            package.writestr('AppxManifest.xml', xml)
            package.writestr('flutter_forge.exe', binary)
            if name == 'signed.msix':
                package.writestr('AppxSignature.p7x', 'fixture signature')
    build = {'package_build': 'PASS', 'identity_kind': 'local-test', 'source': {'head': 'a' * 40, 'status': 'generated file dirty'},
             'identity': identity, 'app_version': '1.2.11+6', 'package_version': '1.2.11.0',
             'package': {'path': 'unsigned.msix', 'sha256': tool.digest(bundle / 'unsigned.msix')},
             'files': [{'path': 'flutter_forge.exe', 'sha256': hashlib.sha256(binary).hexdigest()}]}
    sign = {'source_sha': 'a' * 40, 'package': 'signed.msix', 'sha256': tool.digest(bundle / 'signed.msix'),
            'certificate': 'test.cer', 'certificate_sha256': tool.digest(bundle / 'test.cer'),
            'certificate_thumbprint': hashlib.sha1(cert).hexdigest().upper(), 'certificate_subject': 'CN=Fixture',
            'certificate_expires': (datetime.now(timezone.utc) + timedelta(days=10)).isoformat()}
    smoke = {'sourceSha': 'a' * 40, 'status': 'PASS', 'runs': [{'status': 'PASS', 'tests': {'passed': 1, 'failed': 0, 'skipped': 0}}]}
    for name, data in [('result.json', build), ('local-test-signature.json', sign), ('windows-host-smoke.json', smoke)]:
        write_json(bundle / name, data)
    return build, sign, smoke, binary


class SelfTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.bundle = self.root / 'bundle'
        self.build, self.sign, self.smoke, self.binary = fixture(self.bundle)

    def user_installer(self):
        path = self.bundle / 'user-setup.exe'
        path.write_bytes(b'fixture installer')
        info = {'schema': 'flutter_forge.windows_user_installer.v1', 'source_sha': 'a' * 40,
                'install_scope': 'current-user', 'version': '1.2.11', 'file': path.name,
                'sha256': tool.digest(path), 'signing': 'unsigned'}
        info['runtime_files'] = [{'path': name, 'sha256': hashlib.sha256(b'fixture runtime').hexdigest()} for name in ['msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll']]
        build = tool.read_json(self.bundle / 'result.json')
        build['files'].extend(info['runtime_files'])
        write_json(self.bundle / 'result.json', build)
        write_json(self.bundle / 'user-installer.json', info)
        return info

    def test_default_check_selects_user_exe_without_msix_evidence(self):
        self.user_installer()
        (self.bundle / 'local-test-signature.json').unlink()
        output = self.root / 'default-exe'
        with patch.object(tool.sys, 'platform', 'darwin'):
            code = tool.main(['check', '--bundle', str(self.bundle), '--output', str(output)])
        report = tool.read_json(output / 'result.json')
        self.assertEqual(code, 2)
        self.assertEqual(report['target'], 'user-exe')
        self.assertEqual(report['candidate']['integrity'], 'PASS')

    def test_user_exe_integrity_does_not_depend_on_msix_trust(self):
        info = self.user_installer()
        (self.bundle / 'local-test-signature.json').unlink()
        (self.bundle / 'test.cer').unlink()
        result = tool.verify_user_bundle(self.bundle)
        self.assertEqual(result['packageSha256'], info['sha256'])
        self.assertEqual(result['signing'], 'unsigned')
        self.assertEqual(result['signatureTrust'], 'NOT_RUN')
        (self.bundle / 'user-setup.exe').write_bytes(b'wrong installer')
        with self.assertRaisesRegex(ValueError, 'installer hash'):
            tool.verify_user_bundle(self.bundle)

    def test_user_installer_requires_runtime_matching_verified_payload(self):
        info = self.user_installer()
        info['runtime_files'][0]['sha256'] = '0' * 64
        write_json(self.bundle / 'user-installer.json', info)
        with self.assertRaisesRegex(ValueError, 'Runtime fingerprint'):
            tool.verify_user_bundle(self.bundle)
        info['runtime_files'] = []
        write_json(self.bundle / 'user-installer.json', info)
        with self.assertRaisesRegex(ValueError, 'runtime evidence'):
            tool.verify_user_bundle(self.bundle)

    def test_user_install_display_name_is_not_the_identity(self):
        with patch.object(tool, 'powershell', return_value={'location': 'C:/user', 'version': '1.2.13', 'name': 'Flutter Forge 1.2.13'}):
            exe, report = tool.installed_user_executable({'packageVersion': '1.2.13'})
            self.assertEqual(exe.name, 'flutter_forge.exe')
            self.assertIn('Fixed HKCU AppId', report['identityBasis'])

    def test_user_install_discovery_does_not_accept_wrong_version(self):
        with patch.object(tool, 'powershell', return_value={'location': 'C:/user', 'version': '1.0.0', 'name': 'Flutter Forge'}):
            with self.assertRaisesRegex(tool.Blocked, 'version differs'):
                tool.installed_user_executable({'packageVersion': '1.2.11'})

    def test_integrity_preserves_scope_dirty_state_and_missing_origin(self):
        result = tool.verify_bundle(self.bundle)
        self.assertEqual(result['integrity'], 'PASS')
        self.assertEqual(result['signatureTrust'], 'NOT_RUN')
        self.assertEqual(result['sourceStatus'], 'generated file dirty')
        self.assertIsNone(result['runUrl'])

    def test_wrong_hash_path_and_source_cannot_pass(self):
        sign_path = self.bundle / 'local-test-signature.json'
        for change in [{'sha256': '0' * 64}, {'source_sha': 'b' * 40}, {'package': '../outside.msix'}]:
            with self.subTest(change=change):
                write_json(sign_path, {**self.sign, **change})
                with self.assertRaises(ValueError):
                    tool.verify_bundle(self.bundle)

    def test_zero_execution_or_failed_cloud_smoke_is_rejected(self):
        for results in [{'passed': 0, 'skipped': 1}, {'passed': 1, 'failed': 1}]:
            write_json(self.bundle / 'windows-host-smoke.json', {**self.smoke, 'runs': [{'status': 'PASS', 'tests': results}]})
            with self.assertRaisesRegex(ValueError, 'passing native smoke'):
                tool.verify_bundle(self.bundle)

    def test_powershell_seven_digit_timestamp_is_portable(self):
        write_json(self.bundle / 'local-test-signature.json', {**self.sign, 'certificate_expires': '2099-01-01T00:00:00.0000000Z'})
        self.assertEqual(tool.verify_bundle(self.bundle)['integrity'], 'PASS')

    def test_expired_certificate_is_blocked_not_a_pass(self):
        write_json(self.bundle / 'local-test-signature.json', {**self.sign, 'certificate_expires': '2000-01-01T00:00:00Z'})
        with self.assertRaisesRegex(tool.Blocked, 'expired'):
            tool.verify_bundle(self.bundle)

    def test_matching_report_hash_does_not_hide_wrong_msix_identity(self):
        with zipfile.ZipFile(self.bundle / 'signed.msix', 'w') as package:
            package.writestr('AppxManifest.xml', '<Package xmlns="' + tool.NS['p'] + '"><Identity Name="Wrong"/></Package>')
        write_json(self.bundle / 'local-test-signature.json', {**self.sign, 'sha256': tool.digest(self.bundle / 'signed.msix')})
        with self.assertRaisesRegex(ValueError, 'identity/version'):
            tool.verify_bundle(self.bundle)

    def test_origin_must_match_candidate_source(self):
        write_json(self.bundle / 'candidate-origin.json', {'source_sha': 'b' * 40, 'run_url': 'https://github.com/fixture'})
        with self.assertRaisesRegex(ValueError, 'origin source'):
            tool.verify_bundle(self.bundle)

    def test_non_windows_creates_blocked_report_and_archive(self):
        output = self.root / 'output'
        with patch.object(tool.sys, 'platform', 'darwin'):
            code = tool.main(['check', '--target', 'installed', '--bundle', str(self.bundle), '--output', str(output)])
        report = tool.read_json(output / 'result.json')
        self.assertEqual(code, 2)
        self.assertEqual(report['status'], 'BLOCKED')
        self.assertEqual(report['candidate']['integrity'], 'PASS')
        self.assertTrue((self.root / 'output-report.zip').is_file())
        self.assertTrue(all(item['status'] == 'NOT_RUN' for item in report['manual']))
        with self.assertRaises(SystemExit):
            tool.main(['check', '--target', 'installed', '--bundle', str(self.bundle), '--output', str(output)])

    def run_fixture(self, output, native_runs=None, signature='Valid', exe_bytes=None, active_pids=None, target=None, elevated=False):
        exe = self.root / 'installed/flutter_forge.exe'
        exe.parent.mkdir(exist_ok=True)
        exe.write_bytes(exe_bytes or self.binary)
        signer = {'signer': self.sign['certificate_thumbprint'], 'thumbprint': self.sign['certificate_thumbprint'],
                  'subject': 'CN=Fixture', 'status': signature}
        if target == 'user-exe':
            info = self.user_installer()
            for item in info['runtime_files']:
                (exe.parent / item['path']).write_bytes(b'fixture runtime')
            (self.bundle / 'local-test-signature.json').unlink()
        calls = []
        def native(command, **kwargs):
            calls.append(command)
            (output / 'native').mkdir()
            runs = native_runs if native_runs is not None else [{'case': case} for case in tool.NATIVE_CASES]
            write_json(output / 'native/result.json', {'status': 'PASS', 'runs': runs})
            return SimpleNamespace(returncode=0)
        with patch.object(tool.sys, 'platform', 'win32'), patch.object(tool, 'inspect_signature', return_value=signer), \
             patch.object(tool, 'installed_executable', return_value=(exe, {'version': '1.2.11.0'})), \
             patch.object(tool, 'installed_user_executable', return_value=(exe, {'version': '1.2.11', 'scope': 'current-user'})), \
             patch.object(tool, 'interactive_desktop', return_value={'status': 'AVAILABLE'}), \
             patch.object(tool, 'user_execution_context', return_value={'elevated': elevated}), \
             patch.object(tool, 'process_ids_for_executable', return_value=active_pids or []), \
             patch.dict('sys.modules', {'pywinauto': SimpleNamespace(), 'PIL': SimpleNamespace()}), \
             patch.object(tool.subprocess, 'run', side_effect=native):
            code = tool.main(['run', '--bundle', str(self.bundle), '--output', str(output), '--device-kind', 'vm-x64', '--target', target or 'installed'])
        return code, tool.read_json(output / 'result.json'), calls

    def test_elevated_exe_run_cannot_be_standard_user_acceptance(self):
        code, report, commands = self.run_fixture(self.root / 'elevated', target='user-exe', elevated=True)
        self.assertEqual(code, 2)
        self.assertEqual(report['status'], 'BLOCKED')
        self.assertTrue(report['userContext']['elevated'])
        self.assertFalse(commands)

    def test_user_exe_run_works_without_msix_signature_report(self):
        code, report, commands = self.run_fixture(self.root / 'user-exe', target='user-exe')
        self.assertEqual(code, 0)
        self.assertEqual(report['target'], 'user-exe')
        self.assertEqual(report['installedPackage']['scope'], 'current-user')
        self.assertEqual(report['certificateTrustChanges'], 'NOT_RUN')
        self.assertEqual(report['status'], 'NEEDS_MANUAL_REVIEW')
        self.assertEqual(len(commands), 1)

    def test_msix_run_is_one_bounded_round_and_never_full_acceptance(self):
        code, report, commands = self.run_fixture(self.root / 'run')
        self.assertEqual(code, 0)
        self.assertEqual(report['automated']['executed'], 4)
        self.assertEqual(report['status'], 'NEEDS_MANUAL_REVIEW')
        self.assertEqual(report['host']['declaredDeviceKind'], 'vm-x64')
        self.assertEqual(commands[0][commands[0].index('--iterations') + 1], '1')
        self.assertNotIn('rapid_categories', commands[0])

    def test_existing_test_process_is_not_reused_or_killed(self):
        code, report, commands = self.run_fixture(self.root / 'active', active_pids=[123])
        self.assertEqual(code, 2)
        self.assertIn('already running', report['error'])
        self.assertFalse(commands)

    def test_old_installed_exe_same_version_is_blocked(self):
        code, report, commands = self.run_fixture(self.root / 'old', exe_bytes=b'old binary same version')
        self.assertEqual(code, 2)
        self.assertEqual(report['status'], 'BLOCKED')
        self.assertIn('hash differs', report['error'])
        self.assertEqual(commands, [])

    def test_untrusted_package_does_not_install_or_change_trust(self):
        code, report, commands = self.run_fixture(self.root / 'untrusted', signature='NotTrusted')
        self.assertEqual(code, 2)
        self.assertEqual(report['certificateTrustChanges'], 'NOT_RUN')
        self.assertEqual(report['installation'], 'NOT_RUN')
        self.assertFalse(commands)

    def test_zero_or_duplicate_native_cases_cannot_pass(self):
        for name, runs in [('zero', []), ('duplicate', [{'case': 'observation'}] * 4)]:
            with self.subTest(name=name):
                code, report, _ = self.run_fixture(self.root / name, native_runs=runs)
                self.assertEqual(code, 1)
                self.assertEqual(report['status'], 'FAIL')

    def test_user_installation_omissions_cannot_produce_overall_pass(self):
        output = self.root / 'install-incomplete'
        output.mkdir()
        (output / 'notes.txt').write_text('observed interaction')
        manual = tool.manual_template('user-exe')
        for item in manual['checks']:
            if item['id'] not in tool.USER_INSTALL_IDS:
                item.update(status='PASS', note='observed', evidence=['notes.txt'])
        write_json(output / 'manual-results.json', manual)
        report = {'schema': tool.SCHEMA, 'target': 'user-exe', 'status': 'NEEDS_MANUAL_REVIEW', 'automated': {'status': 'PASS'}}
        tool.write_report(output, report)
        self.assertEqual(report['status'], 'NEEDS_MANUAL_REVIEW')
        self.assertEqual(len(report['installationAcceptance']['checks']), 4)
        manual['checks'] = [item for item in manual['checks'] if item['id'] not in tool.USER_INSTALL_IDS]
        write_json(output / 'manual-results.json', manual)
        with self.assertRaisesRegex(ValueError, 'checklist IDs'):
            tool.write_report(output, report)

    def test_missing_minimize_observation_does_not_pass(self):
        output = self.root / 'minimize-not-run'
        output.mkdir()
        (output / 'notes.txt').write_text('manual observations')
        manual = tool.manual_template('user-exe')
        for item in manual['checks']:
            if item['id'] != 'caption-minimize-main-child':
                item.update(status='PASS', note='Observed by tester', evidence=['notes.txt'])
        write_json(output / 'manual-results.json', manual)
        report = {'target': 'user-exe', 'status': 'NEEDS_MANUAL_REVIEW', 'automated': {'status': 'PASS'}}
        tool.write_report(output, report)
        self.assertEqual(report['status'], 'NEEDS_MANUAL_REVIEW')

    def test_manual_target_cannot_be_changed_to_skip_install_checks(self):
        output = self.root / 'target-changed'
        output.mkdir()
        write_json(output / 'manual-results.json', tool.manual_template('installed'))
        report = {'target': 'user-exe', 'status': 'NEEDS_MANUAL_REVIEW', 'automated': {'status': 'PASS'}}
        with self.assertRaisesRegex(ValueError, 'target differs'):
            tool.write_report(output, report)

    def test_manual_pass_needs_evidence_and_no_external_path(self):
        output = self.root / 'manual'
        output.mkdir()
        manual = tool.manual_template()
        manual['checks'][0].update(status='PASS', note='Observed')
        write_json(output / 'manual-results.json', manual)
        with self.assertRaisesRegex(ValueError, 'requires notes and evidence'):
            tool.manual_results(output)
        manual['checks'][0]['evidence'] = ['../external.log']
        write_json(output / 'manual-results.json', manual)
        with self.assertRaisesRegex(ValueError, 'escapes'):
            tool.manual_results(output)

    def test_manual_completion_remains_user_observed_and_excludes_external_links(self):
        output = self.root / 'complete'
        output.mkdir()
        (output / 'observations.txt').write_text('User observations')
        manual = tool.manual_template()
        for item in manual['checks']:
            item.update(status='PASS', note='Observed by tester', evidence=['observations.txt'])
        write_json(output / 'manual-results.json', manual)
        outside = self.root / 'private.txt'
        outside.write_text('not test evidence')
        (output / 'external-link.txt').write_text('fixture representing a link; no Windows symlink privileges required')
        report = {'schema': tool.SCHEMA, 'status': 'NEEDS_MANUAL_REVIEW', 'automated': {'status': 'PASS'}}
        with patch.object(Path, 'is_symlink', lambda path: path.name == 'external-link.txt'):
            archive = tool.write_report(output, report)
        self.assertEqual(report['status'], 'PASS')
        with zipfile.ZipFile(archive) as zipped:
            self.assertNotIn('external-link.txt', zipped.namelist())
            self.assertIn('REPORT.html', zipped.namelist())


if __name__ == '__main__':
    unittest.main()
