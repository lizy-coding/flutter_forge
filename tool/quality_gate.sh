#!/usr/bin/env bash
set -euo pipefail

# quality_gate.sh — 全量质量门禁
# 按固定顺序执行: 文档生成/校验 → 格式 → 分析 → 测试 → 测试布局 → FlutterGuard
# 任一步失败返回非零状态码并指明失败阶段。

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

run_stage() {
  local label="$1"
  shift
  echo "--- [$label] ---"
  if "$@" 2>&1; then
    echo -e "  ${GREEN}✓ $label 通过${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗ $label 失败${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
  echo ""
}

echo "=== Flutter Forge 质量门禁 ==="
echo ""

# Stage 1: Agent 文档生成 + 校验 + 漂移检测
run_stage "Agent 文档生成与校验" bash -c "
  bash tool/generate_harness_ai_analysis.sh &&
  git diff --exit-code -- AI_ANALYSIS_SCHEMA.json AI_PROJECT_CONTEXT.md REFACTOR_PLAN.md lib/**/AI_ANALYSIS.md lib/AI_MODULE_INDEX.md packages/**/AI_ANALYSIS.md
"

# Stage 2: 代码格式
run_stage "Dart 格式" bash -c "
  dart format . &&
  git diff --exit-code -- '*.dart'
"

# Stage 3: 静态分析
run_stage "Flutter 静态分析" flutter analyze --no-fatal-infos --no-fatal-warnings

# Stage 4: 测试
run_stage "全量测试" bash tool/test_all.sh

# Stage 5: 测试布局校验
run_stage "测试布局校验" bash tool/verify_test_layout.sh

# Stage 6: FlutterGuard 安全扫描
run_stage "FlutterGuard" dart run flutterguard_cli:flutterguard scan . --fail-on high

echo "=== 质量门禁完成 ==="
echo -e "  通过: ${GREEN}$PASS_COUNT${NC}"
echo -e "  失败: ${RED}$FAIL_COUNT${NC}"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
echo "所有门禁通过。"
