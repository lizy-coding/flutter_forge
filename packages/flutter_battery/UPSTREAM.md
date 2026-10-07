# Flutter Battery integration snapshot

Source: `/Users/forest/code/flutter_battery`, current working tree. This internal plugin dependency avoids an unprovisioned sibling checkout. Source and projected-file hashes are recorded in `upstream-files.json`; a working-tree snapshot is not a released version.

Use upstream `scripts/sync_forge_dependency.py --forge-root /path/to/flutter_forge` to check, then `--apply` to synchronize. The script refuses local Forge package edits and removed source files; it retains Forge workspace settings and formatting. No example app, generated build output or IoT bridge is copied. Run the package tests independently as well as module tests, native builds and the unchanged Forge quality gate.

The module uses independent observation sessions, selecting level/info/health only when those stream capabilities exist. Closing a module releases only its observation. Android and macOS are implemented native hosts; Android device and full manual UI acceptance remain separate. Optional notification/BLE permissions are declared and requested by the host, not the plugin.
