#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_root="$repo_root/apps/flutter_forge"
sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
output_root="${ANDROID_RELEASE_OUTPUT:-$app_root/build/android-release}"
keystore="$output_root/local-upload-keystore.jks"
store_password="${ANDROID_KEYSTORE_PASSWORD:-local-only-change-me}"
key_alias="${ANDROID_KEY_ALIAS:-local-upload}"
key_password="${ANDROID_KEY_PASSWORD:-$store_password}"

android_studio_jdk="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
if [[ -x "$android_studio_jdk/bin/keytool" ]]; then
  export JAVA_HOME="$android_studio_jdk"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

mkdir -p "$output_root"
if [[ ! -f "$keystore" ]]; then
  keytool -genkeypair -v \
    -keystore "$keystore" \
    -storetype JKS \
    -storepass "$store_password" \
    -keypass "$key_password" \
    -alias "$key_alias" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Flutter Forge Local,O=Flutter Forge,C=CN"
fi

export ANDROID_KEYSTORE_PATH="$keystore"
export ANDROID_KEYSTORE_PASSWORD="$store_password"
export ANDROID_KEY_ALIAS="$key_alias"
export ANDROID_KEY_PASSWORD="$key_password"

cd "$repo_root"
bash tool/quality_gate.sh

cd "$app_root"
flutter build appbundle --release
flutter build apk --release --split-per-abi

bundle="$app_root/build/app/outputs/bundle/release/app-release.aab"
apk_dir="$app_root/build/app/outputs/apk/release"
apksigner="$sdk_root/build-tools/$(ls -1 "$sdk_root/build-tools" | sort -V | tail -1)/apksigner"

[[ -f "$bundle" ]] || { echo "Missing AAB: $bundle" >&2; exit 1; }
[[ -x "$apksigner" ]] || { echo "Missing apksigner: $apksigner" >&2; exit 1; }

for apk in "$apk_dir"/*.apk; do
  "$apksigner" verify --verbose "$apk"
done
jarsigner -verify -verbose -certs "$bundle" >/dev/null

{
  sha256sum "$bundle"
  sha256sum "$apk_dir"/*.apk
} | tee "$output_root/SHA256SUMS"

echo "Android local release validation passed"
echo "AAB: $bundle"
echo "APKs: $apk_dir"
