#!/usr/bin/env bash
# 基线冒烟：从全项目测试中固定的关键路径子集，零网络、确定性、目标 2 分钟内。
# 用作本地改动后的快速预检与事故回归入口；完整验收仍是 tool/quality_gate.sh。
# 用例选型与维护规则见 docs/TESTING.md 的「基线冒烟」一节。
# 用法：
#   bash tool/smoke_baseline.sh               # 基线用例
#   bash tool/smoke_baseline.sh --ax-soak     # 追加 macOS AX 语义浸泡（默认 24 轮）
#   bash tool/smoke_baseline.sh --ax-soak=120
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/apps/flutter_forge"

BASELINE_TESTS=(
  "test/shared/genui_session_core_test.dart"
  "test/shared/module_discovery_streaming_test.dart"
  "test/modules/ui/genui_workbench/genui_workbench_test.dart"
  "test/shared/multi_window_manager_test.dart"
  "test/shared/desktop_workbench_test.dart"
  "test/shared/forge_nav_tile_test.dart"
)

echo "=== 模块测试存在性 ==="
bash "$ROOT/tool/verify_test_layout.sh"

echo "=== GenUI 桥接（Python，零网络） ==="
python3 "$ROOT/tool/genui_codex_bridge_test.py"

echo "=== 应用关键路径（widget/单元） ==="
(cd "$APP" && flutter test --no-pub "${BASELINE_TESTS[@]}")

echo "=== 工作流文章管线（packages/forge_articles） ==="
(cd "$ROOT/packages/forge_articles" && flutter test --no-pub test/article_workflow_test.dart)

AX_ROUNDS=""
for arg in "$@"; do
  case "$arg" in
    --ax-soak) AX_ROUNDS=24 ;;
    --ax-soak=*) AX_ROUNDS="${arg#--ax-soak=}" ;;
  esac
done
if [ -n "$AX_ROUNDS" ]; then
  echo "=== macOS AX 语义浸泡（${AX_ROUNDS} 轮） ==="
  (cd "$APP" && flutter test integration_test/genui_ax_soak_test.dart -d macos \
    --dart-define=FORGE_AX_SOAK=true --dart-define=FORGE_AX_SOAK_ROUNDS="$AX_ROUNDS")
fi

echo "SMOKE: PASS"
