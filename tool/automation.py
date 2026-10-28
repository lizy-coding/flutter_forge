#!/usr/bin/env python3
"""Bounded automation catalog and platform command adapters. No CI changes.

list: inventory only. run: one smoke case by default, no implicit expensive suite.
Exit 0 PASS; 1 FAIL; 2 BLOCKED/configuration/not applicable. No retries.
"""
import argparse
import json
import os
import platform as host_platform
from pathlib import Path
import re
import signal
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / 'apps/flutter_forge'
PLATFORMS = {'local', 'windows', 'macos', 'android', 'web'}
KINDS = {'smoke', 'integration', 'browser', 'python', 'command', 'windows-ui', 'windows-close', 'manual'}


class Blocked(RuntimeError):
    pass


def load_catalog(root=ROOT):
    data = json.loads((root / 'tool/automation_catalog.json').read_text(encoding='utf-8'))
    if data.get('schema') != 'flutter_forge.automation.v1':
        raise ValueError('Unsupported automation catalog schema')
    cases = data['cases']
    ids, registered = set(), set()
    for case in cases:
        if not re.fullmatch(r'[a-z][a-z0-9-]*', case['id']) or case['id'] in ids:
            raise ValueError('Invalid or duplicate case id')
        ids.add(case['id'])
        if case['kind'] not in KINDS or not set(case['platforms']) <= PLATFORMS or not case['platforms']:
            raise ValueError(f'Invalid adapter: {case["id"]}')
        if not 0 < case['timeout'] <= 1200 or not case['targets']:
            raise ValueError(f'Invalid bounded case: {case["id"]}')
        for target in case['targets'] + ([case['widget_target']] if 'widget_target' in case else []):
            base = root / 'apps/flutter_forge' if target.startswith(('integration_test/', 'test/')) else root
            file = (base / target).resolve()
            if not file.is_relative_to(root.resolve()) or not file.is_file():
                raise ValueError(f'Invalid automation source: {target}')
            if target.startswith('integration_test/'):
                if target in registered:
                    raise ValueError(f'Duplicate integration execution: {target}')
                registered.add(target)
    actual = {p.relative_to(root / 'apps/flutter_forge').as_posix()
              for p in (root / 'apps/flutter_forge/integration_test').rglob('*_test.dart')}
    if actual != registered:
        raise ValueError(f'Integration catalog drift: missing={actual - registered}, stale={registered - actual}')
    return {case['id']: case for case in cases}


def command_for(case, platform, *, device=None, exe=None, output=None, ready=()):
    if platform not in case['platforms']:
        raise Blocked(f'{case["id"]} does not apply to {platform}')
    requirements = set(case.get('requirements', []))
    if requirements - set(ready):
        raise Blocked('Explicit prerequisites required: ' + ', '.join(sorted(requirements - set(ready))))
    kind = case['kind']
    if kind == 'manual':
        raise Blocked('Specialist workflow: use the listed source with its explicit fixtures; never part of smoke')
    if platform in ('windows', 'macos') and sys.platform != {'windows': 'win32', 'macos': 'darwin'}[platform]:
        raise Blocked(f'{platform} requires its real host; a platform override is not host acceptance')
    if kind in ('windows-ui', 'windows-close'):
        if not exe or not Path(exe).is_file():
            raise Blocked('--exe must identify the tested Windows executable')
        if kind == 'windows-close':
            return ['powershell.exe', '-NoProfile', '-File', str(ROOT / case['targets'][0]),
                    '-Executable', str(Path(exe).resolve()), '-Iterations', '2'], ROOT, 'native-posted-close'
        return [sys.executable, str(ROOT / case['targets'][0]), '--exe', str(Path(exe).resolve()),
                '--output', str(output / 'native'), '--iterations', '1'], ROOT, 'native-ui'
    if kind == 'command':
        return case['command'], ROOT, 'source-checks'
    if kind == 'python':
        return [sys.executable, *case['targets']], ROOT, 'source-tests'
    if kind == 'smoke' and platform == 'local':
        return ['flutter', 'test', '--no-pub', case['widget_target'], '--reporter=json'], APP, 'simulated-platform-widget'
    if kind == 'browser' or (kind == 'smoke' and platform == 'web'):
        targets = [case['widget_target']] if kind == 'smoke' else case['targets']
        return ['flutter', 'test', '--no-pub', '--platform', 'chrome', *targets, '--reporter=json'], APP, 'chrome-widget'
    if platform == 'web':
        raise Blocked('This native integration entry has no browser driver; use smoke/web-contracts for browser widgets')
    if platform == 'android' and (not device or device in ('windows', 'macos', 'chrome')):
        raise Blocked('Android requires an explicit Android device id')
    device = device if platform == 'android' else platform
    expected = 'macOS' if platform == 'macos' else platform
    command = ['flutter', 'test', '--no-pub', *case['targets'], '-d', device, '--reporter=json',
               f'--dart-define=FORGE_AUTOMATION_PLATFORM={expected}']
    command.extend('--dart-define=' + define for define in case.get('defines', []))
    return command, APP, 'native-integration'


def verify_android_device(device):
    probe = subprocess.run([shutil.which('flutter') or 'flutter', 'devices', '--machine'], capture_output=True,
                           text=True, encoding='utf-8', timeout=30, check=True)
    try:
        devices = json.loads(probe.stdout)
    except ValueError as error:
        raise Blocked('Could not read Flutter device inventory') from error
    if not any(d.get('id') == device and str(d.get('targetPlatform', '')).startswith('android') and d.get('isSupported', True)
               for d in devices):
        raise Blocked('Selected device is not a connected Android target')


def flutter_result(text):
    tests, done, error = {}, False, False
    for line in text.splitlines():
        try:
            event = json.loads(line)
        except (ValueError, TypeError):
            continue
        if not isinstance(event, dict):
            continue
        if event.get('type') == 'testDone' and not event.get('hidden', False):
            tests[event['testID']] = event
        if event.get('type') == 'done':
            done = event.get('success') is True
        if event.get('type') == 'error':
            error = True
    skipped = sum(bool(t.get('skipped')) for t in tests.values())
    passed = sum(t.get('result') == 'success' and not t.get('skipped') for t in tests.values())
    failed = sum(t.get('result') not in ('success', None) for t in tests.values())
    status = 'PASS' if done and passed and not failed and not error else 'FAIL'
    if done and not passed and skipped and not failed and not error:
        status = 'BLOCKED'
    return status, {'passed': passed, 'failed': failed, 'skipped': skipped}


def run_owned(command, cwd, log, timeout):
    # Resolve PATHEXT (including flutter.bat) without enabling shell expansion.
    command = [shutil.which(command[0]) or command[0], *command[1:]]
    options = {'start_new_session': True} if os.name != 'nt' else {
        'creationflags': subprocess.CREATE_NEW_PROCESS_GROUP}
    with log.open('w', encoding='utf-8') as stream:
        process = subprocess.Popen(command, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT,
                                   env={**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'}, **options)
        try:
            return process.wait(timeout=timeout)
        except (subprocess.TimeoutExpired, KeyboardInterrupt):
            # Only the process tree created by this invocation is owned here.
            if process.poll() is None:
                if os.name == 'nt':
                    subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'],
                                   stdout=stream, stderr=subprocess.STDOUT, check=False, timeout=15)
                else:
                    # Give Flutter a chance to close its owned native test app
                    # before forcibly stopping this command's process group.
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=15)
            raise


def run_case(case, args, output, execute=run_owned):
    result = {'id': case['id'], 'platform': args.platform, 'status': 'NOT_RUN'}
    started = time.monotonic()
    try:
        command, cwd, evidence = command_for(case, args.platform, device=args.device, exe=args.exe,
                                           output=output, ready=args.ready)
        result.update(command=command, evidence=evidence)
        log = output / (case['id'] + '.log')
        result['log'] = str(log)
        try:
            if args.platform == 'android':
                verify_android_device(args.device)
            code = execute(command, cwd, log, case['timeout'])
        except FileNotFoundError as error:
            raise Blocked('Required command is missing: ' + str(error)) from error
        result['returncode'] = code
        result['status'] = 'PASS' if code == 0 else 'FAIL'
        if '--reporter=json' in command:
            status, counts = flutter_result(log.read_text(encoding='utf-8', errors='replace'))
            result.update(status=status if code == 0 else 'FAIL', tests=counts)
        if case['kind'] == 'windows-ui' and code in (0, 2):
            result['nativeReport'] = str(output / 'native/result.json')
            native = json.loads((output / 'native/result.json').read_text(encoding='utf-8'))
            result['status'] = native['status'] if native['status'] in ('PASS', 'FAIL', 'BLOCKED') else 'FAIL'
            if result['status'] == 'PASS' and (code != 0 or not native.get('runs')):
                result['status'] = 'FAIL'
    except Blocked as error:
        result.update(status='BLOCKED', reason=str(error))
    except Exception as error:
        result.update(status='FAIL', reason=type(error).__name__ + ': ' + str(error))
    result['seconds'] = round(time.monotonic() - started, 3)
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['list', 'run'])
    parser.add_argument('--platform', choices=sorted(PLATFORMS), default='local')
    parser.add_argument('--case', dest='cases', action='append')
    parser.add_argument('--device', help='Explicit Android device id; desktop and Chrome targets are fixed')
    parser.add_argument('--exe')
    parser.add_argument('--ready', action='append', default=[], help='Explicitly confirm a named catalog prerequisite')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args(argv)
    try:
        catalog = load_catalog()
    except (ValueError, KeyError, OSError) as error:
        parser.error(str(error))
    if args.action == 'list':
        print(json.dumps(list(catalog.values()), ensure_ascii=False, indent=2))
        return 0
    if not args.output:
        parser.error('run requires --output (a new result directory)')
    selected = list(dict.fromkeys(args.cases or ['smoke']))
    unknown = set(selected) - catalog.keys()
    if unknown:
        parser.error('Unknown cases: ' + ', '.join(sorted(unknown)))
    args.output.mkdir(parents=True, exist_ok=False)
    results, interrupted = [], False
    for index, id_ in enumerate(selected):
        try:
            results.append(run_case(catalog[id_], args, args.output))
        except KeyboardInterrupt:
            interrupted = True
            results.append({'id': id_, 'platform': args.platform, 'status': 'FAIL', 'reason': 'Interrupted'})
            results.extend({'id': pending, 'platform': args.platform, 'status': 'NOT_RUN'}
                           for pending in selected[index + 1:])
            break
    status = 'FAIL' if any(r['status'] == 'FAIL' for r in results) else (
        'BLOCKED' if any(r['status'] != 'PASS' for r in results) else 'PASS')
    report = {'schema': 'flutter_forge.automation_run.v1', 'status': status, 'runs': results,
              'host': {'os': host_platform.platform(), 'architecture': host_platform.machine()},
              'sourceSha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'sourceStatus': subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True).splitlines()}
    (args.output / 'result.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'status': status, 'report': str(args.output / 'result.json')}, ensure_ascii=False))
    return 130 if interrupted else {'PASS': 0, 'FAIL': 1, 'BLOCKED': 2}[status]


if __name__ == '__main__':
    raise SystemExit(main())
