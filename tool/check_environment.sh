#!/usr/bin/env bash
set -euo pipefail

# check_environment.sh — 验证开发环境组件
# 输出: 版本信息、缺失组件、修复建议
# 退出码: 0 = OK, 非0 = 有缺失

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

check_cmd() {
  local name="$1"
  local cmd="$2"
  local version_flag="${3:---version}"
  local min_version="${4:-}"

  if command -v "$cmd" &>/dev/null; then
    local version
    version=$("$cmd" $version_flag 2>&1 | head -1 || true)
    echo -e "  ${GREEN}✓${NC} $name: $version"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} $name: NOT FOUND"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Flutter Forge 环境检查 ==="
echo ""

echo "--- 核心工具链 ---"
check_cmd "Flutter" flutter "--version"
check_cmd "Dart" dart "--version"
check_cmd "Node.js" node "--version"
check_cmd "npm" npm "--version"
echo ""

echo "--- 平台 SDK (按需) ---"
if command -v xcodebuild &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Xcode: $(xcodebuild -version 2>&1 | head -1)"
  PASS=$((PASS + 1))
else
  echo -e "  ${YELLOW}⚠${NC} Xcode: NOT FOUND (仅 macOS/iOS 构建需要)"
  WARN=$((WARN + 1))
fi

if command -v java &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Java: $(java -version 2>&1 | head -1)"
  PASS=$((PASS + 1))
else
  echo -e "  ${YELLOW}⚠${NC} Java: NOT FOUND (仅 Android 构建需要)"
  WARN=$((WARN + 1))
fi

if [ -d "$ANDROID_HOME" ] || [ -d "$ANDROID_SDK_ROOT" ]; then
  echo -e "  ${GREEN}✓${NC} Android SDK: found"
  PASS=$((PASS + 1))
else
  echo -e "  ${YELLOW}⚠${NC} Android SDK: NOT FOUND (仅 Android 构建需要)"
  WARN=$((WARN + 1))
fi
echo ""

echo "--- 项目工具 ---"
if [ -f "pubspec.yaml" ]; then
  echo -e "  ${GREEN}✓${NC} pubspec.yaml: found"
  PASS=$((PASS + 1))
else
  echo -e "  ${RED}✗${NC} pubspec.yaml: NOT FOUND (不在项目根目录?)"
  FAIL=$((FAIL + 1))
fi

if [ -f "pubspec.lock" ]; then
  echo -e "  ${GREEN}✓${NC} pubspec.lock: found"
  PASS=$((PASS + 1))
else
  echo -e "  ${YELLOW}⚠${NC} pubspec.lock: NOT FOUND (需要 flutter pub get)"
  WARN=$((WARN + 1))
fi

echo ""
echo "--- 汇总 ---"
echo -e "  通过: ${GREEN}$PASS${NC}"
echo -e "  警告: ${YELLOW}$WARN${NC}"
echo -e "  失败: ${RED}$FAIL${NC}"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "修复建议:"
  echo "  1. 安装缺失的命令行工具"
  echo "  2. 运行 bash tool/bootstrap.sh 初始化项目依赖"
  exit 1
fi

echo ""
echo "环境检查通过。"
