{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {
    "id": "flutter_forge_app.modules.basic",
    "kind": "module_category_index",
    "package": "flutter_forge_app",
    "path": "lib/modules/basic",
    "status": "active"
  },
  "entrypoints": [
    "constraint_layout",
    "tree_state",
    "microtask",
    "debounce_throttle"
  ],
  "owns": [
    "basic_mechanisms"
  ],
  "depends": [
    "shared_learning",
    "module_registry",
    "go_router"
  ],
  "children": [
    "constraint_layout/AI_ANALYSIS.md",
    "tree_state/AI_ANALYSIS.md",
    "microtask/AI_ANALYSIS.md",
    "debounce_throttle/AI_ANALYSIS.md"
  ],
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "coding_agent",
    "doc_mode": "machine_contract"
  },
  "validation": [
    "flutter analyze"
  ]
}
