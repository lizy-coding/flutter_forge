import argparse
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import automation as a


def events(*items):
    return '\n'.join(json.dumps(item) for item in items)


def completed(result='success', skipped=False):
    return events({'type': 'testDone', 'testID': 1, 'result': result, 'skipped': skipped, 'hidden': False},
                  {'type': 'done', 'success': result == 'success'})


class CatalogTest(unittest.TestCase):
    def test_caption_specialist_does_not_expand_default_lifecycle_or_smoke(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(a.sys, 'platform', 'win32'):
            exe = Path(directory) / 'app.exe'
            exe.touch()
            catalog = a.load_catalog()
            command, _, _ = a.command_for(catalog['windows-caption'], 'windows', exe=exe, output=Path(directory))
            self.assertEqual(command[-2:], ['--cases', 'caption_controls'])
            command, _, _ = a.command_for(catalog['windows-lifecycle'], 'windows', exe=exe, output=Path(directory))
            self.assertNotIn('--cases', command)
            with self.assertRaises(a.Blocked):
                a.command_for(catalog['windows-start-menu-observation'], 'windows', ready=['interactive-start-menu-observer'])

    def test_all_integration_entries_are_registered_once(self):
        catalog = a.load_catalog()
        self.assertEqual(catalog['smoke']['targets'], ['integration_test/app_test.dart'])
        self.assertNotIn('requirements', catalog['smoke'])
        self.assertNotIn('defines', catalog['smoke'])

    def test_platform_adapters_share_one_native_entry(self):
        case = a.load_catalog()['smoke']
        for platform, host in [('windows', 'win32'), ('macos', 'darwin'), ('android', 'linux')]:
            with self.subTest(platform=platform), patch.object(a.sys, 'platform', host):
                command, cwd, evidence = a.command_for(case, platform, device='android-id')
                self.assertIn('integration_test/app_test.dart', command)
                self.assertEqual(evidence, 'native-integration')
                self.assertEqual(cwd, a.APP)
        for platform, flag, evidence in [('local', None, 'simulated-platform-widget'), ('web', 'chrome', 'chrome-widget')]:
            command, _, kind = a.command_for(case, platform)
            self.assertIn('test/automation/smoke_test.dart', command)
            self.assertEqual(kind, evidence)
            if flag:
                self.assertIn(flag, command)

    def test_wrong_host_missing_device_and_hardware_are_blocked(self):
        catalog = a.load_catalog()
        with patch.object(a.sys, 'platform', 'darwin'):
            with self.assertRaises(a.Blocked):
                a.command_for(catalog['smoke'], 'windows')
        for device in [None, 'macos', 'windows', 'chrome']:
            with self.assertRaises(a.Blocked):
                a.command_for(catalog['smoke'], 'android', device=device)
        with self.assertRaises(a.Blocked):
            a.command_for(catalog['ble'], 'android', device='android-id')

    def test_posted_close_is_explicit_and_keeps_a_distinct_evidence_kind(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(a.sys, 'platform', 'win32'):
            exe = Path(directory) / 'app.exe'
            exe.touch()
            command, _, evidence = a.command_for(a.load_catalog()['windows-posted-close'], 'windows', exe=exe)
            self.assertEqual(evidence, 'native-posted-close')
            self.assertEqual(command[-2:], ['-Iterations', '2'])
            self.assertNotIn('-Command', command)

    def test_device_id_must_really_be_android(self):
        probe = subprocess.CompletedProcess([], 0, json.dumps([{'id': 'chosen', 'targetPlatform': 'darwin'}]), '')
        with patch.object(a.subprocess, 'run', return_value=probe):
            with self.assertRaises(a.Blocked):
                a.verify_android_device('chosen')
        probe.stdout = json.dumps([{'id': 'chosen', 'targetPlatform': 'android-arm64'}])
        with patch.object(a.subprocess, 'run', return_value=probe):
            a.verify_android_device('chosen')

    def test_unregistered_integration_and_duplicate_execution_fail_catalog_validation(self):
        catalog = list(a.load_catalog().values())
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'tool').mkdir()
            for case in catalog:
                for target in case['targets'] + ([case['widget_target']] if 'widget_target' in case else []):
                    base = root / 'apps/flutter_forge' if target.startswith(('integration_test/', 'test/')) else root
                    file = base / target
                    file.parent.mkdir(parents=True, exist_ok=True)
                    file.touch()
            file = root / 'tool/automation_catalog.json'
            file.write_text(json.dumps({'schema':'flutter_forge.automation.v1', 'cases':catalog}), encoding='utf-8')
            extra = root / 'apps/flutter_forge/integration_test/forgotten_test.dart'
            extra.touch()
            with self.assertRaisesRegex(ValueError, 'Integration catalog drift'):
                a.load_catalog(root)
            extra.unlink()
            duplicate = {**catalog[0], 'id': 'duplicate'}
            file.write_text(json.dumps({'schema':'flutter_forge.automation.v1', 'cases':catalog + [duplicate]}), encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'Duplicate integration execution'):
                a.load_catalog(root)

    def test_cli_runs_smoke_once_even_when_selected_twice(self):
        with tempfile.TemporaryDirectory() as directory, patch('builtins.print'), patch.object(a, 'run_case',
                return_value={'id':'smoke','status':'PASS'}) as run:
            output = Path(directory) / 'report'
            self.assertEqual(a.main(['run', '--case', 'smoke', '--case', 'smoke', '--output', str(output)]), 0)
            self.assertEqual(run.call_count, 1)
            self.assertEqual(json.loads((output / 'result.json').read_text())['status'], 'PASS')


class ResultTest(unittest.TestCase):
    def test_flutter_report_requires_executed_success(self):
        for text, status in [(completed(), 'PASS'), (completed(skipped=True), 'BLOCKED'),
                             (completed('failure'), 'FAIL'), ('All tests passed!', 'FAIL'),
                             (events({'type': 'done', 'success': True}), 'FAIL'),
                             (completed() + '\n' + events({'type': 'error'}), 'FAIL')]:
            with self.subTest(status=status, text=text):
                self.assertEqual(a.flutter_result(text)[0], status)

    def test_hidden_loader_does_not_count_as_executed_test(self):
        text = events({'type':'testDone', 'testID':1, 'result':'success', 'hidden':True},
                      {'type':'done', 'success':True})
        self.assertEqual(a.flutter_result(text)[0], 'FAIL')

    def test_runner_keeps_failure_and_all_skip_even_if_process_exits_zero(self):
        case = a.load_catalog()['smoke']
        args = argparse.Namespace(platform='local', device=None, exe=None, ready=[])
        for text, expected in [(completed(), 'PASS'), (completed(skipped=True), 'BLOCKED'), (completed('failure'), 'FAIL')]:
            with self.subTest(expected=expected), tempfile.TemporaryDirectory() as directory:
                def execute(command, cwd, log, timeout):
                    log.write_text(text, encoding='utf-8')
                    return 0
                result = a.run_case(case, args, Path(directory), execute=execute)
                self.assertEqual(result['status'], expected)
                self.assertEqual(result['evidence'], 'simulated-platform-widget')

    def test_timeout_is_a_failure_and_missing_executable_is_blocked(self):
        args = argparse.Namespace(platform='local', device=None, exe=None, ready=[])
        case = a.load_catalog()['smoke']
        for error, status in [(FileNotFoundError('flutter'), 'BLOCKED'),
                              (subprocess.TimeoutExpired(['flutter'], 1), 'FAIL')]:
            with tempfile.TemporaryDirectory() as directory:
                def execute(*_):
                    raise error
                self.assertEqual(a.run_case(case, args, Path(directory), execute)['status'], status)

    def test_incomplete_output_is_failure_not_an_environment_block(self):
        args = argparse.Namespace(platform='local', device=None, exe=None, ready=[])
        with tempfile.TemporaryDirectory() as directory:
            result = a.run_case(a.load_catalog()['smoke'], args, Path(directory), execute=lambda *_: 0)
            self.assertEqual(result['status'], 'FAIL')

    def test_interrupt_stops_later_cases_and_preserves_a_partial_report(self):
        with tempfile.TemporaryDirectory() as directory, patch('builtins.print'), patch.object(a, 'run_case', side_effect=KeyboardInterrupt) as run:
            output = Path(directory) / 'report'
            code = a.main(['run', '--case', 'smoke', '--case', 'windows-log-tests', '--output', str(output)])
            self.assertEqual(code, 130)
            self.assertEqual(run.call_count, 1)
            report = json.loads((output / 'result.json').read_text())
            self.assertEqual([r['status'] for r in report['runs']], ['FAIL', 'NOT_RUN'])

    def test_command_resolution_keeps_argument_boundaries_without_a_shell(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(a.shutil, 'which', return_value='/sdk with spaces/flutter'):
            with patch.object(a.subprocess, 'Popen') as launch:
                launch.return_value.wait.return_value = 0
                a.run_owned(['flutter', 'test', 'a path/test.dart'], Path(directory),
                            Path(directory) / 'log', 1)
                self.assertEqual(launch.call_args.args[0], ['/sdk with spaces/flutter', 'test', 'a path/test.dart'])
                self.assertFalse(launch.call_args.kwargs.get('shell', False))

    def test_owned_process_timeout_is_terminated_and_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(subprocess.TimeoutExpired):
                a.run_owned([a.sys.executable, '-c', 'import time; time.sleep(60)'],
                            Path(directory), Path(directory) / 'process.log', .1)



if __name__ == '__main__':
    unittest.main()
