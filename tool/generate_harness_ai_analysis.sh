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

write_harness \
  "$ROOT/AI_ANALYSIS.md" \
  "flutter_study.root" \
  "$ROOT" \
  "." \
  "app_workspace" \
  "main_app" \
  "$(json_string_array "lib/main.dart" "lib/app/app.dart" "lib/app/router/app_route_table.dart")" \
  "$(json_string_array "app_shell" "module_registry" "learning_modules" "path_dependency_bindings")" \
  "$(json_string_array "../gcode_core" "../flutter_study_learning" "../flutter_study_platform_file_picker" "../flutter_ioc_core" "../flutterguard/packages/flutterguard_cli")" \
  "$(json_string_array "pubspec.yaml" "lib/app/router/app_route_table.dart" "lib/modules/**" "macos/Runner/AppDelegate.swift")" \
  "$(json_string_array "dart format ." "flutter analyze" "dart run flutterguard_cli:flutterguard scan --path . --fail-on high" "flutter build macos")" \
  "active"

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
  "$(json_string_array "../flutter_study_learning" "../flutter_study_platform_file_picker")" \
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
  "$(json_string_array "../flutter_study_platform_file_picker" "macos/Runner/AppDelegate.swift")" \
  "$(json_string_array "AI_ANALYSIS.md" "macos/Runner/AppDelegate.swift")" \
  "$(json_string_array "flutter analyze" "flutter build macos")" \
  "transition"

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
write_module "ui" "gcode_visualizer" "learning_module_adapter" "active" "gcode_core,flutter_study_learning,flutter_study_platform_file_picker,module_registry"
write_module "ui" "popup_widgets" "learning_module" "active" "module_registry"
write_module "ui" "scroll_table" "learning_module" "active" "two_dimensional_scrollables,module_registry"
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
write_package "flutter_study_platform_file_picker" "packages.flutter_study_platform_file_picker" "flutter_package" "file_picker_api,method_channel_client" "flutter_sdk" "dart format .,flutter analyze,flutter test"
write_package "flutter_ioc_core" "packages.flutter_ioc_core" "dart_package" "ioc_container,ioc_types,lifetime_scope" "dart_sdk" "dart format .,dart analyze"

echo "harness AI_ANALYSIS generation completed"
