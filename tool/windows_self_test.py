#!/usr/bin/env python3
"""Portable candidate self-test. No install, trust changes, downloads or uploads."""
import argparse
from datetime import datetime, timezone
import hashlib
from html import escape
import json
import os
from pathlib import Path
import platform
import re
import subprocess
import sys
import uuid
import zipfile
import xml.etree.ElementTree as ET

from windows_ui_acceptance import Blocked, process_ids_for_executable

SCHEMA = 'flutter_forge.windows_self_test.v1'
NATIVE_CASES = ['observation', 'caption_controls', 'main_with_child', 'reopen']
MANUAL_IDS = ['A04', 'A05', 'B01', 'B02', 'B03', 'B04', 'B05', 'B06', 'B07',
              'C04-visual', 'configure-log']
NS = {'p': 'http://schemas.microsoft.com/appx/manifest/foundation/windows10'}


def read_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def digest(path):
    hasher = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            hasher.update(block)
    return hasher.hexdigest()


def within(root, name):
    if not name or not isinstance(name, str):
        raise ValueError('Missing relative evidence path')
    path = (root / name).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError('Evidence path escapes its directory')
    return path


def parse_timestamp(value):
    # PowerShell DateTime 'o' emits seven fractional digits; Python 3.9 accepts six.
    value = re.sub(r'(\.\d{6})\d+(Z|[+-]\d{2}:\d{2})$', lambda match: match[1] + match[2], value)
    return datetime.fromisoformat(value.replace('Z', '+00:00'))


def verify_bundle(bundle):
    build = read_json(bundle / 'result.json')
    sign = read_json(bundle / 'local-test-signature.json')
    smoke = read_json(bundle / 'windows-host-smoke.json')
    if build['package_build'] != 'PASS' or build['identity_kind'] != 'local-test':
        raise ValueError('Expected a built LocalTest candidate')
    source = build['source']['head']
    if not re.fullmatch(r'[a-f0-9]{40}', source) or source != sign['source_sha'] or source != smoke['sourceSha']:
        raise ValueError('Build/signature/smoke source SHA mismatch')
    executed = sum(item.get('tests', {}).get('passed', 0) for item in smoke['runs'])
    if smoke['status'] != 'PASS' or not smoke['runs'] or executed < 1 or any(
        item['status'] != 'PASS' or item.get('tests', {}).get('failed', 0) for item in smoke['runs']
    ):
        raise ValueError('Candidate requires at least one passing native smoke test')
    for name, expected in [(build['package']['path'], build['package']['sha256']),
                           (sign['package'], sign['sha256']),
                           (sign['certificate'], sign['certificate_sha256'])]:
        if digest(within(bundle, name)) != expected:
            raise ValueError(f'Hash mismatch: {name}')
    certificate = within(bundle, sign['certificate']).read_bytes()
    if hashlib.sha1(certificate).hexdigest().upper() != sign['certificate_thumbprint'].upper():
        raise ValueError('Public certificate thumbprint mismatch')
    expiry = parse_timestamp(sign['certificate_expires'])
    if expiry.tzinfo is None:
        raise ValueError('Certificate expiry requires timezone')
    if expiry <= datetime.now(timezone.utc):
        raise Blocked('Test certificate expired; obtain a fresh candidate')
    if sign['certificate_subject'] != build['identity']['publisher']:
        raise ValueError('Certificate publisher mismatch')
    with zipfile.ZipFile(within(bundle, sign['package'])) as package:
        manifest = ET.fromstring(package.read('AppxManifest.xml'))
        identity = manifest.find('p:Identity', NS)
        expected = build['identity']
        if identity is None or any(identity.get(k) != v for k, v in {
            'Name': expected['identity_name'], 'Publisher': expected['publisher'],
            'Version': build['package_version'], 'ProcessorArchitecture': 'x64'
        }.items()):
            raise ValueError('MSIX identity/version/architecture mismatch')
        if 'AppxSignature.p7x' not in package.namelist():
            raise ValueError('MSIX signature entry missing')
        exe_records = [item for item in build['files'] if item['path'] == 'flutter_forge.exe']
        if len(exe_records) != 1 or hashlib.sha256(package.read('flutter_forge.exe')).hexdigest() != exe_records[0]['sha256']:
            raise ValueError('Packaged executable does not match build evidence')
    origin_path = bundle / 'candidate-origin.json'
    origin = read_json(origin_path) if origin_path.is_file() else {'run_url': None, 'run_attempt': None}
    if origin.get('source_sha', source) != source:
        raise ValueError('Candidate origin source SHA mismatch')
    return {'runUrl': origin.get('run_url'), 'runAttempt': origin.get('run_attempt'), 'sourceSha': source, 'appVersion': build['app_version'], 'packageVersion': build['package_version'],
            'package': sign['package'], 'packageSha256': sign['sha256'],
            'certificateThumbprint': sign['certificate_thumbprint'], 'certificateExpires': sign['certificate_expires'],
            'identity': build['identity'], 'executableSha256': exe_records[0]['sha256'],
            'cloudSmoke': {'status': 'PASS', 'passed': executed, 'scope': 'Windows Server source-host integration'},
            'sourceStatus': build['source'].get('status', ''),
            'sourceDiffSha256': build['source'].get('diff_sha256'),
            'signatureTrust': 'NOT_RUN', 'integrity': 'PASS'}


def verify_user_bundle(bundle):
    build = read_json(bundle / 'result.json')
    installer = read_json(bundle / 'user-installer.json')
    smoke = read_json(bundle / 'windows-host-smoke.json')
    source = build['source']['head']
    if not re.fullmatch(r'[a-f0-9]{40}', source) or installer['source_sha'] != source or smoke['sourceSha'] != source:
        raise ValueError('EXE/build/smoke source SHA mismatch')
    if build['package_build'] != 'PASS' or installer['schema'] != 'flutter_forge.windows_user_installer.v1':
        raise ValueError('Expected built candidate and user installer report')
    if installer['install_scope'] != 'current-user' or installer['version'] != build['app_version'].split('+')[0]:
        raise ValueError('User installer version/scope mismatch')
    if digest(within(bundle, installer['file'])) != installer['sha256']:
        raise ValueError('User installer hash mismatch')
    runs = smoke['runs']
    passed = sum(item.get('tests', {}).get('passed', 0) for item in runs)
    if smoke['status'] != 'PASS' or passed < 1 or any(item['status'] != 'PASS' or item.get('tests', {}).get('failed', 0) for item in runs):
        raise ValueError('Candidate requires executed passing smoke')
    records = [item for item in build['files'] if item['path'] == 'flutter_forge.exe']
    if len(records) != 1 or not re.fullmatch(r'[a-f0-9]{64}', records[0]['sha256']):
        raise ValueError('Candidate executable fingerprint missing')
    runtime = installer['runtime_files']
    required = {'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll'}
    if len(runtime) != 3 or {item['path'] for item in runtime} != required:
        raise ValueError('App-local runtime evidence missing')
    build_hashes = {item['path']: item['sha256'] for item in build['files']}
    if any(item['sha256'] != build_hashes.get(item['path']) for item in runtime):
        raise ValueError('Runtime fingerprint differs from verified payload')
    origin_path = bundle / 'candidate-origin.json'
    origin = read_json(origin_path) if origin_path.exists() else {}
    if origin.get('source_sha', source) != source:
        raise ValueError('Candidate origin source SHA mismatch')
    return {'sourceSha': source, 'runUrl': origin.get('run_url'), 'runAttempt': origin.get('run_attempt'),
            'appVersion': build['app_version'], 'packageVersion': installer['version'],
            'package': installer['file'], 'packageSha256': installer['sha256'],
            'signing': installer['signing'], 'signatureTrust': 'NOT_RUN', 'integrity': 'PASS', 'runtimeFiles': runtime,
            'executableSha256': records[0]['sha256'], 'sourceStatus': build['source'].get('status', ''),
            'cloudSmoke': {'status': 'PASS', 'passed': passed, 'scope': 'Windows Server source-host integration'}}


def installed_user_executable(evidence):
    # Inspect only the current user's uninstall registry; never use HKLM or elevate.
    package = powershell("""$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.UTF8Encoding]::new()
$found=@{}
foreach($view in @([Microsoft.Win32.RegistryView]::Registry64,[Microsoft.Win32.RegistryView]::Registry32)) {
  $base=[Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::CurrentUser,$view)
  try {
    $key=$base.OpenSubKey('Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\{48C090B8-E508-4D2C-929F-4FA25EFB255D}_is1')
    if($key){ try {
      $location=[string]$key.GetValue('InstallLocation')
      if($location){$found[$location]=@{location=$location;version=[string]$key.GetValue('DisplayVersion');scope='current-user';name=[string]$key.GetValue('DisplayName')}}
    } finally {$key.Dispose()} }
  } finally {$base.Dispose()}
}
if($found.Count -ne 1){throw 'Expected one current-user Flutter Forge installation'}
@($found.Values)[0] | ConvertTo-Json -Compress
""")
    if package['version'] != evidence['packageVersion']:
        raise Blocked('Current-user EXE installation version differs from candidate')
    package['identityBasis'] = 'Fixed HKCU AppId and verified executable hash; display name is informational'
    return Path(package['location']) / 'flutter_forge.exe', package


def powershell(script, values=None):
    result = subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command', script],
                            env={**os.environ, **(values or {})}, capture_output=True,
                            text=True, encoding='utf-8', timeout=30)
    if result.returncode:
        raise Blocked('PowerShell read-only inspection failed: ' + result.stderr.strip())
    return json.loads(result.stdout.lstrip('\ufeff'))


def inspect_signature(bundle, evidence):
    return powershell("""$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.UTF8Encoding]::new()
$s=Get-AuthenticodeSignature -LiteralPath $env:FORGE_SELFTEST_PACKAGE
$c=[Security.Cryptography.X509Certificates.X509Certificate2]::new($env:FORGE_SELFTEST_CERT)
@{status=[string]$s.Status; signer=if($s.SignerCertificate){$s.SignerCertificate.Thumbprint}else{''};
 subject=$c.Subject; thumbprint=$c.Thumbprint; expires=$c.NotAfter.ToUniversalTime().ToString('o')} | ConvertTo-Json -Compress
""", {'FORGE_SELFTEST_PACKAGE': str(within(bundle, evidence['package'])),
       'FORGE_SELFTEST_CERT': str(within(bundle, read_json(bundle / 'local-test-signature.json')['certificate']))})


def installed_executable(evidence):
    package = powershell("""$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.UTF8Encoding]::new()
$p=@(Get-AppxPackage -Name $env:FORGE_SELFTEST_ID)
if($p.Count -ne 1){throw 'Expected exactly one installed LocalTest package for this user'}
@{name=$p[0].Name;version=[string]$p[0].Version;fullName=$p[0].PackageFullName;
 family=$p[0].PackageFamilyName;location=$p[0].InstallLocation} | ConvertTo-Json -Compress
""", {'FORGE_SELFTEST_ID': evidence['identity']['identity_name']})
    if package['name'] != evidence['identity']['identity_name'] or package['version'] != evidence['packageVersion']:
        raise Blocked('Installed package identity/version differs from candidate')
    return Path(package['location']) / 'flutter_forge.exe', package


def interactive_desktop():
    import ctypes
    user32 = ctypes.windll.user32
    user32.OpenInputDesktop.restype = ctypes.c_void_p
    user32.CloseDesktop.argtypes = [ctypes.c_void_p]
    handle = user32.OpenInputDesktop(0, False, 0x0001)
    if not handle:
        raise Blocked('Input desktop unavailable; use an unlocked interactive desktop')
    try:
        size = ctypes.c_ulong()
        user32.GetUserObjectInformationW.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p,
                                                   ctypes.c_ulong, ctypes.POINTER(ctypes.c_ulong)]
        user32.GetUserObjectInformationW(handle, 2, None, 0, ctypes.byref(size))
        name = ctypes.create_unicode_buffer(max(1, size.value // ctypes.sizeof(ctypes.c_wchar)))
        if not user32.GetUserObjectInformationW(handle, 2, name, size.value, ctypes.byref(size)) or name.value.lower() != 'default':
            raise Blocked('Default input desktop unavailable; unlock the test session')
        return {'inputDesktop': name.value, 'status': 'AVAILABLE', 'captureAndInput': 'NOT_RUN'}
    finally:
        user32.CloseDesktop(handle)


def manual_template():
    return {'scope': 'User-observed results; never inferred from cloud or UIA pass',
            'checks': [{'id': key, 'status': 'NOT_RUN', 'note': '', 'evidence': []} for key in MANUAL_IDS]}


def manual_results(output):
    data = read_json(output / 'manual-results.json')
    checks = data['checks']
    if len(checks) != len(MANUAL_IDS) or {item['id'] for item in checks} != set(MANUAL_IDS):
        raise ValueError('Manual checklist IDs changed or duplicated')
    for item in checks:
        if not isinstance(item['note'], str) or not isinstance(item['evidence'], list):
            raise ValueError('Manual notes must be text and evidence must be a list')
        if item['status'] not in {'PASS', 'FAIL', 'BLOCKED', 'NOT_RUN'}:
            raise ValueError('Invalid manual status')
        if item['status'] in {'PASS', 'FAIL'}:
            if not item['note'].strip() or not item['evidence']:
                raise ValueError('Manual PASS/FAIL requires notes and evidence files')
        for name in item['evidence']:
            if not within(output, name).is_file():
                raise ValueError('Manual evidence file missing: ' + name)
    return checks


def summarize(report, checks):
    automated = report.get('automated', {}).get('status', 'NOT_RUN')
    if report.get('error'):
        return report['status']
    if automated in {'FAIL', 'BLOCKED'}:
        return automated
    if any(item['status'] == 'FAIL' for item in checks):
        return 'FAIL'
    if any(item['status'] == 'BLOCKED' for item in checks):
        return 'BLOCKED'
    if automated == 'PASS' and checks and all(item['status'] == 'PASS' for item in checks):
        return 'PASS'
    return 'NEEDS_MANUAL_REVIEW'


def write_report(output, report):
    checks = manual_results(output)
    report['status'] = summarize(report, checks)
    report['manual'] = checks
    (output / 'result.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    rows = ''.join(f'<tr><td>{escape(item["id"])}</td><td>{escape(item["status"])}</td><td>{escape(item["note"])}</td></tr>' for item in checks)
    detail = escape(json.dumps({key: value for key, value in report.items() if key != 'manual'}, ensure_ascii=False, indent=2))
    html = f'''<!doctype html><html lang="zh-CN"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Flutter Forge 自测报告</title>
<style>body{{font:16px/1.6 system-ui;max-width:1000px;margin:auto;padding:24px}}td,th{{border:1px solid #ccc;padding:8px}}table{{border-collapse:collapse}}pre{{white-space:pre-wrap;overflow-wrap:anywhere}}</style>
<h1>Flutter Forge 自测报告：{escape(report['status'])}</h1>
<p>云端冒烟、此处自动复核和人工验收分别记录；物理设备类型由测试者声明。此报告不包含升级、卸载、WACK或商店验收。</p>
<pre>{detail}</pre><table><tr><th>人工项目</th><th>状态</th><th>说明</th></tr>{rows}</table></html>'''
    (output / 'REPORT.html').write_text(html, encoding='utf-8')
    # Bundle only this dedicated output directory. Never traverse external links.
    archive = output.with_name(output.name + '-report.zip')
    if archive.is_symlink():
        raise ValueError('Report archive cannot be a symbolic link')
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as zipped:
        for path in sorted(output.rglob('*')):
            if path.is_file() and not path.is_symlink() and path.resolve().is_relative_to(output.resolve()):
                zipped.write(path, path.relative_to(output))
    return archive


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['check', 'run', 'report'], nargs='?', default='check')
    parser.add_argument('--bundle', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--target', choices=['installed', 'user-exe', 'unpacked'], default='user-exe')
    parser.add_argument('--exe', type=Path)
    parser.add_argument('--device-kind', choices=['physical-x64', 'vm-x64', 'arm64-emulation', 'unknown'], default='unknown')
    parser.add_argument('--manual-start-menu', action='store_true')
    args = parser.parse_args(argv)
    if args.mode == 'report':
        if not args.output:
            parser.error('report requires --output pointing to an existing self-test result')
        output = args.output.resolve()
        try:
            report = read_json(output / 'result.json')
            if report.get('schema') != SCHEMA:
                raise ValueError('Not a self-test report')
            archive = write_report(output, report)
        except (ValueError, OSError, KeyError, TypeError) as error:
            parser.exit(1, str(error) + '\n')
        print(json.dumps({'status': report['status'], 'report': str(archive)}, ensure_ascii=False))
        return {'PASS': 0, 'BLOCKED': 2}.get(report['status'], 1)
    output = (args.output or Path.home() / 'Documents/FlutterForgeSelfTests' /
              (datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:6])).resolve()
    if output.exists() or output.with_name(output.name + '-report.zip').exists():
        parser.error('Output and its report archive must be new')
    if args.bundle.resolve().is_relative_to(output):
        parser.error('Output cannot contain the input bundle')
    output.mkdir(parents=True)
    (output / 'manual-results.json').write_text(json.dumps(manual_template(), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    report = {'schema': SCHEMA, 'status': 'RUNNING', 'startedAt': datetime.now().astimezone().isoformat(),
              'host': {'os': platform.platform(), 'python': platform.python_version(), 'processArchitecture': platform.machine(),
                       'processorArchitecture': os.environ.get('PROCESSOR_ARCHITECTURE'),
                       'nativeArchitectureHint': os.environ.get('PROCESSOR_ARCHITEW6432'),
                       'declaredDeviceKind': args.device_kind},
              'target': args.target, 'mode': args.mode, 'automated': {'status': 'NOT_RUN'},
              'installation': 'NOT_RUN', 'certificateTrustChanges': 'NOT_RUN',
              'startMenuEvidence': 'NOT_RUN'}
    code = 2
    try:
        bundle = args.bundle.resolve(strict=True)
        evidence = verify_user_bundle(bundle) if args.target == 'user-exe' else verify_bundle(bundle)
        report['candidate'] = evidence
        manifests = ['result.json', 'windows-host-smoke.json', 'user-installer.json' if args.target == 'user-exe' else 'local-test-signature.json']
        for name in manifests:
            (output / ('candidate-' + name)).write_bytes((bundle / name).read_bytes())
        if sys.platform != 'win32':
            raise Blocked('Integrity checked only; native self-test requires Windows')
        if args.target == 'user-exe':
            exe, report['installedPackage'] = installed_user_executable(evidence)
        else:
            signature = inspect_signature(bundle, evidence)
            evidence['signatureTrust'] = signature
            if signature['signer'].upper() != evidence['certificateThumbprint'].upper() or signature['thumbprint'].upper() != evidence['certificateThumbprint'].upper() or signature['subject'] != evidence['identity']['publisher']:
                raise ValueError('Authenticode signer or certificate identity mismatch')
            if signature['status'] != 'Valid':
                raise Blocked('Certificate trust/signature is not Valid; follow A01-A02 with the device owner, no trust is changed by this tool')
            if args.target == 'installed':
                exe, report['installedPackage'] = installed_executable(evidence)
            else:
                if not args.exe:
                    raise Blocked('Unpacked tests require --exe; this does not verify installation or Start Menu')
                exe = args.exe.resolve(strict=True)
        if digest(exe) != evidence['executableSha256']:
            raise Blocked('Executable hash differs from candidate, even if its displayed version matches')
        if args.target == 'user-exe':
            for item in evidence['runtimeFiles']:
                if digest(within(exe.parent, item['path'])) != item['sha256']:
                    raise Blocked('Installed app-local runtime differs from candidate: ' + item['path'])
        report['executable'] = {'path': str(exe), 'sha256': digest(exe)}
        report['desktop'] = interactive_desktop()
        report['preflight'] = 'PASS'
        if args.mode == 'run':
            if args.device_kind == 'unknown':
                raise Blocked('Declare --device-kind; virtual/ARM environments cannot be reported as physical x64')
            if process_ids_for_executable(exe):
                raise Blocked('Tested executable is already running; close it normally before this run')
            try:
                import pywinauto  # noqa: F401
                import PIL  # noqa: F401
            except ImportError as error:
                raise Blocked('Install recheck-tools/windows_acceptance_requirements.txt with the same Python') from error
            command = [sys.executable, str(Path(__file__).with_name('windows_ui_acceptance.py')),
                       '--exe', str(exe), '--output', str(output / 'native'), '--iterations', '1',
                       '--cases', *NATIVE_CASES]
            if args.manual_start_menu:
                if args.target not in ('installed', 'user-exe'):
                    raise ValueError('Start Menu observation requires installed target')
                command.extend(['--launch-mode', 'manual-start-menu'])
            (output / 'command.json').write_text(json.dumps(command, ensure_ascii=False, indent=2), encoding='utf-8')
            with (output / 'runner.log').open('w', encoding='utf-8') as log:
                try:
                    run = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=600)
                except subprocess.TimeoutExpired as error:
                    raise Blocked('Native checks exceeded 600s; close any remaining test app normally and preserve evidence') from error
            native_path = output / 'native/result.json'
            if not native_path.is_file():
                raise Blocked('Native runner did not produce a result; see runner.log')
            native = read_json(native_path)
            if args.manual_start_menu and native.get('runs'):
                report['startMenuEvidence'] = 'user-attested-start-menu'
            if any(item.get('case') == 'observation' for item in native.get('runs', [])):
                report['desktop']['captureAndInput'] = 'OBSERVED_IN_NATIVE_RUN'
            expected = len(NATIVE_CASES)
            cases = [item.get('case') for item in native.get('runs', [])]
            if native.get('status') == 'PASS' and (run.returncode != 0 or len(cases) != expected or set(cases) != set(NATIVE_CASES)):
                raise ValueError('Native PASS lacks the expected executed cases')
            report['automated'] = {'status': native['status'], 'executed': len(native.get('runs', [])),
                                   'expected': expected, 'report': 'native/result.json', 'returncode': run.returncode,
                                   'scope': 'physical input and window observation; screenshots need manual review'}
            if native['status'] == 'BLOCKED':
                raise Blocked(native.get('error', 'Native runner blocked'))
            if native['status'] != 'PASS' or run.returncode != 0:
                raise ValueError(native.get('error', 'Native runner failed'))
        code = 0
    except (Blocked, FileNotFoundError) as error:
        report.update(status='BLOCKED', error=str(error))
        code = 2
    except Exception as error:
        report.update(status='FAIL', error=str(error))
        code = 1
    archive = write_report(output, report)
    print(json.dumps({'status': report['status'], 'automated': report['automated']['status'],
                      'preflight': report.get('preflight', 'NOT_RUN'), 'report': str(archive)}, ensure_ascii=False))
    return code


if __name__ == '__main__':
    raise SystemExit(main())
