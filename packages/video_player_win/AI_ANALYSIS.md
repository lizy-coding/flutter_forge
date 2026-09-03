{
  "schema": "vibecoding.harness.ai_analysis.v2",
  "mode": "index",
  "node": {"id":"video_player_win","kind":"workspace_package","package":"video_player_win","path":"packages/video_player_win","status":"active"},
  "entrypoints": ["lib/video_player_win.dart"],
  "owns": ["windows_video_player_backend"],
  "depends": ["flutter","video_player_platform_interface"],
  "children": [],
  "contracts": {"no_natural_language":true,"index_only":true,"max_index_depth":2,"doc_consumer":"coding_agent","doc_mode":"machine_contract"},
  "validation": ["flutter analyze"]
}
