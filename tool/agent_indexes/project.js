const { writePlan } = require('./plan');

function writeProjectDocuments({ writeJson, workspacePackages, facts }) {
  function writeProjectContext() {
    writeJson('AI_PROJECT_CONTEXT.md', {
      schema: 'flutter_forge.agent_docs.project_context.v1',
      consumer: 'coding_agent',
      package: {
        name: 'flutter_forge_app',
        type: 'flutter_modular_learning_app',
        sdk: ['flutter_3', 'dart_3'],
      },
      platform: {
        current_hosts: facts.currentHosts,
        host_evidence_semantics: 'directory_presence_only',
        target_hosts: ['android', 'ios', 'macos', 'web', 'windows'],
      },
      entrypoints: {
        process: 'lib/main.dart',
        bootstrap: 'lib/app/app_bootstrap.dart',
        app: 'lib/app/app.dart',
        router: 'lib/app/router/app_router.dart',
        route_table: 'lib/app/router/app_route_table.dart',
        module_manifest: 'lib/module_registry/module_manifest.dart',
      },
      repository: {
        layout: 'pub_workspace',
        workspace_root: '.',
        members: facts.workspaceMembers,
        resolution_status: 'active',
        resolution_blocker: 'none',
      },
      internal_packages: workspacePackages.map(({ name, kind, path: packagePath, entrypoints }) => ({
        name,
        type: kind,
        path: packagePath,
        entrypoint: entrypoints[0],
      })),
      external_packages: [{ ...facts.gcodeDependency, entrypoint: 'lib/gcode_core.dart', flutter_min: '3.47.2', entry_platforms: facts.gcodeEntryPlatforms, requires: ['impeller', 'flutter_gpu'], macos_deployment_target_min: '12.0' }],
      capability_aliases: { shared_learning: 'lib/shared/learning', shared_popup: 'lib/shared/popup', shared_table: 'lib/shared/table' },
      external_tools: [],
      layers: [
        {
          id: 'app',
          path: 'lib/app',
          owns: ['host_bootstrap', 'app_shell', 'navigation_policy', 'route_composition'],
          may_depend_on: ['module_registry', 'shared', 'modules'],
        },
        {
          id: 'module_registry',
          path: 'lib/module_registry',
          owns: ['module_metadata', 'platform_snapshot', 'catalog_operations'],
          may_depend_on: ['flutter', 'go_router'],
          assembly_exception: 'lib/module_registry/module_manifest.dart',
        },
        {
          id: 'shared',
          path: 'lib/shared',
          owns: ['business_neutral_capabilities', 'platform_boundaries'],
          forbidden_dependencies: ['app', 'modules'],
        },
        {
          id: 'modules',
          path: 'lib/modules/{category}/{module}',
          owns: ['learning_ui', 'module_state', 'module_domain', 'module_data'],
          forbidden_dependencies: ['other_modules'],
        },
      ],
      module_contract: {
        required_files: ['module_entry.dart', 'AI_ANALYSIS.md'],
        required_registration: 'lib/module_registry/module_manifest.dart',
        required_metadata: ['category', 'difficulty', 'concepts', 'estimatedMinutes', 'status', 'subtitle'],
        required_learning_dependency: 'shared_learning',
        route_path_style: 'kebab_case',
        directory_style: 'snake_case',
      },
      platform_rules: {
        router_platform_api: 'forbidden',
        module_host_navigation: 'forbidden',
        desktop_window_policy: 'lib/app/category_navigation.dart',
        navigation_policy: 'lib/app/navigation_policy.dart',
        compact_width_breakpoint_dp: 600,
        mobile_window_policy: 'in_app_navigation_only',
        web_window_policy: 'in_app_navigation_only',
        platform_snapshot: 'bootstrap_initialized_process_immutable',
        target_platforms: ['android', 'ios', 'macos', 'web', 'windows'],
        non_target_platforms: 'unsupported',
        module_platform_semantics: 'target_platform_entry_open_unless_excluded',
        unsupported_route: 'stable_guarded_module_route',
        web_release_build: 'bash tool/build_web_release.sh',
        web_startup_shell: 'web/index.html + web/flutter_bootstrap.js',
        platform_capability_contract: 'business_neutral_interface',
        availability_source: 'tool/agent_indexes/availability.js',
        maintenance_semantics: 'support_declarations_and_known_constraints',
        maintenance_matrix: 'docs/module_availability/matrix.json',
        historical_reports: 'docs/module_availability/archive/README.md',
      },
      change_protocol: {
        branch_policy: {
          development_branch: 'dev',
          stable_branch: 'master',
          stable_branch_update: 'pull_request_from_dev_only',
          stable_branch_direct_push: 'forbidden',
          stable_branch_force_push: 'forbidden',
          stable_branch_delete: 'forbidden',
          required_status_check: 'quality-gate',
          required_approvals: 0,
          required_approvals_reason: 'single_maintainer_self_review_deadlock',
          sync_after_merge: 'merge_master_topology_back_into_dev',
        },
        pre_read: ['AI_PROJECT_CONTEXT.md', 'REFACTOR_PLAN.md', '{target}/AI_ANALYSIS.md'],
        update_source: ['tool/generate_agent_indexes.js', 'tool/agent_indexes/catalog.js', 'tool/agent_indexes/project.js', 'tool/agent_indexes/plan.js', 'tool/agent_indexes/generator.js', 'tool/agent_indexes/contracts.js', 'tool/agent_indexes/routes.js', 'tool/agent_indexes/availability.js', 'tool/agent_indexes/support.js'],
        generate: 'bash tool/generate_harness_ai_analysis.sh',
        validate: [
          'bash tool/check_generated_docs.sh',
          'dart format --output=none --set-exit-if-changed .',
          'flutter analyze (bare)',
          'bash tool/test_all.sh',
          'bash tool/verify_test_layout.sh',
          'bash tool/build_web_release.sh',
        ],
        ci: {
          authoritative_remote_packaging_gate: '.github/workflows/ci.yml',
          analyze_standard: 'bare flutter analyze (info/warning treated as failure)',
          steps: ['flutter pub get --enforce-lockfile', 'bash tool/quality_gate.sh'],
          implementation: 'bash tool/quality_gate.sh; no FlutterGuard dependency',
        },
      },
    });
  }

  writeProjectContext();
  writePlan({ writeJson, workspacePackages, facts });
}

module.exports = { writeProjectDocuments };
