#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
app_root = root / "apps" / "flutter_forge"
test_root = app_root / "test"
allowed_top_level = {"modules", "shared"}
actual_top_level = {entry.name for entry in test_root.iterdir() if entry.is_dir()}
unexpected = sorted(actual_top_level - allowed_top_level)

print("=== Test Layout Verification ===")
if unexpected:
    print("FAIL: unexpected top-level test directories:")
    for directory in unexpected:
        print(f"  - test/{directory}/")
    raise SystemExit(1)

print("PASS: test/ top-level directories are modules/ and shared/")

module_index = json.loads((app_root / "lib/AI_MODULE_INDEX.md").read_text())
modules = module_index["modules"]
present = []
missing = []

for module in modules:
    relative = Path(
        "test",
        "modules",
        module["category"],
        module["id"],
        f'{module["id"]}_test.dart',
    )
    if (app_root / relative).is_file():
        present.append(relative)
    else:
        missing.append(relative)

print("")
print("=== Module Test Coverage ===")
print(f"Modules: {len(modules)}")
print(f"Tests present: {len(present)}")
print(f"Tests missing: {len(missing)}")

if missing:
    print("Missing module tests (report only):")
    for path in missing:
        print(f"  - {path.as_posix()}")

print("")
print("Test layout verification passed.")
PY
