{
  "schema": "vibecoding.harness.ai_analysis.v1",
  "mode": "harness",
  "node": {
    "id": "main_app.modules.popup_table.popup_widgets",
    "kind": "learning_module",
    "package": "main_app",
    "path": "lib/modules/popup_table/popup_widgets",
    "status": "active"
  },
  "entrypoints": ["module_entry.dart","module_root.dart"],
  "owns": ["module_entry","module_ui"],
  "depends": ["module_registry","flutter_study_learning"],
  "mutates": ["AI_ANALYSIS.md","**/*.dart"],
  "files": ["module_entry.dart","module_root.dart"],
  "classes": {
    "PopDemoHomePage": "StatefulWidget page entry",
    "_PopDemoHomePageState": "Main state: LearningScaffold build, 9 demo trigger methods, chain/overlay dialog management",
    "ChainOrderStore": "ValueNotifier-based data model for chain dialog ordering (open/close order)",
    "_CupertinoDoubleTapTile": "GestureDetector tile for double-tap Cupertino dialog trigger",
    "_ContextMenuTile": "GestureDetector tile for onTapDown context menu trigger"
  },
  "contracts": {
    "no_natural_language": true,
    "doc_consumer": "vibecoding",
    "doc_mode": "harness",
    "update_required_on_file_change": true,
    "import_direction_enforced": true
  },
  "validation": ["flutter analyze","flutter test"],
  "refactoring": {
    "date": "2026-06-15",
    "summary": "Retrofit P0: Replaced PopScope+Scaffold with LearningScaffold from flutter_study_learning package",
    "changes": [
      "Removed PopScope exit confirmation (no back-swipe guard needed in teaching module)",
      "Removed Drawer (AboutDialog moved into interactive demo list)",
      "Removed AppBar actions (moved to interactive demo toolbar row)",
      "Removed GlobalKey<ScaffoldState>/PersistentBottomSheetController (replaced with inline _showBottomSheet bool toggle)",
      "Added 5 teaching sections: LearningObjectives, ConceptChips (×2 CodeSnippetCard), CommonPitfalls, ExerciseCard",
      "Added smoke test test/popup_widgets/popup_widgets_page_test.dart"
    ]
  }
}
