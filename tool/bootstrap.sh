#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh — 环境校验 + 依赖获取 + hooks 启用
# 不修改业务代码，仅初始化开发环境

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== Flutter Study 环境自举 ==="
echo ""

# 1. 环境校验
echo "--- 1/4 环境校验 ---"
bash tool/check_environment.sh

# 2. 依赖获取
echo ""
echo "--- 2/4 依赖获取 ---"
flutter pub get
echo "  依赖获取完成。"

# 3. 启用 Git hooks
echo ""
echo "--- 3/4 Git hooks ---"
if [ -d ".githooks" ]; then
  git config core.hooksPath .githooks
  echo "  hooks 路径已设置: .githooks"
else
  echo "  ⚠ .githooks 目录不存在，跳过 hooks 配置"
fi

# 4. 最小 smoke check
echo ""
echo "--- 4/4 Smoke check ---"
if dart analyze lib/ 2>&1 | grep -q "No issues found"; then
  echo "  ✓ dart analyze: 通过"
else
  local issues
  issues=$(flutter analyze 2>&1 | grep -c "error •" || true)
  if [ "$issues" -gt 0 ]; then
    echo "  ✗ flutter analyze: 发现 $issues 个 error"
    exit 1
  else
    echo "  ✓ flutter analyze: 无 error (info/warning 可接受)"
  fi
fi

echo ""
echo "=== 自举完成 ==="
echo ""
echo "后续步骤:"
echo "  bash tool/quality_gate.sh    # 运行全量质量门禁"
echo "  flutter run                  # 启动应用"
