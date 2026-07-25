#!/usr/bin/env bash
set -euo pipefail

# test_all.sh — 遍历主应用与 workspace packages 执行测试
# 退出码: 0 = 全部通过, 非0 = 有失败

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

run_tests() {
  local dir="$1"
  local label="$2"
  local cmd="$3"

  TOTAL=$((TOTAL + 1))

  if [ ! -d "$dir/test" ]; then
    echo "  ⚠ $label: 无 test/ 目录，跳过"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  echo "  ▶ $label ($cmd)"
  if (cd "$dir" && eval "$cmd" 2>&1) ; then
    echo "    ✓ 通过"
    PASSED=$((PASSED + 1))
  else
    echo "    ✗ 失败"
    FAILED=$((FAILED + 1))
  fi
  echo ""
}

echo "=== Flutter Study 全量测试 ==="
echo ""

# 主应用
run_tests "." "main_app" "flutter test"

# Workspace packages
run_tests "packages/gcode_core" "gcode_core" "flutter test"
run_tests "packages/flutter_study_learning" "flutter_study_learning" "flutter test"
run_tests "packages/file_picker_bridge" "file_picker_bridge" "flutter test"
run_tests "packages/flutter_ioc_core" "flutter_ioc_core" "dart test"

echo "--- 汇总 ---"
echo "  总计: $TOTAL | 通过: $PASSED | 失败: $FAILED | 跳过: $SKIPPED"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
echo "全部通过。"
