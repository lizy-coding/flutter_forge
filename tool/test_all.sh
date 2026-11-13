#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
MEMBERS="$(node tool/workspace_members.js)"
FAILED=0
while IFS= read -r member; do
  echo "=== Tests: $member ==="
  if [ ! -d "$member/test" ] || ! find "$member/test" -name '*_test.dart' -print -quit | grep -q .; then
    echo "FAIL: $member has no tests" >&2
    FAILED=$((FAILED + 1))
  elif ! (cd "$member" && flutter test --no-pub); then
    FAILED=$((FAILED + 1))
  fi
done <<< "$MEMBERS"
if ! node --test tool/agent_indexes/generator.test.js tool/agent_indexes/availability.test.js tool/ci_contracts.test.js; then
  FAILED=$((FAILED + 1))
fi
if ! dart tool/module_scaffold_test.dart; then
  FAILED=$((FAILED + 1))
fi
if ! python3 tool/genui_codex_bridge_test.py; then
  FAILED=$((FAILED + 1))
fi
[ "$FAILED" -eq 0 ]
