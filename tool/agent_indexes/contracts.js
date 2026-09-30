const fs = require('fs');
const path = require('path');

function writeContracts({ appRoot, modules, workspacePackages, categoryMeta, contracts, facts, writeJson }) {
  function nodePath(rel) {
    return rel.replace(/\/?AI_ANALYSIS\.md$/, '') || '.';
  }
  function writeIndex({
    rel,
    id,
    kind,
    status = 'active',
    entrypoints = [],
    owns = [],
    depends = [],
    children = [],
    validation = ['flutter analyze'],
  }) {
    writeJson(rel, {
      schema: 'vibecoding.harness.ai_analysis.v2',
      mode: 'index',
      node: {
        id,
        kind,
        package: 'flutter_forge_app',
        path: nodePath(rel),
        status,
      },
      entrypoints,
      owns,
      depends,
      children,
      contracts,
      validation,
    });
  }

  function writeSchema() {
    writeJson('AI_ANALYSIS_SCHEMA.json', {
      schema: 'flutter_forge.agent_docs.schema.v2',
      syntax: 'json_config',
      prose: 'forbidden',
      markdown: 'forbidden',
      generated_by: 'tool/generate_agent_indexes.js',
      documents: {
        project_context: 'AI_PROJECT_CONTEXT.md',
        refactor_plan: 'REFACTOR_PLAN.md',
        module_index: 'lib/AI_MODULE_INDEX.md',
        analysis_glob: '**/AI_ANALYSIS.md',
      },
      levels: {
        workspace: ['AI_ANALYSIS.md'],
        package_contract: workspacePackages.map(({ path: packagePath }) => `${packagePath}/AI_ANALYSIS.md`),
        section: [
          'lib/AI_ANALYSIS.md',
          'lib/app/AI_ANALYSIS.md',
          'lib/module_registry/AI_ANALYSIS.md',
          'lib/shared/AI_ANALYSIS.md',
          'lib/modules/AI_ANALYSIS.md',
        ],
        subsection: [
          'lib/app/router/AI_ANALYSIS.md',
          'lib/shared/platform/AI_ANALYSIS.md',
          'lib/shared/multi_window/AI_ANALYSIS.md',
          'lib/modules/basic/AI_ANALYSIS.md',
          'lib/modules/async/AI_ANALYSIS.md',
          'lib/modules/state/AI_ANALYSIS.md',
          'lib/modules/ui/AI_ANALYSIS.md',
          'lib/modules/popup_table/AI_ANALYSIS.md',
          'lib/modules/platform/AI_ANALYSIS.md',
        ],
        module_contract: ['lib/modules/*/*/AI_ANALYSIS.md'],
      },
      required_keys: ['schema', 'mode', 'node', 'entrypoints', 'owns', 'depends', 'children', 'contracts', 'validation'],
      node_required_keys: ['id', 'kind', 'package', 'path', 'status'],
      contracts_required: {
        no_natural_language: true,
        doc_consumer: 'coding_agent',
        doc_mode: 'machine_contract',
      },
      module_contract_policy: {
        keep_for_module_rule: true,
        content: ['route', 'category', 'status', 'platform_support', 'entrypoints', 'analysis_parent'],
        avoid: ['class_descriptions', 'long_file_inventory', 'natural_language_notes'],
      },
      package_contract_policy: {
        required_for_workspace_member: true,
        content: ['package_type', 'workspace', 'entrypoints', 'owns', 'depends', 'validation', 'test_status'],
        avoid: ['platform_claims_not_proven_by_manifest', 'natural_language_notes'],
      },
    });
  }

  function writeModuleIndex() {
    writeJson('lib/AI_MODULE_INDEX.md', {
      schema: 'flutter_forge.agent_docs.module_index.v1',
      registry: 'lib/module_registry/module_manifest.dart',
      count: modules.length,
      modules: modules.map(({ category, id, route, status, depends, excludedPlatforms = [] }) => ({
        id,
        category,
        path: `lib/modules/${category}/${id}`,
        route,
        status,
        depends,
        platform_support: {
          target_platforms: ['android', 'iOS', 'macOS', 'web', 'windows'],
          excluded_platforms: excludedPlatforms,
        },
        analysis: `lib/modules/${category}/${id}/AI_ANALYSIS.md`,
      })),
    });
  }

  function writeRootIndexes() {
    writeIndex({
      rel: 'AI_ANALYSIS.md',
      id: 'flutter_forge.root',
      kind: 'workspace_index',
      entrypoints: ['lib/main.dart', 'lib/app/app_bootstrap.dart', 'lib/app/app.dart', 'lib/app/router/app_route_table.dart'],
      owns: ['app_shell', 'module_registry', 'shared_capabilities', 'learning_modules', 'host_integrations'],
      depends: [
        `git:${facts.gcodeDependency.url}#${facts.gcodeDependency.ref}`,
        'lib/shared/learning',
        ...workspacePackages.map(({ path: packagePath }) => packagePath),
        `git:${facts.flutterGuardDependency.url}#${facts.flutterGuardDependency.ref}`,
      ],
      children: [
        'lib/AI_ANALYSIS.md',
        'lib/app/AI_ANALYSIS.md',
        'lib/module_registry/AI_ANALYSIS.md',
        'lib/shared/AI_ANALYSIS.md',
        'lib/modules/AI_ANALYSIS.md',
        ...workspacePackages.map(({ path: packagePath }) => `${packagePath}/AI_ANALYSIS.md`),
      ],
      validation: ['node --test tool/agent_indexes/generator.test.js', 'node tool/generate_agent_indexes.js --check', 'bash tool/generate_harness_ai_analysis.sh', 'dart format .', 'flutter analyze', 'dart run flutterguard_cli:flutterguard scan . --fail-on high'],
    });
    writeIndex({
      rel: 'lib/AI_ANALYSIS.md',
      id: 'flutter_forge_app.lib',
      kind: 'source_index',
      entrypoints: ['main.dart', 'app/app_bootstrap.dart', 'app/app.dart', 'app/router/app_route_table.dart'],
      owns: ['app', 'module_registry', 'shared', 'modules'],
      depends: ['flutter_sdk', 'go_router', 'flutter_riverpod'],
      children: ['app/AI_ANALYSIS.md', 'module_registry/AI_ANALYSIS.md', 'shared/AI_ANALYSIS.md', 'modules/AI_ANALYSIS.md'],
    });
  }

  function writeLayerIndexes() {
    writeIndex({
      rel: 'lib/app/AI_ANALYSIS.md',
      id: 'flutter_forge_app.app',
      kind: 'app_index',
      entrypoints: ['app.dart', 'app_bootstrap.dart', 'app_platform_provider.dart', 'adaptive_app_shell.dart', 'creator_home_page.dart', 'creator_profile.dart', 'module_home_page.dart', 'unsupported_module_page.dart', 'category_navigation.dart', 'navigation_policy.dart', 'category_window_app.dart', 'router/app_router.dart', 'router/app_route_table.dart'],
      owns: ['host_bootstrap', 'platform_snapshot_injection', 'material_app_router', 'router', 'creator_home', 'module_catalog', 'title_search', 'unsupported_module_route', 'responsive_navigation_shell', 'adaptive_category_navigation', 'desktop_category_window_shell'],
      depends: ['go_router', 'flutter_riverpod', 'url_launcher', 'module_registry', 'shared/multi_window', 'modules'],
      children: ['router/AI_ANALYSIS.md'],
    });
    writeIndex({
      rel: 'lib/app/router/AI_ANALYSIS.md',
      id: 'flutter_forge_app.app.router',
      kind: 'router_index',
      entrypoints: ['app_router.dart', 'app_route_table.dart'],
      owns: ['go_router_root', 'adaptive_shell_route', 'creator_home_route', 'category_route', 'stable_guarded_module_routes', 'module_route_aggregation', 'module_catalog_composition'],
      depends: ['app/adaptive_app_shell', 'app/creator_home_page', 'app/module_home_page', 'module_registry', 'modules'],
    });
    writeIndex({
      rel: 'lib/module_registry/AI_ANALYSIS.md',
      id: 'flutter_forge_app.module_registry',
      kind: 'registry_index',
      entrypoints: ['app_platform_snapshot.dart', 'module_entry.dart', 'module_category.dart', 'module_platform_support.dart', 'module_catalog_utils.dart'],
      owns: ['platform_snapshot', 'product_target_platforms', 'module_entry_model', 'module_category_enum', 'difficulty_enum', 'module_status_enum', 'excluded_platform_availability', 'module_catalog_filtering', 'category_route_rebasing'],
      depends: ['flutter_material', 'go_router'],
    });
    writeIndex({
      rel: 'lib/shared/AI_ANALYSIS.md',
      id: 'flutter_forge_app.shared',
      kind: 'shared_index',
      entrypoints: ['learning', 'multi_window', 'platform'],
      owns: ['business_free_capabilities', 'learning_templates', 'desktop_window_lifecycle', 'platform_boundaries'],
      depends: ['desktop_multi_window', 'packages/file_picker_bridge'],
      children: ['multi_window/AI_ANALYSIS.md', 'platform/AI_ANALYSIS.md'],
    });
    writeIndex({
      rel: 'lib/shared/multi_window/AI_ANALYSIS.md',
      id: 'flutter_forge_app.shared.multi_window',
      kind: 'shared_capability_index',
      entrypoints: ['multi_window_manager.dart', 'mac_window.dart'],
      owns: ['desktop_window_lifecycle', 'desktop_window_arguments', 'window_backend_protocol'],
      depends: ['desktop_multi_window', 'module_registry'],
    });
    writeIndex({
      rel: 'lib/shared/platform/AI_ANALYSIS.md',
      id: 'flutter_forge_app.shared.platform',
      kind: 'shared_boundary_index',
      status: 'transition',
      entrypoints: ['AI_ANALYSIS.md'],
      owns: ['platform_boundary', 'host_channel_registry'],
      depends: ['packages/file_picker_bridge', 'macos/Runner/AppDelegate.swift'],
      validation: ['flutter analyze', 'flutter build macos'],
    });
  }

  function writeModuleIndexes() {
    writeIndex({
      rel: 'lib/modules/AI_ANALYSIS.md',
      id: 'flutter_forge_app.modules',
      kind: 'modules_index',
      entrypoints: ['basic', 'async', 'state', 'ui', 'popup_table', 'platform'],
      owns: ['learning_module_categories', 'route_registered_modules'],
      depends: ['module_registry', 'shared_learning'],
      children: ['basic/AI_ANALYSIS.md', 'async/AI_ANALYSIS.md', 'state/AI_ANALYSIS.md', 'ui/AI_ANALYSIS.md', 'popup_table/AI_ANALYSIS.md', 'platform/AI_ANALYSIS.md'],
    });
    for (const [category, [children, owns, depends]] of Object.entries(categoryMeta)) {
      writeIndex({
        rel: `lib/modules/${category}/AI_ANALYSIS.md`,
        id: `flutter_forge_app.modules.${category}`,
        kind: 'module_category_index',
        entrypoints: children,
        owns,
        depends,
        children: children.map((module) => `${module}/AI_ANALYSIS.md`),
      });
    }
  }

  function writeModuleContracts() {
    for (const { category, id: module, route, status, depends, excludedPlatforms = [] } of modules) {
      const dir = path.join(appRoot, 'lib/modules', category, module);
      const entrypoints = [];
      for (const item of ['module_entry.dart', 'module_root.dart', 'module_routes.dart']) {
        if (fs.existsSync(path.join(dir, item))) entrypoints.push(item);
      }
      for (const item of ['pages', 'widgets', 'state']) {
        if (fs.existsSync(path.join(dir, item))) entrypoints.push(item);
      }
      writeJson(`lib/modules/${category}/${module}/AI_ANALYSIS.md`, {
        schema: 'vibecoding.harness.ai_analysis.v2',
        mode: 'module_contract',
        node: {
          id: `flutter_forge_app.modules.${category}.${module}`,
          kind: 'learning_module',
          package: 'flutter_forge_app',
          path: `lib/modules/${category}/${module}`,
          status,
        },
        route,
        category,
        platform_support: {
          target_platforms: ['android', 'iOS', 'macOS', 'web', 'windows'],
          excluded_platforms: excludedPlatforms,
        },
        entrypoints: entrypoints.length ? entrypoints : ['module_entry.dart'],
        owns: ['module_entry', 'module_ui', 'module_docs'],
        depends,
        children: [],
        analysis_parent: `lib/modules/${category}/AI_ANALYSIS.md`,
        contracts,
        validation: ['flutter analyze'],
      });
    }
  }

  function writePackageContracts() {
    for (const packageMeta of workspacePackages) {
      writeJson(`${packageMeta.path}/AI_ANALYSIS.md`, {
        schema: 'vibecoding.harness.ai_analysis.v2',
        mode: 'package_contract',
        node: {
          id: `flutter_forge.workspace.${packageMeta.name}`,
          kind: packageMeta.kind,
          package: packageMeta.name,
          path: packageMeta.path,
          status: 'active',
        },
        package_type: packageMeta.kind,
        workspace: {
          member: true,
          resolution: 'workspace',
          resolution_status: 'active',
          resolution_blocker: 'none',
        },
        entrypoints: packageMeta.entrypoints,
        owns: packageMeta.owns,
        depends: packageMeta.depends,
        children: [],
        contracts,
        validation: packageMeta.validation,
        test_status: packageMeta.test_status,
      });
    }
  }
  writeSchema();
  writeModuleIndex();
  writeRootIndexes();
  writeLayerIndexes();
  writeModuleIndexes();
  writeModuleContracts();
  writePackageContracts();
}
module.exports = { writeContracts };
