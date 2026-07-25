# Shared Dependency Migration — Codex Task Queue

Decision already accepted for planning purposes:

- Internal shared packages move under `packages/`.
- Dart Pub Workspace manages internal packages.
- Repository-external `../` path dependencies are forbidden.
- `flutterguard_cli` becomes an immutable Git dependency.
- Sibling repositories are read-only migration sources.

Execution rules:

- Execute tasks in the listed order.
- Use a fresh Codex context for every task.
- Read `AGENTS.md` before every modifying task.
- Preserve all pre-existing working-tree changes.
- Never use `git reset`, `git checkout`, `git stash`, history rewriting, commit, push, merge, or publish.
- If a required file is not in `allowed_files`, stop and report `blocked` instead of extending scope.
- Do not combine migration with formatting or package-internal refactoring.

## Ordered Queue

| Order | Task ID | Risk | Depends on |
|---|---|---|---|
| 1 | MIG-P0-001 | Low | none |
| 2 | MIG-P0-002 | Low | MIG-P0-001 |
| 3 | MIG-P0-003 | Low | MIG-P0-002 |
| 4 | MIG-P0-004 | Low | MIG-P0-002 |
| 5 | MIG-P0-005 | Low | MIG-P0-002 |
| 6 | MIG-P0-006 | Low | MIG-P0-002 |
| 7 | MIG-P0-007 | Medium | MIG-P0-003..006 |
| 8 | MIG-P0-008 | Medium | MIG-P0-001 |
| 9 | MIG-P0-009 | Low | MIG-P0-007, MIG-P0-008 |
| 10 | MIG-P0-010 | Medium | MIG-P0-007, MIG-P0-009 |
| 11 | MIG-P0-011 | Low | MIG-P0-007..010 |
| 12 | MIG-P0-012 | Low, read-only | MIG-P0-011 |

---

```yaml
task_id: MIG-P0-001
objective: Build a read-only inventory of the current dependency graph and migration inputs.
background: >
  The governance decision is already made. This task does not compare alternatives and
  does not modify the repository. It identifies every current path dependency, package
  manifest, package type, direct dependency, test command, source location, and path
  reference that later migration tasks must update.
allowed_files: []
forbidden_changes:
  - Do not modify any file in the current repository.
  - Do not modify sibling repositories.
  - Do not run pub get, formatter, code generation, or any command that can update lockfiles.
  - Do not reassess or replace the accepted governance decision.
implementation_steps:
  - Read AGENTS.md, AI_PROJECT_CONTEXT.md, REFACTOR_PLAN.md, pubspec.yaml, and pubspec.lock.
  - Inspect the pubspec.yaml and public entrypoint of gcode_core.
  - Inspect the pubspec.yaml and public entrypoint of flutter_study_learning.
  - Inspect the pubspec.yaml and public entrypoint of file_picker_bridge.
  - Inspect the pubspec.yaml and public entrypoint of flutter_ioc_core.
  - Inspect the pubspec.yaml, executable entrypoint, current Git remote, tags, and HEAD commit of flutterguard_cli.
  - Enumerate all tracked pubspec files and record every path dependency containing ../.
  - Search tracked scripts, Agent contracts, and human documents for references to the five sibling paths.
  - Classify each package as pure Dart, Flutter package, Flutter plugin/bridge, or CLI according to its actual manifest and source.
  - Record the package-specific dependency-fetch, analyze, and test commands.
  - Return the inventory in the task execution report; create no report file in the repository.
acceptance_criteria:
  - All five current sibling dependencies appear in the inventory.
  - Every tracked external ../ path dependency is listed with its declaring file.
  - Each package has a recorded source path, target path, package type, public entrypoint, and test command.
  - flutterguard_cli has a recorded immutable tag candidate or exact commit candidate.
  - Initial and final git status are identical.
validation_commands:
  - git status --short --branch
  - git ls-files '*pubspec.yaml'
  - git diff --exit-code
  - git status --short
```

---

```yaml
task_id: MIG-P0-002
objective: Create the empty canonical packages/ container without changing dependency resolution.
background: >
  Internal packages will be imported by later isolated tasks. Git does not retain empty
  directories, so this task creates only a temporary tracked marker. It must not copy
  package source or edit any manifest.
allowed_files:
  - packages/.gitkeep
forbidden_changes:
  - Do not modify pubspec.yaml or pubspec.lock.
  - Do not create package subdirectories yet.
  - Do not modify lib/, test/, tool/, Agent documents, platform projects, or sibling repositories.
  - Do not add workspace configuration.
implementation_steps:
  - Read AGENTS.md and confirm packages/ does not already contain user-owned content.
  - Create packages/ if absent.
  - Add only packages/.gitkeep.
  - Confirm the new container does not alter dependency resolution or tracked source.
acceptance_criteria:
  - packages/ exists.
  - packages/.gitkeep is the only changed file created by this task.
  - Root pubspec.yaml and pubspec.lock are unchanged.
validation_commands:
  - git status --short
  - test -d packages
  - test -f packages/.gitkeep
  - git diff --check
```

---

```yaml
task_id: MIG-P0-003
objective: Import gcode_core into packages/gcode_core without changing its behavior or manifest semantics.
background: >
  ../gcode_core is a read-only migration source. The package currently has Flutter in
  its manifest, so this task must treat it according to its actual source rather than
  assuming it is pure Dart. Workspace activation and root dependency changes happen later.
allowed_files:
  - packages/gcode_core/**
forbidden_changes:
  - Do not modify ../gcode_core/**.
  - Do not modify root pubspec.yaml or pubspec.lock.
  - Do not modify package APIs, imports, SDK constraints, dependencies, tests, or formatting.
  - Do not copy .git/, .dart_tool/, build/, IDE state, logs, credentials, or generated caches.
  - Do not copy a legacy AI_ANALYSIS.md that violates the current machine-document schema; Agent context is handled by MIG-P0-010.
implementation_steps:
  - Read AGENTS.md and inspect the source package manifest, public entrypoint, source, tests, README, license, and gitignore.
  - Confirm packages/gcode_core does not contain user-owned files.
  - Copy the package into packages/gcode_core while applying the exclusion rules.
  - Preserve file contents and executable bits; do not reformat.
  - Compare source and destination manifests, public entrypoints, lib/, and test/ trees.
  - Fetch package dependencies from the destination.
  - Run the destination package's actual analyze and test commands.
acceptance_criteria:
  - packages/gcode_core contains its manifest, public API, source, tests, and applicable documentation/license.
  - Source and destination functional files are identical before workspace-specific edits.
  - No excluded cache, repository metadata, credential, or legacy incompatible Agent document is copied.
  - Destination dependency resolution, analysis, and tests succeed.
  - The sibling source repository is unchanged.
validation_commands:
  - flutter pub get
  - flutter analyze
  - flutter test
  - diff -qr ../gcode_core/lib packages/gcode_core/lib
  - diff -qr ../gcode_core/test packages/gcode_core/test
  - git diff --check
  - git status --short
```

---

```yaml
task_id: MIG-P0-004
objective: Import flutter_study_learning into packages/flutter_study_learning without changing behavior or manifest semantics.
background: >
  This package provides shared Flutter teaching widgets and is an internal application-owned
  package. This task copies only this package; workspace and root dependency activation are deferred.
allowed_files:
  - packages/flutter_study_learning/**
forbidden_changes:
  - Do not modify ../flutter_study_learning/**.
  - Do not modify root pubspec.yaml or pubspec.lock.
  - Do not modify APIs, imports, SDK constraints, dependencies, tests, or formatting.
  - Do not copy .git/, .dart_tool/, build/, IDE state, logs, credentials, or generated caches.
  - Do not copy a legacy incompatible AI_ANALYSIS.md.
implementation_steps:
  - Read AGENTS.md and inspect the source manifest, public entrypoint, lib/, test/, README, license, and gitignore.
  - Confirm the destination does not contain user-owned files.
  - Copy the package to packages/flutter_study_learning with exclusions.
  - Preserve file contents and executable bits; do not reformat.
  - Compare functional source and test trees.
  - Fetch dependencies and run destination package analysis/tests.
acceptance_criteria:
  - The destination contains the package manifest, public entrypoint, source, tests, and applicable documentation/license.
  - Functional files match the sibling source before workspace-specific edits.
  - Destination analysis/tests succeed.
  - No excluded files or incompatible Agent document is copied.
  - The sibling source repository is unchanged.
validation_commands:
  - flutter pub get
  - flutter analyze
  - flutter test
  - diff -qr ../flutter_study_learning/lib packages/flutter_study_learning/lib
  - if both test directories exist, diff -qr ../flutter_study_learning/test packages/flutter_study_learning/test
  - git diff --check
  - git status --short
```

---

```yaml
task_id: MIG-P0-005
objective: Import file_picker_bridge into packages/file_picker_bridge without changing behavior or platform ownership.
background: >
  file_picker_bridge currently supplies a Flutter-side bridge while host platform
  registration may remain in the main application. This task is source relocation only;
  it must not convert the package into a full plugin or change platform support claims.
allowed_files:
  - packages/file_picker_bridge/**
forbidden_changes:
  - Do not modify ../file_picker_bridge/**.
  - Do not modify root pubspec.yaml or pubspec.lock.
  - Do not modify macos/, windows/, Android/iOS files, channel names, APIs, tests, or formatting.
  - Do not create plugin scaffolding.
  - Do not copy .git/, .dart_tool/, build/, IDE state, logs, credentials, generated caches, or a legacy incompatible AI_ANALYSIS.md.
implementation_steps:
  - Read AGENTS.md and inspect the source manifest, public entrypoint, channels, lib/, test/, README, license, and gitignore.
  - Confirm the destination does not contain user-owned files.
  - Copy the package to packages/file_picker_bridge with exclusions.
  - Preserve file contents and executable bits; do not reformat.
  - Compare functional source and tests.
  - Fetch dependencies and run destination package analysis/tests.
acceptance_criteria:
  - The destination contains the package manifest, public entrypoint, source, tests, and applicable documentation/license.
  - Existing MethodChannel/API identifiers are unchanged.
  - No plugin conversion or platform-host modification occurs.
  - Destination analysis/tests succeed.
  - The sibling source repository is unchanged.
validation_commands:
  - flutter pub get
  - flutter analyze
  - flutter test
  - diff -qr ../file_picker_bridge/lib packages/file_picker_bridge/lib
  - diff -qr ../file_picker_bridge/test packages/file_picker_bridge/test
  - git diff --check
  - git status --short
```

---

```yaml
task_id: MIG-P0-006
objective: Import flutter_ioc_core into packages/flutter_ioc_core without changing its pure Dart behavior.
background: >
  flutter_ioc_core is an application-owned pure Dart package. This task relocates it
  unchanged and verifies it independently before workspace activation.
allowed_files:
  - packages/flutter_ioc_core/**
forbidden_changes:
  - Do not modify ../flutter_ioc_core/**.
  - Do not modify root pubspec.yaml or pubspec.lock.
  - Do not add Flutter dependencies.
  - Do not modify APIs, SDK constraints, dependencies, tests, or formatting.
  - Do not copy .git/, .dart_tool/, build/, IDE state, logs, credentials, generated caches, or a legacy incompatible AI_ANALYSIS.md.
implementation_steps:
  - Read AGENTS.md and inspect the source manifest, public entrypoint, lib/, test/, README, license, and gitignore.
  - Confirm the destination does not contain user-owned files.
  - Copy the package to packages/flutter_ioc_core with exclusions.
  - Preserve file contents and executable bits; do not reformat.
  - Compare functional source and tests.
  - Fetch dependencies and run destination package analysis/tests using Dart commands.
acceptance_criteria:
  - The destination contains the manifest, public entrypoint, source, tests, and applicable documentation/license.
  - The package remains pure Dart.
  - Functional files match the sibling source before workspace-specific edits.
  - Destination Dart analysis/tests succeed.
  - The sibling source repository is unchanged.
validation_commands:
  - dart pub get
  - dart analyze
  - dart test
  - diff -qr ../flutter_ioc_core/lib packages/flutter_ioc_core/lib
  - if both test directories exist, diff -qr ../flutter_ioc_core/test packages/flutter_ioc_core/test
  - git diff --check
  - git status --short
```

---

```yaml
task_id: MIG-P0-007
objective: Activate Dart Pub Workspace and switch the four internal dependencies to repository-local packages/ paths.
background: >
  All four packages have already been copied and independently verified. This task makes
  packages/ canonical by configuring the native workspace, adjusting only manifests,
  regenerating the lockfile, and removing the temporary directory marker.
allowed_files:
  - pubspec.yaml
  - pubspec.lock
  - packages/.gitkeep
  - packages/gcode_core/pubspec.yaml
  - packages/flutter_study_learning/pubspec.yaml
  - packages/file_picker_bridge/pubspec.yaml
  - packages/flutter_ioc_core/pubspec.yaml
forbidden_changes:
  - Do not modify Dart source, tests, public APIs, package names, or package versions.
  - Do not modify flutterguard_cli dependency in this task.
  - Do not modify tool scripts, Agent documents, human documents, platform projects, or sibling repositories.
  - Do not upgrade unrelated hosted dependencies.
implementation_steps:
  - Read AGENTS.md and preserve all pre-existing root manifest/lockfile changes.
  - Confirm the active Dart SDK supports native Pub Workspace.
  - Add the four packages to the root workspace declaration using supported syntax.
  - Add the required workspace-resolution declaration to each member manifest.
  - Raise member SDK lower bounds only when required by the selected native workspace format; do not otherwise widen or upgrade constraints.
  - Change root internal path dependencies from ../name to packages/name.
  - Leave flutterguard_cli unchanged for MIG-P0-008.
  - Remove packages/.gitkeep after real package directories are tracked.
  - Run root dependency resolution and inspect lockfile changes for unrelated upgrades.
  - Run dependency resolution, analysis, and tests through the workspace and per package as needed.
acceptance_criteria:
  - Root manifest declares all four internal workspace members.
  - Each member participates in workspace resolution.
  - All four root internal dependencies resolve from packages/ and contain no ../ path.
  - flutterguard_cli remains unchanged for the next task.
  - Root and member dependency resolution succeeds.
  - Root and package analysis/tests succeed, or any proven pre-existing failure is reported without being modified.
  - No source or test file changes.
validation_commands:
  - flutter pub get
  - dart pub workspace list or the supported native workspace listing command
  - flutter analyze
  - flutter test
  - run flutter analyze/flutter test in each Flutter member when not covered by workspace tooling
  - run dart analyze/dart test in flutter_ioc_core
  - inspect git diff for pubspec.yaml, pubspec.lock, and member manifests only
  - git diff --check
  - git status --short
```

---

```yaml
task_id: MIG-P0-008
objective: Replace the flutterguard_cli external path dependency with an immutable Git tag or commit.
background: >
  flutterguard_cli remains independently governed. The current local package version is
  0.7.1 and declares a public repository. This task must select an existing immutable tag
  that resolves to the intended source; if no suitable tag exists, it must pin an exact
  commit SHA. A branch name is forbidden.
allowed_files:
  - pubspec.yaml
  - pubspec.lock
forbidden_changes:
  - Do not modify internal package dependencies or workspace declarations.
  - Do not modify ../flutterguard/** or any remote repository.
  - Do not create or push a Git tag.
  - Do not use main, master, dev, HEAD, or another moving branch as ref.
  - Do not upgrade unrelated dependencies.
  - Do not modify source, tests, scripts, Agent documents, or platform files.
implementation_steps:
  - Read AGENTS.md and capture the existing root manifest/lockfile diff.
  - Verify the repository URL declared by flutterguard_cli.
  - Fetch or inspect remote tags without modifying the remote.
  - Prefer an existing release tag corresponding to the intended 0.7.1 source.
  - Verify the selected tag resolves to an exact commit and contains package name flutterguard_cli plus bin/flutterguard.dart.
  - If no valid immutable tag exists, select the exact verified commit SHA.
  - Replace only the flutterguard_cli path dependency with the immutable Git source/ref.
  - Run root dependency resolution and inspect the lockfile's resolved Git revision.
  - Run FlutterGuard help and scan commands.
acceptance_criteria:
  - flutterguard_cli is a Git dependency pinned to an immutable tag or commit.
  - No moving branch ref is used.
  - pubspec.lock records the resolved immutable revision.
  - dart run can resolve and execute FlutterGuard.
  - No unrelated dependency declaration changes.
  - ../flutterguard remains unchanged.
validation_commands:
  - git ls-remote --tags https://github.com/lizy-coding/flutterguard.git
  - flutter pub get
  - dart run flutterguard_cli:flutterguard --help
  - dart run flutterguard_cli:flutterguard scan --path . --fail-on high
  - inspect git diff for pubspec.yaml and pubspec.lock only
  - git diff --check
  - git status --short
```

---

```yaml
task_id: MIG-P0-009
objective: Update migration and maintenance scripts so they no longer depend on or recreate the legacy sibling layout.
background: >
  The canonical internal package location is now packages/. Existing one-time migration
  tooling may contain ../ paths, destructive copy operations, or instructions that could
  overwrite the new canonical packages. This task updates or retires only those scripts.
allowed_files:
  - tool/migrate_sibling_packages.sh
  - tool/generate_harness_ai_analysis.sh
  - tool/validate_agent_docs.js
forbidden_changes:
  - Do not modify tool/generate_agent_indexes.js in this task; Agent context paths are handled by MIG-P0-010.
  - Do not modify package source, manifests, lockfile, application source, tests, Agent documents, human documents, hooks, or platform projects.
  - Do not execute the legacy migration script against sibling repositories.
implementation_steps:
  - Read AGENTS.md and inspect every current tool script for ../ package paths.
  - Identify scripts that are one-time migration utilities versus active validation tools.
  - Retire tool/migrate_sibling_packages.sh safely by deleting it or replacing it with a non-destructive failure message, according to repository convention.
  - Remove stale package-path assumptions from the other allowed scripts only if they exist.
  - Preserve current document generation and validation behavior.
  - Do not add package orchestration or P1 quality-gate functionality.
acceptance_criteria:
  - No active allowed script reads, writes, deletes, or recreates the five legacy sibling dependency paths.
  - The retired migration script cannot overwrite packages/ or sibling repositories.
  - Agent document validation still runs successfully against the current pre-context-update state, or any expected temporary failure is explicitly tied to MIG-P0-010.
  - Shell scripts pass syntax validation and Node scripts parse.
validation_commands:
  - bash -n tool/migrate_sibling_packages.sh if the file remains
  - bash -n tool/generate_harness_ai_analysis.sh
  - node --check tool/validate_agent_docs.js
  - search tool/ for the five legacy ../ dependency paths
  - git diff --check
  - git status --short
```

---

```yaml
task_id: MIG-P0-010
objective: Update generated Agent Context so repository ownership and dependency paths match the new workspace layout.
background: >
  Agent machine documents are generated JSON contracts despite .md extensions. The generator
  remains the authoritative edit point. This task updates dependency ownership, paths, package
  nodes, and validation coverage, then regenerates all affected contracts deterministically.
allowed_files:
  - tool/generate_agent_indexes.js
  - tool/validate_agent_docs.js
  - AI_ANALYSIS_SCHEMA.json
  - AI_PROJECT_CONTEXT.md
  - REFACTOR_PLAN.md
  - AI_ANALYSIS.md
  - lib/AI_ANALYSIS.md
  - lib/AI_MODULE_INDEX.md
  - lib/**/AI_ANALYSIS.md
  - packages/gcode_core/AI_ANALYSIS.md
  - packages/flutter_study_learning/AI_ANALYSIS.md
  - packages/file_picker_bridge/AI_ANALYSIS.md
  - packages/flutter_ioc_core/AI_ANALYSIS.md
forbidden_changes:
  - Do not modify source code, tests, manifests, lockfile, README, DEVELOPMENT docs, hooks, or platform projects.
  - Do not hand-edit generated machine documents without making the corresponding generator-source change.
  - Do not add natural-language Markdown to machine-contract files.
  - Do not describe gcode_core as pure Dart if its actual manifest still depends on Flutter.
  - Do not claim file_picker_bridge is a complete plugin unless its actual package structure proves it.
implementation_steps:
  - Read AGENTS.md, schema, project context, refactor plan, root index, package manifests, and accepted repository-layout ADR.
  - Replace generated dependency references from sibling paths to packages/ paths.
  - Represent flutterguard_cli as an immutable external Git tool dependency rather than an internal sibling package.
  - Add machine-contract nodes for the four internal workspace packages with accurate package types, ownership, entrypoints, dependencies, and validation commands.
  - Extend schema/validator coverage only as needed for package-level contracts.
  - Keep module route and status data unchanged.
  - Run the generator and validator.
  - Run the generator a second time and verify deterministic zero diff.
  - Search generated contracts for all five forbidden sibling paths.
acceptance_criteria:
  - All generated Agent contracts use packages/ for internal shared packages.
  - flutterguard_cli is represented as an external immutable tool dependency.
  - Each internal package has a valid machine contract.
  - Contracts match actual package manifests and do not repeat stale boundary claims.
  - No forbidden ../ dependency path remains in generated Agent documents.
  - Generator output is deterministic.
  - Agent document validation passes.
validation_commands:
  - bash tool/generate_harness_ai_analysis.sh
  - node tool/validate_agent_docs.js
  - run generator a second time
  - git diff --exit-code after the second generator run, relative to first generated state
  - search AI_ANALYSIS_SCHEMA.json, AI_PROJECT_CONTEXT.md, REFACTOR_PLAN.md, AI_ANALYSIS.md, lib/, and packages/ Agent contracts for legacy sibling paths
  - git diff --check
  - git status --short
```

---

```yaml
task_id: MIG-P0-011
objective: Update human-facing path references to the canonical packages/ layout and immutable FlutterGuard source policy.
background: >
  Machine Agent Context is already updated. This low-risk documentation task changes only
  human-facing path and setup references made stale by the migration. It must not broaden
  platform support claims or rewrite unrelated roadmap content.
allowed_files:
  - README.md
  - GCODE_VISUALIZER_EVOLUTION_PLAN.md
  - docs/DEVELOPMENT.md
  - docs/adr/0001-repository-layout.md
forbidden_changes:
  - Do not modify machine Agent documents, generator source, manifests, lockfile, source code, tests, scripts, hooks, or platform projects.
  - Do not change the accepted decision in ADR 0001; only mark implementation status and correct paths.
  - Do not claim a platform or package boundary that has not been validated.
implementation_steps:
  - Read AGENTS.md, the updated machine context, accepted ADR, root manifest, and package manifests.
  - Replace the four internal sibling paths with packages/ paths.
  - Replace the local FlutterGuard path description with the immutable Git dependency policy.
  - Update setup and package-layout examples.
  - Correct G-code paths while preserving the document's feature scope.
  - Mark ADR implementation status without altering its accepted decision.
  - Verify every referenced local path exists.
acceptance_criteria:
  - No modified human document instructs users to create the old sibling layout.
  - All four internal package paths resolve inside packages/.
  - FlutterGuard is described as an immutable external dependency.
  - All local document links and paths exist.
  - No source or machine-contract file changes.
validation_commands:
  - search modified documents for ../gcode_core, ../flutter_study_learning, ../file_picker_bridge, ../flutter_ioc_core, and ../flutterguard
  - verify every backticked local path in modified documents exists
  - git diff --check
  - git status --short
```

---

```yaml
task_id: MIG-P0-012
objective: Perform a read-only end-to-end verification of the completed shared dependency migration.
background: >
  This task validates the migration and creates no fixes. Any failure must be returned as
  a blocker with evidence. Verification must distinguish pre-existing working-tree changes
  from changes created by validation commands.
allowed_files: []
forbidden_changes:
  - Do not modify any tracked or untracked project file.
  - Do not run repository-wide formatter in place.
  - Do not regenerate Agent documents; validate the committed/generated state as found.
  - Do not repair failures.
  - Do not modify sibling or remote repositories.
implementation_steps:
  - Capture initial git status and diff.
  - Verify root workspace membership and package resolution.
  - Verify all declared local path dependencies resolve inside the repository.
  - Verify no tracked pubspec uses a ../ path dependency.
  - Verify flutterguard_cli uses an immutable Git tag or commit and lockfile contains the resolved revision.
  - Run Agent document validation without regeneration.
  - Run root analysis and tests.
  - Run each internal package's analysis/tests.
  - Run FlutterGuard help and high-severity scan.
  - Verify tool scripts contain no active legacy sibling path operations.
  - Verify human and machine documents contain no stale sibling dependency paths.
  - Compare final status/diff with initial state and report any validation-created mutation.
acceptance_criteria:
  - Root dependency resolution succeeds from the repository checkout.
  - The four internal packages are workspace members under packages/.
  - No tracked pubspec contains an external ../ path dependency.
  - flutterguard_cli resolves from an immutable Git revision.
  - Root analyze and tests pass.
  - Every internal package analyze/test command passes.
  - FlutterGuard scan passes with no high-severity issue.
  - Agent document validation passes.
  - No active script or current document depends on the old sibling layout.
  - Verification creates no repository change.
validation_commands:
  - git status --short --branch
  - flutter pub get
  - dart pub workspace list or the supported native workspace listing command
  - search all tracked pubspec.yaml files for path values containing ../
  - node tool/validate_agent_docs.js
  - flutter analyze
  - flutter test
  - run flutter analyze/flutter test for each Flutter workspace package
  - run dart analyze/dart test for flutter_ioc_core
  - dart run flutterguard_cli:flutterguard --help
  - dart run flutterguard_cli:flutterguard scan --path . --fail-on high
  - search active scripts and current documents for the five legacy sibling paths
  - git diff --check
  - git status --short
```
