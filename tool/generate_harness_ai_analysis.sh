#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT="$(cd "$ROOT/.." && pwd)"

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

json_string_array() {
  local first=1
  printf '['
  for value in "$@"; do
    if [[ "$first" -eq 0 ]]; then
      printf ','
    fi
    first=0
    printf '"%s"' "$(json_escape "$value")"
  done
  printf ']'
}

json_files_array() {
  local base="$1"
  local first=1
  printf '['
  if [[ -d "$base" ]]; then
    while IFS= read -r file; do
      local rel="${file#$base/}"
      if [[ "$rel" == "AI_ANALYSIS.md" ]]; then
        continue
      fi
      if [[ "$rel" == .dart_tool/* ||
            "$rel" == build/* ||
            "$rel" == .git/* ||
            "$rel" == .idea/* ||
            "$rel" == .claude/* ||
            "$rel" == .flutterguard/* ||
            "$rel" == macos/Pods/* ||
            "$rel" == macos/Flutter/ephemeral/* ||
            "$rel" == ios/Pods/* ||
            "$rel" == windows/flutter/ephemeral/* ||
            "$rel" == linux/flutter/ephemeral/* ]]; then
        continue
      fi
      if [[ "$first" -eq 0 ]]; then
        printf ','
      fi
      first=0
      printf '"%s"' "$(json_escape "$rel")"
    done < <(find "$base" -type f | sort)
  fi
  printf ']'
}

write_harness() {
  local out="$1"
  local id="$2"
  local abs_dir="$3"
  local rel_dir="$4"
  local kind="$5"
  local package_name="$6"
  local entrypoints="$7"
  local owns="$8"
  local depends="$9"
  local mutates="${10}"
  local commands="${11}"
  local status="${12}"

  mkdir -p "$(dirname "$out")"
  cat > "$out" <<EOF
{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "$(json_escape "$id")",
    "kind": "$(json_escape "$kind")",
    "package": "$(json_escape "$package_name")",
    "path": "$(json_escape "$rel_dir")",
    "status": "$(json_escape "$status")"
  },
  "entrypoints": $entrypoints,
  "owns": $owns,
  "depends": $depends,
  "mutates": $mutates,
  "files": $(json_files_array "$abs_dir"),
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": $commands
}
EOF
}

write_root_harness() {
  cat > "$ROOT/AI_ANALYSIS.md" <<EOF
{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "flutter_study.root",
    "kind": "app_workspace",
    "package": "main_app",
    "path": ".",
    "status": "active"
  },
  "entrypoints": [
    "lib/main.dart",
    "lib/app/app.dart",
    "lib/app/router/app_route_table.dart"
  ],
  "architecture_layers": [
    {
      "path": "lib/app",
      "role": "app_shell",
      "owns": ["material_app_router", "go_router_root", "module_home_index"],
      "analysis": ["lib/app/router/AI_ANALYSIS.md"]
    },
    {
      "path": "lib/module_registry",
      "role": "module_metadata_contract",
      "owns": ["module_entry", "module_category", "difficulty", "module_status"],
      "analysis": []
    },
    {
      "path": "lib/shared",
      "role": "business_free_shared_capabilities",
      "owns": ["multi_window", "platform_boundary"],
      "analysis": [
        "lib/shared/AI_ANALYSIS.md",
        "lib/shared/multi_window/AI_ANALYSIS.md",
        "lib/shared/platform/AI_ANALYSIS.md"
      ]
    },
    {
      "path": "lib/modules",
      "role": "learning_modules",
      "owns": ["basic", "async", "state", "ui", "popup_table", "platform"],
      "analysis": ["lib/AI_MODULE_INDEX.md", "lib/modules/**/AI_ANALYSIS.md"]
    },
    {
      "path": "macos",
      "role": "host_platform_integration",
      "owns": ["desktop_runner", "multi_window_host", "file_picker_bridge_wiring"],
      "analysis": ["lib/shared/platform/AI_ANALYSIS.md"]
    }
  ],
  "module_summary": {
    "total_registered": 17,
    "by_category": {
      "basic": 3,
      "async": 3,
      "state": 2,
      "ui": 3,
      "popup_table": 4,
      "platform": 2
    },
    "by_status": {
      "recommended": 4,
      "ready": 13,
      "pending": 0
    },
    "required_route_table": "lib/app/router/app_route_table.dart",
    "required_index": "lib/AI_MODULE_INDEX.md"
  },
  "external_packages": [
    "../gcode_core",
    "../flutter_study_learning",
    "../file_picker_bridge",
    "../flutter_ioc_core",
    "../flutterguard/packages/flutterguard_cli"
  ],
  "next_direction": [
    {
      "priority": 1,
      "id": "stabilize_analysis_hierarchy",
      "scope": [
        "AI_ANALYSIS.md",
        "lib/AI_MODULE_INDEX.md",
        "tool/generate_harness_ai_analysis.sh"
      ],
      "actions": ["sync_schema", "remove_file_inventory", "enforce_layer_scope"],
      "blocks": ["analysis_drift"]
    },
    {
      "priority": 2,
      "id": "split_large_popup_widgets",
      "scope": ["lib/modules/popup_table/popup_widgets"],
      "actions": ["split_module_root", "extract_widgets", "add_smoke_test"],
      "blocks": ["large_file", "flutterguard_noise"]
    },
    {
      "priority": 3,
      "id": "raise_recommended_modules",
      "scope": ["module_status_ready", "learning_scaffold_modules"],
      "actions": ["verify_metadata", "verify_ai_analysis", "add_widget_smoke_tests"],
      "blocks": ["status_inflation"]
    },
    {
      "priority": 4,
      "id": "shared_boundary_tests",
      "scope": ["lib/shared/multi_window", "../file_picker_bridge"],
      "actions": ["add_platform_mocks", "add_cancel_tests", "add_error_tests"],
      "blocks": ["shared_regression"]
    },
    {
      "priority": 5,
      "id": "quality_noise_reduction",
      "scope": ["flutterguard_medium_low", "module_widget_tests"],
      "actions": ["triage_medium_low", "add_module_tests", "record_visual_acceptance"],
      "blocks": ["quality_debt"]
    }
  ],
  "update_policy": {
    "syntax": "json_config",
    "prose": "forbidden",
    "markdown": "forbidden",
    "root_file": ["layers", "module_totals", "package_boundaries", "next_direction"],
    "layer_files": ["ownership", "entrypoints", "dependencies", "contracts", "validation"],
    "module_files": ["structure", "data_flow", "key_classes", "teaching_components", "change_notes"],
    "avoid": ["root_file_inventory", "module_internal_duplication"]
  },
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": [
    "dart format .",
    "flutter analyze",
    "dart run flutterguard_cli:flutterguard scan --path . --fail-on high"
  ]
}
EOF
}

write_root_harness

write_harness \
  "$ROOT/lib/app/router/AI_ANALYSIS.md" \
  "main_app.app.router" \
  "$ROOT/lib/app/router" \
  "lib/app/router" \
  "app_layer" \
  "main_app" \
  "$(json_string_array "app_router.dart" "app_route_table.dart")" \
  "$(json_string_array "go_router_root" "module_route_aggregation" "module_home_index")" \
  "$(json_string_array "module_registry" "modules/*/module_entry.dart" "modules/*/module_routes.dart")" \
  "$(json_string_array "app_route_table.dart" "app_router.dart")" \
  "$(json_string_array "flutter analyze")" \
  "active"

write_harness \
  "$ROOT/lib/shared/AI_ANALYSIS.md" \
  "main_app.shared" \
  "$ROOT/lib/shared" \
  "lib/shared" \
  "shared_layer" \
  "main_app" \
  "$(json_string_array "AI_ANALYSIS.md")" \
  "$(json_string_array "boundary_docs" "transition_layer")" \
  "$(json_string_array "../flutter_study_learning" "../file_picker_bridge")" \
  "$(json_string_array "AI_ANALYSIS.md" "platform/AI_ANALYSIS.md")" \
  "$(json_string_array "flutter analyze")" \
  "transition"

write_harness \
  "$ROOT/lib/shared/platform/AI_ANALYSIS.md" \
  "main_app.shared.platform" \
  "$ROOT/lib/shared/platform" \
  "lib/shared/platform" \
  "platform_boundary_layer" \
  "main_app" \
  "$(json_string_array "AI_ANALYSIS.md")" \
  "$(json_string_array "platform_boundary_docs" "host_channel_registry_docs")" \
  "$(json_string_array "../file_picker_bridge" "macos/Runner/AppDelegate.swift")" \
  "$(json_string_array "AI_ANALYSIS.md" "macos/Runner/AppDelegate.swift")" \
  "$(json_string_array "flutter analyze" "flutter build macos")" \
  "transition"

write_harness \
  "$ROOT/lib/shared/multi_window/AI_ANALYSIS.md" \
  "main_app.shared.multi_window" \
  "$ROOT/lib/shared/multi_window" \
  "lib/shared/multi_window" \
  "shared_layer" \
  "main_app" \
  "$(json_string_array "multi_window_manager.dart" "category_window_app.dart" "multi_window_route_filter.dart")" \
  "$(json_string_array "desktop_window_lifecycle" "category_window_router" "module_route_filter")" \
  "$(json_string_array "desktop_multi_window" "go_router" "module_registry" "app_router_module_table")" \
  "$(json_string_array "AI_ANALYSIS.md" "**/*.dart")" \
  "$(json_string_array "dart format ." "flutter analyze" "dart run flutterguard_cli:flutterguard scan --path . --fail-on high")" \
  "ready"

write_module() {
  local category="$1"
  local module="$2"
  local kind="$3"
  local state="$4"
  local depends_csv="$5"
  local dir="$ROOT/lib/modules/$category/$module"
  local depends=()
  IFS=',' read -r -a depends <<< "$depends_csv"
  write_harness \
    "$dir/AI_ANALYSIS.md" \
    "main_app.modules.$category.$module" \
    "$dir" \
    "lib/modules/$category/$module" \
    "$kind" \
    "main_app" \
    "$(json_string_array "module_entry.dart" "module_routes.dart" "module_root.dart" "pages" "widgets" "state")" \
    "$(json_string_array "module_entry" "module_ui" "module_state" "module_docs")" \
    "$(json_string_array "${depends[@]}")" \
    "$(json_string_array "AI_ANALYSIS.md" "**/*.dart")" \
    "$(json_string_array "flutter analyze" "flutter test")" \
    "$state"
}

write_module "basic" "tree_state" "learning_module" "active" "flutter_study_learning,module_registry,go_router"
write_module "basic" "microtask" "learning_module" "active" "module_registry,go_router"
write_module "basic" "debounce_throttle" "learning_module" "active" "module_registry"
write_module "async" "isolate_basic" "learning_module" "active" "module_registry,go_router"
write_module "async" "isolate_task_manager" "learning_module" "active" "module_registry"
write_module "async" "stream_subscription" "learning_module" "active" "module_registry,go_router"
write_module "state" "status_management" "learning_module" "active" "provider,flutter_riverpod,flutter_bloc,module_registry"
write_module "state" "flutter_ioc" "learning_module_adapter" "active" "flutter_ioc_core,provider,module_registry"
write_module "ui" "adsorption_line" "learning_module" "active" "provider,module_registry"
write_module "ui" "download_animation" "learning_module" "active" "module_registry,go_router"
write_module "ui" "gcode_visualizer" "learning_module_adapter" "active" "gcode_core,flutter_study_learning,file_picker_bridge,module_registry"
write_module "popup_table" "popup_widgets" "learning_module" "active" "module_registry,flutter_study_learning"
write_module "popup_table" "popup_list_interaction" "learning_module" "active" "module_registry,flutter_study_learning,go_router"
write_module "popup_table" "scroll_table" "learning_module" "active" "two_dimensional_scrollables,module_registry,flutter_study_learning"
write_module "popup_table" "overlay_follow_compare" "learning_module" "active" "module_registry,flutter_study_learning"
write_module "platform" "dio_interceptor" "learning_module" "active" "dio,module_registry,go_router"
write_module "platform" "usb_detector" "learning_module" "active" "usb_serial,device_info_plus,module_registry"

write_package() {
  local package_dir="$1"
  local id="$2"
  local kind="$3"
  local owns_csv="$4"
  local depends_csv="$5"
  local commands_csv="$6"
  local abs="$PARENT/$package_dir"
  local owns=()
  local depends=()
  local commands=()
  IFS=',' read -r -a owns <<< "$owns_csv"
  IFS=',' read -r -a depends <<< "$depends_csv"
  IFS=',' read -r -a commands <<< "$commands_csv"
  write_harness \
    "$abs/AI_ANALYSIS.md" \
    "$id" \
    "$abs" \
    "../$package_dir" \
    "$kind" \
    "$package_dir" \
    "$(json_string_array "lib/$package_dir.dart")" \
    "$(json_string_array "${owns[@]}")" \
    "$(json_string_array "${depends[@]}")" \
    "$(json_string_array "lib/**" "test/**" "pubspec.yaml" "AI_ANALYSIS.md")" \
    "$(json_string_array "${commands[@]}")" \
    "active"
}

write_package "gcode_core" "packages.gcode_core" "dart_package" "gcode_readers,gcode_parser,gcode_domain,gcode_toolpath,gcode_pipeline" "dart_sdk" "dart format .,dart analyze,dart test"
write_package "flutter_study_learning" "packages.flutter_study_learning" "flutter_package" "learning_scaffold,learning_widgets" "flutter_sdk" "dart format .,flutter analyze"
write_package "file_picker_bridge" "packages.file_picker_bridge" "flutter_package" "file_picker_api,method_channel_client" "flutter_sdk" "dart format .,flutter analyze,flutter test"
write_package "flutter_ioc_core" "packages.flutter_ioc_core" "dart_package" "ioc_container,ioc_types,lifetime_scope" "dart_sdk" "dart format .,dart analyze"

echo "harness AI_ANALYSIS generation completed"
