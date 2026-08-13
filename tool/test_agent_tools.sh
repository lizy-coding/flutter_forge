#!/usr/bin/env bash
set -euo pipefail

# test_agent_tools.sh — generator + validator 冒烟/回归测试
# 依赖: Node.js, bash, git

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

run_test() {
  local label="$1"
  shift
  echo -n "  [$label] ... "
  if "$@" >/dev/null 2>&1; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Agent Tool 回归测试 ==="
echo ""

echo "--- Generator ---"
run_test "node syntax" node --check tool/generate_agent_indexes.js
run_test "generator runs" bash tool/generate_harness_ai_analysis.sh
run_test "generator deterministic (2nd run)" bash -c 'bash tool/generate_harness_ai_analysis.sh >/dev/null 2>&1'
run_test "AI_PROJECT_CONTEXT valid JSON" node -e "JSON.parse(require('fs').readFileSync('AI_PROJECT_CONTEXT.md','utf8'))"
run_test "REFACTOR_PLAN valid JSON" node -e "JSON.parse(require('fs').readFileSync('REFACTOR_PLAN.md','utf8'))"
run_test "AI_MODULE_INDEX valid JSON" node -e "JSON.parse(require('fs').readFileSync('lib/AI_MODULE_INDEX.md','utf8'))"
run_test "AI_ANALYSIS_SCHEMA valid JSON" node -e "JSON.parse(require('fs').readFileSync('AI_ANALYSIS_SCHEMA.json','utf8'))"

echo ""
echo "--- Validator ---"
run_test "node syntax" node --check tool/validate_agent_docs.js
run_test "validator passes" node tool/validate_agent_docs.js
run_test "validator detects JSON error" bash -c '
  echo "{" > tool/.tmp_bad_schema.json
  sed "s|AI_ANALYSIS_SCHEMA.json|tool/.tmp_bad_schema.json|g" tool/validate_agent_docs.js > tool/.test-validator.js
  node tool/.test-validator.js 2>&1 | grep -q "invalid_json" || exit 1
  rm -f tool/.test-validator.js tool/.tmp_bad_schema.json
'
run_test "validator detects unregistered module" bash -c '
  mkdir -p lib/modules/basic/__unregistered_test_xyz__
  touch lib/modules/basic/__unregistered_test_xyz__/module_entry.dart
  node tool/validate_agent_docs.js 2>&1 | grep -q "unregistered_module" || exit 1
  rm -rf lib/modules/basic/__unregistered_test_xyz__
'

echo ""
echo "--- Workspace Packages ---"
for pkg in gcode_core flutter_study_learning file_picker_bridge flutter_ioc_core; do
  run_test "${pkg} contract valid" node -e "JSON.parse(require('fs').readFileSync('packages/${pkg}/AI_ANALYSIS.md','utf8'))"
  run_test "${pkg} manifest has workspace resolution" grep -q 'resolution: workspace' "packages/${pkg}/pubspec.yaml"
done

echo ""
echo "--- Summary ---"
echo "  PASS: $PASS  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "All tests passed."
