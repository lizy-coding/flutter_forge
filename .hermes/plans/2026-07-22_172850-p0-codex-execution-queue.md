# P0 Codex Execution Queue

> Scope: only Phase 0 tasks from the approved Agent-Ready Project Transformation Roadmap.
>
> Execution model: execute one task at a time in dependency order. Start each task in a clean Codex context. Do not commit, push, merge, publish, or modify files outside the task allowlist.

## Queue Order

| Order | Task ID | Depends on | Codex direct | Claude architecture review | Human confirmation |
|---|---|---|---|---|---|
| 1 | AR-P0-001 | none | Yes, after confirmation | No | Required before start |
| 2 | AR-P0-002 | AR-P0-001 | Draft only | Required | Required for acceptance |
| 3 | AR-P0-003 | AR-P0-002 accepted | Yes, after confirmation | Required after implementation | Required before start and before deleting legacy layout |
| 4 | AR-P0-004 | AR-P0-001 | Yes | No | Not required |
| 5 | AR-P0-005 | AR-P0-004 | Yes | No | Not required |
| 6 | AR-P0-006 | AR-P0-003, AR-P0-005 | Yes | No | Not required |
| 7 | AR-P0-007 | AR-P0-003 | Yes, after confirmation | No | Required before start |
| 8 | AR-P0-008 | AR-P0-003, AR-P0-004, AR-P0-006 | Yes | No | Required only if documentation changes project claims |
| 9 | AR-P0-009 | AR-P0-006, AR-P0-007, AR-P0-008 | Yes, read-only | No | Required to accept P0 completion |

---

## AR-P0-001 — Restore Dependency Resolution

```yaml
task_id: AR-P0-001
objective: >
  Repair only the invalid flutterguard_cli path dependency so the current main
  application can resolve packages again.

execution_classification:
  codex_can_execute: true
  claude_architecture_review: false
  human_confirmation: required_before_start

context: >
  The working tree already contains user-owned modifications in pubspec.yaml and
  pubspec.lock. The current flutterguard_cli dependency points to
  ../flutterguard/packages/flutterguard_cli, while the package currently exists at
  ../flutterguard. Preserve every unrelated user change. This task is a narrow
  baseline repair; it must not decide or implement the final repository layout.

files_to_inspect:
  - AGENTS.md
  - AI_ANALYSIS_SCHEMA.json
  - AI_PROJECT_CONTEXT.md
  - REFACTOR_PLAN.md
  - pubspec.yaml
  - pubspec.lock
  - ../flutterguard/pubspec.yaml
  - ../flutterguard/bin/flutterguard.dart
  - .githooks/pre-commit

files_allowed_to_modify:
  - pubspec.yaml
  - pubspec.lock

files_forbidden_to_modify:
  - lib/**
  - test/**
  - tool/**
  - .githooks/**
  - macos/**
  - windows/**
  - ../flutterguard/**
  - ../gcode_core/**
  - ../flutter_study_learning/**
  - ../file_picker_bridge/**
  - ../flutter_ioc_core/**
  - all files not explicitly allowed

implementation_steps:
  - Capture git status and the existing diff for pubspec.yaml and pubspec.lock.
  - Verify the package name and executable in ../flutterguard without modifying it.
  - Change only the flutterguard_cli path to the actual package root.
  - Run flutter pub get and allow it to update only pubspec.lock.
  - Compare the resulting diff with the pre-task diff and confirm unrelated user edits remain.
  - Run the FlutterGuard help command to prove executable resolution.
  - Do not run formatter and do not edit business code.

acceptance_criteria:
  - flutter pub get exits with code 0.
  - flutterguard_cli resolves from the corrected local path.
  - The existing SDK/version edits in pubspec.yaml and pubspec.lock are preserved.
  - No file other than pubspec.yaml and pubspec.lock changes.
  - No commit is created.

validation_commands:
  - git status --short --branch
  - git diff -- pubspec.yaml pubspec.lock
  - flutter pub get
  - dart run flutterguard_cli:flutterguard --help
  - git diff --check
  - git status --short

expected_execution_report_format:
  task_id: AR-P0-001
  status: completed | blocked | partial
  summary: string
  inspected_files: [path]
  changed_files: [path]
  preserved_preexisting_changes:
    pubspec_yaml: string
    pubspec_lock: string
  commands:
    - command: string
      exit_code: integer
      result: string
  acceptance:
    - criterion: string
      status: passed | failed | not_run
      evidence: string
  risks: [string]
  blockers: [string]
  followups: [string]
  review_required:
    claude: false
    human: true
```

---

## AR-P0-002 — Approve the Reproducible Repository Layout

```yaml
task_id: AR-P0-002
objective: >
  Produce and obtain approval for one repository-layout ADR that selects the
  reproducible dependency strategy for the main app and its shared packages.

execution_classification:
  codex_can_execute: draft_only
  claude_architecture_review: required
  human_confirmation: required_for_acceptance

context: >
  The roadmap recommends a monorepo layout because the current application depends
  on undeclared sibling directories. This task makes the decision only; it must not
  copy, move, delete, or rewrite package source. The ADR must compare a monorepo
  workspace with fixed Git dependencies and record the final approved choice.

files_to_inspect:
  - AGENTS.md
  - AI_PROJECT_CONTEXT.md
  - REFACTOR_PLAN.md
  - pubspec.yaml
  - tool/migrate_sibling_packages.sh
  - ../gcode_core/pubspec.yaml
  - ../flutter_study_learning/pubspec.yaml
  - ../file_picker_bridge/pubspec.yaml
  - ../flutter_ioc_core/pubspec.yaml
  - ../flutterguard/pubspec.yaml
  - README.md

files_allowed_to_modify:
  - docs/adr/README.md
  - docs/adr/0001-repository-layout.md

files_forbidden_to_modify:
  - pubspec.yaml
  - pubspec.lock
  - lib/**
  - test/**
  - tool/**
  - packages/**
  - tools/**
  - ../**
  - all files not explicitly allowed

implementation_steps:
  - Create the ADR index only if it does not already exist.
  - Draft a decision comparing monorepo workspace and fixed Git dependencies.
  - Record decision drivers: one-clone bootstrap, atomic changes, package tests, CI,
    release independence, package history, and rollback.
  - Select the roadmap default of an in-repository packages/ layout unless a human
    supplies a different decision.
  - Define the intended locations for the four shared packages and FlutterGuard.
  - Define migration boundaries, rollback strategy, and completion criteria.
  - Request Claude architecture review of the ADR.
  - Apply review corrections only within the two allowed ADR files.
  - Stop for explicit human acceptance; do not mark accepted without it.

acceptance_criteria:
  - The ADR contains context, alternatives, decision, consequences, migration,
    rollback, and status.
  - The ADR identifies one unambiguous target layout.
  - Claude architecture review has no unresolved blocking finding.
  - A human explicitly changes or approves the ADR status as accepted.
  - No source, dependency, or package file changes.

validation_commands:
  - git diff -- docs/adr/README.md docs/adr/0001-repository-layout.md
  - git diff --check
  - verify all paths referenced by the ADR are syntactically consistent
  - git status --short

expected_execution_report_format:
  task_id: AR-P0-002
  status: completed | awaiting_human_approval | blocked
  summary: string
  decision:
    selected_strategy: monorepo_workspace | fixed_git_dependencies | undecided
    target_layout: [path]
    adr_status: proposed | accepted
  inspected_files: [path]
  changed_files: [path]
  commands:
    - command: string
      exit_code: integer
      result: string
  claude_review:
    status: approved | changes_requested | not_run
    findings: [string]
  human_confirmation:
    status: approved | rejected | pending
    evidence: string
  acceptance:
    - criterion: string
      status: passed | failed | pending
      evidence: string
  risks: [string]
  blockers: [string]
  followups: [string]
```

---

## AR-P0-003 — Implement the Approved Repository Layout

```yaml
task_id: AR-P0-003
objective: >
  Migrate the declared local dependencies into the repository layout accepted by
  ADR 0001 so a fresh clone no longer depends on parent-directory packages.

execution_classification:
  codex_can_execute: true_after_human_confirmation
  claude_architecture_review: required_after_implementation
  human_confirmation: required_before_start_and_before_legacy_deletion

context: >
  This task executes only the layout accepted in docs/adr/0001-repository-layout.md.
  The default expected decision is packages/gcode_core,
  packages/flutter_study_learning, packages/file_picker_bridge,
  packages/flutter_ioc_core, and tools/flutterguard_cli. Source sibling repositories
  are read-only inputs. The task must preserve public APIs and behavior and must not
  refactor package internals. If the accepted ADR selects fixed Git dependencies,
  Codex must implement that decision instead of the default paths and must not create
  packages/ or tools/ copies.

files_to_inspect:
  - AGENTS.md
  - AI_ANALYSIS_SCHEMA.json
  - AI_PROJECT_CONTEXT.md
  - REFACTOR_PLAN.md
  - docs/adr/0001-repository-layout.md
  - pubspec.yaml
  - pubspec.lock
  - tool/generate_agent_indexes.js
  - tool/migrate_sibling_packages.sh
  - all tracked source, pubspec, analysis, README, and test files in each dependency source

files_allowed_to_modify:
  - pubspec.yaml
  - pubspec.lock
  - packages/gcode_core/**
  - packages/flutter_study_learning/**
  - packages/file_picker_bridge/**
  - packages/flutter_ioc_core/**
  - tools/flutterguard_cli/**
  - tool/generate_agent_indexes.js
  - tool/migrate_sibling_packages.sh
  - AI_ANALYSIS_SCHEMA.json
  - AI_PROJECT_CONTEXT.md
  - REFACTOR_PLAN.md
  - AI_ANALYSIS.md
  - lib/AI_ANALYSIS.md
  - lib/AI_MODULE_INDEX.md
  - lib/**/AI_ANALYSIS.md

files_forbidden_to_modify:
  - lib/**/*.dart
  - test/**/*.dart
  - macos/**
  - windows/**
  - .githooks/**
  - README.md
  - GCODE_VISUALIZER_EVOLUTION_PLAN.md
  - ../gcode_core/**
  - ../flutter_study_learning/**
  - ../file_picker_bridge/**
  - ../flutter_ioc_core/**
  - ../flutterguard/**
  - all secrets and credential files
  - all files not explicitly allowed

implementation_steps:
  - Verify ADR 0001 is accepted and record the exact selected layout.
  - Capture the current working-tree diff and preserve unrelated user changes.
  - Import each dependency with its source, tests, manifest, license, and public entrypoint.
  - Exclude build output, caches, IDE state, credentials, and repository-internal .git data.
  - Update root dependency paths or fixed Git references exactly as approved.
  - Update only Agent documentation generator source required by the new dependency paths.
  - Regenerate machine Agent documents using the project generator.
  - Update or retire the one-time sibling migration script so it cannot overwrite the
    new canonical packages.
  - Resolve dependencies from the repository root.
  - Run each imported package's own analyze/test command before testing the app.
  - Run root analyze, tests, and FlutterGuard.
  - Search tracked manifests and machine contracts for forbidden parent path dependencies.
  - Request Claude architecture review focused on boundaries, package ownership, public
    APIs, and source-of-truth consistency.
  - Do not delete or modify sibling source repositories. Report them as legacy cleanup
    requiring separate human action.

acceptance_criteria:
  - A fresh checkout of the current repository contains every local dependency required
    for root dependency resolution, or uses the accepted fixed Git references.
  - No tracked manifest depends on undeclared parent-directory paths.
  - Imported package public APIs and tests remain intact.
  - Root flutter pub get succeeds.
  - Each package test suite succeeds.
  - Root flutter analyze and flutter test succeed, or pre-existing failures are reported
    with evidence and no new failure is introduced.
  - FlutterGuard completes without high-severity findings introduced by the migration.
  - Generated Agent documents contain the approved dependency paths and validate.
  - Sibling repositories remain unchanged.
  - Claude architecture review has no unresolved blocking finding.

validation_commands:
  - git status --short --branch
  - flutter pub get
  - run dart pub get and dart test for each pure Dart package
  - run flutter pub get and flutter test for each Flutter package
  - run dart test in tools/flutterguard_cli
  - bash tool/generate_harness_ai_analysis.sh
  - node tool/validate_agent_docs.js
  - flutter analyze
  - flutter test
  - dart run flutterguard_cli:flutterguard scan --path . --fail-on high
  - git diff --check
  - search tracked pubspec and contract files for forbidden path: ../ dependencies

expected_execution_report_format:
  task_id: AR-P0-003
  status: completed | blocked | partial
  summary: string
  approved_adr:
    path: docs/adr/0001-repository-layout.md
    strategy: string
    status: accepted
  imported_dependencies:
    - name: string
      source: string
      destination: string
      source_unchanged: boolean
  inspected_files: [path]
  changed_files: [path]
  preserved_preexisting_changes: [string]
  commands:
    - command: string
      working_directory: string
      exit_code: integer
      result: string
  acceptance:
    - criterion: string
      status: passed | failed | not_run
      evidence: string
  claude_review:
    status: approved | changes_requested | not_run
    findings: [string]
  human_confirmation:
    before_start: approved | missing
    legacy_cleanup: approved | deferred | rejected
  risks: [string]
  blockers: [string]
  followups: [string]
```

---

## AR-P0-004 — Pin the Development Toolchain

```yaml
task_id: AR-P0-004
objective: >
  Add repository-level version pins for Flutter and Node so local and CI tooling can
  select deterministic tool versions.

execution_classification:
  codex_can_execute: true
  claude_architecture_review: false
  human_confirmation: not_required

context: >
  The approved roadmap baseline uses Flutter 3.44.6, Dart 3.12.2, and Node.js
  20.20.2. Dart is supplied by Flutter and must not be independently pinned to an
  incompatible SDK. This task adds version-selection files only; environment scripts
  and documentation are separate tasks.

files_to_inspect:
  - AGENTS.md
  - pubspec.yaml
  - .metadata
  - README.md
  - existing tool-version files if present

files_allowed_to_modify:
  - .fvmrc
  - .nvmrc

files_forbidden_to_modify:
  - pubspec.yaml
  - pubspec.lock
  - README.md
  - docs/**
  - lib/**
  - test/**
  - tool/**
  - all files not explicitly allowed

implementation_steps:
  - Confirm neither version file contains user-owned content that would be overwritten.
  - Add a valid FVM configuration pinning Flutter 3.44.6.
  - Add an NVM version file pinning Node.js 20.20.2.
  - Validate file syntax and compare pins with the current approved roadmap versions.
  - Do not install, upgrade, or switch SDKs in this task.

acceptance_criteria:
  - .fvmrc is valid and pins Flutter 3.44.6.
  - .nvmrc contains Node.js 20.20.2.
  - No other file changes.
  - No SDK installation or system configuration occurs.

validation_commands:
  - node -e "JSON.parse(require('fs').readFileSync('.fvmrc','utf8')); console.log('fvmrc_valid')"
  - test "$(tr -d '[:space:]' < .nvmrc)" = "20.20.2"
  - git diff --check
  - git status --short

expected_execution_report_format:
  task_id: AR-P0-004
  status: completed | blocked | partial
  summary: string
  inspected_files: [path]
  changed_files: [path]
  pinned_versions:
    flutter: 3.44.6
    node: 20.20.2
    dart_source: flutter_sdk
  commands:
    - command: string
      exit_code: integer
      result: string
  acceptance:
    - criterion: string
      status: passed | failed | not_run
      evidence: string
  risks: [string]
  blockers: [string]
  followups: [string]
  review_required:
    claude: false
    human: false
```

---

## AR-P0-005 — Add the Read-Only Environment Check

```yaml
task_id: AR-P0-005
objective: >
  Create one read-only environment diagnostic command that verifies required project
  tools and reports actionable missing prerequisites.

execution_classification:
  codex_can_execute: true
  claude_architecture_review: false
  human_confirmation: not_required

context: >
  The script must validate the repository pins and platform prerequisites without
  installing software, changing Flutter configuration, fetching dependencies, or
  modifying source. It must work from any current directory by resolving the project
  root from the script location. Platform-specific checks may be reported as required,
  optional, or not applicable.

files_to_inspect:
  - AGENTS.md
  - .fvmrc
  - .nvmrc
  - pubspec.yaml
  - README.md
  - macos/** configuration entrypoints
  - windows/** configuration entrypoints

files_allowed_to_modify:
  - tool/check_environment.sh

files_forbidden_to_modify:
  - .fvmrc
  - .nvmrc
  - pubspec.yaml
  - pubspec.lock
  - README.md
  - docs/**
  - lib/**
  - test/**
  - macos/**
  - windows/**
  - all files not explicitly allowed

implementation_steps:
  - Implement strict Bash error handling and project-root resolution.
  - Read expected Flutter and Node versions from .fvmrc and .nvmrc rather than duplicating them.
  - Check availability and versions of Flutter, Dart, Node, and Git.
  - Check Flutter Doctor and report Android, Xcode, CocoaPods, and connected-device status
    without treating non-target platform tools as universal hard failures.
  - Check that all in-repository dependency paths declared by pubspec exist.
  - Emit stable machine-readable stage/result prefixes in addition to human-readable guidance.
  - Return zero only when required baseline prerequisites pass.
  - Add no install commands and perform no mutation.

acceptance_criteria:
  - The script is read-only and repeatable.
  - It reads version pins from repository files.
  - Missing required tools produce a nonzero exit code and a remediation message.
  - Optional platform gaps are clearly distinguished from required failures.
  - Running the script twice produces no repository diff.

validation_commands:
  - bash -n tool/check_environment.sh
  - bash tool/check_environment.sh
  - git diff --exit-code after two consecutive runs, excluding pre-existing changes
  - git diff --check

expected_execution_report_format:
  task_id: AR-P0-005
  status: completed | blocked | partial
  summary: string
  inspected_files: [path]
  changed_files: [path]
  environment_results:
    - capability: string
      required: boolean
      status: passed | failed | optional_missing
      detected_version: string | null
      expected_version: string | null
  commands:
    - command: string
      exit_code: integer
      result: string
  mutation_check:
    repository_diff_created_by_script: boolean
    evidence: string
  acceptance:
    - criterion: string
      status: passed | failed | not_run
      evidence: string
  risks: [string]
  blockers: [string]
  followups: [string]
  review_required:
    claude: false
    human: false
```

---

## AR-P0-006 — Add the Idempotent Bootstrap Command

```yaml
task_id: AR-P0-006
objective: >
  Create one idempotent bootstrap command that prepares repository dependencies and
  local Git hooks after the environment check passes.

execution_classification:
  codex_can_execute: true
  claude_architecture_review: false
  human_confirmation: not_required

context: >
  Repository layout must already be canonical and the environment checker must exist.
  Bootstrap may create normal package-manager caches and generated dependency metadata,
  but must not edit business source, install administrator-level software, modify global
  Git configuration, or run destructive migration scripts.

files_to_inspect:
  - AGENTS.md
  - docs/adr/0001-repository-layout.md
  - pubspec.yaml
  - packages/**/pubspec.yaml
  - tools/flutterguard_cli/pubspec.yaml
  - tool/check_environment.sh
  - .githooks/pre-commit
  - .gitignore

files_allowed_to_modify:
  - tool/bootstrap.sh

files_forbidden_to_modify:
  - pubspec.yaml
  - pubspec.lock
  - packages/**
  - tools/**
  - lib/**
  - test/**
  - docs/**
  - README.md
  - .githooks/**
  - .gitignore
  - global Git configuration
  - all files not explicitly allowed

implementation_steps:
  - Resolve the repository root from the script location.
  - Run tool/check_environment.sh and stop on required failures.
  - Fetch root dependencies.
  - Fetch dependencies for workspace packages/tools only when the selected workspace mechanism
    does not already do so.
  - Set repository-local core.hooksPath to .githooks.
  - Verify the expected hook is executable; report, but do not silently rewrite it.
  - Print the next recommended validation command.
  - Run bootstrap twice and confirm the second run is successful and does not modify tracked source.

acceptance_criteria:
  - Bootstrap succeeds on a correctly configured checkout.
  - Bootstrap stops before dependency mutation when required environment checks fail.
  - Repository-local hooksPath equals .githooks after success.
  - Running bootstrap twice is safe and produces no tracked source diff.
  - No global configuration or administrator-level installation occurs.

validation_commands:
  - bash -n tool/bootstrap.sh
  - bash tool/bootstrap.sh
  - bash tool/bootstrap.sh
  - git config --local --get core.hooksPath
  - git diff --check
  - git status --short

expected_execution_report_format:
  task_id: AR-P0-006
  status: completed | blocked | partial
  summary: string
  inspected_files: [path]
  changed_files: [path]
  bootstrap_runs:
    - run: 1
      exit_code: integer
      result: string
    - run: 2
      exit_code: integer
      result: string
  hooks:
    configured_path: string
    executable: boolean
  commands:
    - command: string
      exit_code: integer
      result: string
  idempotence:
    passed: boolean
    evidence: string
  acceptance:
    - criterion: string
      status: passed | failed | not_run
      evidence: string
  risks: [string]
  blockers: [string]
  followups: [string]
  review_required:
    claude: false
    human: false
```

---

## AR-P0-007 — Normalize the Dart Formatting Baseline

```yaml
task_id: AR-P0-007
objective: >
  Apply the repository's current Dart formatter to tracked Dart source and tests as one
  isolated formatting-only change.

execution_classification:
  codex_can_execute: true_after_human_confirmation
  claude_architecture_review: false
  human_confirmation: required_before_start

context: >
  A prior check showed that many tracked Dart files are not at the formatter baseline.
  This is intentionally a broad but mechanical task. It must happen after dependency
  resolution is stable so analyze and tests can verify no behavior regression. The task
  must not include manual refactors, import redesign, lint fixes, or generated-document changes.

files_to_inspect:
  - AGENTS.md
  - analysis_options.yaml
  - pubspec.yaml
  - current git status and complete pre-task diff

files_allowed_to_modify:
  - lib/**/*.dart
  - test/**/*.dart
  - packages/**/*.dart
  - tools/flutterguard_cli/**/*.dart

files_forbidden_to_modify:
  - pubspec.yaml
  - pubspec.lock
  - analysis_options.yaml
  - README.md
  - docs/**
  - AI_ANALYSIS_SCHEMA.json
  - AI_PROJECT_CONTEXT.md
  - REFACTOR_PLAN.md
  - '**/AI_ANALYSIS.md'
  - macos/**
  - windows/**
  - all non-Dart files

implementation_steps:
  - Capture git status and identify pre-existing Dart modifications, if any.
  - Stop and request human direction if a formatter target already has user-owned changes
    whose ownership cannot be separated.
  - Run dart format on only the allowed Dart trees.
  - Do not manually edit formatter output.
  - Run formatter a second time and confirm it reports no changes.
  - Run root analyze and tests plus package tests.
  - Review the diff to confirm it is formatting-only.

acceptance_criteria:
  - Every changed file is an allowed Dart file.
  - A second formatter run produces no diff.
  - No semantic/manual code change is introduced.
  - Root analyze and tests pass, or pre-existing failures are documented with evidence.
  - Package tests pass, or pre-existing failures are documented with evidence.
  - No commit is created.

validation_commands:
  - git status --short --branch
  - dart format lib test packages tools/flutterguard_cli
  - dart format lib test packages tools/flutterguard_cli
  - flutter analyze
  - flutter test
  - run tests for each package and tools/flutterguard_cli
  - git diff --check
  - git diff --stat
  - git status --short

expected_execution_report_format:
  task_id: AR-P0-007
  status: completed | blocked | partial
  summary: string
  human_confirmation:
    status: approved | missing
    evidence: string
  preexisting_dart_changes: [path]
  inspected_files: [path]
  changed_files: [path]
  formatting:
    first_run_changed_files: [path]
    second_run_clean: boolean
  commands:
    - command: string
      exit_code: integer
      result: string
  semantic_diff_review:
    formatting_only: boolean
    evidence: string
  acceptance:
    - criterion: string
      status: passed | failed | not_run
      evidence: string
  risks: [string]
  blockers: [string]
  followups: [string]
  review_required:
    claude: false
    human: true
```

---

## AR-P0-008 — Correct Baseline Documentation

```yaml
task_id: AR-P0-008
objective: >
  Update the human-facing baseline documentation so all setup commands, paths, tool
  versions, and document references match the completed P0 repository state.

execution_classification:
  codex_can_execute: true
  claude_architecture_review: false
  human_confirmation: conditional_if_support_claims_change

context: >
  Documentation currently includes an invalid plan reference, broad tool versions, and
  pre-migration G-code paths. This task updates only human-facing baseline documentation.
  Machine Agent contracts remain generated and are forbidden here. Platform support must
  not be upgraded from planned to supported without actual build evidence.

files_to_inspect:
  - AGENTS.md
  - .fvmrc
  - .nvmrc
  - docs/adr/0001-repository-layout.md
  - AI_PROJECT_CONTEXT.md
  - REFACTOR_PLAN.md
  - README.md
  - GCODE_VISUALIZER_EVOLUTION_PLAN.md
  - pubspec.yaml
  - tool/check_environment.sh
  - tool/bootstrap.sh
  - current package locations and public entrypoints

files_allowed_to_modify:
  - README.md
  - GCODE_VISUALIZER_EVOLUTION_PLAN.md
  - docs/DEVELOPMENT.md

files_forbidden_to_modify:
  - AGENTS.md
  - .fvmrc
  - .nvmrc
  - pubspec.yaml
  - pubspec.lock
  - AI_ANALYSIS_SCHEMA.json
  - AI_PROJECT_CONTEXT.md
  - REFACTOR_PLAN.md
  - AI_ANALYSIS.md
  - lib/**
  - test/**
  - tool/**
  - packages/**
  - tools/**
  - macos/**
  - windows/**
  - all files not explicitly allowed

implementation_steps:
  - Update Quick Start to use the actual environment check and bootstrap commands.
  - Document exact pinned versions by referencing version files as the source of truth.
  - Remove or correct the missing PLUGIN_DECOMPOSITION_PLAN reference.
  - Replace sibling-package paths with the accepted canonical repository paths.
  - Update G-code plan paths to current module/package paths.
  - Mark old test counts and historical status as historical, or remove them from current claims.
  - Separate currently verified platforms from planned target platforms.
  - Keep README concise and place detailed setup/troubleshooting in docs/DEVELOPMENT.md.
  - Verify every local file path and command mentioned in modified documents.

acceptance_criteria:
  - No modified document references a missing local file.
  - Setup commands match actual scripts and execute successfully.
  - Tool versions match .fvmrc and .nvmrc.
  - No current path uses the legacy sibling layout after a monorepo migration.
  - Platform support claims are backed by current evidence or explicitly marked planned.
  - Machine-generated Agent documents are unchanged.

validation_commands:
  - bash tool/check_environment.sh
  - bash tool/bootstrap.sh
  - run repository-local Markdown link/path checker if available
  - manually verify every backticked local path in the three modified files exists
  - git diff --check
  - git diff -- README.md GCODE_VISUALIZER_EVOLUTION_PLAN.md docs/DEVELOPMENT.md

expected_execution_report_format:
  task_id: AR-P0-008
  status: completed | blocked | partial
  summary: string
  inspected_files: [path]
  changed_files: [path]
  corrected_references:
    - old: string
      new: string
      evidence: string
  commands:
    - command: string
      exit_code: integer
      result: string
  support_claim_changes:
    changed: boolean
    human_confirmation: approved | pending | not_required
    details: [string]
  acceptance:
    - criterion: string
      status: passed | failed | not_run
      evidence: string
  risks: [string]
  blockers: [string]
  followups: [string]
  review_required:
    claude: false
    human: conditional
```

---

## AR-P0-009 — Verify and Close the P0 Baseline

```yaml
task_id: AR-P0-009
objective: >
  Perform a read-only end-to-end verification of the completed P0 baseline and return
  the evidence required for human acceptance.

execution_classification:
  codex_can_execute: true_read_only
  claude_architecture_review: false
  human_confirmation: required_to_accept_phase_completion

context: >
  All prior P0 implementation tasks must be complete. This task does not fix failures
  and does not modify files. Its only purpose is to prove whether the repository is
  self-contained, bootstrap is repeatable, formatting is stable, documentation is
  current, and the existing quality commands run from a fresh project state. Any failure
  must be reported as a blocker or follow-up task rather than repaired in place.

files_to_inspect:
  - AGENTS.md
  - .fvmrc
  - .nvmrc
  - docs/adr/0001-repository-layout.md
  - docs/DEVELOPMENT.md
  - README.md
  - pubspec.yaml
  - pubspec.lock
  - tool/check_environment.sh
  - tool/bootstrap.sh
  - tool/generate_harness_ai_analysis.sh
  - tool/validate_agent_docs.js
  - .githooks/pre-commit
  - all package pubspec files needed to enumerate validation commands

files_allowed_to_modify: []

files_forbidden_to_modify:
  - '**/*'

implementation_steps:
  - Capture initial git status and identify all pre-existing changes.
  - Run the read-only environment check.
  - Run bootstrap twice and verify no tracked source change is produced.
  - Verify all declared local dependency paths are inside the repository and exist.
  - Validate Agent machine documents without regenerating them first.
  - Check formatting stability using an isolated temporary copy or a non-destructive method;
    do not allow formatter output to modify the working tree.
  - Run root analyze, root tests, package tests, and FlutterGuard.
  - Verify repository-local hooksPath.
  - Recheck git status and prove the verification task created no changes.
  - Return a pass/fail matrix and stop. Do not repair any failure.

acceptance_criteria:
  - Environment check passes for required baseline capabilities.
  - Bootstrap succeeds twice and is idempotent.
  - Root dependency resolution succeeds without undeclared parent directories.
  - Agent document validation passes.
  - Formatting check reports no required changes.
  - Root analyze and test pass.
  - Every imported package/tool test suite passes.
  - FlutterGuard reports no high-severity issue.
  - Verification creates no repository diff.
  - Human explicitly accepts or rejects P0 completion based on the report.

validation_commands:
  - git status --short --branch
  - bash tool/check_environment.sh
  - bash tool/bootstrap.sh
  - bash tool/bootstrap.sh
  - node tool/validate_agent_docs.js
  - perform non-destructive formatting verification in a temporary worktree or copy
  - flutter analyze
  - flutter test
  - run tests for every package and tools/flutterguard_cli
  - dart run flutterguard_cli:flutterguard scan --path . --fail-on high
  - git config --local --get core.hooksPath
  - git diff --check
  - git status --short

expected_execution_report_format:
  task_id: AR-P0-009
  status: passed | failed | blocked
  summary: string
  initial_git_status: string
  final_git_status: string
  repository_mutated_by_verification: boolean
  baseline_matrix:
    - capability: environment
      status: passed | failed | blocked
      evidence: string
    - capability: bootstrap_idempotence
      status: passed | failed | blocked
      evidence: string
    - capability: self_contained_dependencies
      status: passed | failed | blocked
      evidence: string
    - capability: agent_docs
      status: passed | failed | blocked
      evidence: string
    - capability: formatting
      status: passed | failed | blocked
      evidence: string
    - capability: analyze
      status: passed | failed | blocked
      evidence: string
    - capability: root_tests
      status: passed | failed | blocked
      evidence: string
    - capability: package_tests
      status: passed | failed | blocked
      evidence: string
    - capability: flutterguard
      status: passed | failed | blocked
      evidence: string
  commands:
    - command: string
      working_directory: string
      exit_code: integer
      result: string
  blockers: [string]
  followup_tasks: [string]
  human_acceptance:
    status: approved | rejected | pending
    evidence: string
```

---

## P0 Execution Rules for Codex

1. Start every task by reading `AGENTS.md`, the listed context files, and current `git status`.
2. Treat all pre-existing working-tree changes as user-owned. Never reset, checkout, stash, or overwrite them.
3. Modify only the explicit allowlist. If another file is required, stop and return `blocked` with the proposed scope change.
4. Never modify sibling repositories. They are read-only migration sources until a human separately approves cleanup.
5. Never commit, push, merge, publish, or rewrite history.
6. Do not claim success when a validation command was not run or failed.
7. A task requiring Claude Review is not complete until blocking findings are resolved.
8. A task requiring human confirmation must stop at the stated checkpoint.
9. Do not start P1 work, create `.agent/manifest.json`, add CI, or introduce Task/Report schemas during this batch.
10. Return only the task-specific execution report after each task; do not combine multiple task reports.
