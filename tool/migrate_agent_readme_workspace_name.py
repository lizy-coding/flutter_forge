#!/usr/bin/env python3
"""Migrate the agent README from the legacy project name to the workspace name."""

from __future__ import annotations

import argparse
from pathlib import Path


REPLACEMENTS = {
    "> flutter_forge 项目 Hermes Agent 托管架构 — 完全托管模式": (
        "> flutter_forge_workspace Hermes Agent 托管架构 — 完全托管模式"
    ),
    "flutter_forge 是一个 Flutter 模块化学习应用": (
        "flutter_forge_workspace 是一个 Flutter 模块化学习工作区"
    ),
    "flutter_forge/\n├── AGENTS.md": (
        "flutter_forge_workspace/\n├── AGENTS.md"
    ),
}


def migrate(readme: Path, *, check: bool) -> int:
    content = readme.read_text(encoding="utf-8")
    migrated = content
    missing = []

    for old, new in REPLACEMENTS.items():
        old_count = migrated.count(old)
        new_count = migrated.count(new)
        if old_count == 1:
            migrated = migrated.replace(old, new)
        elif old_count == 0 and new_count == 1:
            continue
        else:
            missing.append(f"expected exactly one old or new form: {old!r}")

    if missing:
        raise SystemExit("\n".join(missing))

    if "flutter_study_learning/AI_ANALYSIS.md" not in migrated:
        raise SystemExit("teaching package contract was unexpectedly renamed")

    changed = migrated != content
    if check:
        if changed:
            raise SystemExit(f"migration required: {readme}")
        print(f"agent_readme_workspace_name_valid:{readme}")
        return 0

    if changed:
        readme.write_text(migrated, encoding="utf-8")
        print(f"migrated:{readme}")
    else:
        print(f"already_migrated:{readme}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    repository_root = Path(__file__).resolve().parent.parent
    return migrate(repository_root / ".hermes" / "README.md", check=args.check)


if __name__ == "__main__":
    raise SystemExit(main())
