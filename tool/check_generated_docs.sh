#!/usr/bin/env bash
set -euo pipefail

# check_generated_docs.sh — 检测生成物是否漂移
# 生成 → git diff → 有差异则失败
# CI 中通过此脚本确保提交了最新生成物

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== 文档漂移检测 ==="

# 1. 运行生成器
echo "--- 1/3 生成 Agent 文档 ---"
bash tool/generate_harness_ai_analysis.sh

# 2. 检测生成物漂移
echo "--- 2/3 检测漂移 ---"
GENERATED_FILES=(
  "AI_PROJECT_CONTEXT.md"
  "REFACTOR_PLAN.md"
  "apps/flutter_forge/lib/AI_MODULE_INDEX.md"
  "packages/file_picker_bridge/AI_ANALYSIS.md"
  "packages/flutter_ioc_core/AI_ANALYSIS.md"
)

if ! git diff --exit-code -- "${GENERATED_FILES[@]}" 2>/dev/null; then
  echo ""
  echo "✗ 检测到生成物漂移！"
  echo "  上述文件在生成后与已提交版本不一致。"
  echo "  请执行 'bash tool/generate_harness_ai_analysis.sh' 后提交更新。"
  exit 1
fi

# 3. 验证 JSON 合法性
echo "--- 3/3 JSON 合法性 ---"
node tool/validate_agent_docs.js

echo ""
echo "✓ 生成物无漂移，所有文档合法。"
