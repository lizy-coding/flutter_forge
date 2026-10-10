#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FAILED=0
stage() {
  local label="$1"
  shift
  echo "=== $label ==="
  if "$@"; then echo "PASS: $label"; else echo "FAIL: $label"; FAILED=$((FAILED + 1)); fi
}
stage "Generated contracts" bash tool/check_generated_docs.sh
stage "Dart format (read only)" dart format --output=none --set-exit-if-changed .
stage "Flutter analyze" flutter analyze
stage "Workspace and tool tests" bash tool/test_all.sh
stage "Module test presence" bash tool/verify_test_layout.sh
[ "$FAILED" -eq 0 ]
