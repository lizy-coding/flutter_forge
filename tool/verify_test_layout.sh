#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
app_root = root / "apps" / "flutter_forge"
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
    directory = app_root / relative.parent
    if directory.is_dir() and any(directory.rglob("*_test.dart")):
        present.append(relative)
    else:
        missing.append(relative)

print("")
print("=== Module Test Coverage ===")
print(f"Modules: {len(modules)}")
print(f"Tests present: {len(present)}")
print(f"Tests missing: {len(missing)}")

blocking = missing
if missing:
    print("Missing module tests:")
    for path in missing:
        print(f"  - {path.as_posix()}")

print("")
if blocking:
    print("FAIL: modules without tests:", blocking)
    raise SystemExit(1)
print("Module test presence verification passed.")
PY
