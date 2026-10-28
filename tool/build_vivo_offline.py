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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--signing-config', type=Path, default=Path.home() / '.local/share/flutter-forge/signing/signing-secrets.json')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    app = root / 'apps/flutter_forge'
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
    subprocess.run(['flutter', 'build', 'apk', '--release', '--dart-define=FORGE_OFFLINE=true', '--target-platform', 'android-arm64', '--split-per-abi'], cwd=app, env=env, check=True)
    apk = app / 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk'
    sdk = Path(env.get('ANDROID_SDK_ROOT') or env.get('ANDROID_HOME') or str(Path.home() / 'Library/Android/sdk'))
    versions = sorted((sdk / 'build-tools').iterdir(), key=lambda p: tuple(int(part) for part in p.name.split('.') if part.isdigit()))
    build_tools = versions[-1]
    signature = subprocess.check_output([str(build_tools / 'apksigner'), 'verify', '--verbose', '--print-certs', str(apk)], env=env, text=True)
    # Compare the actual APK signer with the selected keystore, never a debug key.
    cert_env = env.copy()
    cert_env['FORGE_STORE_PASS'] = config['ANDROID_KEYSTORE_PASSWORD']
    certificate = subprocess.check_output(['keytool', '-exportcert', '-keystore', config['ANDROID_KEYSTORE_PATH'], '-alias', config['ANDROID_KEY_ALIAS'], '-storepass:env', 'FORGE_STORE_PASS'], env=cert_env)
    certificate_sha = hashlib.sha256(certificate).hexdigest()
    signer_hashes = {value.lower() for value in re.findall(r'certificate SHA-256 digest: ([0-9a-fA-F]+)', signature)}
    if signer_hashes != {certificate_sha}:
        raise SystemExit('APK certificate does not match the release keystore')
    badging = subprocess.check_output([str(build_tools / 'aapt'), 'dump', 'badging', str(apk)], text=True)
    if re.search(r"uses-permission[^\n]*name='android.permission.INTERNET'", badging):
        raise SystemExit('Offline APK unexpectedly has INTERNET permission')
    package = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    if not package or package[1] != 'com.forge.forest':
        raise SystemExit('Unexpected application identity')
    app_id, code, version = package.groups()
    output = root / '.release/vivo' / version / 'offline'
    output.mkdir(parents=True, exist_ok=True)
    target = output / f'FlutterForge-{version}-{code}-arm64-offline-release.apk'
    shutil.copy2(apk, target)
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    (output / 'SHA256SUMS').write_text(f'{digest}  {target.name}\n')
    (output / 'apk-badging.txt').write_text(badging)
    (output / 'signature-verification.txt').write_text(signature)
    (output / 'release-certificate.der').write_bytes(certificate)
    (output / 'manifest.json').write_text(json.dumps({
        'application_id': app_id, 'version_name': version, 'version_code': code,
        'edition': 'offline', 'build_mode': 'release', 'abi': 'arm64-v8a',
        'internet_permission': False, 'certificate_sha256': certificate_sha,
        'apk_sha256': digest, 'device_acceptance': 'pending',
        'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
        'source_dirty': bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=root)),
    }, indent=2) + '\n')
    print(f'Verified offline release: {target}')


if __name__ == '__main__':
    main()
