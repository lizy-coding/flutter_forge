#!/usr/bin/env python3
"""Build and verify the signed, network-permission-free Android distribution."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

from privacy_policy import binding, generate as check_privacy


APP_ID = 'com.forge.forest'

def highest_version_code(root, catalog):
    codes = [int(item['build_number']) for item in catalog['artifacts']
             if catalog['profiles'][item['profile']]['platform'] == 'android'
             and catalog['profiles'][item['profile']].get('application_id', APP_ID) == APP_ID]
    paths = list((root / '.release/vivo').glob('*/*/manifest.json'))
    paths += list((root / 'release').glob('*/RELEASE_MANIFEST-android.json'))
    for path in paths:
        data = json.loads(path.read_text())
        if data.get('application_id') == APP_ID and 'version_code' in data:
            codes.append(int(data['version_code']))
    return max(codes, default=0)

def validate_target(code, highest, output):
    if code <= highest or code <= 0 or code > 2100000000:
        raise SystemExit('versionCode must exceed all recorded and frozen Android builds and be a valid Android integer')
    if output.exists():
        raise SystemExit(f'Output already exists: {output}')

def verify_package(badging, version, code):
    package = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    if not package or package.groups() != (APP_ID, str(code), version):
        raise SystemExit('APK application identity or version differs from the requested versionCode/versionName')
    native = re.search(r'^native-code:\s*(.+)$', badging, re.MULTILINE)
    if not native or re.findall(r"'([^']+)'", native[1]) != ['arm64-v8a']:
        raise SystemExit('APK must contain ARM64 only')
    if re.search(r"uses-permission[^\n]*name='android.permission.INTERNET'", badging):
        raise SystemExit('Offline APK unexpectedly has INTERNET permission')
    return package.groups()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--signing-config', type=Path, default=Path.home() / '.local/share/flutter-forge/signing/signing-secrets.json')
    parser.add_argument('--version-code', type=int, help='Final APK versionCode, without ABI offset')
    parser.add_argument('--build-number', help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.build_number is not None:
        parser.error('--build-number used an ABI-offset base and is no longer accepted; use --version-code with the final APK code')
    if args.version_code is None:
        parser.error('--version-code is required')
    root = Path(__file__).resolve().parent.parent
    app = root / 'apps/flutter_forge'
    check_privacy(check=True, root=root)
    policy = binding('offline', root=root)
    catalog = json.loads((root / 'docs/distribution/catalog.json').read_text())
    version_match = re.search(r'^version:\s*(\S+)', (app / 'pubspec.yaml').read_text(), re.MULTILINE)
    if not version_match:
        raise SystemExit('Application version is missing')
    expected_version = version_match[1].strip("\"'").split('+')[0]
    output = root / '.release/vivo' / expected_version / f'offline-{args.version_code}'
    previous_highest = highest_version_code(root, catalog)
    validate_target(args.version_code, previous_highest, output)
    config = json.loads(args.signing_config.read_text())
    keys = ('ANDROID_KEYSTORE_PATH', 'ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD')
    if any(not config.get(key) for key in keys):
        raise SystemExit('Incomplete signing configuration')
    if not Path(config['ANDROID_KEYSTORE_PATH']).is_file():
        raise SystemExit('Release keystore not found')
    env = os.environ.copy()
    env.update({key: config[key] for key in keys})
    env['PUB_HOSTED_URL'] = 'https://pub.dev'
    java = Path('/Applications/Android Studio.app/Contents/jbr/Contents/Home')
    if java.is_dir():
        env['JAVA_HOME'] = str(java)
        env['PATH'] = str(java / 'bin') + os.pathsep + env['PATH']
    # Compare the actual APK signer with the selected keystore, never a debug key.
    cert_env = env.copy()
    cert_env['FORGE_STORE_PASS'] = config['ANDROID_KEYSTORE_PASSWORD']
    certificate = subprocess.check_output(['keytool', '-exportcert', '-keystore', config['ANDROID_KEYSTORE_PATH'], '-alias', config['ANDROID_KEY_ALIAS'], '-storepass:env', 'FORGE_STORE_PASS'], env=cert_env)
    certificate_sha = hashlib.sha256(certificate).hexdigest()
    if certificate_sha != catalog['profiles']['android-offline']['certificate_sha256']:
        raise SystemExit('Release certificate differs from the registered offline identity')
    subprocess.run(['flutter', 'build', 'apk', '--release', '--build-number', str(args.version_code), '--android-project-arg=force-version-code-ignoring-abi=true', '--dart-define=FORGE_OFFLINE=true', '--target-platform', 'android-arm64', '--split-per-abi'], cwd=app, env=env, check=True)
    apk = app / 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk'
    sdk = Path(env.get('ANDROID_SDK_ROOT') or env.get('ANDROID_HOME') or str(Path.home() / 'Library/Android/sdk'))
    versions = sorted((sdk / 'build-tools').iterdir(), key=lambda p: tuple(int(part) for part in p.name.split('.') if part.isdigit()))
    build_tools = versions[-1]
    signature = subprocess.check_output([str(build_tools / 'apksigner'), 'verify', '--verbose', '--print-certs', str(apk)], env=env, text=True)
    signer_hashes = {value.lower() for value in re.findall(r'certificate SHA-256 digest: ([0-9a-fA-F]+)', signature)}
    if signer_hashes != {certificate_sha}:
        raise SystemExit('APK certificate does not match the release keystore')
    badging = subprocess.check_output([str(build_tools / 'aapt'), 'dump', 'badging', str(apk)], text=True)
    app_id, code, version = verify_package(badging, expected_version, args.version_code)
    validate_target(int(code), highest_version_code(root, catalog), output)
    output.mkdir(parents=True, exist_ok=False)
    target = output / f'FlutterForge-{version}-{code}-arm64-offline-release.apk'
    shutil.copy2(apk, target)
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    (output / 'SHA256SUMS').write_text(f'{digest}  {target.name}\n')
    (output / 'apk-badging.txt').write_text(badging)
    (output / 'signature-verification.txt').write_text(signature)
    (output / 'release-certificate.der').write_bytes(certificate)
    (output / 'manifest.json').write_text(json.dumps({
        'application_id': app_id, 'version_name': version, 'version_code': code,
        'requested_version_code': args.version_code, 'version_code_mode': 'exact_no_abi_offset',
        'previous_highest_version_code': previous_highest, 'store_state': 'needs_verification',
        'edition': 'offline', 'build_mode': 'release', 'abi': 'arm64-v8a',
        'distribution_profile': 'android-offline', 'policy_binding': policy,
        'internet_permission': False, 'certificate_sha256': certificate_sha,
        'apk_sha256': digest, 'device_acceptance': 'pending',
        'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
        'source_dirty': bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=root)),
    }, indent=2) + '\n')
    print(f'Verified offline release: {target}')


if __name__ == '__main__':
    main()
